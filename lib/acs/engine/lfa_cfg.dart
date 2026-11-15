// =============================================================================
// CONTEXT-FREE GRAMMARS, WORKED THROUGH: derivation trees, ambiguity, the
// Chomsky normal form step by step, and the CYK table.
//   A nonterminal is a capital letter, maybe followed by subscript digits or
//   primes (S, A, S₀, C₁, A'), so A1 is A then the terminal 1; every other
//   character is a terminal; ε (or e alone)
//   is the empty word. The first rule's left side is the start symbol.
// =============================================================================

import 'lfa.dart';

bool isNonterminal(String s) => RegExp(r"^[A-Z][₀-₉']*$").hasMatch(s);

/// The symbols of a right side: "aSb" -> [a, S, b]; "S₀A1" -> [S₀, A, 1].
List<String> cfgSymbols(String right) {
  final out = <String>[];
  for (final m in RegExp(r"[A-Z][₀-₉']*|.").allMatches(right)) {
    final s = m[0]!;
    if (s == lfaEps || s == 'λ') continue;
    out.add(s);
  }
  return out;
}

class Cfg {
  final String start;
  final Map<String, List<List<String>>> rules; // an empty list is ε; keys in the order written
  const Cfg(this.start, this.rules);

  static Cfg parse(String text) {
    final rules = <String, List<List<String>>>{};
    String? start;
    for (final (n, raw) in text.split('\n').indexed) {
      final line = raw.replaceAll(RegExp(r'\s'), '');
      if (line.isEmpty || line.startsWith('#')) continue;
      final m = RegExp(r"^([A-Z][₀-₉']*)(?:->|→|::=)(.*)$").firstMatch(line);
      if (m == null) throw LfaError('Linia ${n + 1}: scrie o regulă ca „S -> aSb | ε”.');
      start ??= m[1]!;
      for (final alt in m[2]!.split('|')) {
        if (alt.isEmpty) throw LfaError('Linia ${n + 1}: o variantă e goală; pentru cuvântul vid scrie ε.');
        final syms = alt == 'e' ? <String>[] : cfgSymbols(alt);
        final list = rules[m[1]!] ??= [];
        if (!list.any((r) => r.join(' ') == syms.join(' '))) list.add(syms);
      }
    }
    if (start == null) throw const LfaError('Scrie cel puțin o regulă.');
    for (final rs in rules.values) {
      for (final r in rs) {
        for (final s in r) {
          if (isNonterminal(s) && !rules.containsKey(s)) throw LfaError('Neterminalul $s nu are nicio regulă.');
        }
      }
    }
    return Cfg(start, rules);
  }

  Set<String> get nonterminals => rules.keys.toSet();
  Set<String> get terminals => {for (final rs in rules.values) for (final r in rs) for (final s in r) if (!isNonterminal(s)) s};

  /// One rule per line, alternatives joined by |.
  String show() => [
        for (final e in rules.entries)
          if (e.value.isNotEmpty) '${e.key} → ${e.value.map((r) => r.isEmpty ? lfaEps : r.join()).join(' | ')}',
      ].join('\n');

  int get ruleCount => rules.values.fold(0, (a, r) => a + r.length);

  /// Every word of at most [max] symbols.
  Set<String> words(int max) {
    final lang = {for (final a in rules.keys) a: <String>{}};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in rules.entries) {
        for (final right in e.value) {
          var acc = <String>{''};
          for (final s in right) {
            final part = lang[s] ?? {s};
            acc = {
              for (final x in acc)
                for (final y in part)
                  if (x.length + y.length <= max) x + y,
            };
            if (acc.isEmpty) break;
          }
          final into = lang[e.key]!;
          final before = into.length;
          into.addAll(acc);
          if (into.length != before) changed = true;
        }
      }
    }
    return lang[start]!;
  }

  Set<String> nullable() {
    final out = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in rules.entries) {
        if (out.contains(e.key)) continue;
        if (e.value.any((r) => r.every(out.contains))) {
          out.add(e.key);
          changed = true;
        }
      }
    }
    return out;
  }

  /// The nonterminals that generate at least one word of terminals.
  Set<String> generating() {
    final out = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in rules.entries) {
        if (out.contains(e.key)) continue;
        if (e.value.any((r) => r.every((s) => !isNonterminal(s) || out.contains(s)))) {
          out.add(e.key);
          changed = true;
        }
      }
    }
    return out;
  }

  Set<String> reachable() {
    final out = {start};
    final todo = [start];
    while (todo.isNotEmpty) {
      for (final r in rules[todo.removeLast()] ?? const <List<String>>[]) {
        for (final s in r) {
          if (isNonterminal(s) && out.add(s)) todo.add(s);
        }
      }
    }
    return out;
  }

  bool get isChomsky => rules.entries.every((e) => e.value.every((r) =>
      (r.length == 1 && !isNonterminal(r.single)) ||
      (r.length == 2 && r.every(isNonterminal) && r.every((s) => s != start)) ||
      (r.isEmpty && e.key == start)));
}

// ---------------------------------------------------------------- trees
class ParseTree {
  final String sym;
  final List<ParseTree> kids; // empty for a terminal; [ε] for A -> ε
  const ParseTree(this.sym, [this.kids = const []]);

  bool get leaf => kids.isEmpty;
  int get size => 1 + kids.fold(0, (a, k) => a + k.size);
  String get yield => leaf ? (sym == lfaEps ? '' : sym) : kids.map((k) => k.yield).join();
  String get key => leaf ? sym : '$sym(${kids.map((k) => k.key).join(' ')})';

  /// The leftmost derivation this tree stands for: each step rewrites the
  /// leftmost nonterminal.
  List<String> leftmost() {
    final out = <String>[];
    var form = <ParseTree>[this];
    String show(List<ParseTree> f) {
      final s = f.map((t) => t.sym == lfaEps ? '' : t.sym).join();
      return s.isEmpty ? lfaEps : s;
    }

    out.add(show(form));
    while (true) {
      final i = form.indexWhere((t) => !t.leaf);
      if (i < 0) break;
      form = [...form.sublist(0, i), ...form[i].kids, ...form.sublist(i + 1)];
      out.add(show(form));
    }
    return out;
  }

  /// The rules used, in the order of the leftmost derivation.
  List<String> rulesUsed() {
    final out = <String>[];
    void walk(ParseTree t) {
      if (t.leaf) return;
      out.add('${t.sym} → ${t.kids.map((k) => k.sym).join()}');
      t.kids.forEach(walk);
    }

    walk(this);
    return out;
  }
}

/// Up to [limit] different derivation trees of [w] (the smallest first), or
/// none. A table over every piece w[i..j) of the word, filled until it no
/// longer changes, so rules like A -> B, B -> A or A -> ε do not loop.
List<ParseTree> parseTrees(Cfg g, String w, {int limit = 2}) {
  final n = w.length;
  final table = <String, List<ParseTree>>{}; // 'A i j' -> trees
  List<ParseTree> at(String a, int i, int j) => table['$a $i $j'] ?? const [];

  // the ways the symbols r[k..] can cover w[i..j)
  List<List<ParseTree>> cover(List<String> r, int k, int i, int j) {
    if (k == r.length) return i == j ? [const []] : const [];
    final s = r[k];
    final out = <List<ParseTree>>[];
    if (!isNonterminal(s)) {
      if (i < j && w[i] == s) {
        for (final rest in cover(r, k + 1, i + 1, j)) {
          out.add([ParseTree(s), ...rest]);
          if (out.length >= limit) break;
        }
      }
      return out;
    }
    for (var m = i; m <= j; m++) {
      final first = at(s, i, m);
      if (first.isEmpty) continue;
      for (final rest in cover(r, k + 1, m, j)) {
        for (final t in first) {
          out.add([t, ...rest]);
          if (out.length >= limit * 2) return out;
        }
      }
    }
    return out;
  }

  var changed = true;
  for (var round = 0; changed && round < 60; round++) {
    changed = false;
    for (var len = 0; len <= n; len++) {
      for (var i = 0; i + len <= n; i++) {
        final j = i + len;
        for (final e in g.rules.entries) {
          final cand = <ParseTree>[...at(e.key, i, j)];
          for (final r in e.value) {
            if (r.isEmpty) {
              if (len == 0) cand.add(ParseTree(e.key, const [ParseTree(lfaEps)]));
              continue;
            }
            for (final kids in cover(r, 0, i, j)) {
              cand.add(ParseTree(e.key, kids));
            }
          }
          final seen = <String>{};
          final best = [for (final t in cand..sort((x, y) => x.size - y.size)) if (seen.add(t.key)) t].take(limit).toList();
          final old = at(e.key, i, j);
          if (best.length != old.length || [for (var k = 0; k < best.length; k++) best[k].key != old[k].key].any((x) => x)) {
            table['${e.key} $i $j'] = best;
            changed = true;
          }
        }
      }
    }
  }
  return at(g.start, 0, n);
}

// ---------------------------------------------------------------- Chomsky normal form
class CnfStep {
  final String title;
  final String what; // what was done, in a sentence or two
  final Cfg grammar;
  const CnfStep(this.title, this.what, this.grammar);
}

/// The conversion to Chomsky normal form as in the course: a new start
/// symbol, the ε rules taken out, the unit rules (A -> B) taken out, the
/// useless symbols dropped, terminals in long rules given their own
/// nonterminal, long rules cut in two.
List<CnfStep> toChomsky(Cfg g) {
  final steps = <CnfStep>[CnfStep('Gramatica dată', 'Punctul de plecare.', g)];
  final used = {...g.nonterminals};
  String fresh(String base) {
    const sub = '₀₁₂₃₄₅₆₇₈₉';
    for (final c in [base, for (var i = 1; i < 10; i++) '$base${sub[i]}', ...'ZYXWVUTRQPONMLKJIHGFEDCBA'.split('')]) {
      if (!used.contains(c)) {
        used.add(c);
        return c;
      }
    }
    for (var i = 0;; i++) {
      final c = 'X${[for (final d in '$i'.split('')) '₀₁₂₃₄₅₆₇₈₉'[int.parse(d)]].join()}';
      if (used.add(c)) return c;
    }
  }

  Map<String, List<List<String>>> copy(Map<String, List<List<String>>> r) => {for (final e in r.entries) e.key: [for (final x in e.value) [...x]]};
  void addRule(Map<String, List<List<String>>> r, String a, List<String> right) {
    final list = r[a] ??= [];
    if (!list.any((x) => x.join(' ') == right.join(' '))) list.add(right);
  }

  // 1. a new start symbol, so the start never appears on a right side
  var start = g.start;
  var rules = copy(g.rules);
  final s0 = fresh('${g.start}₀');
  rules = {s0: [[g.start]], ...rules};
  start = s0;
  steps.add(CnfStep('1. Simbol de start nou', 'Adăugăm $s0 → ${g.start}, ca simbolul de start să nu apară în dreapta niciunei reguli.', Cfg(start, rules)));

  // 2. ε rules
  final nullable = Cfg(start, rules).nullable();
  final r2 = <String, List<List<String>>>{};
  for (final e in rules.entries) {
    for (final r in e.value) {
      final idx = [for (var k = 0; k < r.length; k++) if (nullable.contains(r[k])) k];
      for (var mask = 0; mask < (1 << idx.length); mask++) {
        final drop = {for (var b = 0; b < idx.length; b++) if (mask & (1 << b) != 0) idx[b]};
        final v = [for (var k = 0; k < r.length; k++) if (!drop.contains(k)) r[k]];
        if (v.isEmpty && e.key != start) continue;
        addRule(r2, e.key, v);
      }
    }
    r2.putIfAbsent(e.key, () => []);
  }
  rules = r2;
  steps.add(CnfStep(
      '2. Eliminarea regulilor ε',
      nullable.isEmpty
          ? 'Niciun neterminal nu generează ε: nu e nimic de făcut.'
          : 'Generează ε: ${(nullable.toList()..sort()).join(', ')}. În fiecare regulă adăugăm variantele fără aceste simboluri și scoatem regulile A → ε${nullable.contains(start) ? ' (rămâne doar $start → ε, pentru că ε e în limbaj)' : ''}.',
      Cfg(start, rules)));

  // 3. unit rules: A -> B is replaced by A -> what B gives (not a unit)
  final unitOf = <String, Set<String>>{};
  for (final a in rules.keys) {
    final reach = {a};
    final todo = [a];
    while (todo.isNotEmpty) {
      for (final r in rules[todo.removeLast()] ?? const <List<String>>[]) {
        if (r.length == 1 && isNonterminal(r.single) && reach.add(r.single)) todo.add(r.single);
      }
    }
    unitOf[a] = reach;
  }
  final hadUnit = rules.values.any((rs) => rs.any((r) => r.length == 1 && isNonterminal(r.single)));
  final r3 = <String, List<List<String>>>{};
  for (final a in rules.keys) {
    r3[a] = [];
    for (final b in unitOf[a]!) {
      for (final r in rules[b] ?? const <List<String>>[]) {
        if (r.length == 1 && isNonterminal(r.single)) continue;
        addRule(r3, a, r);
      }
    }
  }
  rules = r3;
  steps.add(CnfStep('3. Eliminarea redenumirilor (A → B)',
      hadUnit ? 'Pentru fiecare A → B, A primește direct regulile lui B (și ale celor în care se ajunge din B tot prin redenumiri).' : 'Nu există reguli A → B.', Cfg(start, rules)));

  // 4. useless symbols: first what generates nothing, then what can't be reached
  final gen = Cfg(start, rules).generating();
  var r4 = <String, List<List<String>>>{
    for (final e in rules.entries)
      if (gen.contains(e.key)) e.key: [for (final r in e.value) if (r.every((s) => !isNonterminal(s) || gen.contains(s))) r],
  };
  if (!r4.containsKey(start)) r4 = {start: []};
  final reach = Cfg(start, r4).reachable();
  r4 = {for (final e in r4.entries) if (reach.contains(e.key)) e.key: e.value};
  final dropped = rules.keys.where((k) => !r4.containsKey(k)).toList();
  rules = r4;
  steps.add(CnfStep('4. Simboluri inutile',
      dropped.isEmpty ? 'Toate neterminalele generează cuvinte și pot fi atinse din start.' : 'Scoatem ${dropped.join(', ')}: nu generează niciun cuvânt sau nu pot fi atinse din $start.', Cfg(start, rules)));

  // 5. terminals in rules of length >= 2 get a nonterminal of their own
  final forTerm = <String, String>{};
  final r5 = <String, List<List<String>>>{};
  for (final e in rules.entries) {
    r5[e.key] = [];
    for (final r in e.value) {
      if (r.length < 2) {
        addRule(r5, e.key, r);
        continue;
      }
      addRule(r5, e.key, [
        for (final s in r)
          if (isNonterminal(s)) s else forTerm.putIfAbsent(s, () => fresh(s.toUpperCase() == s ? 'T' : "${s.toUpperCase()}'")),
      ]);
    }
  }
  for (final e in forTerm.entries) {
    r5[e.value] = [
      [e.key],
    ];
  }
  rules = r5;
  steps.add(CnfStep('5. Terminalele din regulile lungi',
      forTerm.isEmpty ? 'Nicio regulă lungă nu conține terminale.' : 'Fiecare terminal dintr-o regulă cu cel puțin două simboluri e înlocuit cu un neterminal nou: ${forTerm.entries.map((e) => '${e.value} → ${e.key}').join(', ')}.', Cfg(start, rules)));

  // 6. long rules A -> B1 B2 ... Bk become a chain of two-symbol rules
  final r6 = <String, List<List<String>>>{};
  var cut = 0;
  for (final e in rules.entries) {
    r6.putIfAbsent(e.key, () => []);
    for (final r in e.value) {
      if (r.length <= 2) {
        addRule(r6, e.key, r);
        continue;
      }
      var left = e.key;
      for (var k = 0; k < r.length - 2; k++) {
        final c = fresh('C');
        addRule(r6, left, [r[k], c]);
        r6.putIfAbsent(c, () => []);
        left = c;
        cut++;
      }
      addRule(r6, left, [r[r.length - 2], r.last]);
    }
  }
  rules = r6;
  steps.add(CnfStep('6. Regulile lungi, tăiate în două',
      cut == 0 ? 'Toate regulile au cel mult două simboluri.' : 'O regulă A → B1B2…Bk devine A → B1C1, C1 → B2C2, …, Ck-2 → Bk-1Bk.', Cfg(start, rules)));
  return steps;
}

// ---------------------------------------------------------------- CYK
class CykResult {
  final String word;
  final List<List<Set<String>>> table; // table[len - 1][i]: what generates w[i, i + len)
  final bool accepted;
  const CykResult(this.word, this.table, this.accepted);
}

/// The CYK table of [w] for a grammar in Chomsky normal form.
CykResult cyk(Cfg g, String w) {
  final n = w.length;
  if (n == 0) return CykResult(w, const [], g.rules[g.start]?.any((r) => r.isEmpty) ?? false);
  final t = [for (var l = 1; l <= n; l++) [for (var i = 0; i + l <= n; i++) <String>{}]];
  for (var i = 0; i < n; i++) {
    for (final e in g.rules.entries) {
      if (e.value.any((r) => r.length == 1 && r.single == w[i])) t[0][i].add(e.key);
    }
  }
  for (var l = 2; l <= n; l++) {
    for (var i = 0; i + l <= n; i++) {
      for (var k = 1; k < l; k++) {
        final left = t[k - 1][i], right = t[l - k - 1][i + k];
        for (final e in g.rules.entries) {
          if (e.value.any((r) => r.length == 2 && left.contains(r[0]) && right.contains(r[1]))) t[l - 1][i].add(e.key);
        }
      }
    }
  }
  return CykResult(w, t, t[n - 1][0].contains(g.start));
}
