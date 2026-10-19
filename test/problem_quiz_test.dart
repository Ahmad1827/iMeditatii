// Questions before a problem: a few multiple-choice questions that lead into
// it, each explained once answered; "Sari peste" goes straight to the problem.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/problem_quiz.dart';
import 'package:iMeditatii/theme_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeManager.themeNotifier.value = ThemeMode.light;
    ThemeManager.styleNotifier.value = AppStyleMode.clean;
  });

  test('every problem in the app has its questions, each with one right answer', () {
    final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
    final bank = jsonDecode(File('assets/data/problem_quizzes.json').readAsStringSync()) as Map<String, dynamic>;
    var problems = 0;
    for (final subject in details.keys) {
      for (final grade in (details[subject] as Map<String, dynamic>).keys) {
        for (final id in (details[subject][grade] as Map<String, dynamic>).keys) {
          problems++;
          final raw = bank[subject]?[grade]?[id] as List?;
          final where = '$subject $grade/$id';
          expect(raw, isNotNull, reason: where);
          final qs = ProblemQuiz.parse(raw);
          expect(qs.length, raw!.length, reason: '$where: a question that does not parse');
          expect(qs.length, inInclusiveRange(2, 5), reason: where);
          for (final q in qs) {
            expect(q.options.toSet().length, q.options.length, reason: '$where: the same option twice');
            expect(q.explanation, isNotEmpty, reason: where);
          }
        }
      }
    }
    expect(problems, 384);
    // and nothing for a problem that doesn't exist
    for (final subject in bank.keys) {
      for (final grade in (bank[subject] as Map<String, dynamic>).keys) {
        for (final id in (bank[subject][grade] as Map<String, dynamic>).keys) {
          expect(details[subject]?[grade]?[id], isNotNull, reason: '$subject $grade/$id');
        }
      }
    }
  });

  test('a problem added by a teacher brings its own questions', () async {
    final own = await ProblemQuiz.load('Informatică', '9', 'abc', problem: {
      'intrebari': [
        {'q': 'Cât face 2 + 2?', 'o': ['3', '4'], 'a': 1, 'e': 'Doi plus doi.'},
        {'q': 'fără variante', 'o': [], 'a': 0},
      ],
    });
    expect(own.map((q) => q.question), ['Cât face 2 + 2?']); // the broken one is left out
    expect(await ProblemQuiz.load('Informatică', '9', 'abc', problem: {}), isEmpty);
    expect((await ProblemQuiz.load('Informatică', '9', '1')).length, 3);
  });

  test('what does not make a question', () {
    expect(QuizQuestion.fromJson({'q': 'x', 'o': ['a', 'b'], 'a': 2}), isNull); // the answer isn't an option
    expect(QuizQuestion.fromJson({'q': '', 'o': ['a', 'b'], 'a': 0}), isNull);
    expect(QuizQuestion.fromJson({'q': 'x', 'o': ['a', ''], 'a': 0}), isNull);
    expect(QuizQuestion.fromJson('x'), isNull);
    final q = QuizQuestion.fromJson({'q': 'x', 'o': ['a', 'b'], 'a': '1'})!;
    expect(q.toJson(), {'q': 'x', 'o': ['a', 'b'], 'a': 1});
  });

  const qs = [
    QuizQuestion('Ce structură folosești?', ['Coada', 'Stiva', 'Setul'], 1, 'Ultima deschisă se închide prima.'),
    QuizQuestion('Ce răspuns dă ([)]?', ['1', '0'], 1, 'La ) vârful este [.'),
  ];

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(onPressed: () => showProblemQuiz(context, qs, random: Random(1)), child: const Text('deschide')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('deschide'));
    await tester.pumpAndSettle();
  }

  testWidgets('answering: the right one and why, then on to the next, then to the problem', (tester) async {
    await open(tester);
    expect(find.text('Ce structură folosești?'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    // nothing to continue to before answering
    await tester.tap(find.text('Continuă'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Ce structură folosești?'), findsOneWidget);

    await tester.tap(find.text('Coada'));
    await tester.pumpAndSettle();
    expect(find.text('Nu chiar.'), findsOneWidget);
    expect(find.text('Ultima deschisă se închide prima.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // the right one is shown
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    // one answer per question
    await tester.tap(find.text('Setul'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    await tester.tap(find.text('Continuă'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    expect(find.text('Corect!'), findsOneWidget);
    expect(find.text('1 din 2 corecte'), findsOneWidget);

    await tester.tap(find.text('La problemă'));
    await tester.pumpAndSettle();
    expect(find.text('Ce răspuns dă ([)]?'), findsNothing);
  });

  testWidgets('Sari peste goes straight to the problem', (tester) async {
    await open(tester);
    await tester.tap(find.text('Sari peste'));
    await tester.pumpAndSettle();
    expect(find.text('Ce structură folosești?'), findsNothing);
    expect(find.text('deschide'), findsOneWidget);
  });

  testWidgets('fits a phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showProblemQuiz(context, qs, random: Random(1)), child: const Text('deschide')),
        ),
      ),
    ));
    await tester.tap(find.text('deschide'));
    await tester.pumpAndSettle();
    for (final pick in ['Stiva', 'Continuă', '0']) {
      await tester.tap(find.text(pick));
      await tester.pumpAndSettle();
    }
    expect(find.text('1 din 2 corecte'), findsNothing);
    expect(find.text('2 din 2 corecte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in the retro style too', (tester) async {
    ThemeManager.styleNotifier.value = AppStyleMode.retro;
    await open(tester);
    expect(find.text('ÎNAINTE SĂ ÎNCEPI'), findsOneWidget);
    await tester.tap(find.text('Stiva'));
    await tester.pumpAndSettle();
    expect(find.text('Corect!'), findsOneWidget);
  });
}
