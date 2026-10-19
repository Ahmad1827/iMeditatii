import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/bac_progress.dart';

void main() {
  final list = jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, dynamic>;

  test('the BAC chapters are every chapter of IX–XII but the olympiad and the extra practice', () {
    for (final subject in Bac.subjects) {
      final topics = Bac.topics(list, subject);
      expect(topics, isNotEmpty);
      expect(topics.map((t) => t.grade).toSet(), {'9', '10', '11', '12'});
      for (final t in topics) {
        expect(t.chapter.toLowerCase(), isNot(contains('olimpiad')));
        expect(t.chapter.toLowerCase(), isNot(contains('suplimentar')));
        expect(t.ids, isNotEmpty);
      }
    }
    final info = Bac.topics(list, 'Informatică');
    expect(info.first.grade, '9'); // in grade order, not "10" before "9"
    expect(info.first.name, 'Structuri secvențiale');
    expect(info.where((t) => t.grade == '12').map((t) => t.name), [
      'Subiectul III.1 · Subprograme',
      'Subiectul III.2 · Șiruri și matrice',
      'Subiectul III.3 · Fișiere și algoritmi eficienți',
    ]);
  });

  test('a chapter is covered after 3 solved problems, or all of them when it has fewer', () {
    const t = BacTopic(subject: 'Matematică', grade: '11', chapter: '1. Matrice', ids: ['1', '2', '3', '4']);
    expect(t.status({}), BacStatus.notStarted);
    expect(t.status({'Matematică_11_1', 'Informatică_11_2'}), BacStatus.started);
    expect(t.status({'Matematică_11_1', 'Matematică_11_2', 'Matematică_11_4'}), BacStatus.covered);
    expect(t.status({'Matematică_10_1', 'Matematică_10_2', 'Matematică_10_3'}), BacStatus.notStarted);

    const small = BacTopic(subject: 'Matematică', grade: '11', chapter: '2. Sisteme', ids: ['7', '8']);
    expect(small.status({'Matematică_11_7', 'Matematică_11_8'}), BacStatus.covered);
  });

  test('next is the chapter already started, else the first not started', () {
    const a = BacTopic(subject: 'Informatică', grade: '9', chapter: '1. A', ids: ['1', '2', '3']);
    const b = BacTopic(subject: 'Informatică', grade: '9', chapter: '2. B', ids: ['4', '5', '6']);
    const c = BacTopic(subject: 'Informatică', grade: '10', chapter: '1. C', ids: ['7', '8', '9']);
    expect(Bac.next([a, b, c], {}), a);
    expect(Bac.next([a, b, c], {'Informatică_10_7'}), c);
    expect(Bac.next([a, b, c], {'Informatică_9_1', 'Informatică_9_2', 'Informatică_9_3'}), b);
    expect(Bac.next([a], {'Informatică_9_1', 'Informatică_9_2', 'Informatică_9_3'}), isNull);
  });

  test('a chapter links to its problems', () {
    const t = BacTopic(subject: 'Informatică', grade: '10', chapter: '3. Recursivitate', ids: ['1']);
    final uri = Uri.parse(t.path);
    expect(uri.path, '/lista-exercitii');
    expect(uri.queryParameters, {'materie': 'Informatică', 'clasa': '10', 'capitol': '3. Recursivitate'});
  });
}
