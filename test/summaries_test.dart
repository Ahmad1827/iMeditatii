import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/problem_thumb.dart';

/// assets/data/summaries.json is made by tool/summaries.py from the details: a
/// problem added or changed without running it shows in the list with no line.
void main() {
  final list = jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, dynamic>;
  final about = jsonDecode(File('assets/data/summaries.json').readAsStringSync()) as Map<String, dynamic>;

  test('every listed problem has its line in summaries.json (run tool/summaries.py)', () {
    list.forEach((subject, grades) {
      (grades as Map<String, dynamic>).forEach((grade, chapters) {
        (chapters as Map<String, dynamic>).forEach((chapter, items) {
          for (final item in items as List) {
            final s = about[subject]?[grade]?['${item['id']}'];
            expect(s, isNotNull, reason: '$subject $grade ${item['id']}');
            final text = '${s['s']}';
            expect(text.trim(), isNotEmpty, reason: '$subject $grade ${item['id']}');
            expect(text.contains(r'\'), false, reason: 'TeX left in $subject $grade ${item['id']}: $text');
            if (subject.startsWith('Mat')) expect(s['e'], isNull, reason: 'maths shows no example (it is the answer)');
          }
        });
      });
    });
  });

  test('every chapter has a picture of its own kind', () {
    list.forEach((subject, grades) {
      (grades as Map<String, dynamic>).forEach((grade, chapters) {
        for (final chapter in (chapters as Map<String, dynamic>).keys) {
          expect(thumbKindOf(chapter), isNot(ThumbKind.other), reason: '$subject $grade: $chapter');
        }
      });
    });
  });
}
