// The USO shell takes the keyboard without a click: it has the focus when the
// page opens, a key typed while nothing is focused goes into it, a click
// anywhere on the terminal focuses it, and so do the buttons and nano's Esc.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/acs_problem_screen.dart';
import 'package:iMeditatii/theme_manager.dart';

Future<void> open(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  ThemeManager.acsStyleNotifier.value = AcsStyle.terminal;
  t.view.physicalSize = const Size(1300, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.runAsync(() => loadAcsCourse('uso'));
  await t.pumpWidget(const MaterialApp(home: AcsProblemScreen(course: 'uso', id: '1')));
  for (var i = 0; i < 4; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The shell's command line: the only one-line field with the send action.
TextField prompt(WidgetTester t) => t.widget<TextField>(find.byWidgetPredicate((w) => w is TextField && w.textInputAction == TextInputAction.send));

void main() {
  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('focused as soon as the page opens', (t) async {
    await open(t);
    expect(prompt(t).focusNode!.hasFocus, isTrue);
  }, variant: desktop);

  testWidgets('a key typed while nothing has the focus goes to the shell', (t) async {
    await open(t);
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pump();
    expect(prompt(t).focusNode!.hasFocus, isFalse);
    await t.sendKeyEvent(LogicalKeyboardKey.keyL, character: 'l');
    await t.pump();
    expect(prompt(t).controller!.text, 'l');
    expect(prompt(t).focusNode!.hasFocus, isTrue);
  }, variant: desktop);

  testWidgets('a click on the output focuses it, and so does Verifică', (t) async {
    await open(t);
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pump();
    await t.tapAt(t.getTopLeft(find.textContaining('scrie direct')) + const Offset(20, 6));
    await t.pump();
    expect(prompt(t).focusNode!.hasFocus, isTrue);

    FocusManager.instance.primaryFocus?.unfocus();
    await t.tap(find.text('[ verifică ]'));
    await t.pump();
    await t.pump();
    expect(prompt(t).focusNode!.hasFocus, isTrue);
  }, variant: desktop);

  testWidgets('nano takes the keyboard, Esc saves and gives it back to the shell', (t) async {
    await open(t);
    await t.enterText(find.byWidget(prompt(t)), 'nano note.txt');
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pump();
    await t.pump();
    final editor = find.byWidgetPredicate((w) => w is TextField && w.maxLines == null);
    expect(editor, findsOneWidget);
    expect(t.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
    await t.enterText(editor, 'salut');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    await t.pump();
    expect(editor, findsNothing);
    expect(find.textContaining('am scris'), findsOneWidget);
    expect(prompt(t).focusNode!.hasFocus, isTrue);
  }, variant: desktop);
}
