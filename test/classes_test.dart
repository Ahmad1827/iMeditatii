// Classes and homework against an in-memory Firestore:
// teacher makes a class -> student opens the link and joins -> teacher gives
// homework -> student sees it in the dock on any page, hides it, brings it
// back, finishes it -> teacher sees the progress.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/classes_models.dart';
import 'package:iMeditatii/classes_screen.dart';
import 'package:iMeditatii/homework_dock.dart';
import 'package:iMeditatii/theme_manager.dart';
import 'package:iMeditatii/workspace_models.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ThemeManager.themeNotifier.value = ThemeMode.light;
    ThemeManager.styleNotifier.value = AppStyleMode.clean;
    db = FakeFirebaseFirestore();
    Classes.overrideDb = db;
    Workspace.overrideDb = db;
    await db.collection('users').doc('t1').set({'name': 'Ana Pop', 'role': 'teacher'});
    await db.collection('teachers').doc('t1').set({'name': 'Ana Pop'});
    await db.collection('users').doc('s1').set({'name': 'Mihai Ionescu', 'role': 'student'});
    await db.collection('users').doc('s2').set({'name': 'Ioana Radu', 'role': 'student'});
    await db.collection('users').doc('s3').set({'name': 'Dan Marin', 'role': 'student'});
  });

  tearDown(() {
    Classes.overrideDb = null;
    Workspace.overrideDb = null;
  });

  group('model', () {
    test('codes are short, unambiguous and survive sloppy typing', () {
      for (var i = 0; i < 200; i++) {
        final c = Classes.newCode();
        expect(c, matches(RegExp(r'^[A-HJKMNP-Z2-9]{6}$')));
      }
      expect(Classes.cleanCode(' k7m-2qx '), 'K7M2QX');
    });

    test('class homework reaches students who join later; direct homework only its student', () async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Mate', subject: 'Matematică');
      await Classes.join(code, 's1', 'Mihai Ionescu');
      final cls = SchoolClass.fromSnap(await Classes.classes.doc(code).get());
      expect(cls.members.map((m) => m.name), ['Mihai Ionescu']);

      await Classes.assign(teacherId: 't1', teacherName: 'Ana Pop', title: 'Ecuații', toClasses: [cls], dueAt: DateTime.now().add(const Duration(days: 2)));
      await Classes.assign(teacherId: 't1', teacherName: 'Ana Pop', title: 'Doar pentru Ioana', toStudents: [const HwStudent('s2', 'Ioana Radu')]);

      expect((await Classes.forStudent('s1').first).map((h) => h.title), ['Ecuații']);
      expect((await Classes.forStudent('s2').first).map((h) => h.title), ['Doar pentru Ioana']);
      expect(await Classes.forStudent('s3').first, isEmpty);

      // Dan joins after the homework was given: he still gets it.
      await Classes.join(code, 's3', 'Dan Marin');
      expect((await Classes.forStudent('s3').first).map((h) => h.title), ['Ecuații']);

      // Teacher's progress counts current members.
      final hw = (await Classes.assignedBy('t1').first).firstWhere((h) => h.title == 'Ecuații');
      await Classes.setDone(hw.id, 's1', true);
      final classes = await Classes.taughtBy('t1').first;
      final fresh = Homework.fromSnap(await Classes.homework.doc(hw.id).get());
      final r = hwRecipients(fresh, classes);
      expect(r.keys.toSet(), {'s1', 's3'});
      expect(r.keys.where(fresh.isDone), ['s1']);

      // Removed from the class: no more class homework.
      await Classes.removeMember(code, 's3');
      expect(await Classes.forStudent('s3').first, isEmpty);
    });

    test('the Atelier page is copied for the student the first time they open it', () async {
      final docId = await Workspace.create(ownerId: 't1', type: WsDoc.code, title: 'main.cpp', content: 'int main(){}');
      final id = await Classes.assign(
        teacherId: 't1',
        teacherName: 'Ana Pop',
        title: 'Cod',
        toStudents: [const HwStudent('s1', 'Mihai Ionescu')],
        material: HwMaterial(docId: docId, type: WsDoc.code, title: 'main.cpp', lang: 'cpp'),
      );
      final hw = Homework.fromSnap(await Classes.homework.doc(id).get());
      final shareId = await Classes.openMaterial(hw, 's1', 'Mihai Ionescu');
      final share = WsShare.fromSnap(await Workspace.shares.doc(shareId).get());
      expect(share.studentId, 's1');
      expect(share.content, 'int main(){}');

      // Opening again keeps the student's work.
      await Workspace.saveStudentCopy(shareId, 'int main(){ return 0; }');
      await Workspace.update(docId, {'content': 'changed by teacher'});
      expect(await Classes.openMaterial(hw, 's1', 'Mihai Ionescu'), shareId);
      expect(WsShare.fromSnap(await Workspace.shares.doc(shareId).get()).studentContent, 'int main(){ return 0; }');
    });

    test('a logged-out invite brings the student back to the class after login', () async {
      expect(await Classes.studentLanding(), '/materii');
      await Classes.rememberInvite('K7M2QX');
      expect(await Classes.studentLanding(), '/clasa/K7M2QX');
      await Classes.forgetInvite();
      expect(await Classes.studentLanding(), '/materii');
    });
  });

  group('screens', () {
    Future<void> open(WidgetTester tester, Widget home, {Size size = const Size(1280, 860), StreamController<String?>? dockUser}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/x',
        routes: [
          GoRoute(path: '/x', builder: (_, __) => Scaffold(body: home)),
          GoRoute(path: '/clase', builder: (_, __) => const Scaffold(body: Text('PAGINA CLASE'))),
          GoRoute(path: '/clasa/:code', builder: (_, __) => const Scaffold(body: Text('PAGINA CLASA'))),
          GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('PAGINA LOGIN'))),
          GoRoute(path: '/exercitiu/:id', builder: (_, s) => Scaffold(body: Text('PAGINA EXERCITIU ${s.pathParameters['id']}'))),
          GoRoute(path: '/inregistrare', builder: (_, __) => const Scaffold(body: Text('PAGINA SIGNUP'))),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        key: UniqueKey(),
        theme: ThemeData(useMaterial3: false),
        routerConfig: router,
        builder: (context, child) => Stack(children: [
          child!,
          if (dockUser != null) HomeworkDock(router: router, users: dockUser.stream),
        ]),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('logged out: the invite shows the class and remembers it', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Mate', subject: 'Matematică');
      await open(tester, ClassBody(uid: '', code: code.toLowerCase()));
      expect(find.text('9B Mate'), findsOneWidget);
      expect(find.text('Ana Pop · Matematică'), findsOneWidget);
      expect(await Classes.studentLanding(), '/clasa/$code');
      await tester.tap(find.text('Creează cont'));
      await tester.pumpAndSettle();
      expect(find.text('PAGINA SIGNUP'), findsOneWidget);
    });

    testWidgets('a student who opens the link joins the class', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Mate');
      await Classes.rememberInvite(code);
      await open(tester, ClassBody(uid: 's1', code: code));
      final cls = SchoolClass.fromSnap(await Classes.classes.doc(code).get());
      expect(cls.hasMember('s1'), isTrue);
      expect(cls.members.single.name, 'Mihai Ionescu');
      expect(find.text('9B Mate'), findsWidgets); // on the board and on its sign
      expect(await Classes.studentLanding(), '/materii'); // invite used up

      // The room is empty until they pick a chair.
      expect(find.text('Alege-ți un loc: apasă pe un scaun liber.'), findsOneWidget);
      await tester.ensureVisible(find.text('Stai aici').at(3));
      await tester.tap(find.text('Stai aici').at(3));
      await tester.pumpAndSettle();
      expect(SchoolClass.fromSnap(await Classes.classes.doc(code).get()).seats['s1'], 3);
      expect(find.text('Tu'), findsOneWidget);
      expect(find.text('Stai aici'), findsNothing);
    });

    testWidgets('the owner sees the link, members and progress', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Mate');
      await Classes.join(code, 's1', 'Mihai Ionescu');
      await Classes.join(code, 's2', 'Ioana Radu');
      final cls = SchoolClass.fromSnap(await Classes.classes.doc(code).get());
      final id = await Classes.assign(
        teacherId: 't1',
        teacherName: 'Ana Pop',
        title: 'Ecuații',
        toClasses: [cls],
        problems: const [HwProblem(id: '1', title: 'Suma a două numere', subject: 'Informatică', grade: '9')],
      );
      await Classes.setDone(id, 's2', true);
      await db.collection('users').doc('s2').update({'solvedIds': ['Informatică_9_1']});
      await Classes.saveSolution(uid: 's2', key: 'Informatică_9_1', text: 'int main() { return 1; }', lang: 'cpp', passed: true);
      await Classes.saveSolution(uid: 's2', key: 'Informatică_9_1', text: 'int main() { return 2; }', lang: 'cpp', passed: false);
      await open(tester, ClassBody(uid: 't1', code: code));
      expect(find.text('Mihai'), findsOneWidget); // sitting in a bench
      expect(find.text('Ioana'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget); // the paper on Ioana's desk
      expect(find.text('0/1'), findsOneWidget); // and on Mihai's

      // The catedra: the notebook of exercises given, nothing else.
      await tester.tap(find.text('CATEDRA'));
      await tester.pumpAndSettle();
      expect(find.text('Exerciții'), findsOneWidget);
      expect(find.text('1 exercițiu'), findsOneWidget);
      expect(find.text('Deschide'), findsOneWidget);
      expect(find.text('Linkul clasei'), findsNothing);

      // Ioana's desk: her notebook, the exercise crossed off.
      await tester.tap(find.text('Înapoi în clasă'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel('Banca lui Ioana Radu'));
      await tester.tap(find.bySemanticsLabel('Banca lui Ioana Radu'));
      await tester.pumpAndSettle();
      expect(find.text('Exerciții'), findsOneWidget);
      expect(find.text('1 din 1 rezolvate'), findsOneWidget);
      expect(find.text('Rezolvată'), findsOneWidget);

      // What she sent: the version that passed, and the later one that doesn't.
      await tester.tap(find.text('Vezi soluția'));
      await tester.pumpAndSettle();
      expect(find.textContaining('A trecut toate testele'), findsOneWidget);
      expect(find.textContaining('Ultima încercare, nu trece'), findsOneWidget);
      expect(find.textContaining('return 1;'), findsOneWidget);
      expect(find.textContaining('return 2;'), findsOneWidget);
      await tester.tap(find.text('Închide'));
      await tester.pumpAndSettle();
    });

    testWidgets('the dock: shows homework, hides it, brings it back, done makes it go away', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Mate');
      await Classes.join(code, 's1', 'Mihai Ionescu');
      final cls = SchoolClass.fromSnap(await Classes.classes.doc(code).get());
      final id = await Classes.assign(
        teacherId: 't1',
        teacherName: 'Ana Pop',
        title: 'Ecuații de gradul II',
        toClasses: [cls],
        dueAt: DateTime.now().add(const Duration(days: 1)),
      );

      final user = StreamController<String?>.broadcast();
      addTearDown(user.close);
      await open(tester, const Center(child: Text('ORICE PAGINĂ')), dockUser: user);
      user.add('s1');
      await tester.pumpAndSettle();

      expect(find.textContaining('1 temă'), findsOneWidget);
      await tester.tap(find.textContaining('1 temă'));
      await tester.pumpAndSettle();
      expect(find.text('Ecuații de gradul II'), findsOneWidget);

      // Hide it: the dock shrinks to a round button but doesn't disappear.
      await tester.tap(find.bySemanticsLabel('Ascunde'));
      await tester.pumpAndSettle();
      expect(Homework.fromSnap(await Classes.homework.doc(id).get()).isHidden('s1'), isTrue);
      expect(find.text('1 temă ascunsă'), findsOneWidget);
      await tester.tap(find.text('Arată-le'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arată în bară'));
      await tester.pumpAndSettle();
      expect(Homework.fromSnap(await Classes.homework.doc(id).get()).isHidden('s1'), isFalse);

      // Open the details and finish it.
      await tester.tap(find.text('Ecuații de gradul II'));
      await tester.pumpAndSettle();
      expect(find.text('Am terminat'), findsOneWidget);
      await tester.tap(find.text('Am terminat'));
      await tester.pumpAndSettle();
      expect(Homework.fromSnap(await Classes.homework.doc(id).get()).isDone('s1'), isTrue);
      await tester.tap(find.text('Închide'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.assignment_outlined), findsNothing);

      // Teachers never get a dock.
      user.add('t1');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.assignment_outlined), findsNothing);
    });

    testWidgets('the teacher gives homework from the composer', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Mate');
      await Classes.join(code, 's1', 'Mihai Ionescu');
      await Classes.join(code, 's2', 'Ioana Radu');
      await open(tester, ClassroomView(uid: 't1', teacher: true));

      // From the board: the class is already picked.
      await tester.tap(find.text('Temă nouă'));
      await tester.pumpAndSettle();
      expect(find.text('Trimite la 2 elevi'), findsOneWidget);
      await tester.tap(find.text('9B Mate').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trimite tema'));
      await tester.pumpAndSettle();
      expect(find.text('Alege cel puțin o clasă sau un elev.'), findsOneWidget);

      await tester.tap(find.text('9B Mate').last);
      await tester.pumpAndSettle();
      expect(find.text('Trimite la 2 elevi'), findsOneWidget);
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '').startsWith('Titlu')), 'Ecuații');
      await tester.tap(find.text('Mâine'));
      await tester.tap(find.text('Probleme din bancă'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Informatică').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suma a două numere'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adaugă o problemă'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trimite la 2 elevi'));
      await tester.pumpAndSettle();

      final hw = (await Classes.homework.get()).docs.map(Homework.fromSnap).single;
      expect(hw.title, 'Ecuații');
      expect(hw.classIds, [code]);
      expect(hw.dueAt, isNotNull);
      expect(hw.problems.single.title, 'Suma a două numere');
      await tester.tap(find.text('CATEDRA'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Suma a două numere'), findsOneWidget); // in the catedra's notebook
    });

    testWidgets('the desk of a student: a notebook of exercises, solved ones crossed off', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: '9B Info', subject: 'Informatică');
      await Classes.join(code, 's1', 'Mihai Ionescu');
      await db.collection('users').doc('s1').update({'solvedIds': ['Informatică_9_1']});
      final cls = SchoolClass.fromSnap(await Classes.classes.doc(code).get());
      await Classes.assign(
        teacherId: 't1',
        teacherName: 'Ana Pop',
        title: 'Sume și produse',
        toClasses: [cls],
        problems: const [
          HwProblem(id: '1', title: 'Suma a două numere', subject: 'Informatică', grade: '9'),
          HwProblem(id: '2', title: 'Produsul cifrelor', subject: 'Informatică', grade: '9'),
        ],
        dueAt: DateTime.now().add(const Duration(days: 3)),
      );
      await Classes.takeSeat(code, 's1', 0);
      await open(tester, ClassroomView(uid: 's1', teacher: false));
      await tester.ensureVisible(find.bySemanticsLabel('Banca ta'));
      await tester.tap(find.bySemanticsLabel('Banca ta'));
      await tester.pumpAndSettle();

      expect(find.text('Exerciții'), findsOneWidget);
      expect(find.text('1 din 2 rezolvate'), findsOneWidget);
      expect(find.text('Rezolvată'), findsOneWidget); // Suma, crossed off
      expect(find.text('Rezolvă'), findsOneWidget); // Produsul
      expect(find.text('Am terminat'), findsNothing); // just the exercises

      await tester.tap(find.text('Rezolvă'));
      await tester.pumpAndSettle();
      expect(find.text('PAGINA EXERCITIU 2'), findsOneWidget);
    });

    testWidgets('student page and phone layouts build without overflow', (tester) async {
      final code = await Classes.create(teacherId: 't1', teacherName: 'Ana Pop', name: 'Andrei, pregătire BAC', subject: 'Informatică');
      await Classes.join(code, 's1', 'Mihai Ionescu');
      final cls = SchoolClass.fromSnap(await Classes.classes.doc(code).get());
      await Classes.assign(
        teacherId: 't1',
        teacherName: 'Ana Pop',
        title: 'O temă cu un titlu destul de lung ca să nu încapă pe un rând',
        instructions: 'Rezolvă problemele de mai jos.',
        toClasses: [cls],
        problems: const [HwProblem(id: '1', title: 'Suma a două numere', subject: 'Informatică', grade: '9')],
        dueAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      await Classes.takeSeat(code, 's1', 1);
      for (final size in const [Size(1280, 860), Size(380, 800)]) {
        await open(tester, ClassroomView(uid: 's1', teacher: false), size: size);
        await tester.ensureVisible(find.bySemanticsLabel('Banca ta'));
        await tester.tap(find.bySemanticsLabel('Banca ta'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Suma a două numere'), findsOneWidget);
        await open(tester, ClassroomView(uid: 't1', teacher: true), size: size);
        expect(find.text('Andrei, pregătire BAC'), findsWidgets);
        await open(tester, ClassBody(uid: 't1', code: code), size: size);
        await tester.ensureVisible(find.text('CATEDRA'));
        await tester.tap(find.text('CATEDRA'));
        await tester.pumpAndSettle();
        expect(find.text('Exerciții'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
