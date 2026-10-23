// A statement in sections: the text as written, only placed better.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/statement.dart';

void main() {
  markupTests();
  pictureTests();
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

void markupTests() {
  test('a problem with its own sections keeps them; an old one is sorted from description', () {
    final p = StatementParts.of({'context': 'Un număr e ascendent dacă ...', 'cerinta': 'Scrie subprogramul.\n\nAl doilea paragraf.', 'description': 'ignored'});
    expect(p.context, ['Un număr e ascendent dacă ...']);
    expect(p.body, ['Scrie subprogramul.', 'Al doilea paragraf.']);
    expect(StatementParts.of({'description': 'Se dă n.'}).body, ['Se dă n.']);
  });

  test('blocks: prose, bullets, lettered parts, formulas and boxes', () {
    expect(Markup.blocks('Se dă:\n• n, un număr;\n• x și y.\nApoi'), [
      const StatementBlock(BlockKind.prose, ['Se dă:']),
      const StatementBlock(BlockKind.bullets, ['n, un număr;', 'x și y.']),
      const StatementBlock(BlockKind.prose, ['Apoi']),
    ]);
    expect(Markup.blocks('a) Calculează \$f(1)\$.\nb) Arată că\n  f e crescătoare.'),
        [const StatementBlock(BlockKind.parts, [r'Calculează $f(1)$.', 'Arată că f e crescătoare.'], labels: ['a)', 'b)'])]);
    expect(Markup.blocks('Fie\n\$\$A=1\$\$\nși'), [
      const StatementBlock(BlockKind.prose, ['Fie']),
      const StatementBlock(BlockKind.math, ['A=1']),
      const StatementBlock(BlockKind.prose, ['și']),
    ]);
    expect(Markup.blocks('Calculează \$\$A = 1.\$\$ Apoi \$B\$.'), [
      const StatementBlock(BlockKind.prose, ['Calculează']),
      const StatementBlock(BlockKind.math, ['A = 1.']),
      const StatementBlock(BlockKind.prose, ['Apoi \$B\$.']),
    ]);
    expect(Markup.blocks('```\nab\ncd\n```'), [const StatementBlock(BlockKind.code, ['ab\ncd'])]);
    expect(Markup.blocks('Scrie:\nint f(int n)'), [
      const StatementBlock(BlockKind.prose, ['Scrie:']),
      const StatementBlock(BlockKind.code, ['int f(int n)']),
    ]);
  });

  test('spans: code, formulas, bold; an open marker and an escaped dollar stay text', () {
    expect(Markup.spans(r'Fie `n` și $x^2$, **cel mult** 5'), [
      const StatementSpan(SpanKind.text, 'Fie '),
      const StatementSpan(SpanKind.code, 'n'),
      const StatementSpan(SpanKind.text, ' și '),
      const StatementSpan(SpanKind.tex, 'x^2'),
      const StatementSpan(SpanKind.text, ', '),
      const StatementSpan(SpanKind.bold, 'cel mult'),
      const StatementSpan(SpanKind.text, ' 5'),
    ]);
    expect(Markup.spans(r'costă 5\$ și $ rămâne'), [const StatementSpan(SpanKind.text, r'costă 5$ și $ rămâne')]);
    expect(Markup.plain(r'**Scrie** `f` cu $x^2$'), 'Scrie f cu x^2');
  });

  test('every statement field of every problem has its markup closed', () {
    final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
    for (final subject in details.values) {
      for (final grade in (subject as Map<String, dynamic>).values) {
        for (final e in (grade as Map<String, dynamic>).values) {
          for (final f in ['context', 'cerinta', 'input', 'output', 'explicatie', 'hint', 'solutie']) {
            final t = (e[f] ?? '').toString().replaceAll(r'\$', '');
            expect(RegExp(r'\$').allMatches(t).length.isEven, isTrue, reason: '${e['title']}: $f has an open \$');
            expect(RegExp('`').allMatches(t).length.isEven, isTrue, reason: '${e['title']}: $f has an open `');
          }
        }
      }
    }
  });
}

void pictureTests() {
  test('every original picture a problem links to comes with the app', () {
    final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
    var n = 0;
    for (final subject in details.values) {
      for (final grade in (subject as Map<String, dynamic>).values) {
        for (final e in (grade as Map<String, dynamic>).values) {
          final p = e['imagine_originala'];
          if (p == null) continue;
          n++;
          expect(File('$p').existsSync(), isTrue, reason: '${e['title']}: $p');
          expect('${e['sursa']}', startsWith('BAC'), reason: '${e['title']}');
        }
      }
    }
    expect(n, greaterThan(0));
  });
}
