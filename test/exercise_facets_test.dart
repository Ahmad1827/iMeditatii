import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/exercise_facets.dart';

void main() {
  test('the year and kind of a paper are read from its source', () {
    expect(ExFacets.year('BAC 2026 · Sesiunea august · Subiectul III.1'), 2026);
    expect(ExFacets.type('BAC 2026 · Sesiunea august · Subiectul III.1', ''), 'August');
    expect(ExFacets.type('BAC 2026 · Simulare clasa a XII-a · Subiectul III.2', ''), 'Simulare');
    expect(ExFacets.type('BAC 2025 · Sesiunea iunie–iulie (rezervă) · Subiectul III.1', ''), 'Rezervă');
    expect(ExFacets.type('BAC 2025 · Sesiunea iunie–iulie · Subiectul III.1', ''), 'Iunie–iulie');
    expect(ExFacets.type('BAC 2020 · Test de antrenament 3 · Subiectul III.1', ''), 'Test de antrenament');
    expect(ExFacets.type('Exercițiu de antrenament (nu e dintr-o variantă BAC)', ''), 'Antrenament');
    expect(ExFacets.year('Exercițiu de antrenament (nu e dintr-o variantă BAC)'), isNull);
    expect(ExFacets.type('AcadNet 2024 · Etapa județeană · clasele 9–12', ''), 'Etapa județeană');
    expect(ExFacets.classes('AcadNet 2024 · Etapa județeană · clasele 9–12'), '9–12');
    expect(ExFacets.type('', '11. Olimpiadă'), 'Olimpiadă');
    expect(ExFacets.type('', '3. Recursivitate'), 'Exercițiu');
    expect(ExFacets.type('UVa Online Judge 100 · The 3n + 1 problem', ''), 'Problemă clasică');
    expect(ExFacets.year('W. Ackermann (1928), în forma dată de R. Péter (1935)'), isNull);
  });

  test('every word must be found; a letter wrong is forgiven; the title ranks first', () {
    int s(String q, {String title = 'Suma cifrelor pare', String st = 'Se citește un număr natural n.', String sursa = ''}) =>
        ExSearch(q).score(id: '61', title: title, statement: st, sursa: sursa, category: '3. Prelucrarea cifrelor', difficulty: 'ușoară');
    expect(s('cifre'), greaterThan(0));
    expect(s('cifrelor citeste'), greaterThan(0));
    expect(s('cifrelor matrice'), 0);
    expect(s('cifrleor'), greaterThan(0), reason: 'one letter swapped');
    expect(s('numar'), greaterThan(0), reason: 'diacritics folded');
    expect(s('usoara'), greaterThan(0));
    expect(s('#61'), greaterThan(0));
    expect(s('#62'), 0);
    expect(s('2024 iunie', sursa: 'BAC 2024 · Sesiunea iunie–iulie'), greaterThan(0));
    expect(s('suma'), greaterThan(s('natural')), reason: 'title above statement');
    expect(ExSearch('ab').score(id: '1', title: 'xy'), 0, reason: 'short words are not fuzzy');
  });

  test('marks fall on the words, merged and in order', () {
    expect(ExSearch('cifre suma').marks('Suma cifrelor'), [(0, 4), (5, 10)]);
    expect(ExSearch('ăș').marks('Țară'), isEmpty);
    expect(ExSearch('tara').marks('Țară'), [(0, 4)]);
    expect(ExSearch('fibonaci').marks('Șirul lui Fibonacci'), [(10, 19)], reason: 'a typo still marks the word');
  });

  test('clasa a XII-a informatică has years and kinds to choose from', () {
    final data = jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, dynamic>;
    final items = [for (final l in (data['Informatică']['12'] as Map).values) ...(l as List)];
    final years = items.map((e) => ExFacets.year('${e['sursa'] ?? ''}')).whereType<int>().toSet();
    final kinds = items.map((e) => ExFacets.type('${e['sursa'] ?? ''}', '')).toSet();
    expect(years.length, greaterThan(3));
    expect(years, contains(2026));
    expect(kinds, containsAll(['Model', 'Simulare', 'August', 'Antrenament']));
    for (final t in kinds) {
      expect(ExFacets.typeOrder, contains(t));
    }
  });
}
