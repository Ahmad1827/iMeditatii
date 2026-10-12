import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/code_workbench.dart';
import 'package:iMeditatii/note_editor.dart';
import 'package:iMeditatii/workspace_models.dart';

Widget _host(Widget child, {Size size = const Size(1100, 800)}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: size.width, height: size.height, child: child)),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('note content survives a round trip', () {
    final blocks = [
      NoteBlock(type: NoteBlock.h1, text: 'Titlu'),
      NoteBlock(type: NoteBlock.todo, text: 'temă', checked: true),
      NoteBlock(type: NoteBlock.code, text: 'int x;', lang: 'python'),
      NoteBlock(type: NoteBlock.draw, paper: 'grid', strokes: [
        NoteStroke(color: 0xFF112233, width: 0.006, marker: true, points: const [Offset(0.1, 0.2), Offset(0.33333, 0.4)]),
      ]),
    ];
    final back = NoteContent.parse(NoteContent.encode(blocks));
    expect(back.map((b) => b.type), [NoteBlock.h1, NoteBlock.todo, NoteBlock.code, NoteBlock.draw]);
    expect(back[1].checked, true);
    expect(back[2].lang, 'python');
    expect(back[3].paper, 'grid');
    expect(back[3].strokes.single.marker, true);
    expect(back[3].strokes.single.points.last.dx, closeTo(0.3333, 1e-9));
    expect(back[0].id, blocks[0].id);
    expect(NoteContent.parse('').single.type, NoteBlock.p);
    expect(NoteContent.parse('a\nb').map((b) => b.text), ['a', 'b']);
    expect(NoteContent.preview(NoteContent.encode(blocks)), 'Titlu · temă · int x;');
  });

  testWidgets('note editor: shortcuts, split, join, toolbar', (tester) async {
    final handle = NoteEditorHandle();
    var dirty = 0;
    await tester.pumpWidget(_host(NoteEditor(initialContent: '', handle: handle, onDirty: () => dirty++)));
    List<NoteBlock> read() => NoteContent.parse(handle.read()!);

    // "# " turns the paragraph into a heading
    await tester.enterText(find.byType(TextField).first, '# ');
    await tester.pump();
    expect(read().single.type, NoteBlock.h1);
    await tester.enterText(find.byType(TextField).first, 'Lecția 1');
    await tester.pump();

    // Enter splits into a new paragraph
    await tester.enterText(find.byType(TextField).first, 'Lecția 1\n');
    await tester.pump();
    await tester.pump();
    expect(read().map((b) => b.type), [NoteBlock.h1, NoteBlock.p]);
    expect(find.byType(TextField), findsNWidgets(2));

    // list, continued by Enter, ended by Enter on an empty item
    await tester.enterText(find.byType(TextField).at(1), '- ');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'unu\n');
    await tester.pump();
    await tester.pump();
    expect(read().map((b) => b.type), [NoteBlock.h1, NoteBlock.bullet, NoteBlock.bullet]);
    await tester.enterText(find.byType(TextField).at(2), '\n');
    await tester.pump();
    await tester.pump();
    expect(read().map((b) => b.type), [NoteBlock.h1, NoteBlock.bullet, NoteBlock.p]);

    // pasted lines become blocks
    await tester.enterText(find.byType(TextField).at(2), 'a\nb\nc');
    await tester.pump();
    await tester.pump();
    expect(read().map((b) => b.text), ['Lecția 1', 'unu', 'a', 'b', 'c']);

    // backspace at the start of "c" joins it to "b"
    await tester.tap(find.byType(TextField).at(4));
    await tester.pump();
    final c = tester.widget<TextField>(find.byType(TextField).at(4)).controller!;
    c.selection = const TextSelection.collapsed(offset: 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    await tester.pump();
    expect(read().map((b) => b.text), ['Lecția 1', 'unu', 'a', 'bc']);

    // toolbar: checklist, drawing, divider
    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await tester.pump();
    expect(read().last.type, NoteBlock.todo);
    await tester.tap(find.byIcon(Icons.draw_outlined));
    await tester.pump();
    await tester.pump();
    expect(read().map((b) => b.type), [NoteBlock.h1, NoteBlock.bullet, NoteBlock.p, NoteBlock.todo, NoteBlock.draw, NoteBlock.p]);

    // bold wraps and unwraps the selection
    await tester.tap(find.byType(TextField).at(2));
    await tester.pump();
    final a = tester.widget<TextField>(find.byType(TextField).at(2)).controller!;
    a.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();
    expect(read()[2].text, '**a**');
    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();
    expect(read()[2].text, 'a');

    // "```" makes a code block, "---" a divider
    await tester.enterText(find.byType(TextField).last, '```');
    await tester.pump();
    await tester.pump();
    expect(read().last.type, NoteBlock.code);
    expect(dirty, greaterThan(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ink pad records strokes and the view renders every block', (tester) async {
    final handle = NoteEditorHandle();
    final start = NoteContent.encode([NoteBlock(type: NoteBlock.draw), NoteBlock(text: 'x')]);
    await tester.pumpWidget(_host(NoteEditor(initialContent: start, handle: handle, onDirty: () {})));
    final pad = find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter.runtimeType.toString() == '_InkPainter');
    expect(pad, isNotEmpty);
    final center = tester.getCenter(find.byWidget(pad.first.widget));
    final g = await tester.startGesture(center);
    await g.moveBy(const Offset(40, 10));
    await g.moveBy(const Offset(40, -30));
    await g.up();
    await tester.pump();
    final drawn = NoteContent.parse(handle.read()!).first;
    expect(drawn.strokes.length, 1);
    expect(drawn.strokes.single.points.length, greaterThanOrEqualTo(3));

    final all = NoteContent.encode([
      for (final t in NoteBlock.labels.keys) NoteBlock(type: t, text: 'text **gras** `cod` ==x== ~~y~~ *i*'),
      drawn,
    ]);
    String? ticked;
    await tester.pumpWidget(_host(SingleChildScrollView(child: NoteView(content: all, onCheck: (id, v) => ticked = id))));
    expect(find.textContaining('gras', findRichText: true), findsWidgets);
    // only the code block keeps the markers, as literal text
    expect(find.textContaining('**', findRichText: true), findsOneWidget);
    await tester.tap(find.byType(AnimatedContainer).first);
    expect(ticked, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('code editor keys', (tester) async {
    String code = '';
    await tester.pumpWidget(_host(CodeWorkbench(
      initialCode: 'int main() {}',
      onCodeChanged: (v) => code = v,
      onLangChanged: (_) {},
    )));
    await tester.pump();
    final field = find.byType(TextField).first;
    final c = tester.widget<TextField>(field).controller! as CodeController;
    await tester.tap(field);
    await tester.pump();

    // Enter between braces opens an indented body
    c.selection = const TextSelection.collapsed(offset: 12);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(code, 'int main() {\n    \n}');
    expect(c.selection.baseOffset, 17);

    // auto-closing pair, then typing the closer steps over it
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit9, character: '(');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit9);
    expect(c.text, 'int main() {\n    ()\n}');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit0, character: ')');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit0);
    expect(c.text, 'int main() {\n    ()\n}');
    expect(c.selection.baseOffset, 19);

    // backspace inside an empty pair removes both
    c.selection = const TextSelection.collapsed(offset: 18);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(c.text, 'int main() {\n    \n}');

    // Tab indents, Shift+Tab outdents the selected lines
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(c.text, '    int main() {\n        \n    }');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(c.text, 'int main() {\n    \n}');

    // Ctrl+/ comments and uncomments
    c.selection = const TextSelection.collapsed(offset: 2);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    expect(c.text, '// int main() {\n    \n}');
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(c.text, 'int main() {\n    \n}');

    // snippet keeps the indentation of the line it lands on
    c.value = const TextEditingValue(text: '    ', selection: TextSelection.collapsed(offset: 4));
    c.insertSnippet('for (;;) {\n    |\n}');
    expect(c.text, '    for (;;) {\n        \n    }');
    expect(c.selection.baseOffset, 23);

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('workbench fits a phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(
      CodeWorkbench(initialCode: 'print(1)\n' * 80, initialLang: 'python', compact: true, onLangChanged: (_) {}),
      size: const Size(360, 560),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final h = NoteEditorHandle();
    await tester.pumpWidget(_host(NoteEditor(initialContent: WsTemplate.all[1].build(), handle: h, onDirty: () {}, compact: true), size: const Size(360, 560)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
