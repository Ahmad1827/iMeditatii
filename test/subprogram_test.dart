// Subprogram problems: the student writes only the subprogram, and the main
// that reads the input, calls it and prints (main_verificare) is added after it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
  final subs = <String, Map<String, dynamic>>{
    for (final s in details.entries)
      for (final g in (s.value as Map<String, dynamic>).entries)
        for (final e in (g.value as Map<String, dynamic>).entries)
          if ((e.value as Map)['main_verificare'] != null) '${s.key} ${g.key} #${e.key}': e.value as Map<String, dynamic>,
  };

  test('every BAC III.1 problem is a subprogram one, with its header in the statement and a main of its own', () {
    final g12 = details['Informatică']['12'] as Map<String, dynamic>;
    for (final e in g12.values) {
      if ('${e['sursa']}'.endsWith('III.1')) expect(e['main_verificare'], isNotNull, reason: '${e['title']}');
    }
    for (final e in subs.entries) {
      expect('${e.value['cerinta']}', contains('${e.value['antet']}'), reason: e.key);
      expect('${e.value['cerinta']}', contains('este scrisă deja'), reason: e.key);
      expect('${e.value['main_verificare']}', contains('int main'), reason: e.key);
    }
    expect(subs.length, greaterThan(70));
  });

  final gpp = Process.runSync('which', ['g++']).exitCode == 0;
  test('the official subprogram with the hidden main passes every test; the starting code compiles', () async {
    String norm(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final tmp = Directory.systemTemp.createTempSync('sub');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final failures = <String>[];
    var n = 0;
    for (final e in subs.entries) {
      final dir = Directory('${tmp.path}/${n++}')..createSync();
      final code = '${e.value['official_solution']['code']}';
      final student = code.substring(0, RegExp(r'^int main\s*\(', multiLine: true).firstMatch(code)!.start);
      final harness = '${e.value['main_verificare']}';
      File('${dir.path}/a.cpp').writeAsStringSync('$student\n\n$harness\n');
      File('${dir.path}/start.cpp').writeAsStringSync('#include <iostream>\nusing namespace std;\n\n${e.value['antet']} {\n    // TODO\n}\n\n$harness\n');
      final start = await Process.run('g++', ['-std=c++17', '-c', 'start.cpp', '-o', 'start.o'], workingDirectory: dir.path);
      if (start.exitCode != 0) failures.add('${e.key}: the starting code does not compile');
      final c = await Process.run('g++', ['-std=c++17', '-O2', 'a.cpp', '-o', 'a'], workingDirectory: dir.path);
      if (c.exitCode != 0) {
        failures.add('${e.key}: compile error');
        continue;
      }
      for (final t in e.value['tests'] as List) {
        final p = await Process.start('${dir.path}/a', [], workingDirectory: dir.path);
        p.stdin.write(t['input']);
        await p.stdin.close();
        final out = await p.stdout.transform(const SystemEncoding().decoder).join();
        await p.exitCode;
        if (norm(out) != norm('${t['output']}')) failures.add('${e.key}: ${'${t['input']}'.split('\n').first}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, skip: gpp ? false : 'needs g++', timeout: const Timeout(Duration(minutes: 10)));
}
