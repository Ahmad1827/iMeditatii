import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/exercise_detail_screen.dart';

void main() {
  final list = jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, dynamic>;
  final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;

  test('short answers accept the usual ways of writing a number', () {
    bool ok(String given, String expected) => ExerciseDetailScreen.answersMatch(given, expected);
    expect(ok('39', '39'), true);
    expect(ok(' 39 ', '39'), true);
    expect(ok('39,0', '39'), true);
    expect(ok('−12', '-12'), true); // typographic minus
    expect(ok('- 12', '-12'), true);
    expect(ok('1/2', '0.5'), true);
    expect(ok('0,5', '1/2'), true);
    expect(ok('10/4', '5/2'), true);
    expect(ok('40', '39'), false);
    expect(ok('', '0'), false);
    expect(ok('1/0', '1'), false);
    expect(ok('abc', 'ABC'), true); // non-numeric answers still compare as text
    expect(ok('abd', 'abc'), false);
  });

  test('every listed problem has details, and every subject offered has problems', () {
    for (final subject in ['Informatică', 'Matematică']) {
      expect(list[subject], isNotNull, reason: subject);
      var count = 0;
      (list[subject] as Map<String, dynamic>).forEach((grade, chapters) {
        (chapters as Map<String, dynamic>).forEach((chapter, items) {
          for (final item in items as List) {
            count++;
            final d = details[subject]?[grade]?[item['id']];
            expect(d, isNotNull, reason: '$subject $grade ${item['id']}');
            expect(d['title'], item['title']);
            expect(d['category'], chapter);
            expect('${d['description']}'.trim(), isNotEmpty);
          }
        });
      });
      expect(count, greaterThanOrEqualTo(40), reason: subject);
    }
  });

  test('maths problems are checked by a person, who has the worked solution to hand', () {
    // no answer is compared automatically: the student sends a sheet or photos
    // and an admin or the homework's teacher reviews it, with this beside them
    final ids = <String>{};
    (details['Matematică'] as Map<String, dynamic>).forEach((grade, problems) {
      (problems as Map<String, dynamic>).forEach((id, p) {
        expect(ids.add(id), true, reason: 'duplicate id $id');
        expect('${p['solutie'] ?? ''}'.trim(), isNotEmpty, reason: id);
        expect(p['tip_exercitiu'], isNot('cod'), reason: id);
      });
    });
    expect(ids.length, 304);
  });

  test('every maths chapter of IX–XII has 10 problems, from ușoară to grea, and the olympiad comes last', () {
    (list['Matematică'] as Map<String, dynamic>).forEach((grade, chapters) {
      final names = (chapters as Map<String, dynamic>).keys.toList();
      expect(names.last, endsWith('Olimpiadă'), reason: grade);
      for (var i = 0; i < names.length; i++) {
        expect(names[i], startsWith('${i + 1}. '), reason: '$grade: ${names[i]}');
      }
      for (final name in names.take(names.length - 1)) {
        final items = chapters[name] as List;
        expect(items.length, 10, reason: '$grade $name');
        expect({for (final it in items) it['difficulty']}, {'ușoară', 'medie', 'grea'}, reason: '$grade $name');
      }
    });
  });

  group('grade 12 informatics: Subiectul III from every BAC paper, 2019 to 2026', () {
    final g12 = (details['Informatică']['12'] as Map<String, dynamic>);
    final bac = {for (final e in g12.entries) if ('${e.value['sursa'] ?? ''}'.startsWith('BAC ')) e.key: e.value as Map<String, dynamic>};

    test('each paper with its three problems, each problem with its source, difficulty and why', () {
      expect(bac.length, 216);
      final papers = <String, Set<String>>{};
      for (final e in bac.entries) {
        final p = e.value;
        final m = RegExp(r'^BAC (20\d\d) · (.+) · Subiectul III\.([123])').firstMatch('${p['sursa']}');
        expect(m, isNotNull, reason: '${e.key}: ${p['sursa']}');
        final year = int.parse(m!.group(1)!);
        expect(year, inInclusiveRange(2019, 2026));
        papers.putIfAbsent('$year ${m.group(2)}', () => {}).add(m.group(3)!);
        expect(p['category'], startsWith('${m.group(3)}. Subiectul III.${m.group(3)}'), reason: e.key);
        expect(['ușoară', 'medie', 'grea'], contains(p['difficulty']), reason: e.key);
        expect('${p['dificultate_motiv'] ?? ''}'.trim(), isNotEmpty, reason: e.key);
        expect((p['tests'] as List).length, greaterThanOrEqualTo(3), reason: e.key);
        expect(p['examples']['output'], (p['tests'] as List).first['output'], reason: '${e.key}: the example is the first test');
      }
      // 2019–2026: models, simulations, special, June–July, reserve and August sessions,
      // plus the 2020 and 2021 training tests (test 11 of 2021 is the 2021 special session again)
      expect(papers.length, 72);
      for (final e in papers.entries) {
        expect(e.value, {'1', '2', '3'}, reason: e.key);
      }
      for (final y in ['2019', '2020', '2021', '2022', '2023', '2024', '2025', '2026']) {
        expect(papers.keys.where((k) => k.startsWith(y)), isNotEmpty, reason: y);
        expect(papers.containsKey('$y Sesiunea iunie–iulie'), true, reason: y);
        expect(papers.containsKey('$y Model'), true, reason: y);
      }
      expect(papers.keys.where((k) => k.startsWith('2020 Test de antrenament')).length, 20);
      expect(papers.keys.where((k) => k.startsWith('2021 Test de antrenament')).length, 11);
    });

    test('the list shows the same source and difficulty; the older practice problems say they are not from a paper', () {
      final cats = list['Informatică']['12'] as Map<String, dynamic>;
      for (final c in cats.entries) {
        for (final item in c.value as List) {
          final d = g12[item['id']];
          expect(item['sursa'], d['sursa'], reason: '${item['id']}');
          expect(item['difficulty'], d['difficulty'], reason: '${item['id']}');
        }
      }
      final extra = cats.entries.firstWhere((c) => c.key.startsWith('5.')).value as List;
      expect(extra.length, 30);
      for (final item in extra) {
        expect('${item['sursa']}', startsWith('Exercițiu de antrenament'));
      }
    });

    final gpp = Process.runSync('which', ['g++']).exitCode == 0;
    test('every official solution passes all its tests', () async {
      String norm(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final tmp = Directory.systemTemp.createTempSync('bac');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final failures = <String>[];
      final ids = bac.keys.toList();
      for (var i = 0; i < ids.length; i += 8) {
        await Future.wait([
          for (final id in ids.skip(i).take(8))
            () async {
              final dir = Directory('${tmp.path}/$id')..createSync();
              File('${dir.path}/main.cpp').writeAsStringSync(bac[id]!['official_solution']['code']);
              final c = await Process.run('g++', ['-std=c++17', '-O2', 'main.cpp', '-o', 'main'], workingDirectory: dir.path);
              if (c.exitCode != 0) return failures.add('$id: compile error');
              for (final t in bac[id]!['tests'] as List) {
                final p = await Process.start('${dir.path}/main', [], workingDirectory: dir.path);
                p.stdin.write(t['input']);
                await p.stdin.close();
                final out = await p.stdout.transform(const SystemEncoding().decoder).join();
                await p.exitCode;
                if (norm(out) != norm('${t['output']}')) failures.add('$id: ${'${t['input']}'.split('\n').first}');
              }
            }(),
        ]);
      }
      expect(failures, isEmpty);
    }, skip: gpp ? false : 'needs g++', timeout: const Timeout(Duration(minutes: 10)));
  });
}
