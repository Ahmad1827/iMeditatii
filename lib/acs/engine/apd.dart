// =============================================================================
// APD: A FEW THREADS, AND EVERY WAY THEIR STEPS CAN INTERLEAVE
//   A small language: shared variables, locks, semaphores, a barrier, and
//   threads made of assignments. `x = x + 1` on a shared variable is two
//   steps (read, then write), as on a real machine, so updates can be lost.
//   The explorer walks every interleaving and keeps what the shared
//   variables can end as, and a schedule that reaches a deadlock if one exists.
//
//     shared x = 0
//     lock m
//     sem s = 1
//     barrier b = 2
//     thread A:
//       lock(m)
//       x = x + 1
//       unlock(m)
// =============================================================================

class ApdError implements Exception {
  final String message;
  const ApdError(this.message);
  @override
  String toString() => message;
}

enum StepKind { assign, load, store, lock, unlock, down, up, arrive, pass }

/// One atomic step of a thread.
class Step {
  final StepKind kind;
  final String target; // the variable, lock, semaphore or barrier
  final List<String> expr; // assign / load: the expression, in postfix
  final String text; // as shown: "x = x + 1 (citește)"
  final String source; // the statement it comes from, without spaces
  const Step(this.kind, this.target, this.expr, this.text, this.source);
}

class ThreadCode {
  final String name;
  final List<Step> steps;
  const ThreadCode(this.name, this.steps);
}

/// Where a run is: each thread's next step and every value.
class RunState {
  final List<int> pc;
  final Map<String, int> shared;
  final List<Map<String, int>> locals;
  final Map<String, int> owner; // lock -> thread index, -1 free
  final Map<String, int> sems;
  final Map<String, int> arrived; // barrier -> threads waiting at it
  RunState(this.pc, this.shared, this.locals, this.owner, this.sems, this.arrived);

  RunState copy() => RunState([...pc], {...shared}, [for (final l in locals) {...l}], {...owner}, {...sems}, {...arrived});

  String get key => '$pc|${shared.values.join(',')}|${[for (final l in locals) (l.keys.toList()..sort()).map((k) => '$k=${l[k]}').join(',')].join(';')}'
      '|${owner.values.join(',')}|${sems.values.join(',')}|${arrived.values.join(',')}';
}

class Program {
  final Map<String, int> shared; // with the initial values
  final Set<String> locks;
  final Map<String, int> sems;
  final Map<String, int> barriers; // how many threads each one waits for
  final List<ThreadCode> threads;
  const Program(this.shared, this.locks, this.sems, this.barriers, this.threads);

  static final _id = RegExp(r'^[A-Za-z_]\w*$');

  static Program parse(String text) {
    final shared = <String, int>{};
    final locks = <String>{};
    final sems = <String, int>{};
    final barriers = <String, int>{};
    final threads = <ThreadCode>[];
    List<Step>? cur;

    for (final (n, raw) in text.split('\n').indexed) {
      final line = raw.replaceFirst(RegExp(r'(#|//).*$'), '').trim();
      if (line.isEmpty) continue;
      ApdError err(String m) => ApdError('Linia ${n + 1}: $m');
      var m = RegExp(r'^(shared|sem|barrier)\s+(.+)$').firstMatch(line);
      if (m != null) {
        for (final part in m[2]!.split(',')) {
          final d = RegExp(r'^\s*([A-Za-z_]\w*)\s*(?:=\s*(-?\d+))?\s*$').firstMatch(part);
          if (d == null) throw err('scrie „${m[1]} nume = valoare”.');
          final v = int.parse(d[2] ?? (m[1] == 'barrier' ? '2' : '0'));
          (m[1] == 'shared' ? shared : (m[1] == 'sem' ? sems : barriers))[d[1]!] = v;
        }
        continue;
      }
      m = RegExp(r'^lock\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)$').firstMatch(line);
      if (m != null) {
        locks.addAll(m[1]!.split(',').map((s) => s.trim()));
        continue;
      }
      m = RegExp(r'^thread\s+([A-Za-z_]\w*)\s*:?$').firstMatch(line);
      if (m != null) {
        if (threads.any((t) => t.name == m![1])) throw err('firul ${m[1]} există deja.');
        cur = [];
        threads.add(ThreadCode(m[1]!, cur));
        continue;
      }
      if (cur == null) throw err('instrucțiunile stau într-un fir: scrie întâi „thread A:”.');
      final src = line.replaceAll(RegExp(r'\s|;'), '');
      m = RegExp(r'^(lock|unlock|P|V|acquire|release|await)\s*\(\s*([A-Za-z_]\w*)\s*\)\s*;?$').firstMatch(line);
      if (m != null) {
        final op = m[1]!, what = m[2]!;
        if (op == 'lock' || op == 'unlock') {
          if (!locks.contains(what)) throw err('„$what” nu e declarat ca lock.');
          cur.add(Step(op == 'lock' ? StepKind.lock : StepKind.unlock, what, const [], '$op($what)', src));
        } else if (op == 'await') {
          if (!barriers.containsKey(what)) throw err('„$what” nu e declarat ca barieră.');
          cur.add(Step(StepKind.arrive, what, const [], 'await($what) (ajunge la barieră)', src));
          cur.add(Step(StepKind.pass, what, const [], 'await($what) (trece)', src));
        } else {
          if (!sems.containsKey(what)) throw err('„$what” nu e declarat ca semafor.');
          final down = op == 'P' || op == 'acquire';
          cur.add(Step(down ? StepKind.down : StepKind.up, what, const [], '$op($what)', src));
        }
        continue;
      }
      m = RegExp(r'^([A-Za-z_]\w*)\s*=\s*(.+?)\s*;?$').firstMatch(line);
      if (m == null) throw err('nu înțeleg „$line”.');
      final target = m[1]!;
      if (locks.contains(target) || sems.containsKey(target) || barriers.containsKey(target)) throw err('„$target” nu e o variabilă.');
      final List<String> post;
      try {
        post = _postfix(m[2]!);
      } on ApdError catch (e) {
        throw err(e.message);
      }
      final show = '$target = ${m[2]!.trim()}';
      final readsShared = post.any(shared.containsKey);
      if (shared.containsKey(target) && readsShared) {
        // not atomic: the value is read, and written back in a later step
        cur.add(Step(StepKind.load, target, post, '$show (citește)', src));
        cur.add(Step(StepKind.store, target, const [], '$show (scrie)', src));
      } else {
        cur.add(Step(StepKind.assign, target, post, show, src));
      }
    }
    if (threads.isEmpty) throw const ApdError('Programul nu are niciun fir („thread A:”).');
    return Program(shared, locks, sems, barriers, threads);
  }

  /// Shunting-yard, for + - * / % and parentheses over numbers and names.
  static List<String> _postfix(String e) {
    final tokens = RegExp(r'\d+|[A-Za-z_]\w*|[-+*/%()]').allMatches(e).map((m) => m[0]!).toList();
    if (tokens.join() != e.replaceAll(RegExp(r'\s'), '')) throw const ApdError('expresia are un caracter necunoscut.');
    const prec = {'+': 1, '-': 1, '*': 2, '/': 2, '%': 2};
    final out = <String>[], ops = <String>[];
    var wantValue = true;
    for (final t in tokens) {
      if (prec.containsKey(t)) {
        if (wantValue) throw const ApdError('lipsește o valoare înainte de un operator.');
        while (ops.isNotEmpty && ops.last != '(' && prec[ops.last]! >= prec[t]!) {
          out.add(ops.removeLast());
        }
        ops.add(t);
        wantValue = true;
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          out.add(ops.removeLast());
        }
        if (ops.isEmpty) throw const ApdError('paranteze nepotrivite.');
        ops.removeLast();
      } else {
        if (!wantValue) throw const ApdError('lipsește un operator.');
        out.add(t);
        wantValue = false;
      }
    }
    if (wantValue) throw const ApdError('expresia e neterminată.');
    while (ops.isNotEmpty) {
      if (ops.last == '(') throw const ApdError('paranteze nepotrivite.');
      out.add(ops.removeLast());
    }
    return out;
  }

  RunState start() => RunState(
        List.filled(threads.length, 0),
        {...shared},
        [for (final _ in threads) <String, int>{}],
        {for (final l in locks) l: -1},
        {...sems},
        {for (final b in barriers.keys) b: 0},
      );

  Step? next(RunState s, int t) => s.pc[t] < threads[t].steps.length ? threads[t].steps[s.pc[t]] : null;

  bool done(RunState s) => [for (var t = 0; t < threads.length; t++) next(s, t)].every((x) => x == null);

  /// Can thread [t] take its next step now?
  bool enabled(RunState s, int t) {
    final st = next(s, t);
    if (st == null) return false;
    return switch (st.kind) {
      StepKind.lock => s.owner[st.target] == -1,
      StepKind.down => s.sems[st.target]! > 0,
      StepKind.pass => s.arrived[st.target]! >= barriers[st.target]!,
      _ => true,
    };
  }

  bool deadlocked(RunState s) => !done(s) && ![for (var t = 0; t < threads.length; t++) enabled(s, t)].contains(true);

  int _eval(List<String> post, RunState s, int t) {
    final st = <int>[];
    for (final tok in post) {
      final n = int.tryParse(tok);
      if (n != null) {
        st.add(n);
      } else if (_id.hasMatch(tok)) {
        st.add(s.shared[tok] ?? s.locals[t][tok] ?? 0);
      } else {
        final b = st.removeLast(), a = st.removeLast();
        st.add(switch (tok) {
          '+' => a + b,
          '-' => a - b,
          '*' => a * b,
          '/' => b == 0 ? 0 : a ~/ b,
          _ => b == 0 ? 0 : a % b,
        });
      }
    }
    return st.single;
  }

  /// The state after thread [t] takes its step ([enabled] must hold).
  RunState step(RunState from, int t) {
    final s = from.copy();
    final st = next(s, t)!;
    switch (st.kind) {
      case StepKind.assign:
        final v = _eval(st.expr, s, t);
        if (s.shared.containsKey(st.target)) {
          s.shared[st.target] = v;
        } else {
          s.locals[t][st.target] = v;
        }
      case StepKind.load:
        s.locals[t]['·'] = _eval(st.expr, s, t); // the value held between read and write
      case StepKind.store:
        s.shared[st.target] = s.locals[t].remove('·') ?? 0;
      case StepKind.lock:
        s.owner[st.target] = t;
      case StepKind.unlock:
        s.owner[st.target] = -1;
      case StepKind.down:
        s.sems[st.target] = s.sems[st.target]! - 1;
      case StepKind.up:
        s.sems[st.target] = s.sems[st.target]! + 1;
      case StepKind.arrive:
        s.arrived[st.target] = s.arrived[st.target]! + 1;
      case StepKind.pass:
        break;
    }
    s.pc[t]++;
    return s;
  }

  /// Every interleaving, breadth first, so the schedules kept are the shortest.
  Exploration explore({int limit = 150000}) {
    final first = start();
    final parent = <String, (String, int)?>{first.key: null};
    final queue = <RunState>[first];
    final finals = <String, (Map<String, int>, String)>{};
    String? dead;
    var truncated = false;
    for (var i = 0; i < queue.length; i++) {
      final s = queue[i];
      if (done(s)) {
        finals.putIfAbsent(s.shared.values.join(','), () => ({...s.shared}, s.key));
        continue;
      }
      var moved = false;
      for (var t = 0; t < threads.length; t++) {
        if (!enabled(s, t)) continue;
        moved = true;
        final n = step(s, t);
        if (parent.containsKey(n.key)) continue;
        if (parent.length >= limit) {
          truncated = true;
          continue;
        }
        parent[n.key] = (s.key, t);
        queue.add(n);
      }
      if (!moved) dead ??= s.key;
    }
    List<String> path(String key) {
      final out = <String>[];
      String? k = key;
      while (parent[k] != null) {
        out.add(threads[parent[k]!.$2].name);
        k = parent[k]!.$1;
      }
      return out.reversed.toList();
    }

    return Exploration(
      [for (final f in finals.values) (f.$1, path(f.$2))],
      dead == null ? null : path(dead),
      truncated,
    );
  }
}

class Exploration {
  /// What the shared variables can end as, each with a schedule that gets there.
  final List<(Map<String, int>, List<String>)> finals;
  final List<String>? deadlock; // a schedule that ends with every thread stuck
  final bool truncated;
  const Exploration(this.finals, this.deadlock, this.truncated);

  Set<int> valuesOf(String name) => {for (final f in finals) f.$1[name] ?? 0};
}

// ---------------------------------------------------------------- the task
class ApdTask {
  final String mode; // outcomes, schedule, fix
  final String program; // the code given (the start, for a fix)
  final String? ask; // outcomes: the variable whose final values are asked
  final Map<String, int> goal; // schedule: the values to end with
  final bool goalDeadlock; // schedule: get every thread stuck
  final Map<String, int> expect; // fix: every run must end with these
  final Map<String, List<String>> keep; // fix: statements each thread must still have
  final List<String> forbid; // fix: primitives not allowed ("lock", "sem", "barrier")
  final String? reference; // fix: a program that passes

  const ApdTask(this.mode, this.program, this.ask, this.goal, this.goalDeadlock, this.expect, this.keep, this.forbid, this.reference);

  factory ApdTask.fromSpec(Map<String, dynamic> spec) {
    Map<String, int> ints(Object? m) => {for (final e in (m as Map? ?? const {}).entries) '${e.key}': (e.value as num).toInt()};
    return ApdTask(
      spec['mode'] as String,
      spec['program'] as String,
      spec['ask'] as String?,
      ints(spec['goal']),
      spec['goalDeadlock'] == true,
      ints(spec['expect']),
      {for (final e in (spec['keep'] as Map? ?? const {}).entries) '${e.key}': [for (final s in e.value as List) '$s']},
      [for (final f in spec['forbid'] as List? ?? const []) '$f'],
      spec['reference'] as String?,
    );
  }

  static String say(Map<String, int> v) => v.entries.map((e) => '${e.key} = ${e.value}').join(', ');

  /// The values typed, "1, 2 3" -> {1, 2, 3}; null if something is not a number.
  static Set<int>? parseValues(String text) {
    final parts = text.split(RegExp(r'[\s,;]+')).where((p) => p.isNotEmpty).toList();
    final out = <int>{};
    for (final p in parts) {
      final v = int.tryParse(p);
      if (v == null) return null;
      out.add(v);
    }
    return out;
  }

  List<(String, bool, String)> checkOutcomes(String typed) {
    final want = Program.parse(program).explore().valuesOf(ask!);
    final got = parseValues(typed);
    if (got == null || got.isEmpty) return [('ai scris valorile, despărțite prin virgulă', false, 'de exemplu: 1, 2')];
    final extra = got.difference(want).toList()..sort();
    final missing = want.difference(got).length;
    return [
      ('fiecare valoare scrisă chiar se poate obține', extra.isEmpty, '${extra.join(', ')} nu se poate obține în nicio întrețesere'),
      ('nu lipsește nicio valoare posibilă', missing == 0, missing == 1 ? 'mai există o valoare' : 'mai există $missing valori'),
    ];
  }

  /// Has the run [s] of the given program reached what the task asks for?
  bool reached(Program p, RunState s) {
    if (goalDeadlock) return p.deadlocked(s);
    return p.done(s) && goal.entries.every((e) => s.shared[e.key] == e.value);
  }

  List<(String, bool, String)> checkFix(String text) {
    final Program p, given;
    try {
      p = Program.parse(text);
      given = Program.parse(program);
    } on ApdError catch (e) {
      return [('programul se poate citi', false, e.message)];
    }
    final out = <(String, bool, String)>[];
    final sameVars = given.shared.entries.every((e) => p.shared[e.key] == e.value) && p.shared.length == given.shared.length;
    out.add(('variabilele partajate și valorile lor inițiale sunt cele date', sameVars, 'nu schimba declarațiile „shared”'));
    final missing = <String>[];
    for (final e in keep.entries) {
      final mine = [for (final t in p.threads) if (t.name == e.key) ...t.steps.where((s) => s.kind != StepKind.store && s.kind != StepKind.pass).map((s) => s.source)];
      for (final stmt in e.value.toSet()) {
        final need = e.value.where((s) => s == stmt).length;
        if (mine.where((s) => s == stmt).length < need) missing.add('${e.key}: $stmt');
      }
    }
    out.add(('fiecare fir își face în continuare treaba (instrucțiunile date au rămas)', missing.isEmpty, 'lipsește ${missing.join('; ')}'));
    for (final f in forbid) {
      final used = switch (f) {
        'lock' => p.threads.any((t) => t.steps.any((s) => s.kind == StepKind.lock)),
        'sem' => p.threads.any((t) => t.steps.any((s) => s.kind == StepKind.down || s.kind == StepKind.up)),
        _ => p.threads.any((t) => t.steps.any((s) => s.kind == StepKind.arrive)),
      };
      final name = switch (f) { 'lock' => 'lock-uri', 'sem' => 'semafoare', _ => 'bariere' };
      out.add(('nu folosește $name', !used, 'rezolvă fără $name'));
    }
    final x = p.explore();
    if (x.truncated) return [...out, ('toate întrețeserile au putut fi încercate', false, 'programul are prea multe stări; scurtează-l')];
    out.add(('nu se blochează în nicio întrețesere', x.deadlock == null, x.deadlock == null ? '' : 'se blochează cu ordinea: ${x.deadlock!.join(' ')}'));
    final bad = [for (final f in x.finals) if (!expect.entries.every((e) => f.$1[e.key] == e.value)) f];
    out.add((
      'în orice întrețesere, la sfârșit ${say(expect)}',
      bad.isEmpty && x.finals.isNotEmpty,
      bad.isEmpty ? 'niciun fir nu ajunge la sfârșit' : 'cu ordinea ${bad.first.$2.join(' ')} se termină cu ${say(bad.first.$1)}',
    ));
    return out;
  }
}
