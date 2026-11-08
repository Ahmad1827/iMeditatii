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

  test('every ready course has problems, and counts what is solved', () async {
    SharedPreferences.setMockInitialValues({'acs:pclp:1': true, 'acs:pclp:2': true, 'acs:sd:1': false});
    final counts = await loadAcsCounts();
    for (final s in acsSubjects.where((s) => s.ready)) {
      expect(counts[s.code]?.problems, greaterThanOrEqualTo(10), reason: s.code);
    }
    expect(counts['pclp']!.solved, 2);
    expect(counts['sd']!.solved, 0);
    expect(acsSubjects.where((s) => s.ready).map((s) => s.semester).toSet(), {1, 2});
  });

  for (final style in AcsStyle.values) {
    for (final width in [390.0, 1300.0]) {
      testWidgets('home, ${style.name} at ${width.toInt()} px', (t) async {
        SharedPreferences.setMockInitialValues({});
        await show(t, const AcsScreen(), width, style);
        for (final s in acsSubjects) {
          expect(find.textContaining(s.name), findsWidgets, reason: s.name);
        }
        expect(t.takeException(), isNull);
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
