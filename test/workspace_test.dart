import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/gestures.dart';

import 'package:iMeditatii/code_workbench.dart';
import 'package:iMeditatii/ink_page.dart';
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

  test('ink document: compact storage and stroke simplification', () {
    final doc = InkDoc(paper: 'lines', height: 2.1, strokes: [
      NoteStroke(color: 0xFF112233, width: 0.0034, points: const [Offset(0.12345, 0.5), Offset(0.2, 1.99999)]),
      NoteStroke(color: 0xFFE5484D, width: 0.0064, straight: true, marker: true, points: const [Offset(0, 0), Offset(1, 2)]),
    ]);
    final raw = doc.encode();
    expect(raw, contains('"q":[1235,5000,2000,20000]'));
    final back = InkDoc.parse(raw);
    expect(back.paper, 'lines');
    expect(back.height, 2.1);
    expect(back.strokes.first.points.first.dx, closeTo(0.1235, 1e-9));
    expect(back.strokes.last.straight, true);
    expect(back.strokes.last.marker, true);
    expect(InkDoc.parse('').strokes, isEmpty);
    expect(InkDoc.parse('not json').paper, 'grid');
    // old-style float points still load
    expect(NoteStroke.fromJson({'c': 1, 'w': 0.01, 'p': [0.5, 0.25]}).points.single, const Offset(0.5, 0.25));

    // a straight run of 200 points collapses to its ends; a corner is kept
    final line = [for (var i = 0; i <= 200; i++) Offset(i / 400, 0.3)];
    expect(simplifyStroke(line).length, 2);
    final corner = [...line, for (var i = 1; i <= 200; i++) Offset(0.5, 0.3 + i / 400)];
    final simple = simplifyStroke(corner);
    expect(simple.length, 3);
    expect(simple[1], const Offset(0.5, 0.3));
  });

  testWidgets('ink page: write, shapes, erase, undo and redo', (tester) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = InkPageHandle();
    var dirty = 0;
    await tester.pumpWidget(_host(InkPage(initialContent: '', handle: handle, onDirty: () => dirty++)));
    InkDoc read() => InkDoc.parse(handle.read()!);
    expect(handle.isEmpty, true);

    final sheet = find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SheetPainter');
    final origin = tester.getTopLeft(sheet);
    final width = tester.getSize(sheet).width;
    Future<void> drag(Offset from, List<Offset> steps) async {
      final g = await tester.startGesture(origin + from, kind: PointerDeviceKind.mouse, buttons: kPrimaryMouseButton);
      for (final s in steps) {
        await g.moveBy(s);
      }
      await g.up();
      await tester.pump();
    }

    // freehand
    await drag(const Offset(100, 100), const [Offset(30, 5), Offset(30, 40), Offset(-20, 30)]);
    expect(read().strokes.single.points.length, greaterThanOrEqualTo(3));
    expect(read().strokes.single.points.first.dx, closeTo(100 / width, 0.001));
    expect(handle.isEmpty, false);

    // rectangle: five corners, closed
    await tester.tap(find.byTooltip('Dreptunghi'));
    await tester.pump();
    await drag(const Offset(300, 100), const [Offset(100, 0), Offset(0, 60)]);
    final rect = read().strokes.last;
    expect(rect.straight, true);
    expect(rect.points.length, 5);
    expect(rect.points.first, rect.points.last);

    // straight line
    await tester.tap(find.byTooltip('Linie dreaptă'));
    await tester.pump();
    await drag(const Offset(100, 300), const [Offset(200, 0)]);
    expect(read().strokes.last.points.length, 2);
    expect(read().strokes.length, 3);

    // eraser removes the line when crossing its middle, undo brings it back in place
    await tester.tap(find.byTooltip('Radieră'));
    await tester.pump();
    await drag(const Offset(200, 280), const [Offset(0, 40)]);
    expect(read().strokes.length, 2);
    await tester.tap(find.byTooltip('Anulează (Ctrl+Z)'));
    await tester.pump();
    expect(read().strokes.length, 3);
    expect(read().strokes.last.points.length, 2);
    await tester.tap(find.byTooltip('Refă (Ctrl+Y)'));
    await tester.pump();
    expect(read().strokes.length, 2);

    // Ctrl+Z works from the keyboard too
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(read().strokes.length, 3);

    // clear is undoable; writing at the bottom edge adds paper
    await tester.tap(find.byTooltip('Șterge toată pagina'));
    await tester.pump();
    expect(read().strokes, isEmpty);
    await tester.tap(find.byTooltip('Anulează (Ctrl+Z)'));
    await tester.pump();
    expect(read().strokes.length, 3);

    expect(read().height, InkDoc.startHeight);
    await tester.tap(find.byTooltip('Adaugă spațiu jos'));
    await tester.pump();
    expect(read().height, closeTo(InkDoc.startHeight + 0.7, 1e-6));
    await tester.tap(find.byTooltip('Hârtie: pătrățele'));
    await tester.pump();
    expect(read().paper, 'lines');

    // the hand tool does not draw
    await tester.tap(find.byTooltip('Mută pagina'));
    await tester.pump();
    await drag(const Offset(100, 200), const [Offset(50, 0)]);
    expect(read().strokes.length, 3);

    // a finger draws until a pen shows up; after that fingers only scroll
    await tester.tap(find.byTooltip('Stilou'));
    await tester.pump();
    var g = await tester.startGesture(origin + const Offset(500, 300));
    await g.moveBy(const Offset(40, 0));
    await g.up();
    await tester.pump();
    expect(read().strokes.length, 4);
    g = await tester.startGesture(origin + const Offset(500, 340), kind: PointerDeviceKind.stylus);
    await g.moveBy(const Offset(40, 0));
    await g.up();
    await tester.pump();
    expect(read().strokes.length, 5);
    g = await tester.startGesture(origin + const Offset(500, 380));
    await g.moveBy(const Offset(40, 0));
    await g.up();
    await tester.pump();
    expect(read().strokes.length, 5);

    expect(dirty, greaterThan(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ink page over a locked base: only the top layer changes', (tester) async {
    final base = InkDoc(paper: 'blank', height: 3, strokes: [
      NoteStroke(color: 0xFF000000, width: 0.004, points: const [Offset(0.1, 0.1), Offset(0.4, 0.1)]),
    ]).encode();
    final handle = InkPageHandle();
    await tester.pumpWidget(_host(InkPage(initialContent: '', base: base, handle: handle, onDirty: () {})));
    final sheet = find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SheetPainter');
    final origin = tester.getTopLeft(sheet);
    final w = tester.getSize(sheet).width;
    expect(tester.getSize(sheet).height, closeTo(w * 3, 1)); // takes the taller of the two
    expect(find.byTooltip('Hârtie: albă'), findsNothing); // paper belongs to the base

    // erasing over the teacher's line removes nothing
    await tester.tap(find.byTooltip('Radieră'));
    await tester.pump();
    var g = await tester.startGesture(origin + Offset(0.25 * w, 0.1 * w - 10), kind: PointerDeviceKind.mouse, buttons: kPrimaryMouseButton);
    await g.moveBy(const Offset(0, 20));
    await g.up();
    await tester.pump();
    expect(handle.isEmpty, true);

    await tester.tap(find.byTooltip('Stilou'));
    await tester.pump();
    g = await tester.startGesture(origin + const Offset(120, 200), kind: PointerDeviceKind.mouse, buttons: kPrimaryMouseButton);
    await g.moveBy(const Offset(60, 20));
    await g.up();
    await tester.pump();
    expect(InkDoc.parse(handle.read()!).strokes.length, 1);

    // read-only: no drawing tools, nothing can be added
    await tester.pumpWidget(_host(InkPage(key: UniqueKey(), initialContent: handle.read()!, base: base, readOnly: true)));
    expect(find.byTooltip('Stilou'), findsNothing);
    expect(find.byTooltip('Mărește'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
