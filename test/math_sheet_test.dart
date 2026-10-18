// Maths on a sheet: the student writes the solution on an ink page and sends
// it; a person checks it (the admin's queue, or the teacher). Accepted, the
// problem counts as solved; turned down, the student reads why and sends again.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/classes_models.dart';
import 'package:iMeditatii/math_sheet.dart';
import 'package:iMeditatii/theme_manager.dart';
import 'package:iMeditatii/workspace_models.dart';

void main() {
  late FakeFirebaseFirestore db;
  const p = HwProblem(id: '1', title: 'Reuniunea a două mulțimi', subject: 'Matematică', grade: '9');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ThemeManager.themeNotifier.value = ThemeMode.light;
    ThemeManager.styleNotifier.value = AppStyleMode.clean;
    db = FakeFirebaseFirestore();
    Classes.overrideDb = db;
    Workspace.overrideDb = db;
    await db.collection('users').doc('s1').set({'name': 'Mihai Ionescu', 'role': 'student'});
    await db.collection('users').doc('admin').set({'name': 'Ahmad', 'role': 'teacher'});
  });

  tearDown(() {
    Classes.overrideDb = null;
    Workspace.overrideDb = null;
  });

  test('only maths goes on a sheet', () {
    expect(isMathSubject('Matematică'), isTrue);
    expect(isMathSubject('Informatică'), isFalse);
  });

  test('a sheet is solved only when a person accepts it, and not any more if they take it back', () async {
    Future<Solution> mine() async => (await Classes.mySolutions('s1').first)[p.progressKey]!;
    Future<int> count() async => ((await db.collection('users').doc('s1').get()).data()?['solvedCount'] as int?) ?? 0;

    await Classes.saveSheet(uid: 's1', studentName: 'Mihai Ionescu', problem: p, sheet: '{"strokes":[]}');
    final queue = await Classes.pendingSheets().first;
    expect(queue.map((s) => s.key), [p.progressKey]);
    expect(queue.single.isSheet, isTrue);
    expect(queue.single.studentName, 'Mihai Ionescu');
    expect(queue.single.exercise!.title, p.title);

    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: false, note: 'Lipsește pasul 2', reviewerId: 'admin', reviewerName: 'Ahmad');
    expect((await mine()).rejected, isTrue);
    expect((await mine()).reviewNote, 'Lipsește pasul 2');
    expect(await Classes.pendingSheets().first, isEmpty);
    expect(await Classes.solvedBy('s1').first, isEmpty);

    // fixed and sent again: back in the queue
    await Classes.saveSheet(uid: 's1', studentName: 'Mihai Ionescu', problem: p, sheet: '{"strokes":[1]}');
    expect((await mine()).pending, isTrue);

    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: true, reviewerId: 'admin', reviewerName: 'Ahmad');
    expect((await mine()).approved, isTrue);
    expect((await mine()).reviewedName, 'Ahmad');
    expect(await Classes.solvedBy('s1').first, {p.progressKey});
    expect(await count(), 1);

    // accepting twice doesn't count it twice
    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: true, reviewerId: 'admin', reviewerName: 'Ahmad');
    expect(await count(), 1);

    // taken back
    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: false, note: 'Am greșit', reviewerId: 'admin', reviewerName: 'Ahmad');
    expect(await Classes.solvedBy('s1').first, isEmpty);
    expect(await count(), 0);
  });

  testWidgets('the student writes and sends; the admin sees it with the answer key and accepts it', (tester) async {
    // the answer key, as the bundled problem has it (the real file is parsed off the test's fake clock)
    exerciseSource = (subject, grade, id) async => {'raspuns_corect': '8', 'solutie': 'A ∪ B are 8 elemente.'};
    addTearDown(() => exerciseSource = loadExercise);
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MathSheetPanel(problem: p, uid: 's1')))));
    await tester.pumpAndSettle();
    expect(find.text('Rezolvarea ta'), findsOneWidget);
    final send = find.widgetWithText(GestureDetector, 'Trimite la verificare');
    expect(find.text('Trimite la verificare'), findsOneWidget);

    // write on the sheet
    final sheet = find.byType(MathSheetPanel);
    final c = tester.getCenter(sheet);
    final g = await tester.startGesture(c, kind: PointerDeviceKind.stylus);
    for (var i = 1; i <= 12; i++) {
      await g.moveBy(const Offset(12, 4));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trimite la verificare'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Așteaptă verificarea'), findsOneWidget);
    expect(send, findsNothing); // the button now reads "Trimite din nou"
    final sent = (await Classes.pendingSheets().first).single;
    expect(sent.last, isNot(contains('"strokes":[]')));

    // the admin's queue
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SheetReviewQueue(reviewerId: 'admin')))));
    await tester.pumpAndSettle();
    expect(find.text('Mihai Ionescu · Reuniunea a două mulțimi'), findsOneWidget);
    expect(find.text('Răspunsul corect: 8'), findsOneWidget); // from the problem, for the reviewer only
    await tester.tap(find.text('Acceptă'));
    await tester.pumpAndSettle();
    expect(find.text('Nicio rezolvare de verificat.'), findsOneWidget);

    // and the student sees it
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MathSheetPanel(problem: p, uid: 's1')))));
    await tester.pumpAndSettle();
    expect(find.text('Acceptată de Ahmad. Problema e rezolvată.'), findsOneWidget);
    expect((await db.collection('users').doc('s1').get()).data()!['solvedIds'], [p.progressKey]);
  });

  testWidgets('a solution on paper: only pictures are sent, and the reviewer sees them', (tester) async {
    await Classes.saveSheet(uid: 's1', studentName: 'Mihai Ionescu', problem: p, sheet: '', photos: ['https://x/1.jpg', 'https://x/2.jpg']);
    final sent = (await Classes.pendingSheets().first).single;
    expect(sent.isSheet, isTrue);
    expect(sent.photos, ['https://x/1.jpg', 'https://x/2.jpg']);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SheetReviewQueue(reviewerId: 'admin')))));
    await tester.pumpAndSettle();
    expect(find.text('Poze cu rezolvarea (apasă ca să mărești)'), findsOneWidget);
    expect(find.bySemanticsLabel('Poza 2'), findsOneWidget);

    // the student's panel opens with what they sent
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MathSheetPanel(problem: p, uid: 's1')))));
    await tester.pumpAndSettle();
    expect(find.text('2 / $sheetMaxPhotos poze'), findsOneWidget);
  });

  testWidgets('the sheet opens big in the middle of the screen; what is written there comes back and is sent', (tester) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<void> draw(Offset at) async {
      final g = await tester.startGesture(at, kind: PointerDeviceKind.stylus);
      for (var i = 1; i <= 12; i++) {
        await g.moveBy(const Offset(12, 4));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MathSheetPanel(problem: p, uid: 's1')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mărește foaia'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await draw(tester.getCenter(find.byType(Dialog)));
    await tester.tap(find.text('Micșorează'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Trimite la verificare'), findsOneWidget);

    // sent from the small sheet: it has what was written big
    await tester.tap(find.text('Trimite la verificare'));
    await tester.pumpAndSettle();
    final sent = (await Classes.pendingSheets().first).single;
    expect(sent.last, isNotEmpty);
    expect(sent.last, isNot(contains('"strokes":[]')));

    // and from the big view straight away
    await tester.tap(find.text('Mărește foaia'));
    await tester.pumpAndSettle();
    await draw(tester.getCenter(find.byType(Dialog)) + const Offset(0, 80));
    await tester.tap(find.text('Trimite'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    final again = (await Classes.pendingSheets().first).single;
    expect(again.last.length, greaterThan(sent.last.length));
  });

  testWidgets('the student sees what they sent and that it was turned down, in red, with why', (tester) async {
    await Classes.saveSheet(uid: 's1', studentName: 'Mihai Ionescu', problem: p, sheet: '', photos: ['https://x/1.jpg']);
    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: false, note: 'Lipsește pasul 2.', reviewerId: 'admin', reviewerName: 'Ahmad');
    final sent = (await Classes.mySolutions('s1').first)[p.progressKey]!;

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SheetSubmission(solution: sent)))));
    await tester.pumpAndSettle();
    expect(find.text('Respinsă de Ahmad: „Lipsește pasul 2”. Corectează și trimite din nou.'), findsOneWidget);
    expect(find.bySemanticsLabel('Poza 1'), findsOneWidget);
  });

  testWidgets('every attempt is kept with its own verdict, newest first', (tester) async {
    await Classes.saveSheet(uid: 's1', studentName: 'Mihai Ionescu', problem: p, sheet: '', photos: ['https://x/1.jpg']);
    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: false, note: 'Lipsește pasul 2.', reviewerId: 'admin', reviewerName: 'Ahmad');
    await Classes.saveSheet(uid: 's1', studentName: 'Mihai Ionescu', problem: p, sheet: '', photos: ['https://x/2.jpg']);
    await Classes.reviewSheet(uid: 's1', key: p.progressKey, accept: true, reviewerId: 'admin', reviewerName: 'Ahmad');

    final all = await Classes.attempts('s1', p.progressKey).first;
    expect(all.map((a) => a.review), ['approved', 'rejected']);
    expect(all.map((a) => a.photos.single), ['https://x/2.jpg', 'https://x/1.jpg']);
    expect(all.last.reviewNote, 'Lipsește pasul 2.');

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SheetHistory(uid: 's1', problemKey: p.progressKey)))));
    await tester.pumpAndSettle();
    expect(find.text('Încercarea 2'), findsOneWidget);
    expect(find.text('Acceptată de Ahmad. Problema e rezolvată.'), findsOneWidget); // the newest, open
    expect(find.textContaining('Lipsește pasul 2'), findsNothing); // the older one, closed
    await tester.tap(find.text('Încercarea 1'));
    await tester.pumpAndSettle();
    expect(find.text('Respinsă de Ahmad: „Lipsește pasul 2”. Corectează și trimite din nou.'), findsOneWidget);
  });
}
