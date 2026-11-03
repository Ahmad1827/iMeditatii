// Looking a problem up in the IDE, by number or by name, and the statement it shows.
import 'details_io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/ide_statement.dart';
import 'package:iMeditatii/problem_statement.dart';

void main() {
  final all = ProblemIndex.fromDetails(readAllDetails());

  test('a number finds that problem first, in Informatică before Matematică', () {
    final r = ProblemIndex.search(all, '12');
    expect(r[0].id, '12');
    expect(r[0].subject, 'Informatică');
    expect(r[1].id, '12');
    expect(r[1].subject, 'Matematică');
    expect(ProblemIndex.search(all, '#12').first.key, r[0].key);
  });

  test('words find a name, with or without diacritics', () {
    expect(ProblemIndex.search(all, 'suma a doua').first.title, 'Suma a două numere');
    expect(ProblemIndex.search(all, 'SUMA numere').first.title, 'Suma a două numere');
    expect(ProblemIndex.search(all, 'zzzzqq'), isEmpty);
    expect(ProblemIndex.search(all, '   '), isEmpty);
  });

  test('every problem can be found again by the key that is saved', () {
    expect({for (final p in all) p.key}.length, all.length);
    for (final p in all.take(20)) {
      expect(p.path, startsWith('/exercitiu/${p.id}?materie='));
    }
  });

  testWidgets('the statement shows the task and the example, never the solution', (t) async {
    final p = all.first;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ProblemStatement(problem: p.data)))));
    expect(find.text('CERINȚA'), findsOneWidget);
    expect(find.text('Exemplu'), findsOneWidget);
    final code = (p.data['official_solution'] as Map)['code'] as String;
    expect(find.textContaining(code), findsNothing);
  });
}
