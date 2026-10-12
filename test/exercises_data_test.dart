import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/exercise_detail_screen.dart';

void main() {
  final list = jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, dynamic>;
  final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;

  test('short answers accept the usual ways of writing a number', () {
    bool ok(String given, String expected) => ExerciseDetailScreen.answersMatch(given, expected);
    expect(ok('39', '39'), true);
    expect(ok(' 39 ', '39'), true);
    expect(ok('39,0', '39'), true);
    expect(ok('−12', '-12'), true); // typographic minus
    expect(ok('- 12', '-12'), true);
    expect(ok('1/2', '0.5'), true);
    expect(ok('0,5', '1/2'), true);
    expect(ok('10/4', '5/2'), true);
    expect(ok('40', '39'), false);
    expect(ok('', '0'), false);
    expect(ok('1/0', '1'), false);
    expect(ok('abc', 'ABC'), true); // non-numeric answers still compare as text
    expect(ok('abd', 'abc'), false);
  });

  test('every listed problem has details, and every subject offered has problems', () {
    for (final subject in ['Informatică', 'Matematică']) {
      expect(list[subject], isNotNull, reason: subject);
      var count = 0;
      (list[subject] as Map<String, dynamic>).forEach((grade, chapters) {
        (chapters as Map<String, dynamic>).forEach((chapter, items) {
          for (final item in items as List) {
            count++;
            final d = details[subject]?[grade]?[item['id']];
            expect(d, isNotNull, reason: '$subject $grade ${item['id']}');
            expect(d['title'], item['title']);
            expect(d['category'], chapter);
            expect('${d['description']}'.trim(), isNotEmpty);
          }
        });
      });
      expect(count, greaterThanOrEqualTo(40), reason: subject);
    }
  });

  test('maths problems can be answered', () {
    final ids = <String>{};
    (details['Matematică'] as Map<String, dynamic>).forEach((grade, problems) {
      (problems as Map<String, dynamic>).forEach((id, p) {
        expect(ids.add(id), true, reason: 'duplicate id $id');
        final answer = '${p['raspuns_corect']}';
        expect(answer, isNotEmpty, reason: id);
        expect('${p['solutie']}'.trim(), isNotEmpty, reason: id);
        if (p['tip_exercitiu'] == 'grila') {
          final options = (p['variante'] as List).cast<String>();
          expect(options.length, 4, reason: id);
          expect(options.toSet().length, 4, reason: id);
          expect(options.where((o) => o == answer).length, 1, reason: id);
        } else {
          expect(p['tip_exercitiu'], 'text', reason: id);
          expect(ExerciseDetailScreen.answersMatch(answer, answer), true, reason: id);
          expect(double.tryParse(answer), isNotNull, reason: '$id: short answers are numbers');
        }
      });
    });
    expect(ids.length, 61);
  });
}
