// A statement in sections: the text as written, only placed better.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/statement.dart';

void main() {
  test('the olympiad line becomes the source, the example paragraph goes to the example', () {
    final p = StatementParts.parse(
      'Olimpiada de Informatică, etapa județeană (OJI) 2024, clasa a IX-a. Ca la olimpiadă, datele se citesc din fișierul macarie.in, iar rezultatul se scrie în fișierul macarie.out.\n\n'
      'Macarie a primit o temă.\n\nExemplu: pentru A = (32, 42) ...',
      file: 'macarie',
    );
    expect(p.source, 'Olimpiada de Informatică, etapa județeană (OJI) 2024, clasa a IX-a.'); // the file sentence: in its own box
    expect(p.body, ['Macarie a primit o temă.']);
    expect(p.examples, ['Exemplu: pentru A = (32, 42) ...']);
  });

  test('a plain statement is all task', () {
    final p = StatementParts.parse('Se dau două numere întregi. Să se calculeze suma lor.');
    expect(p.source, '');
    expect(p.body, ['Se dau două numere întregi. Să se calculeze suma lor.']);
    expect(p.examples, isEmpty);
  });

  test('function headers and rows of numbers go in monospace, prose stays prose', () {
    expect(StatementParts.isCodeLine('int impare(int n)'), isTrue);
    expect(StatementParts.isCodeLine('void dublare(int &n)'), isTrue);
    expect(StatementParts.isCodeLine('int medie(int v[], int n)'), isTrue);
    expect(StatementParts.isCodeLine('1 3 -10 2 1'), isTrue);
    expect(StatementParts.isCodeLine('Scrie definiția completă a subprogramului:'), isFalse);
    expect(StatementParts.isCodeLine('1. Indicii liniilor lui T cu suma elementelor maximă.'), isFalse);
    expect(StatementParts.isCodeLine('-10⁹ ≤ a, b ≤ 10⁹'), isFalse);
    expect(StatementParts.runs('Exemplu: pentru matricea\n1 2\n3 4\ncâștigul este 42.'), [
      (false, 'Exemplu: pentru matricea'),
      (true, '1 2\n3 4'),
      (false, 'câștigul este 42.'),
    ]);
  });

  test('no text is lost: every paragraph of every problem lands somewhere', () {
    final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
    for (final subject in details.values) {
      for (final grade in (subject as Map<String, dynamic>).values) {
        for (final e in (grade as Map<String, dynamic>).values) {
          final d = '${e['description']}';
          final p = StatementParts.parse(d);
          final words = (String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
          expect(words([p.source, ...p.body, ...p.examples].join(' ')).length, words(d).length, reason: '${e['title']}');
          expect(p.body, isNotEmpty, reason: '${e['title']}');
        }
      }
    }
  });
}
