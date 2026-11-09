// Every ACS problem can be solved in its own tool: the reference solution,
// run in the app's engine (shell, emulator, Octave...), passes every check,
// and the untouched start does not.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/engine/circuit.dart';
import 'package:iMeditatii/acs/engine/ds.dart';
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
}
