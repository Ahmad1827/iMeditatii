// Every ACS problem can be solved in its own tool: the reference solution,
// run in the app's engine (shell, emulator, Octave...), passes every check,
// and the untouched start does not.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/engine/apd.dart';
import 'package:iMeditatii/acs/engine/circuit.dart';
import 'package:iMeditatii/acs/engine/crypto.dart';
import 'package:iMeditatii/acs/engine/ds.dart';
import 'package:iMeditatii/acs/engine/egc.dart';
import 'package:iMeditatii/acs/engine/fields.dart';
import 'package:iMeditatii/acs/engine/lfa.dart';
import 'package:iMeditatii/acs/engine/logic.dart';
import 'package:iMeditatii/acs/engine/math_task.dart';
import 'package:iMeditatii/acs/engine/octave_task.dart';
import 'package:iMeditatii/acs/engine/physics.dart';
import 'package:iMeditatii/acs/engine/rowops.dart';
import 'package:iMeditatii/acs/engine/shell_task.dart';
import 'package:iMeditatii/acs/engine/x86.dart';
import 'package:iMeditatii/acs_screen.dart';

AcsCourseData course(String code) => AcsCourseData.parse(code, File('assets/data/acs/$code.json').readAsStringSync());

void main() {
  test('every ready course has a file, chapters and problems', () {
    for (final s in acsSubjects.where((s) => s.ready)) {
      final f = File('assets/data/acs/${s.code}.json');
      if (!f.existsSync()) continue; // added course by course
      final d = course(s.code);
      expect(d.problems, isNotEmpty, reason: s.code);
      for (final p in d.problems) {
        expect(d.chapters, contains(p.chapter), reason: '${s.code} ${p.id}');
        expect(p.statement.trim(), isNotEmpty, reason: '${s.code} ${p.id}');
        expect(acsKindLabels.keys, contains(p.kind), reason: '${s.code} ${p.id}');
        expect(const ['ușoară', 'medie', 'grea'], contains(p.difficulty));
      }
      final raw = json.decode(f.readAsStringSync()) as Map;
      expect(raw['code'], s.code);
    }
  });

  group('USO: the reference commands solve each task in the shell', () {
    for (final p in course('uso').problems) {
      test('${p.id}. ${p.title}', () {
        final task = ShellTask(p.spec);
        final start = task.shell();
        expect(ShellTask.passed(task.verify(start)), isFalse, reason: 'already solved at the start');
        final sh = task.shell();
        for (final cmd in task.reference) {
          final out = sh.run(cmd);
          final errs = out.where((c) => c.$2).map((c) => c.$1).join();
          expect(errs, isEmpty, reason: cmd);
        }
        final r = task.verify(sh);
        for (final c in r) {
          expect(c.ok, isTrue, reason: '${c.label}: ${c.detail}');
        }
      });
    }
  });

  group('IOCLA: the reference assembly passes every test, the starter does not', () {
    for (final p in course('iocla').problems) {
      test('${p.id}. ${p.title}', () {
        final call = AsmCall.fromSpec(p.spec);
        final cases = [for (final c in p.spec['tests'] as List) AsmCase.fromJson(c as Map)];
        final prog = Assembler.assemble(p.spec['reference'] as String);
        for (final c in cases) {
          final r = call.run(prog, c);
          expect(r.ok, isTrue, reason: '${call.describe(c)}: ${r.message}');
        }
        final start = Assembler.assemble(p.spec['starter'] as String);
        expect(cases.every((c) => call.run(start, c).ok), isFalse);
      });
    }
  });

  group('SD: the moves of each algorithm, as the app checks them', () {
    for (final p in course('sd').problems.where((p) => p.kind == 'ds')) {
      test('${p.id}. ${p.title}', () {
        final t = DsTask.fromSpec(p.spec);
        // a wrong first move is refused
        final right = t.expected()!;
        final wrong = switch (right.kind) {
          'slot' => DsTarget('slot', right.a, 1 - right.b),
          'swap' => DsTarget('swap', right.a, right.b + 1),
          'cell' => DsTarget('cell', (right.a + 1) % 11),
          'edge' => DsTarget('edge', (right.a + 1) % 7),
          _ => DsTarget('node', (right.a + 1) % 6),
        };
        if (!(t is GraphTask && (t.allowed().contains(wrong)))) {
          final f = t.play(wrong);
          expect(f.ok, isFalse);
          expect(t.mistakes, 1);
        }
        var guard = 0;
        while (!t.done && guard++ < 200) {
          expect(t.play(t.expected()!).ok, isTrue);
        }
        expect(t.done, isTrue);
        final want = (p.spec['expect'] as Map?) ?? const {};
        if (t is BstTask) {
          final pre = <int>[];
          void go(BstNode? n) {
            if (n == null) return;
            pre.add(n.key);
            go(n.left);
            go(n.right);
          }
          go(t.root);
          expect(pre, want['preorder']);
        }
        if (t is HeapTask) {
          expect(t.a, want['array']);
          if (want['extracted'] != null) expect(t.extracted, want['extracted']);
        }
        if (t is HashTask) expect(t.table, want['table']);
        if (t is GraphTask) {
          if (want['order'] != null) expect([for (final i in t.order) t.nodes[i].name], want['order']);
          if (want['dist'] != null) {
            for (final e in (want['dist'] as Map).entries) {
              expect(t.dist[t.nodes.indexWhere((n) => n.name == e.key)], e.value, reason: e.key);
            }
          }
          if (want['cost'] != null) expect(t.picked.fold<int>(0, (s, i) => s + t.edges[i].w), want['cost']);
          if (t.algo == 'topo') {
            final pos = {for (final (k, i) in t.order.indexed) i: k};
            for (final e in t.edges) {
              expect(pos[e.u]! < pos[e.v]!, isTrue);
            }
          }
        }
      });
    }
  });

  group('PCLP and SD: every reference program passes its tests (gcc)', () {
    final gcc = Process.runSync('which', ['gcc']).exitCode == 0;
    for (final code in ['pclp', 'sd']) {
      for (final p in course(code).problems.where((p) => p.kind == 'c')) {
        test('$code ${p.id}. ${p.title}', () {
          final dir = Directory.systemTemp.createTempSync('acs_c');
          try {
            File('${dir.path}/main.c').writeAsStringSync(p.spec['reference'] as String);
            final cc = Process.runSync('gcc', ['-std=gnu11', '-O2', '-o', '${dir.path}/a.out', '${dir.path}/main.c', '-lm']);
            expect(cc.exitCode, 0, reason: '${cc.stderr}');
            for (final t in (p.spec['tests'] as List).cast<Map>()) {
              File('${dir.path}/in.txt').writeAsStringSync('${t['input']}');
              final run = Process.runSync('bash', ['-c', '"${dir.path}/a.out" < "${dir.path}/in.txt"']);
              String norm(String s) => s.replaceAll('\r', '').trim().split('\n').map((l) => l.trimRight()).join('\n');
              expect(norm(run.stdout as String), norm('${t['output']}'));
            }
          } finally {
            dir.deleteSync(recursive: true);
          }
        }, skip: gcc ? false : 'no gcc');
      }
    }
  });

  group('PL: the reference designs pass, wrong ones do not', () {
    for (final p in course('pl').problems) {
      test('${p.id}. ${p.title}', () {
        final spec = p.spec;
        final ref = spec['reference'] as Map;
        switch (spec['mode']) {
          case 'expr':
            final t = ExprTask.fromSpec(spec);
            for (final o in t.outputs) {
              for (final c in t.check(o.name, '${ref[o.name]}')) {
                expect(c.ok, isTrue, reason: '${o.name}: ${c.label} ${c.detail}');
              }
              expect(t.check(o.name, '0').every((c) => c.ok), isFalse);
            }
          case 'mux':
            final t = MuxTask.fromSpec(spec);
            final sel = [for (final x in ref['sel'] as List) '$x'];
            final data = [for (final x in ref['data'] as List) '$x'];
            expect(t.check(sel, data).every((c) => c.ok), isTrue);
            expect(t.check(sel, List.filled(data.length, '0')).every((c) => c.ok), isFalse);
          case 'fsm':
            final t = FsmTask.fromSpec(spec);
            expect(t.check(Mealy.fromJson(ref)).every((c) => c.ok), isTrue);
            // renamed states are still the same machine
            final m = Mealy.fromJson(ref);
            final renamed = Mealy([for (final s in m.states) 'q$s'], {for (final e in m.t.entries) 'q${e.key}': [for (final (n, o) in e.value) ('q$n', o)]}, 'q${m.start}');
            expect(t.check(renamed).every((c) => c.ok), isTrue);
            final broken = Mealy(m.states, {for (final e in m.t.entries) e.key: [for (final (n, o) in e.value) (n, 1 - o)]}, m.start);
            expect(t.check(broken).every((c) => c.ok), isFalse);
        }
      });
    }
  });

  group('MN: the reference Octave passes the numpy values, the starter does not', () {
    for (final p in course('mn').problems) {
      test('${p.id}. ${p.title}', () {
        final t = OctaveTask.fromSpec(p.spec);
        for (final r in t.run(p.spec['reference'] as String)) {
          expect(r.ok, isTrue, reason: '${t.describe(r.c)}: ${r.message}');
        }
        expect(t.run(p.spec['starter'] as String).every((r) => r.ok), isFalse);
      });
    }
  });

  Map<String, MathAnswer> answers(Map ref) => {
        for (final e in ref.entries)
          '${e.key}': e.value is String
              ? MathAnswer(text: e.value as String)
              : ((e.value as List).isNotEmpty && ((e.value as List).first as List).length == 3 && !(e.value as List).every((r) => (r as List).length != 3)
                  ? (e.value as List).every((r) => const ['min', 'max', 'șa'].contains((r as List)[2]))
                      ? MathAnswer(points: [for (final r in e.value as List) ('${(r as List)[0]}', '${r[1]}', '${r[2]}')])
                      : MathAnswer(cells: [for (final r in e.value as List) [for (final c in r as List) '$c']])
                  : MathAnswer(cells: [for (final r in e.value as List) [for (final c in r as List) '$c']])),
      };

  for (final code in ['am', 'ms', 'algaed']) {
    group('${code.toUpperCase()}: the reference answers pass, the wrong ones do not', () {
      for (final p in course(code).problems) {
        test('${p.id}. ${p.title}', () {
          if (p.kind == 'rowops') {
            final t = RowOpsTask.fromSpec(p.spec);
            expect(t.goalState().$1, isFalse);
            for (final op in (p.spec['reference'] as List).cast<String>()) {
              t.apply(op);
            }
            expect(t.goalState().$1, isTrue, reason: t.m.toString());
            if (p.spec['goal'] == 'triangular') {
              // the determinant: the diagonal's product, divided by the factor of the operations
              var d = Q.one;
              for (var i = 0; i < t.rows; i++) {
                d = d * t.m[i][i];
              }
              expect(d / t.detFactor, Q.parse('${(p.spec['answers'] as List).first['value']}'));
            }
            if (p.spec['goal'] == 'inverse') {
              final n = t.rows;
              final a = [for (final r in p.spec['matrix'] as List) [for (final x in r as List) Q.parse('$x')]];
              for (var i = 0; i < n; i++) {
                for (var j = 0; j < n; j++) {
                  var s = Q.zero;
                  for (var k = 0; k < n; k++) {
                    s = s + a[i][k] * t.m[k][n + j];
                  }
                  expect(s, i == j ? Q.one : Q.zero);
                }
              }
            }
            return;
          }
          final t = MathTask.fromSpec(p.spec);
          for (final c in t.verify(answers(p.spec['reference'] as Map))) {
            expect(c.ok, isTrue, reason: '${c.label} ${c.detail}');
          }
          expect(t.verify(answers(p.spec['wrong'] as Map)).every((c) => c.ok), isFalse);
        });
      }
    });
  }

  group('ELTH: the app solves each circuit as numpy does; the designs reach their goal', () {
    for (final p in course('elth').problems) {
      test('${p.id}. ${p.title}', () {
        final c = Circuit.fromSpec(p.spec);
        final want = (p.spec['expect'] as Map?) ?? const {};
        if (want.isNotEmpty) {
          final s = c.solve();
          for (final e in want.entries) {
            expect(Circuit.quantity(s, '${e.key}'), closeTo((e.value as num).toDouble(), 1e-6 * ((e.value as num).abs() + 1)), reason: '${e.key}');
          }
        }
        final d = p.spec['design'] as Map?;
        if (d != null) {
          final t = d['target'] as Map;
          double at(Circuit k) => Circuit.quantity(k.solve(), t['q'] as String);
          bool meets(double v) {
            final w = (t['value'] as num).toDouble();
            final abstol = (t['abstol'] as num?)?.toDouble();
            return abstol != null ? (v - w).abs() <= abstol : (v - w).abs() <= ((t['tol'] as num?) ?? 0.01) * w.abs();
          }
          final ref = {for (final e in (d['reference'] as Map).entries) '${e.key}': MathTask.number('${e.value}')};
          expect(meets(at(c.withValues(ref))), isTrue);
          expect(meets(at(c)), isFalse);
        }
      });
    }
  });

  group('Fizică: the engine agrees with the formulas; the right throw goes in', () {
    for (final p in course('fizica').problems) {
      test('${p.id}. ${p.title}', () {
        final t = PhysTask.fromSpec(p.spec);
        final a = t.answers();
        for (final e in (p.spec['expect'] as Map).entries) {
          expect(a['${e.key}'], closeTo((e.value as num).toDouble(), 1e-9), reason: '${e.key}');
        }
        for (final f in t.fields) {
          expect(a.containsKey(f['name']), isTrue);
        }
        if (t.sim == 'projectile') {
          expect(t.hits(a['v0']!), isTrue);
          expect(t.hits(a['v0']! * 1.1), isFalse);
        }
        if (t.sim == 'friction') {
          expect(t.slid(2, mu: a['mu']! * 1.01), 0);
          expect(t.slid(2, mu: a['mu']! * 0.9), greaterThan(0));
        }
      });
    }
  });

  group('Admitere: six answers, exactly one correct, each shown', () {
    for (final p in course('admitere').problems) {
      test('${p.id}. ${p.title}', () {
        expect(p.kind, 'grila');
        final opts = p.spec['options'] as List;
        expect(opts, hasLength(6));
        expect(opts.toSet(), hasLength(6), reason: 'two options read the same');
        final ans = (p.spec['answer'] as num).toInt();
        expect(ans, inInclusiveRange(0, 5));
        // a program's question: its real output is the correct option
        final out = p.spec['output'] as String?;
        if (out != null) expect(opts[ans], '`$out`');
        expect(p.solution, isNotEmpty);
      });
    }
  });

  group('LFA: the reference answer describes the language, an empty one does not', () {
    for (final p in course('lfa').problems.where((p) => p.kind == 'lfa')) {
      test('${p.id}. ${p.title}', () {
        final t = LfaTask.fromSpec(p.spec);
        for (final (label, ok, detail) in t.checkReference()) {
          expect(ok, isTrue, reason: '$label: $detail');
        }
        final empty = switch (t.mode) {
          'regex' => t.checkRegex('∅'),
          'cfg' => t.checkGrammar('S -> SS'),
          _ => t.checkAutomaton(const Nfa(1, {}, {})),
        };
        expect(empty.every((c) => c.$2), isFalse);
      });
    }

    test('a wrong automaton gets the shortest word that gives it away', () {
      final t = LfaTask.fromSpec(course('lfa').byId('1')!.spec); // ends in ab
      final r = t.checkAutomaton(Nfa.fromJson({
        'states': 2,
        'final': [1],
        't': {
          '0': {'a': [0], 'b': [1]},
          '1': {'a': [0], 'b': [1]},
        },
      }));
      expect(r.last.$2, isFalse);
      expect(r.last.$3, contains('„b”'));
    });

    test('the expression is read as the course writes it', () {
      final n = Regex.parse('(a ∪ b)* a b | ε', ['a', 'b']);
      expect(n.accepts(''), isTrue);
      expect(n.accepts('bab'), isTrue);
      expect(n.accepts('ba'), isFalse);
      expect(() => Regex.parse('(a∪b', ['a', 'b']), throwsA(isA<LfaError>()));
      expect(() => Regex.parse('ac', ['a', 'b']), throwsA(isA<LfaError>()));
      expect(Regex.parse('(a∪b)*a(a∪b)(a∪b)', ['a', 'b']).toDfa(['a', 'b']).minimalStates, 8);
    });
  });

  group('APD: every interleaving, as the explorer finds them', () {
    for (final p in course('apd').problems.where((p) => p.kind == 'threads')) {
      test('${p.id}. ${p.title}', () {
        final t = ApdTask.fromSpec(p.spec);
        final prog = Program.parse(t.program);
        final x = prog.explore();
        expect(x.truncated, isFalse);
        switch (t.mode) {
          case 'outcomes':
            expect(x.valuesOf(t.ask!).toList()..sort(), p.spec['values']);
            expect(x.deadlock, isNull);
            expect(t.checkOutcomes((p.spec['values'] as List).join(', ')).every((c) => c.$2), isTrue);
            expect(t.checkOutcomes('${(p.spec['values'] as List).first}, 99').every((c) => c.$2), isFalse);
          case 'schedule':
            // the schedule the explorer found reaches the goal when replayed, and the start is not there yet
            final way = t.goalDeadlock ? x.deadlock : [for (final f in x.finals) if (t.goal.entries.every((e) => f.$1[e.key] == e.value)) f.$2].firstOrNull;
            expect(way, isNotNull, reason: 'the goal cannot be reached');
            var s = prog.start();
            expect(t.reached(prog, s), isFalse);
            for (final name in way!) {
              s = prog.step(s, prog.threads.indexWhere((th) => th.name == name));
            }
            expect(t.reached(prog, s), isTrue);
            // and not every order gets there
            expect(t.goalDeadlock ? x.finals.isNotEmpty : x.finals.length > 1, isTrue);
          default:
            for (final (label, ok, detail) in t.checkFix(t.reference!)) {
              expect(ok, isTrue, reason: '$label: $detail');
            }
            expect(t.checkFix(t.program).every((c) => c.$2), isFalse, reason: 'the code given already passes');
        }
      });
    }

    test('a fix that deletes the work, or deadlocks, is refused with the order that breaks it', () {
      final t = ApdTask.fromSpec(course('apd').byId('14')!.spec);
      expect(t.checkFix('shared x = 0\nthread A:\n  x = 2\nthread B:\n  x = 2').every((c) => c.$2), isFalse);
      final r = t.checkFix('shared x = 0\nlock m\nthread A:\n  lock(m)\n  x = x + 1\nthread B:\n  lock(m)\n  x = x + 1\n  unlock(m)');
      expect(r.firstWhere((c) => c.$1.contains('blochează')).$2, isFalse);
      expect(r.firstWhere((c) => c.$1.contains('blochează')).$3, contains('A'));
      expect(() => Program.parse('thread A:\n  lock(q)'), throwsA(isA<ApdError>()));
    });
  });

  group('EGC: the reference list has the target matrix, and the rasters are judged pixel by pixel', () {
    for (final p in course('egc').problems.where((p) => p.kind == 'transform')) {
      test('${p.id}. ${p.title}', () {
        final t = TransformTask.fromSpec(p.spec);
        for (final (label, ok, detail) in t.check(t.reference)) {
          expect(ok, isTrue, reason: '$label: $detail');
        }
        expect(t.check(const []).every((c) => c.$2), isFalse, reason: 'nothing to do');
        // the shape really lands on the target
        final m = compose(t.reference);
        for (final (x, y) in t.shape) {
          final (a, b) = m.apply(x, y);
          final (c, d) = t.target.apply(x, y);
          expect((a - c).abs() + (b - d).abs(), lessThan(1e-6));
        }
      });
    }

    for (final p in course('egc').problems.where((p) => p.kind == 'raster')) {
      test('${p.id}. ${p.title}', () {
        final t = RasterTask.fromSpec(p.spec);
        expect(t.check(t.pixels).every((c) => c.$2), isTrue);
        expect(t.check(t.given).every((c) => c.$2), isFalse);
        expect(t.pixels.containsAll(t.given), isTrue);
        expect(t.check({...t.pixels, (0, t.height - 1)}).first.$2, t.pixels.contains((0, t.height - 1)));
      });
    }

    test('a product is applied right to left, and another way to the same matrix is accepted', () {
      // rotating about (2, 1): the translation to the origin first
      final m = compose(const [Op('T', -2, -1), Op('R', 90), Op('T', 2, 1)]);
      final (x, y) = m.apply(2, 1);
      expect([x, y], [closeTo(2, 1e-9), closeTo(1, 1e-9)]);
      expect(productText(const [Op('T', -2, -1), Op('R', 90)]), 'M = R(90°) · T(-2, -1)');
      final t = TransformTask.fromSpec(course('egc').byId('9')!.spec); // 180° about (2.5, 1)
      expect(t.check(const [Op('T', -2.5, -1), Op('S', -1, -1), Op('T', 2.5, 1)]).every((c) => c.$2), isTrue);
      expect(t.check(const [Op('R', 180), Op('T', 5, 2)]).every((c) => c.$2), isTrue);
      expect(t.check(const [Op('R', 180)]).every((c) => c.$2), isFalse);
    });
  });

  group('RL and EG: the answers typed in fields', () {
    for (final code in ['rl', 'eg']) {
      for (final p in course(code).problems.where((p) => p.kind == 'net' || p.kind == 'market')) {
        test('$code ${p.id}. ${p.title}', () {
          final t = FieldsTask.fromSpec(p.spec);
          expect(t.fields, isNotEmpty);
          expect(t.fields.map((f) => f.id).toSet().length, t.fields.length);
          expect(t.check(t.reference).values.every((ok) => ok), isTrue);
          expect(t.check(const {}).values.any((ok) => ok), isFalse);
          // one wrong field is the only one marked
          final first = t.fields.first;
          final r = t.check({...t.reference, first.id: first.number ? '${double.parse(first.answer) + 7}' : 'altceva'});
          expect(r[first.id], isFalse);
          expect(r.values.where((ok) => !ok).length, 1);
        });
      }
    }

    test('the addresses of RL 2 (192.168.1.70/26), worked out here on the bits', () {
      final ip = parseIp('192.168.1.70')!, mask = maskOf(26);
      final t = FieldsTask.fromSpec(course('rl').byId('2')!.spec);
      expect(t.reference['net'], ipText(ip & mask));
      expect(t.reference['bc'], ipText((ip & mask) | (~mask & 0xFFFFFFFF)));
      expect(t.reference['mask'], ipText(mask));
      expect(bitsOf(mask).where((b) => b == 1).length, 26);
      expect(parseIp('1.2.3'), isNull);
      expect(parseIp('1.2.3.256'), isNull);
    });

    test('numbers are read the way they are written here: a comma, a percent sign, a fraction', () {
      const f = AnswerField('x', '', '0.6667', true, 0.01, '');
      expect(f.accepts('0,67'), isTrue);
      expect(f.accepts('2/3'), isTrue);
      expect(f.accepts('0.7'), isFalse);
      expect(const AnswerField('p', '', '25', true, 0.01, '').accepts('25%'), isTrue);
      expect(const AnswerField('k', '', 'elastică|elastica', false, 0, '').accepts(' Elastica '), isTrue);
      expect(const AnswerField('n', '', '/26|26', false, 0, '').accepts('/26'), isTrue);
    });
  });

  group('ISC: the reference steps turn the scrambled text into the flag', () {
    for (final p in course('isc').problems.where((p) => p.kind == 'crypto')) {
      test('${p.id}. ${p.title}', () {
        final t = CryptoTask.fromSpec(p.spec);
        expect(t.solvedBy(t.reference), isTrue);
        expect(t.solvedBy(const []), isFalse);
        expect(t.solvedBy(t.reference.sublist(0, t.reference.length - 1)), isFalse);
        expect(t.flag, startsWith('ISC{'));
        expect(t.cipher, isNot(contains('ISC{')));
      });
    }

    test('a step that cannot read its input says so, and the run stops there', () {
      final r = CryptoRun.of('not hex!', const [CryptoOp('hex'), CryptoOp('rev')]);
      expect(r.outputs, isEmpty);
      expect(r.error, contains('hex'));
      expect(showBytes(const CryptoOp('rot', '3').apply('Fdhvdu'.codeUnits)), 'Caesar');
      expect(showBytes(const CryptoOp('xor', 'K').apply([0x02])), 'I');
      expect(showBytes([0, 255]), '00 ff');
    });
  });
}
