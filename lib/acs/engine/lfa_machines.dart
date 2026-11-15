// =============================================================================
// PUSHDOWN AUTOMATA AND TURING MACHINES, WRITTEN ONE TRANSITION PER LINE
//   A pushdown automaton as in the course (Lewis & Papadimitriou): a move
//   ((p, a, β), (q, γ)) reads a (or nothing), takes β off the top of the
//   stack and puts γ there, the first symbol on top. A word is accepted when
//   the automaton can read all of it and stop in a final state with the
//   stack empty. A Turing machine: δ(q, a) = (p, b, D), write b, move the
//   head L, R or stay (S); or, as in the course, write or move: (p, b),
//   (p, L), (p, R). The tape is blank (#) on both sides of the word, the
//   head starts on its first symbol; it accepts by reaching a halting state
//   (h, y or acc), rejects in n or rej, or when no move is written.
// =============================================================================

import 'lfa.dart';

const String tmBlank = '#';

String _clean(String s) => s.replaceAll(RegExp(r'\s'), '');
bool _isEmptyWord(String s) => s.isEmpty || s == lfaEps || s == 'e' || s == 'λ' || s == '_';

// ---------------------------------------------------------------- pushdown
class PdaMove {
  final String from, read, pop, to, push; // read, pop, push: '' for ε
  const PdaMove(this.from, this.read, this.pop, this.to, this.push);
  String show() => '(($from, ${read.isEmpty ? lfaEps : read}, ${pop.isEmpty ? lfaEps : pop}), ($to, ${push.isEmpty ? lfaEps : push}))';
}

class PdaConfig {
  final String state;
  final int pos; // how much of the word is read
  final String stack; // top first
  const PdaConfig(this.state, this.pos, this.stack);
  String get key => '$state|$pos|$stack';
}

class PdaRun {
  final bool accepted;
  final List<PdaConfig> path; // the accepting run, or the longest one tried
  final List<PdaMove?> moves; // the move taken into each configuration of [path]
  final bool cut; // the search stopped at its limit
  const PdaRun(this.accepted, this.path, this.moves, this.cut);
}

class Pda {
  final List<String> states; // in the order met; [start] among them
  final String start;
  final Set<String> finals;
  final List<PdaMove> moves;
  const Pda(this.states, this.start, this.finals, this.moves);

  /// One line per move: `p, a, β -> q, γ` (ε, e or nothing for the empty
  /// word); `start s` and `final f1 f2` name the start and final states. The
  /// first state written is the start when no line says otherwise.
  static Pda parse(String text) {
    final states = <String>[];
    String? start;
    final finals = <String>{};
    final moves = <PdaMove>[];
    void note(String s) {
      if (!states.contains(s)) states.add(s);
    }

    for (final (n, raw) in text.split('\n').indexed) {
      var line = raw.trim();
      final hash = line.indexOf('//');
      if (hash >= 0) line = line.substring(0, hash).trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final kw = RegExp(r'^(start|initial[aă]?|final[eă]?|finale|F)\s*[:=]?\s*(.*)$', caseSensitive: false).firstMatch(line);
      if (kw != null && !line.contains('->') && !line.contains('→')) {
        final names = kw[2]!.split(RegExp(r'[\s,;{}]+')).where((s) => s.isNotEmpty).toList();
        if (kw[1]!.toLowerCase().startsWith('f')) {
          finals.addAll(names);
          names.forEach(note);
        } else if (names.isNotEmpty) {
          start = names.first;
          note(start);
        }
        continue;
      }
      final m = RegExp(r'^\(*\s*([^,()]+?)\s*,\s*([^,()]*?)\s*,\s*([^,()]*?)\s*\)*\s*(?:->|→)\s*\(*\s*([^,()]+?)\s*,\s*([^,()]*?)\s*\)*$').firstMatch(line);
      if (m == null) throw LfaError('Linia ${n + 1}: scrie o tranziție ca „q0, a, ε -> q1, A” (stare, citește, scoate -> stare, pune).');
      String word(String s) => _isEmptyWord(_clean(s)) ? '' : _clean(s);
      final read = word(m[2]!);
      final mv = PdaMove(_clean(m[1]!), read, word(m[3]!), _clean(m[4]!), word(m[5]!));
      note(mv.from);
      note(mv.to);
      moves.add(mv);
    }
    if (states.isEmpty) throw const LfaError('Scrie cel puțin o tranziție.');
    return Pda(states, start ?? states.first, finals, moves);
  }

  /// A breadth-first search over configurations, the stack kept below
  /// [maxStack] symbols, at most [limit] configurations.
  PdaRun run(String w, {int maxStack = 0, int limit = 20000}) {
    final cap = maxStack > 0 ? maxStack : 2 * w.length + 8;
    final first = PdaConfig(start, 0, '');
    final seen = {first.key: -1};
    final configs = [first];
    final parent = <int>[-1];
    final via = <PdaMove?>[null];
    var best = 0;
    for (var i = 0; i < configs.length; i++) {
      final c = configs[i];
      if (c.pos == w.length && c.stack.isEmpty && finals.contains(c.state)) return _path(configs, parent, via, i, true, false);
      if (c.pos > configs[best].pos) best = i;
      if (configs.length > limit) return _path(configs, parent, via, best, false, true);
      for (final m in moves) {
        if (m.from != c.state) continue;
        if (m.read.isNotEmpty && !w.startsWith(m.read, c.pos)) continue;
        if (!c.stack.startsWith(m.pop)) continue;
        final stack = m.push + c.stack.substring(m.pop.length);
        if (stack.length > cap) continue;
        final next = PdaConfig(m.to, c.pos + m.read.length, stack);
        if (seen.containsKey(next.key)) continue;
        seen[next.key] = i;
        configs.add(next);
        parent.add(i);
        via.add(m);
      }
    }
    return _path(configs, parent, via, best, false, false);
  }

  PdaRun _path(List<PdaConfig> configs, List<int> parent, List<PdaMove?> via, int end, bool ok, bool cut) {
    final path = <PdaConfig>[], ms = <PdaMove?>[];
    for (var i = end; i >= 0; i = parent[i]) {
      path.add(configs[i]);
      ms.add(via[i]);
    }
    return PdaRun(ok, path.reversed.toList(), ms.reversed.toList(), cut);
  }

  bool accepts(String w) => run(w).accepted;

  /// The automaton as a drawing's arrows: (from, to, label) with labels "a,β/γ".
  List<(int, int, String)> arrows() {
    final by = <(int, int), List<String>>{};
    for (final m in moves) {
      (by[(states.indexOf(m.from), states.indexOf(m.to))] ??= []).add('${m.read.isEmpty ? lfaEps : m.read},${m.pop.isEmpty ? lfaEps : m.pop}/${m.push.isEmpty ? lfaEps : m.push}');
    }
    return [for (final e in by.entries) (e.key.$1, e.key.$2, e.value.join('\n'))];
  }
}

// ---------------------------------------------------------------- Turing
class TmMove {
  final String from, read, to, write, dir; // dir: L, R or S
  const TmMove(this.from, this.read, this.to, this.write, this.dir);
}

class TmStep {
  final String state;
  final Map<int, String> tape;
  final int head;
  const TmStep(this.state, this.tape, this.head);

  /// The written part of the tape and the head's place in it.
  (String, int) window({int pad = 1}) {
    final cells = tape.entries.where((e) => e.value != tmBlank).map((e) => e.key).toList();
    var lo = cells.isEmpty ? head : cells.reduce((a, b) => a < b ? a : b);
    var hi = cells.isEmpty ? head : cells.reduce((a, b) => a > b ? a : b);
    if (head < lo) lo = head;
    if (head > hi) hi = head;
    lo -= pad;
    hi += pad;
    return ([for (var i = lo; i <= hi; i++) tape[i] ?? tmBlank].join(), head - lo);
  }

  /// What is on the tape, the blanks on either side left out.
  String get output {
    final cells = tape.entries.where((e) => e.value != tmBlank).map((e) => e.key).toList();
    if (cells.isEmpty) return '';
    final lo = cells.reduce((a, b) => a < b ? a : b), hi = cells.reduce((a, b) => a > b ? a : b);
    return [for (var i = lo; i <= hi; i++) tape[i] ?? tmBlank].join();
  }
}

enum TmEnd { accept, reject, stuck, running }

class TmRun {
  final TmEnd end;
  final List<TmStep> steps;
  const TmRun(this.end, this.steps);
  bool get accepted => end == TmEnd.accept;
}

class Tm {
  final List<String> states;
  final String start;
  final Map<String, TmMove> moves; // 'q a' -> move
  const Tm(this.states, this.start, this.moves);

  static const accepting = {'h', 'y', 'acc', 'accept', 'H', 'Y'};
  static const rejecting = {'n', 'rej', 'reject', 'N'};

  /// One line per move: `q, a -> p, b, R` (L, R or S; `q a -> p b R` works
  /// too). `start q` names the start state, else the first one written is.
  static Tm parse(String text) {
    final states = <String>[];
    String? start;
    final moves = <String, TmMove>{};
    void note(String s) {
      if (!states.contains(s)) states.add(s);
    }

    for (final (n, raw) in text.split('\n').indexed) {
      var line = raw.trim();
      final c = line.indexOf('//');
      if (c >= 0) line = line.substring(0, c).trim();
      if (line.isEmpty) continue;
      final kw = RegExp(r'^start\s*[:=]?\s*(\S+)$', caseSensitive: false).firstMatch(line);
      if (kw != null) {
        start = kw[1]!;
        note(start);
        continue;
      }
      // q, a -> p, b, D (write b and move); or as in the course, q, a -> p, b (write) / q, a -> p, L (move)
      final m = RegExp(r'^\(?\s*([^\s,()]+)\s*[,\s]\s*(\S)\s*\)?\s*(?:->|→)\s*\(?\s*([^\s,()]+)\s*[,\s]\s*(\S)\s*(?:[,\s]\s*([LRSlrs]))?\s*\)?$').firstMatch(line);
      if (m == null) throw LfaError('Linia ${n + 1}: scrie o tranziție ca „q0, a -> q1, X, R” (stare, citește -> stare, scrie, L/R/S) sau „q0, a -> q1, L”.');
      final second = m[4]!;
      final TmMove mv;
      if (m[5] != null) {
        mv = TmMove(m[1]!, m[2]!, m[3]!, second, m[5]!.toUpperCase());
      } else if (second == 'L' || second == 'R') {
        mv = TmMove(m[1]!, m[2]!, m[3]!, m[2]!, second);
      } else {
        mv = TmMove(m[1]!, m[2]!, m[3]!, second, 'S');
      }
      final k = '${mv.from} ${mv.read}';
      if (moves.containsKey(k)) throw LfaError('Linia ${n + 1}: pentru (${mv.from}, ${mv.read}) e deja o tranziție: mașina e deterministă.');
      if (accepting.contains(mv.from) || rejecting.contains(mv.from)) throw LfaError('Linia ${n + 1}: ${mv.from} e o stare de oprire: din ea nu mai pleacă nimic.');
      moves[k] = mv;
      note(mv.from);
      note(mv.to);
    }
    if (states.isEmpty) throw const LfaError('Scrie cel puțin o tranziție.');
    return Tm(states, start ?? states.first, moves);
  }

  /// [atEnd]: the head starts on the last symbol of the word (as in some of the course's examples).
  TmRun run(String w, {int limit = 3000, bool keep = true, bool atEnd = false}) {
    final tape = <int, String>{for (var i = 0; i < w.length; i++) i: w[i]};
    var state = start, head = atEnd && w.isNotEmpty ? w.length - 1 : 0;
    final steps = <TmStep>[if (keep) TmStep(state, {...tape}, head)];
    TmRun done(TmEnd e) {
      if (!keep) steps.add(TmStep(state, tape, head));
      return TmRun(e, steps);
    }

    for (var k = 0; k <= limit; k++) {
      if (accepting.contains(state)) return done(TmEnd.accept);
      if (rejecting.contains(state)) return done(TmEnd.reject);
      if (k == limit) break;
      final m = moves['$state ${tape[head] ?? tmBlank}'];
      if (m == null) return done(TmEnd.stuck);
      tape[head] = m.write;
      head += m.dir == 'L' ? -1 : (m.dir == 'R' ? 1 : 0);
      state = m.to;
      if (keep) steps.add(TmStep(state, {...tape}, head));
    }
    return done(TmEnd.running);
  }

  bool accepts(String w) => run(w, keep: false).accepted;

  /// What is left on the tape when the machine halts, or null if it does not.
  String? compute(String w) {
    final r = run(w, keep: false);
    if (r.end != TmEnd.accept) return null;
    return r.steps.last.output;
  }

  List<(int, int, String)> arrows() {
    final all = [...states];
    final by = <(int, int), List<String>>{};
    for (final m in moves.values) {
      (by[(all.indexOf(m.from), all.indexOf(m.to))] ??= []).add('${m.read}/${m.write},${m.dir}');
    }
    return [for (final e in by.entries) (e.key.$1, e.key.$2, e.value.join('\n'))];
  }
}
