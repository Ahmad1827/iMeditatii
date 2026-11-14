// The ACS code editor answers keys as the IDE does: a real widget, real key events.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/acs/acs_kit.dart';
import 'package:iMeditatii/acs/ws/ws_common.dart';

Future<TextEditingController> _editor(WidgetTester t, String lang, String text) async {
  final c = acsCodeController(text, const {});
  await t.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AcsCodeEditor(AcsInk.current, c, lang: lang)))));
  await t.tap(find.byType(TextField));
  await t.pump();
  c.selection = TextSelection.collapsed(offset: text.length);
  await t.pump();
  return c;
}

void main() {
  testWidgets('C: { closes itself, Enter opens the body, } lines up', (t) async {
    final c = await _editor(t, 'cpp', 'int main() ');
    await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft, character: '{');
    expect(c.text, 'int main() {}');
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(c.text, 'int main() {\n    \n}');
    await t.sendKeyEvent(LogicalKeyboardKey.digit9, character: '(');
    expect(c.text, 'int main() {\n    ()\n}');
  });

  testWidgets('Octave: Enter after for goes in, end comes back on Enter', (t) async {
    final c = await _editor(t, 'octave', 'for i = 1:n');
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(c.text, 'for i = 1:n\n    ');
    c.value = TextEditingValue(text: '${c.text}x = i;\n    end', selection: TextSelection.collapsed(offset: '${c.text}x = i;\n    end'.length));
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(c.text, 'for i = 1:n\n    x = i;\nend\n');
  });

  testWidgets('Shift+Alt+F aligns the assembly', (t) async {
    final c = await _editor(t, 'asm', 'f:\nmov eax,1\nret');
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyF);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(c.text, 'f:\n    mov eax, 1\n    ret');
  });
}
