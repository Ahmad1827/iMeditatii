// Admitere's multiple-choice questions: a letter key picks an answer and
// Enter checks it; a wrong one is crossed out and named, the right one solves
// the problem; a program's question then shows what it printed.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/acs_problem_screen.dart';
import 'package:iMeditatii/acs/ws/ws_grila.dart';
import 'package:iMeditatii/theme_manager.dart';

Future<AcsProblem> open(WidgetTester t, String id) async {
  SharedPreferences.setMockInitialValues({});
  ThemeManager.acsStyleNotifier.value = AcsStyle.terminal;
  t.view.physicalSize = const Size(1300, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final data = (await t.runAsync(() => loadAcsCourse('admitere')))!;
  await t.pumpWidget(MaterialApp(home: AcsProblemScreen(course: 'admitere', id: id)));
  for (var i = 0; i < 4; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 50));
  }
  return data.byId(id)!;
}

Future<void> press(WidgetTester t, String letter) async {
  await t.sendKeyEvent(LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId + grilaLetters.indexOf(letter)), character: letter);
  await t.pump();
  await t.sendKeyEvent(LogicalKeyboardKey.enter);
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('a wrong letter is named, the right one solves it', (t) async {
    final p = await open(t, '1');
    final right = grilaLetters[(p.spec['answer'] as num).toInt()];
    final wrong = right == 'a' ? 'b' : 'a';
    await press(t, wrong);
    expect(find.textContaining('$wrong) nu e corect'), findsOneWidget);
    expect(find.textContaining('rezolvată'), findsNothing);
    await press(t, right);
    expect(find.textContaining('rezolvată'), findsWidgets);
    expect(t.takeException(), isNull);
  }, variant: desktop);

  testWidgets('a program, solved, shows its real output', (t) async {
    final p = await open(t, '37');
    await press(t, grilaLetters[(p.spec['answer'] as num).toInt()]);
    expect(find.textContaining('./a.out'), findsOneWidget);
    expect(find.text('531135'), findsNWidgets(2)); // the option, and the output under it
  }, variant: desktop);
}
