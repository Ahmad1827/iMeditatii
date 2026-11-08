// The ACS section: the first-year courses open their problems, grouped by
// semester, in both looks and on a phone, with nothing overflowing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/acs_screen.dart';
import 'package:iMeditatii/theme_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every course with problems has them, and counts what is solved', () async {
    SharedPreferences.setMockInitialValues({'ACS_PCLP_1': true, 'ACS_PCLP_2': true, 'ACS_SD_1': false});
    final counts = await loadAcsCounts();
    for (final s in acsSubjects.where((s) => s.ready)) {
      expect(counts[s.section]?.problems, greaterThanOrEqualTo(12), reason: s.section);
    }
    expect(counts['PCLP']!.solved, 2);
    expect(counts['SD']!.solved, 0);
    expect(acsSubjects.where((s) => s.ready).map((s) => s.semester).toSet(), {1, 2});
  });

  for (final style in AcsStyle.values) {
    for (final width in [390.0, 1200.0]) {
      testWidgets('${style.name} at ${width.toInt()} px: every course listed, nothing overflows', (t) async {
        SharedPreferences.setMockInitialValues({});
        ThemeManager.acsStyleNotifier.value = style;
        t.view.physicalSize = Size(width, 2400);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(const MaterialApp(home: AcsScreen()));
        await t.pump(const Duration(milliseconds: 300));
        for (final s in acsSubjects) {
          expect(find.textContaining(s.name), findsWidgets, reason: s.name);
        }
        expect(t.takeException(), isNull);
      });
    }
  }
}
