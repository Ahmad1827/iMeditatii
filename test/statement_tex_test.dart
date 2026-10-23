// Every formula in every problem is TeX the app can typeset.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_math_fork/tex.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/statement.dart';

void main() {
  test('every formula in the problems parses', () {
    final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
    final bad = <String>[];
    var n = 0;
    void check(String where, String text) {
      for (final b in Markup.blocks(text)) {
        final formulas = b.kind == BlockKind.math
            ? [b.text]
            : [for (final item in b.items) for (final s in Markup.spans(item)) if (s.kind == SpanKind.tex) s.text];
        for (final f in formulas) {
          n++;
          try {
            TexParser(f, const TexParserSettings()).parse();
          } catch (e) {
            bad.add('$where: $f\n    $e');
          }
        }
      }
    }

    for (final subject in details.entries) {
      for (final grade in (subject.value as Map<String, dynamic>).entries) {
        for (final e in (grade.value as Map<String, dynamic>).entries) {
          final p = e.value as Map<String, dynamic>;
          for (final f in ['context', 'cerinta', 'explicatie', 'hint', 'solutie', 'raspuns_corect', 'input', 'output', 'nota_examen']) {
            if (p[f] is String) check('${subject.key} ${grade.key} #${e.key} $f', p[f] as String);
          }
          for (final f in ['variante', 'constraints']) {
            if (p[f] is List) for (final v in p[f] as List) check('${subject.key} ${grade.key} #${e.key} $f', '$v');
          }
        }
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
    expect(n, greaterThan(0));
  });
}
