// The ACS section in its own look: the courses by semester, each course's
// list, and every problem's page with its workspace, in both looks, on a
// phone and on a wide screen, with nothing overflowing or throwing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/acs/acs_course_screen.dart';
import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/acs_problem_screen.dart';
import 'package:iMeditatii/acs_screen.dart';
import 'package:iMeditatii/theme_manager.dart';

Future<void> show(WidgetTester t, Widget page, double width, AcsStyle style) async {
  ThemeManager.acsStyleNotifier.value = style;
  t.view.physicalSize = Size(width, 2600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: page));
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // the real font, so the widths are the ones a student sees
  setUpAll(() async {
    ByteData bytes(String path) => ByteData.view(File(path).readAsBytesSync().buffer);
    await (FontLoader('Iosevka')
          ..addFont(Future.value(bytes('assets/fonts/Iosevka-Regular.ttf')))
          ..addFont(Future.value(bytes('assets/fonts/Iosevka-Bold.ttf'))))
        .load();
  });

  test('LFA is split by the seminar\'s three tests, each problem in one', () {
    final d = AcsCourseData.parse('lfa', File('assets/data/acs/lfa.json').readAsStringSync());
    expect([for (final t in d.tests) '${t.name} ${t.short}'], ['Testul 1 LR', 'Testul 2 LIC', 'Testul 3 MT']);
    for (final p in d.problems) {
      expect(p.test, inInclusiveRange(1, 3), reason: p.id);
    }
    expect(d.problems.firstWhere((p) => p.chapter.startsWith('7.')).test, 3);
    expect(d.problems.firstWhere((p) => p.chapter.startsWith('5.')).test, 2);
    // each test's items: every problem in one item of its own test, every item with problems to train on
    for (final t in d.tests) {
      expect(t.topics, isNotEmpty, reason: t.name);
      for (final x in t.topics) {
        expect(d.problems.where((p) => p.topic == x.id).length, greaterThanOrEqualTo(5), reason: x.name);
      }
    }
    for (final p in d.problems) {
      final t = d.tests.firstWhere((t) => t.n == p.test);
      expect(t.topics.map((x) => x.id), contains(p.topic), reason: p.id);
    }
    expect(d.tests.first.topics.map((x) => x.points).fold(0.0, (a, b) => a + b), 12); // 10 + the bonus
  });

  testWidgets('a long list draws a page of rows, and more on request', (t) async {
    SharedPreferences.setMockInitialValues({'acs-capitol:lfa': ''});
    await show(t, const AcsCourseScreen(code: 'lfa'), 1300, AcsStyle.notebook);
    for (var i = 0; i < 40 && find.textContaining('arată încă').evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 50));
    }
    final d = AcsCourseData.parse('lfa', File('assets/data/acs/lfa.json').readAsStringSync());
    expect(find.textContaining('mai sunt ${d.problems.length - 40}'), findsOneWidget);
    final more = find.textContaining('arată încă');
    await t.ensureVisible(more);
    await t.tap(more);
    await t.pump();
    expect(find.textContaining('mai sunt ${d.problems.length - 80}'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('the list filters by one test or more', (t) async {
    SharedPreferences.setMockInitialValues({'acs-capitol:lfa': ''});
    await show(t, const AcsCourseScreen(code: 'lfa'), 1300, AcsStyle.notebook);
    for (var i = 0; i < 40 && find.textContaining('Testul').evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 50));
    }
    final d = AcsCourseData.parse('lfa', File('assets/data/acs/lfa.json').readAsStringSync());
    final t3 = d.problems.where((p) => p.test == 3).toList();
    final t1 = d.problems.firstWhere((p) => p.test == 1);
    Future<void> pick(String name) async {
      final chip = find.textContaining(name).first;
      await t.ensureVisible(chip);
      await t.tap(chip);
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
    }

    await pick('Testul 3 · MT ${t3.length}');
    expect(find.text(t3.first.title), findsWidgets);
    expect(find.text(t1.title), findsNothing);
    expect(find.text('${t3.length} probleme'), findsOneWidget);
    // and a second one
    await pick('Testul 1 · LR');
    expect(find.text(t1.title), findsWidgets);
    // an item of test 1
    final alg = d.problems.where((p) => p.topic == 'lr-algoritmice').toList();
    await pick('P4 · Proprietăți algoritmice (1,5p) ${alg.length}');
    expect(find.text(alg.first.title), findsWidgets);
    expect(find.text(t3.first.title), findsNothing);
    expect(find.text('${alg.length} probleme'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('acs-teste:lfa'), '1,3');
    expect(prefs.getString('acs-subiecte:lfa'), 'lr-algoritmice');
    expect(t.takeException(), isNull);
  });

  test('every ready course has problems, and counts what is solved', () async {
    SharedPreferences.setMockInitialValues({'acs:pclp:1': true, 'acs:pclp:2': true, 'acs:sd:1': false});
    final counts = await loadAcsCounts();
    for (final s in acsSubjects.where((s) => s.ready)) {
      expect(counts[s.code]?.problems, greaterThanOrEqualTo(10), reason: s.code);
    }
    expect(counts['pclp']!.solved, 2);
    expect(counts['sd']!.solved, 0);
    // every course is in a folder of the first page, and a folder's name is not a course's
    expect(acsSubjects.map((s) => s.group).toSet(), acsGroups.map((g) => g.slug).toSet());
    expect(acsGroups.where((g) => g.slug != 'admitere').every((g) => acsSubject(g.slug) == null), isTrue);
    expect(acsGroup('an3-sem1')!.subjects.map((s) => s.code), ['lfa', 'apd', 'egc', 'rl', 'isc', 'eg']);
    expect(acsTrail('rl'), [('an3-sem1', '/acs/an3-sem1'), ('rl', '/acs/rl')]);
  });

  for (final style in AcsStyle.values) {
    for (final width in [390.0, 1300.0]) {
      testWidgets('home, ${style.name} at ${width.toInt()} px', (t) async {
        SharedPreferences.setMockInitialValues({});
        await show(t, const AcsScreen(), width, style);
        // the first page lists the folders, not the courses
        for (final g in acsGroups) {
          expect(find.textContaining(g.title), findsWidgets, reason: g.title);
        }
        expect(find.textContaining('Rețele Locale'), findsNothing);
        expect(t.takeException(), isNull);
        // and each folder, its courses
        for (final g in acsGroups) {
          await show(t, AcsScreen(key: ValueKey(g.slug), group: g.slug), width, style);
          for (final s in g.subjects) {
            expect(find.textContaining(s.name), findsWidgets, reason: '${g.slug}: ${s.name}');
          }
          expect(t.takeException(), isNull, reason: g.slug);
        }
      });
    }
  }

  for (final s in acsSubjects.where((s) => s.ready)) {
    testWidgets('${s.code}: the list and every problem page open', (t) async {
      SharedPreferences.setMockInitialValues({});
      final data = (await t.runAsync(() => loadAcsCourse(s.code)))!;
      await show(t, AcsCourseScreen(code: s.code), 390, AcsStyle.terminal);
      expect(find.text(data.problems.first.title), findsWidgets);
      expect(t.takeException(), isNull);
      for (final (k, p) in data.problems.indexed) {
        // alternate the looks and the widths so both are seen on every kind
        final style = k.isEven ? AcsStyle.terminal : AcsStyle.notebook;
        final width = k % 4 < 2 ? 1300.0 : 390.0;
        await show(t, AcsProblemScreen(key: ValueKey(p.key), course: s.code, id: p.id), width, style);
        expect(find.textContaining(p.title), findsWidgets, reason: '${s.code} ${p.id}');
        expect(t.takeException(), isNull, reason: '${s.code} ${p.id} (${p.kind}, ${style.name}, $width)');
      }
    });
  }
}
