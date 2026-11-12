import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/statement_sheet.dart';

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.view(File('assets/fonts/$f').readAsBytesSync().buffer)));
  }
  await loader.load();
}

void main() {
  test('the sheet says the whole statement, in the order of a paper', () {
    final t = SheetText.of({
      'title': 'Suma cifrelor',
      'cerinta': 'Se dă un număr natural `n`. Calculați suma cifrelor lui.',
      'context': 'Ana adună cifre.',
      'date_intrare': 'Programul citește numărul `n`.',
      'date_iesire': 'Programul afișează suma.',
      'restrictii': ['`1 ≤ n ≤ 10^9`'],
      'exemple': [
        {'input': '123', 'output': '6'}
      ],
      'explicatie': '`1 + 2 + 3 = 6`',
      'hint': 'nu apare pe foaie',
    });
    expect(t.title, 'Suma cifrelor');
    expect(t.paragraphs, ['Ana adună cifre.', 'Se dă un număr natural `n`. Calculați suma cifrelor lui.']);
    expect(t.input, 'Programul citește numărul `n`.');
    expect(t.output, 'Programul afișează suma.');
    expect(t.limits, ['`1 ≤ n ≤ 10^9`']);
    expect(t.examples, [
      {'input': '123', 'output': '6'}
    ]);
    expect(t.explained, ['`1 + 2 + 3 = 6`']);
    expect(t.options, isEmpty);
  });

  test('a multiple-choice problem keeps its options, a problem with files its name', () {
    final t = SheetText.of({'cerinta': r'Cât face $2+2$?', 'tip_exercitiu': 'grila', 'variante': ['3', '4'], 'fisier': 'suma'});
    expect(t.options, ['3', '4']);
    expect(t.file, 'suma');
  });

  testWidgets('every problem without a picture of its paper draws as a sheet', (tester) async {
    await loadFont('Arimo', ['Arimo-Regular.ttf', 'Arimo-Bold.ttf']);
    await loadFont('Cousine', ['Cousine-Bold.ttf']);
    tester.view.physicalSize = const Size(860, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final shot = Platform.environment['SHEET_SHOT'];
    var drawn = 0;
    for (final f in ['informatica_9', 'informatica_10', 'informatica_11', 'matematica_9', 'matematica_12']) {
      final all = [
        for (final e in (jsonDecode(File('assets/data/details/$f.json').readAsStringSync()) as Map).entries) {...e.value as Map, 'id': e.key},
      ];
      // each kind the files have: the first few and some from the middle
      for (final p in [...all.take(4), ...all.skip(all.length ~/ 2).take(3)]) {
        if (p['imagine_originala'] != null) continue;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: RepaintBoundary(key: const Key('sheet'), child: StatementSheet(SheetText.of(p))))),
        ));
        expect(tester.takeException(), isNull, reason: '$f ${p['id']}');
        expect(SheetText.of(p).isEmpty, isFalse, reason: '$f ${p['id']}');
        if (shot != null && drawn < 6 && (drawn.isEven)) {
          await expectLater(find.byKey(const Key('sheet')), matchesGoldenFile('$shot/sheet_${f}_${p['id']}.png'));
        }
        drawn++;
      }
    }
    expect(drawn, greaterThan(20));
  });
}
