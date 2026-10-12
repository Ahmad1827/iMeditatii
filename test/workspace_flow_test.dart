// End-to-end flow of the Atelier against an in-memory Firestore:
// teacher writes -> autosave -> sends -> student sees it -> student works on it
// -> teacher sees the student's copy.
//
// Set WS_SHOTS=<dir> (and WS_FONTS=<dir with scp.ttf>) to also write PNGs of
// each step: `WS_SHOTS=/tmp/shots flutter test --update-goldens test/workspace_flow_test.dart`
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/gestures.dart';

import 'package:iMeditatii/code_workbench.dart';
import 'package:iMeditatii/ink_page.dart';
import 'package:iMeditatii/material_screen.dart';
import 'package:iMeditatii/note_editor.dart';
import 'package:iMeditatii/theme_manager.dart';
import 'package:iMeditatii/workspace_cards.dart';
import 'package:iMeditatii/workspace_models.dart';
import 'package:iMeditatii/workspace_screen.dart';

final String? _shots = Platform.environment['WS_SHOTS'];

Future<void> _loadFonts() async {
  if (_shots == null) return;
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String path) async => ByteData.view((await File(path).readAsBytes()).buffer);
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Italic']) {
    roboto.addFont(bytes('$dir/Roboto-$f.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(bytes('$dir/MaterialIcons-Regular.otf'))).load();
  final mono = Platform.environment['WS_FONTS'];
  if (mono != null && File('$mono/scp.ttf').existsSync()) {
    await (FontLoader('SourceCodePro_regular')..addFont(bytes('$mono/scp.ttf'))).load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shots == null) return;
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('$_shots/$name.png'));
}

Finder _hint(String hint) => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == hint);

void main() {
  late FakeFirebaseFirestore db;
  String viewer = 't1';

  GoRouter router(String start) => GoRouter(
        initialLocation: start,
        routes: [
          GoRoute(
            path: '/atelier',
            builder: (_, st) => Scaffold(
              body: WorkspaceBody(uid: viewer, openDocId: st.uri.queryParameters['doc'], create: st.uri.queryParameters['nou']),
            ),
          ),
          GoRoute(
            path: '/material/:id',
            builder: (_, st) => Scaffold(body: MaterialBody(uid: viewer, shareId: st.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/panou-elev',
            builder: (_, __) => Scaffold(
              backgroundColor: const Color(0xFFF7F8FA),
              body: Center(child: SizedBox(width: 700, child: ReceivedMaterialsCard(uid: viewer))),
            ),
          ),
          GoRoute(
            path: '/panou-profesor',
            builder: (_, __) => Scaffold(
              backgroundColor: const Color(0xFFF7F8FA),
              body: Center(child: SizedBox(width: 900, child: TeacherWorkspaceCard(uid: viewer))),
            ),
          ),
        ],
      );

  Future<void> open(WidgetTester tester, String location, {Size size = const Size(1320, 820)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, brightness: ThemeManager.isDark ? Brightness.dark : Brightness.light),
      routerConfig: router(location),
    ));
    await tester.pumpAndSettle();
  }

  setUpAll(_loadFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ThemeManager.themeNotifier.value = ThemeMode.light;
    ThemeManager.styleNotifier.value = AppStyleMode.clean;
    viewer = 't1';
    db = FakeFirebaseFirestore();
    Workspace.overrideDb = db;
    await db.collection('teachers').doc('t1').set({'name': 'Ana Pop'});
    await db.collection('chats').doc('c1').set({'teacherId': 't1', 'studentId': 's1', 'studentName': 'Mihai Ionescu', 'updatedAt': Timestamp.now()});
    await db.collection('chats').doc('c2').set({'teacherId': 't1', 'studentId': 's2', 'studentName': 'Ioana Radu', 'updatedAt': Timestamp.now()});
    await db.collection('chats').doc('c3').set({'teacherId': 'other', 'studentId': 's9', 'studentName': 'Altcineva', 'updatedAt': Timestamp.now()});
  });

  tearDown(() => Workspace.overrideDb = null);

  testWidgets('a note goes from the teacher to the student', (tester) async {
    await open(tester, '/atelier');
    expect(find.text('Atelierul tău'), findsOneWidget);
    await _shot(tester, '01-welcome');

    // ---- create from the "Fișă de lucru" template
    await tester.tap(find.text('Fișă de lucru'));
    await tester.pumpAndSettle();
    var docs = (await db.collection('workspace_docs').get()).docs;
    expect(docs.length, 1);
    final docId = docs.single.id;
    expect(docs.single['ownerId'], 't1');
    expect(docs.single['type'], 'note');

    // ---- title + body, saved after the debounce
    await tester.enterText(_hint('Pagină fără titlu'), 'Ecuația de gradul II');
    final firstBlock = find.descendant(of: find.byType(NoteEditor), matching: find.byType(TextField)).at(1);
    await tester.enterText(firstBlock, 'Rezolvă **toate** exercițiile.');
    await tester.pump();
    expect(find.text('Se salvează'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.text('Salvat'), findsOneWidget);
    var saved = (await db.collection('workspace_docs').doc(docId).get()).data()!;
    expect(saved['title'], 'Ecuația de gradul II');
    var blocks = NoteContent.parse(saved['content'] as String);
    expect(blocks.first.text, 'Rezolvă **toate** exercițiile.');
    expect(blocks.where((b) => b.type == NoteBlock.draw).length, 3);
    // sidebar + tab show the live title
    expect(find.text('Ecuația de gradul II'), findsNWidgets(3));
    await _shot(tester, '02-note-editor');

    // ---- send to one of the two students (the other teacher's student is not listed)
    await tester.tap(find.text('Trimite elevilor').first);
    await tester.pumpAndSettle();
    expect(find.text('Mihai Ionescu'), findsOneWidget);
    expect(find.text('Ioana Radu'), findsOneWidget);
    expect(find.text('Altcineva'), findsNothing);
    await tester.tap(find.text('Mihai Ionescu'));
    await tester.pump();
    await tester.enterText(_hint('Un mesaj pentru elevi (opțional)'), 'Până joi, te rog.');
    await tester.pump();
    await _shot(tester, '03-send-dialog');
    await tester.tap(find.text('Trimite la un elev'));
    await tester.pumpAndSettle();

    final share = (await db.collection('workspace_shares').doc('${docId}_s1').get()).data()!;
    expect(share['studentId'], 's1');
    expect(share['teacherName'], 'Ana Pop');
    expect(share['title'], 'Ecuația de gradul II');
    expect(share['message'], 'Până joi, te rog.');
    expect(share['version'], 1);
    expect(share['seenAt'], isNull);
    expect((await db.collection('workspace_shares').get()).docs.length, 1);
    final msgs = (await db.collection('chats').doc('c1').collection('messages').get()).docs;
    expect(msgs.single['senderId'], 't1');
    expect(msgs.single['text'], contains('Ecuația de gradul II'));
    expect((await db.collection('chats').doc('c2').collection('messages').get()).docs, isEmpty);
    await tester.pump(const Duration(seconds: 4)); // snackbar
    await tester.pumpAndSettle();
    expect(find.text('Trimis la 1'), findsOneWidget);
    await _shot(tester, '04-after-send');

    // ---- student dashboard card, then the material itself
    viewer = 's1';
    await open(tester, '/panou-elev');
    expect(find.text('Ecuația de gradul II'), findsOneWidget);
    expect(find.text('Nou'), findsOneWidget);
    expect(find.text('1 nou'), findsOneWidget);
    await _shot(tester, '05-student-card');
    await tester.tap(find.text('Ecuația de gradul II'));
    await tester.pumpAndSettle();
    expect(find.text('Până joi, te rog.'), findsOneWidget);
    expect(find.textContaining('toate', findRichText: true), findsWidgets);
    expect((await db.collection('workspace_shares').doc('${docId}_s1').get())['seenAt'], isNotNull);
    expect(find.text('Ai bifat 0 din 3'), findsOneWidget);

    // tick the first exercise
    final todoId = blocks.firstWhere((b) => b.type == NoteBlock.todo).id;
    await tester.tap(find.descendant(of: find.byType(NoteView), matching: find.byType(AnimatedContainer)).first);
    await tester.pumpAndSettle();
    expect(find.text('Ai bifat 1 din 3'), findsOneWidget);
    expect((await db.collection('workspace_shares').doc('${docId}_s1').get())['checks'][todoId], true);
    await _shot(tester, '06-student-note');

    // ---- the other student got nothing
    viewer = 's2';
    await open(tester, '/panou-elev');
    expect(find.text('Ecuația de gradul II'), findsNothing);

    // ---- teacher: resend bumps the version and marks it unseen again
    viewer = 't1';
    await open(tester, '/atelier?doc=$docId');
    expect(find.byType(NoteEditor), findsOneWidget);
    await tester.tap(find.text('Trimis la 1'));
    await tester.pumpAndSettle();
    expect(find.text('Văzut'), findsOneWidget);
    await _shot(tester, '07-sent-dialog');
    await tester.tap(find.text('Trimite și altora'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Are deja o versiune'), findsOneWidget);
    await tester.tap(find.text('Toți'));
    await tester.pump();
    await tester.tap(find.text('Trimite la 2 elevi'));
    await tester.pumpAndSettle();
    final again = (await db.collection('workspace_shares').doc('${docId}_s1').get()).data()!;
    expect(again['version'], 2);
    expect(again['seenAt'], isNull);
    expect(again['checks'][todoId], true); // the student's ticks survive a resend
    expect((await db.collection('workspace_shares').get()).docs.length, 2);

    // ---- pin, then delete: the document goes, the students keep their copies
    await tester.tap(find.byTooltip('Opțiuni').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixează sus'));
    await tester.pumpAndSettle();
    expect((await db.collection('workspace_docs').doc(docId).get())['pinned'], true);
    expect(find.text('FIXATE'), findsOneWidget);
    await tester.tap(find.byTooltip('Opțiuni').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Șterge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Șterge').last);
    await tester.pumpAndSettle();
    expect((await db.collection('workspace_docs').get()).docs, isEmpty);
    expect((await db.collection('workspace_shares').get()).docs.length, 2);
    expect(find.text('Atelierul tău'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a code file: the student works on a copy, the teacher sees it', (tester) async {
    await open(tester, '/atelier?nou=cpp');
    var docs = (await db.collection('workspace_docs').get()).docs;
    expect(docs.length, 1);
    final docId = docs.single.id;
    expect(docs.single['lang'], 'cpp');
    expect(find.byType(CodeWorkbench), findsOneWidget);

    // edit the code and the file name
    final editor = find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField));
    final c = tester.widget<TextField>(editor).controller! as CodeController;
    c.text = '${c.text}// tema: calculeaza si maximul\n';
    await tester.enterText(_hint('Numele fișierului'), 'suma.cpp');
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    final saved = (await db.collection('workspace_docs').doc(docId).get()).data()!;
    expect(saved['title'], 'suma.cpp');
    expect(saved['content'], endsWith('// tema: calculeaza si maximul\n'));
    await _shot(tester, '10-ide');

    // switching language is saved too
    await tester.tap(find.text('C++').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python 3').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1000));
    expect((await db.collection('workspace_docs').doc(docId).get())['lang'], 'python');
    await tester.tap(find.text('Python 3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('C++').last);
    await tester.pumpAndSettle();

    // send to everyone
    await tester.tap(find.text('Trimite elevilor').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toți'));
    await tester.pump();
    await tester.tap(find.text('Trimite la 2 elevi'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect((await db.collection('workspace_shares').get()).docs.length, 2);

    // student opens it and changes the code: saved as their copy, original untouched
    viewer = 's2';
    await open(tester, '/material/${docId}_s2');
    expect(find.text('suma.cpp'), findsOneWidget);
    expect(find.text('Versiunea profesorului'), findsNothing);
    final sEditor = find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField));
    final sc = tester.widget<TextField>(sEditor).controller! as CodeController;
    final original = sc.text;
    sc.text = '$original// rezolvat de Ioana\n';
    await tester.pump();
    expect(find.text('Versiunea profesorului'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    var sh = (await db.collection('workspace_shares').doc('${docId}_s2').get()).data()!;
    expect(sh['studentContent'], endsWith('// rezolvat de Ioana\n'));
    expect(sh['content'], original);
    expect(sh['seenAt'], isNotNull);
    await _shot(tester, '11-student-ide');

    // reopening restores the student's copy
    await open(tester, '/material/${docId}_s2');
    final again = tester.widget<TextField>(find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField))).controller!;
    expect(again.text, endsWith('// rezolvat de Ioana\n'));

    // reset goes back to what the teacher sent
    await tester.tap(find.text('Versiunea profesorului'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revino'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField))).controller!.text, original);
    expect((await db.collection('workspace_shares').doc('${docId}_s2').get())['studentContent'], isNull);

    // the student edits again; the teacher then sees both versions, read-only
    final sc2 = tester.widget<TextField>(find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField))).controller!;
    sc2.text = '$original// a doua incercare\n';
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    viewer = 't1';
    await open(tester, '/material/${docId}_s2');
    expect(find.text('Ce a lucrat elevul'), findsOneWidget);
    final tField = tester.widget<TextField>(find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField)));
    expect(tField.readOnly, true);
    expect(tField.controller!.text, endsWith('// a doua incercare\n'));
    await _shot(tester, '12-teacher-sees-student');
    await tester.tap(find.text('Ce ai trimis'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.descendant(of: find.byType(CodeEditor), matching: find.byType(TextField))).controller!.text, original);

    // a stranger cannot open someone else's material
    viewer = 's1';
    await open(tester, '/material/${docId}_s2');
    expect(find.text('Acest material a fost trimis altcuiva.'), findsOneWidget);
    await open(tester, '/material/nu-exista');
    expect(find.textContaining('Materialul nu mai există'), findsOneWidget);

    // teacher dashboard card reflects it
    viewer = 't1';
    await open(tester, '/panou-profesor');
    expect(find.text('suma.cpp'), findsOneWidget);
    expect(find.text('2 trimise'), findsOneWidget);
    expect(find.text('1 lucrate de elevi'), findsOneWidget);
    await _shot(tester, '13-teacher-card');

    // unsend from one student
    await open(tester, '/atelier?doc=$docId');
    await tester.tap(find.text('Trimis la 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retrage de la acest elev').first);
    await tester.pumpAndSettle();
    expect((await db.collection('workspace_shares').get()).docs.length, 1);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a handwritten page: the student writes on top, the teacher sees it', (tester) async {
    final sheet = find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SheetPainter');
    Future<void> write(List<List<Offset>> strokes, {Offset at = Offset.zero}) async {
      final origin = tester.getTopLeft(sheet) + at;
      for (final st in strokes) {
        final g = await tester.startGesture(origin + st.first, kind: PointerDeviceKind.mouse, buttons: kPrimaryMouseButton);
        for (var i = 1; i < st.length; i++) {
          await g.moveTo(origin + st[i]);
        }
        await g.up();
      }
      await tester.pump();
    }

    // "x² + 1", roughly
    final sample = [
      [const Offset(80, 90), const Offset(110, 130)],
      [const Offset(110, 90), const Offset(80, 130)],
      [const Offset(122, 78), const Offset(132, 72), const Offset(138, 80), const Offset(124, 96), const Offset(142, 96)],
      [const Offset(170, 110), const Offset(200, 110)],
      [const Offset(185, 95), const Offset(185, 125)],
      [const Offset(230, 100), const Offset(242, 88), const Offset(242, 132)],
    ];

    await open(tester, '/atelier?nou=ink');
    final docs = (await db.collection('workspace_docs').get()).docs;
    final docId = docs.single.id;
    expect(docs.single['type'], 'ink');
    expect(find.byType(InkPage), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);

    await tester.enterText(_hint('Pagină fără titlu'), 'Funcția de gradul II');
    await write(sample);
    await tester.tap(find.byTooltip('Dreptunghi'));
    await tester.pump();
    await write([
      [const Offset(60, 60), const Offset(270, 150)],
    ]);
    expect(find.text('Se salvează'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    final saved = (await db.collection('workspace_docs').doc(docId).get()).data()!;
    expect(saved['title'], 'Funcția de gradul II');
    expect(InkDoc.parse(saved['content'] as String).strokes.length, 7);
    await _shot(tester, '40-ink-teacher');

    await tester.tap(find.text('Trimite elevilor').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mihai Ionescu'));
    await tester.pump();
    await tester.tap(find.text('Trimite la un elev'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final sent = (await db.collection('workspace_shares').doc('${docId}_s1').get()).data()!;
    expect(sent['type'], 'ink');
    expect(sent['content'], saved['content']);

    // student: sees the page, writes underneath; only their layer is stored separately
    viewer = 's1';
    await open(tester, '/panou-elev');
    expect(find.textContaining('Pagină scrisă de mână'), findsOneWidget);
    await tester.tap(find.text('Funcția de gradul II'));
    await tester.pumpAndSettle();
    expect(find.byType(InkPage), findsOneWidget);
    await tester.tap(find.byTooltip('Culoare').at(2));
    await tester.pump();
    await write(sample.sublist(3), at: const Offset(0, 140));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    var sh = (await db.collection('workspace_shares').doc('${docId}_s1').get()).data()!;
    expect(sh['content'], saved['content']);
    expect(InkDoc.parse(sh['studentContent'] as String).strokes.length, 3);
    expect(sh['seenAt'], isNotNull);
    await _shot(tester, '41-ink-student');

    // reopening: the student's ink is still there and can be added to
    await open(tester, '/material/${docId}_s1');
    await write([
      [const Offset(300, 300), const Offset(340, 300)],
    ]);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    sh = (await db.collection('workspace_shares').doc('${docId}_s1').get()).data()!;
    expect(InkDoc.parse(sh['studentContent'] as String).strokes.length, 4);

    // teacher: read-only, with and without the student's layer
    viewer = 't1';
    await open(tester, '/material/${docId}_s1');
    expect(find.text('Cu ce a scris elevul'), findsOneWidget);
    expect(find.byTooltip('Stilou'), findsNothing);
    await _shot(tester, '42-ink-teacher-sees');
    await tester.tap(find.text('Doar ce ai trimis'));
    await tester.pumpAndSettle();
    expect(find.byType(InkPage), findsOneWidget);

    // erasing everything clears the student's copy
    viewer = 's1';
    await open(tester, '/material/${docId}_s1');
    await tester.tap(find.byTooltip('Șterge tot ce ai scris tu'));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect((await db.collection('workspace_shares').doc('${docId}_s1').get())['studentContent'], isNull);

    // phone
    await open(tester, '/material/${docId}_s1', size: const Size(390, 780));
    await _shot(tester, '43-ink-phone');
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone and dark layouts build without overflow', (tester) async {
    final id = await Workspace.create(ownerId: 't1', type: WsDoc.note, title: 'Plan', content: WsTemplate.all[1].build(), section: 'Clasa a X-a');
    await Workspace.create(ownerId: 't1', type: WsDoc.code, title: 'main.py', content: WsTemplate.all[4].build(), lang: 'python');
    await Workspace.send(
      docId: id,
      type: WsDoc.note,
      title: 'Plan',
      content: WsTemplate.all[1].build(),
      lang: 'cpp',
      stdin: '',
      teacherId: 't1',
      teacherName: 'Ana Pop',
      students: const [WsStudent(id: 's1', name: 'Mihai Ionescu', chatId: 'c1')],
    );

    const phone = Size(390, 780);
    await open(tester, '/atelier', size: phone);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Clasa a X-a'), findsWidgets);
    await _shot(tester, '20-phone-list');
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditor), findsOneWidget);
    await _shot(tester, '21-phone-note');
    await tester.tap(find.byTooltip('Toate documentele'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('main.py'));
    await tester.pumpAndSettle();
    expect(find.byType(CodeWorkbench), findsOneWidget);
    await _shot(tester, '22-phone-ide');

    viewer = 's1';
    await open(tester, '/material/${id}_s1', size: phone);
    expect(find.byType(NoteView), findsOneWidget);
    await _shot(tester, '23-phone-material');
    await open(tester, '/panou-elev', size: phone);
    await _shot(tester, '24-phone-card');

    ThemeManager.themeNotifier.value = ThemeMode.dark;
    viewer = 't1';
    await open(tester, '/atelier?doc=$id');
    await _shot(tester, '30-dark-note');
    await tester.tap(find.text('main.py').first);
    await tester.pumpAndSettle();
    await _shot(tester, '31-dark-ide');
    ThemeManager.themeNotifier.value = ThemeMode.light;

    expect(tester.takeException(), isNull);
  });
}
