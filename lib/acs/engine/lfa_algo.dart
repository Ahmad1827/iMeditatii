// =============================================================================
// LFA ALGORITHMS, STEP BY STEP: what the theory pages show being done
//   Regular expressions as trees (simplified as they are built, printed with
//   as few parentheses as the meaning allows); state elimination (an
//   automaton to an expression, one state at a time, as in Stanford's CS103
//   guide); the subset construction, row by row; minimisation by marking
//   pairs of states, round by round; the product of two automata; Thompson's
//   construction with the place of every state; a layered layout for any
//   automaton.
// =============================================================================

import 'dart:math' as math;

import 'lfa.dart';

// ---------------------------------------------------------------- expressions
enum ReKind { empty, eps, sym, cat, alt, star }

/// A regular expression as a tree. The constructors simplify what is
/// obviously equal: ∅ in a concatenation, ε beside something, a union that
/// repeats itself, a star of a star.
class Re {
  final ReKind kind;
  final String sym;
  final List<Re> parts;
  Re._(this.kind, [this.sym = '', this.parts = const []]);

  static final Re empty = Re._(ReKind.empty);
  static final Re eps = Re._(ReKind.eps);
  factory Re.sym(String c) => c == lfaEps ? eps : Re._(ReKind.sym, c);

  static Re cat(List<Re> xs) {
    final out = <Re>[];
    for (final x in xs) {
      if (x.kind == ReKind.empty) return empty;
      if (x.kind == ReKind.eps) continue;
      if (x.kind == ReKind.cat) {
        out.addAll(x.parts);
      } else {
        out.add(x);
      }
    }
    // X*X* is X*
    for (var i = out.length - 1; i > 0; i--) {
      if (out[i].kind == ReKind.star && out[i].key == out[i - 1].key) out.removeAt(i);
    }
    if (out.isEmpty) return eps;
    if (out.length == 1) return out.single;
    return Re._(ReKind.cat, '', out);
  }

  static Re alt(List<Re> xs) {
    final out = <Re>[];
    final seen = <String>{};
    void add(Re x) {
      if (x.kind == ReKind.empty) return;
      if (x.kind == ReKind.alt) {
        x.parts.forEach(add);
        return;
      }
      if (seen.add(x.key)) out.add(x);
    }

    xs.forEach(add);
    // ε ∪ X* is X*: the star already has ε
    if (out.any((x) => x.kind == ReKind.eps) && out.any((x) => x.kind == ReKind.star)) {
      out.removeWhere((x) => x.kind == ReKind.eps);
    }
    if (out.isEmpty) return empty;
    if (out.length == 1) return out.single;
    return Re._(ReKind.alt, '', out);
  }

  static Re star(Re x) {
    switch (x.kind) {
      case ReKind.empty:
      case ReKind.eps:
        return eps;
      case ReKind.star:
        return x;
      case ReKind.alt:
        // (ε ∪ X)* is X*
        final rest = x.parts.where((p) => p.kind != ReKind.eps).toList();
        if (rest.length != x.parts.length) return star(alt(rest));
        return Re._(ReKind.star, '', [x]);
      default:
        return Re._(ReKind.star, '', [x]);
    }
  }

  /// The same expression, written; equal keys mean equal trees.
  late final String key = show();

  int get _prec => switch (kind) { ReKind.alt => 0, ReKind.cat => 1, _ => 2 };

  /// Written with ∪, ε, ∅ and *; [sigma] (the alphabet) is written Σ where a
  /// union is exactly all of it.
  String show({List<String>? sigma}) {
    switch (kind) {
      case ReKind.empty:
        return '∅';
      case ReKind.eps:
        return lfaEps;
      case ReKind.sym:
        return sym;
      case ReKind.star:
        final p = parts.single;
        final inner = p.show(sigma: sigma);
        final atom = p.kind == ReKind.sym || (sigma != null && _isSigma(p, sigma));
        return atom ? '$inner*' : '($inner)*';
      case ReKind.cat:
        return parts.map((p) {
          final s = p.show(sigma: sigma);
          return p._prec < 1 && !(sigma != null && _isSigma(p, sigma)) ? '($s)' : s;
        }).join();
      case ReKind.alt:
        if (sigma != null && _isSigma(this, sigma)) return 'Σ';
        return parts.map((p) => p.show(sigma: sigma)).join(' ∪ ');
    }
  }

  static bool _isSigma(Re r, List<String> sigma) =>
      sigma.length > 1 &&
      r.kind == ReKind.alt &&
      r.parts.length == sigma.length &&
      r.parts.every((p) => p.kind == ReKind.sym) &&
      r.parts.map((p) => p.sym).toSet().containsAll(sigma);

  int get size => switch (kind) {
        ReKind.empty || ReKind.eps || ReKind.sym => 1,
        _ => 1 + parts.fold(0, (a, p) => a + p.size),
      };

  @override
  String toString() => key;

  /// Parsed from the course's writing (see [Regex] in lfa.dart): alternation
  /// with ∪ or |, *, + and ?, ε, ∅, parentheses.
  static Re parse(String text, List<String> alphabet) => _ReParser(text.replaceAll(RegExp(r'\s'), ''), alphabet).parse();
}

class _ReParser {
  final String s;
  final List<String> alphabet;
  int i = 0;
  _ReParser(this.s, this.alphabet);

  String? get peek => i < s.length ? s[i] : null;

  Re parse() {
    if (s.isEmpty) throw const LfaError('Scrie o expresie.');
    final r = _alt();
    if (i < s.length) throw LfaError('Nu înțeleg „${s[i]}” la poziția ${i + 1}.');
    return r;
  }

  Re _alt() {
    final xs = [_cat()];
    while (peek == '∪' || peek == '|') {
      i++;
      xs.add(_cat());
    }
    return xs.length == 1 ? xs.single : Re._(ReKind.alt, '', xs);
  }

  Re _cat() {
    final xs = <Re>[];
    while (peek != null && peek != ')' && peek != '∪' && peek != '|') {
      xs.add(_post());
    }
    if (xs.isEmpty) throw LfaError(peek == null ? 'Expresia se termină prea devreme.' : 'Lipsește ceva înainte de „$peek”.');
    return xs.length == 1 ? xs.single : Re._(ReKind.cat, '', xs);
  }

  Re _post() {
    var r = _atom();
    while (peek == '*' || peek == '+' || peek == '?') {
      final op = s[i++];
      r = switch (op) {
        '*' => Re._(ReKind.star, '', [r]),
        '+' => Re._(ReKind.cat, '', [r, Re._(ReKind.star, '', [r])]),
        _ => Re._(ReKind.alt, '', [r, Re.eps]),
      };
    }
    return r;
  }

  Re _atom() {
    final c = s[i++];
    if (c == '(') {
      if (peek == ')') {
        i++;
        return Re.eps;
      }
      final r = _alt();
      if (peek != ')') throw const LfaError('Lipsește o paranteză „)”.');
      i++;
      return r;
    }
    if (c == lfaEps || c == 'λ' || c == '_') return Re.eps;
    if (c == '∅' || c == '@') return Re.empty;
    if (c == 'Σ') return Re._(ReKind.alt, '', [for (final a in alphabet) Re.sym(a)]);
    if (alphabet.contains(c)) return Re.sym(c);
    if (c == ')' || c == '*' || c == '+' || c == '?') throw LfaError('„$c” nu are ce să urmeze la poziția $i.');
    throw LfaError('„$c” nu e în alfabet ({${alphabet.join(', ')}}).');
  }
}

// ---------------------------------------------------------------- state elimination
/// An automaton whose arrows carry expressions. States are numbered; the
/// original ones keep their numbers, the new start and final states are
/// [start] and [accept].
class Gnfa {
  final List<String> names;
  final Set<int> alive;
  final Map<(int, int), Re> edges;
  final int start, accept;
  const Gnfa(this.names, this.alive, this.edges, this.start, this.accept);

  /// Step one: a new start with ε to the old one, a new final state with ε
  /// from every old final one.
  factory Gnfa.of(Nfa a, List<String> alphabet, {List<String>? names}) {
    final n = a.states;
    final edges = <(int, int), Re>{};
    void add(int p, int q, Re r) => edges[(p, q)] = edges.containsKey((p, q)) ? Re.alt([edges[(p, q)]!, r]) : r;
    for (var p = 0; p < n; p++) {
      for (final c in [...alphabet, lfaEps]) {
        for (final q in a.targets(p, c)) {
          add(p, q, Re.sym(c));
        }
      }
    }
    add(n, 0, Re.eps);
    for (final f in a.accepting) {
      add(f, n + 1, Re.eps);
    }
    return Gnfa([...(names ?? [for (var i = 0; i < n; i++) 'q$i']), 'qs', 'qf'], {for (var i = 0; i < n + 2; i++) i}, edges, n, n + 1);
  }

  Re edge(int p, int q) => edges[(p, q)] ?? Re.empty;

  /// The states that can still be eliminated: all but the new start and final.
  List<int> get inner => [for (final s in alive.toList()..sort()) if (s != start && s != accept) s];

  /// The pairs (in, out) that eliminating [q] joins, with the expression of
  /// the new arrow alone and merged with what was already there.
  List<ElimPair> pairs(int q) {
    final loop = edges[(q, q)];
    final out = <ElimPair>[];
    for (final p in alive.toList()..sort()) {
      if (p == q || !edges.containsKey((p, q))) continue;
      for (final r in alive.toList()..sort()) {
        if (r == q || !edges.containsKey((q, r))) continue;
        final through = Re.cat([edges[(p, q)]!, if (loop != null) Re.star(loop), edges[(q, r)]!]);
        final before = edges[(p, r)];
        out.add(ElimPair(p, r, edges[(p, q)]!, loop, edges[(q, r)]!, through, before, before == null ? through : Re.alt([before, through])));
      }
    }
    return out;
  }

  Gnfa eliminate(int q) {
    final next = <(int, int), Re>{
      for (final e in edges.entries)
        if (e.key.$1 != q && e.key.$2 != q) e.key: e.value,
    };
    for (final p in pairs(q)) {
      next[(p.from, p.to)] = p.merged;
    }
    next.removeWhere((_, r) => r.kind == ReKind.empty);
    return Gnfa(names, {...alive}..remove(q), next, start, accept);
  }

  /// A good next state: the one whose elimination makes the fewest new arrows.
  int get cheapest {
    var best = inner.first;
    var cost = 1 << 30;
    for (final q in inner) {
      final c = pairs(q).fold(0, (a, p) => a + p.through.size);
      if (c < cost) {
        cost = c;
        best = q;
      }
    }
    return best;
  }

  /// Step three: the expression on the only arrow left.
  Re get result => edge(start, accept);
}

class ElimPair {
  final int from, to;
  final Re rin;
  final Re? loop;
  final Re rout;
  final Re through; // Rin (Rloop)* Rout
  final Re? before; // what already went from [from] to [to]
  final Re merged;
  const ElimPair(this.from, this.to, this.rin, this.loop, this.rout, this.through, this.before, this.merged);
}

// ---------------------------------------------------------------- subset construction
class SubsetRow {
  final Set<int> set;
  final Map<String, Set<int>> moves; // symbol -> the closure of where it goes
  final Map<String, Set<int>> raw; // symbol -> where it goes before the ε closure
  final bool accepting;
  const SubsetRow(this.set, this.moves, this.raw, this.accepting);
}

String setName(Set<int> s, {String prefix = ''}) => s.isEmpty ? '∅' : '{${(s.toList()..sort()).map((x) => '$prefix$x').join(',')}}';

/// The rows of the subset construction in the order they are found (a queue,
/// from the closure of the start state).
List<SubsetRow> subsetRows(Nfa a, List<String> alphabet) {
  String key(Set<int> s) => (s.toList()..sort()).join(',');
  final start = a.closure({0});
  final rows = <SubsetRow>[];
  final queue = [start];
  final seen = {key(start)};
  for (var i = 0; i < queue.length; i++) {
    final s = queue[i];
    final moves = <String, Set<int>>{}, raw = <String, Set<int>>{};
    for (final c in alphabet) {
      final r = {for (final p in s) ...a.targets(p, c)};
      final t = a.closure(r);
      raw[c] = r;
      moves[c] = t;
      if (seen.add(key(t))) queue.add(t);
    }
    rows.add(SubsetRow(s, moves, raw, s.any(a.accepting.contains)));
  }
  return rows;
}

// ---------------------------------------------------------------- a drawing
/// What a diagram shows: named states at places (in grid units), arrows with
/// labels. [pos] may be empty: [layered] then places the states.
class Diagram {
  final List<String> names;
  final List<(double, double)> pos;
  final Set<int> finals;
  final int start;
  final List<(int, int, String)> edges;
  /// How far each arrow bows out (grid units, to the left of its direction;
  /// null where the drawing decides).
  final List<double?>? bends;
  const Diagram(this.names, this.pos, this.finals, this.start, this.edges, {this.bends});

  int get n => names.length;

  /// From an automaton: arrows between the same two states share one label.
  factory Diagram.ofNfa(Nfa a, List<String> symbols, {List<String>? names, List<(double, double)>? pos}) {
    final by = <(int, int), List<String>>{};
    for (var s = 0; s < a.states; s++) {
      for (final c in symbols) {
        for (final t in a.targets(s, c).toList()..sort()) {
          (by[(s, t)] ??= []).add(c);
        }
      }
    }
    final d = Diagram(names ?? [for (var i = 0; i < a.states; i++) 'q$i'], pos ?? const [], a.accepting, 0,
        [for (final e in by.entries) (e.key.$1, e.key.$2, e.value.join(','))]);
    return d.pos.length == d.n ? d : d.layered();
  }

  /// States in columns by their distance from the start (a breadth-first
  /// walk), those never reached in a last column.
  Diagram layered() {
    final depth = List<int>.filled(n, -1);
    if (n > 0) depth[start] = 0;
    final queue = [start];
    for (var i = 0; i < queue.length; i++) {
      for (final (f, t, _) in edges) {
        if (f == queue[i] && depth[t] < 0) {
          depth[t] = depth[f] + 1;
          queue.add(t);
        }
      }
    }
    final maxD = depth.fold(0, math.max);
    for (var i = 0; i < n; i++) {
      if (depth[i] < 0) depth[i] = maxD + 1;
    }
    final cols = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      (cols[depth[i]] ??= []).add(i);
    }
    final tallest = cols.values.fold(1, (m, c) => math.max(m, c.length));
    final p = List<(double, double)>.filled(n, (0, 0));
    for (final e in cols.entries) {
      for (final (k, s) in e.value.indexed) {
        p[s] = (e.key * 1.6, (tallest - e.value.length) / 2 + k * 1.2);
      }
    }
    return Diagram(names, p, finals, start, edges, bends: bends);
  }
}

// ---------------------------------------------------------------- minimisation
class MinResult {
  final List<int> reach; // the reachable states, start first
  final Map<(int, int), (int, String)> marked; // pair (p < q) -> (round, the symbol that told them apart; '' for round 0)
  final int rounds;
  final List<List<int>> classes; // the states merged, each class sorted
  const MinResult(this.reach, this.marked, this.rounds, this.classes);

  (int, String)? mark(int p, int q) => marked[p < q ? (p, q) : (q, p)];
}

/// The table-filling algorithm on a complete DFA: pairs with one final and one
/// non-final state are marked in round 0; a pair is marked in round k when a
/// symbol takes it to a pair marked earlier. What is never marked merges.
MinResult minimise(Dfa d) {
  final reach = <int>[0];
  for (var i = 0; i < reach.length; i++) {
    for (final t in d.next[reach[i]]) {
      if (!reach.contains(t)) reach.add(t);
    }
  }
  final marked = <(int, int), (int, String)>{};
  (int, int) pair(int p, int q) => p < q ? (p, q) : (q, p);
  for (final p in reach) {
    for (final q in reach) {
      if (p < q && d.accepting[p] != d.accepting[q]) marked[(p, q)] = (0, '');
    }
  }
  var round = 0;
  while (true) {
    round++;
    final fresh = <(int, int), (int, String)>{};
    for (final p in reach) {
      for (final q in reach) {
        if (p >= q || marked.containsKey((p, q))) continue;
        for (var k = 0; k < d.alphabet.length; k++) {
          final a = d.next[p][k], b = d.next[q][k];
          if (a != b && marked.containsKey(pair(a, b))) {
            fresh[(p, q)] = (round, d.alphabet[k]);
            break;
          }
        }
      }
    }
    if (fresh.isEmpty) break;
    marked.addAll(fresh);
  }
  final classes = <List<int>>[];
  final placed = <int>{};
  for (final p in reach) {
    if (placed.contains(p)) continue;
    final c = [p, for (final q in reach) if (q != p && !placed.contains(q) && !marked.containsKey(pair(p, q))) q]..sort();
    placed.addAll(c);
    classes.add(c);
  }
  return MinResult(reach, marked, round - 1, classes);
}

/// The merged automaton of [m]: one state per class, the start's class first.
(Nfa, List<String>) minimalOf(Dfa d, MinResult m) {
  int cls(int s) => m.classes.indexWhere((c) => c.contains(s));
  final moves = <int, Map<String, Set<int>>>{};
  for (final (i, c) in m.classes.indexed) {
    moves[i] = {for (var k = 0; k < d.alphabet.length; k++) d.alphabet[k]: {cls(d.next[c.first][k])}};
  }
  return (
    Nfa(m.classes.length, {for (final (i, c) in m.classes.indexed) if (d.accepting[c.first]) i}, moves),
    [for (final c in m.classes) c.length == 1 ? 'q${c.single}' : c.map((s) => 'q$s').join('')],
  );
}

// ---------------------------------------------------------------- product
enum ProductOp { inter, union, minus, xor }

String productOpName(ProductOp op) => switch (op) { ProductOp.inter => '∩', ProductOp.union => '∪', ProductOp.minus => '\\', ProductOp.xor => '△' };

/// The product of two complete DFAs over one alphabet: a state is a pair, the
/// final pairs are the ones [op] keeps. Only the pairs reached are made.
(Nfa, List<String>) product(Dfa a, Dfa b, ProductOp op) {
  final pairs = <(int, int)>[(0, 0)];
  final moves = <int, Map<String, Set<int>>>{};
  for (var i = 0; i < pairs.length; i++) {
    final (p, q) = pairs[i];
    final row = <String, Set<int>>{};
    for (var k = 0; k < a.alphabet.length; k++) {
      final t = (a.next[p][k], b.next[q][k]);
      var j = pairs.indexOf(t);
      if (j < 0) {
        j = pairs.length;
        pairs.add(t);
      }
      row[a.alphabet[k]] = {j};
    }
    moves[i] = row;
  }
  bool keep(bool x, bool y) => switch (op) { ProductOp.inter => x && y, ProductOp.union => x || y, ProductOp.minus => x && !y, ProductOp.xor => x != y };
  return (
    Nfa(pairs.length, {for (final (i, (p, q)) in pairs.indexed) if (keep(a.accepting[p], b.accepting[q])) i}, moves),
    [for (final (p, q) in pairs) '$p,$q'],
  );
}

// ---------------------------------------------------------------- Thompson
/// Thompson's construction with a place for every state: a symbol is two
/// states side by side, a concatenation puts its parts in a row, a union
/// stacks them between a new start and a new end, a star wraps its part.
/// [order] gives, for each arrow, when it was made (to show the automaton
/// being built).
class ThompsonResult {
  final Nfa nfa;
  final List<(double, double)> pos;
  final List<(int, String, int)> moves; // in the order made
  final List<(String, int, int)> pieces; // (sub-expression, its start, its end), smallest first
  final Map<(int, int), double> bends; // the star's arcs: the skip below, the way back above
  const ThompsonResult(this.nfa, this.pos, this.moves, this.pieces, this.bends);
}

ThompsonResult thompson(Re r) {
  final pos = <(double, double)>[];
  final moves = <(int, String, int)>[];
  final pieces = <(String, int, int)>[];
  final bends = <(int, int), double>{};
  int node(double x, double y) {
    pos.add((x, y));
    return pos.length - 1;
  }

  // the size (columns, rows) of each part, before placing it
  (double, double) size(Re r) => switch (r.kind) {
        ReKind.empty || ReKind.eps || ReKind.sym => (2, 1),
        ReKind.cat => (r.parts.fold(0.0, (a, p) => a + size(p).$1), r.parts.fold(0.0, (a, p) => math.max(a, size(p).$2))),
        ReKind.alt => (r.parts.fold(0.0, (a, p) => math.max(a, size(p).$1)) + 2, r.parts.fold(0.0, (a, p) => a + size(p).$2)),
        ReKind.star => (size(r.parts.single).$1 + 2, size(r.parts.single).$2 + 1.1),
      };

  (int, int) build(Re r, double x, double y) {
    final (w, h) = size(r);
    final mid = y + h / 2;
    late (int, int) out;
    switch (r.kind) {
      case ReKind.empty:
      case ReKind.eps:
      case ReKind.sym:
        final s = node(x, mid), e = node(x + 1, mid);
        if (r.kind != ReKind.empty) moves.add((s, r.kind == ReKind.eps ? lfaEps : r.sym, e));
        out = (s, e);
      case ReKind.cat:
        var cx = x;
        (int, int)? acc;
        for (final p in r.parts) {
          final (pw, ph) = size(p);
          final f = build(p, cx, y + (h - ph) / 2);
          if (acc != null) moves.add((acc.$2, lfaEps, f.$1));
          acc = acc == null ? f : (acc.$1, f.$2);
          cx += pw;
        }
        out = acc!;
      case ReKind.alt:
        final s = node(x, mid);
        final inner = w - 2;
        var cy = y;
        final ends = <int>[];
        for (final p in r.parts) {
          final (pw, ph) = size(p);
          final f = build(p, x + 1 + (inner - pw) / 2, cy);
          moves.add((s, lfaEps, f.$1));
          ends.add(f.$2);
          cy += ph;
        }
        final e = node(x + w - 1, mid);
        for (final f in ends) {
          moves.add((f, lfaEps, e));
        }
        out = (s, e);
      case ReKind.star:
        final p = r.parts.single;
        final (pw, ph) = size(p);
        final s = node(x, y + 0.55 + ph / 2);
        final f = build(p, x + 1, y + 0.55);
        final e = node(x + 1 + pw, y + 0.55 + ph / 2);
        moves
          ..add((s, lfaEps, f.$1))
          ..add((f.$2, lfaEps, f.$1))
          ..add((f.$2, lfaEps, e))
          ..add((s, lfaEps, e));
        // a quadratic arc reaches half its control's distance: twice the room above or below the part
        bends[(f.$2, f.$1)] = (ph / 2 + 0.45) * 2;
        bends[(s, e)] = (ph / 2 + 0.5) * 2;
        out = (s, e);
    }
    pieces.add((r.show(), out.$1, out.$2));
    return out;
  }

  final (s, e) = build(r, 0, 0);
  // the start is state 0: swap it with whatever had number 0
  int at(int q) => q == s ? 0 : (q == 0 ? s : q);
  final p2 = [...pos];
  p2[0] = pos[s];
  p2[s] = pos[0];
  final m2 = [for (final (f, c, t) in moves) (at(f), c, at(t))];
  final nfaMoves = <int, Map<String, Set<int>>>{};
  for (final (f, c, t) in m2) {
    ((nfaMoves[f] ??= {})[c] ??= {}).add(t);
  }
  return ThompsonResult(Nfa(pos.length, {at(e)}, nfaMoves), p2, m2, [for (final (t, a, b) in pieces) (t, at(a), at(b))], {
    for (final e in bends.entries) (at(e.key.$1), at(e.key.$2)): e.value,
  });
}
