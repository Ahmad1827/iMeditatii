// Problems with files (like at the olympiad): the program reads name.in and
// writes name.out. For the server judge, which only has the keyboard and the
// screen, FileIo.wrap adds a prelude; these compile it with this machine's g++.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/judge0.dart';

void main() {
  final gpp = Process.runSync('which', ['g++']).exitCode == 0;

  /// [code] wrapped for x.in holding [input], built and run: the screen, and x.out.
  Future<(String, String?)> run(String code, String input) async {
    final dir = await Directory.systemTemp.createTemp('fileio');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/main.cpp').writeAsString(FileIo.wrap(code, 'x', input));
    final c = await Process.run('g++', ['-std=c++17', '-O1', 'main.cpp', '-o', 'main'], workingDirectory: dir.path);
    expect(c.exitCode, 0, reason: '${c.stderr}');
    final r = await Process.run('${dir.path}/main', [], workingDirectory: dir.path, stdoutEncoding: systemEncoding);
    return FileIo.split('${r.stdout}');
  }

  test('with ifstream and ofstream: what it wrote in x.out', () async {
    final (screen, file) = await run(
      '#include <fstream>\nusing namespace std;\nifstream fin("x.in");\nofstream fout("x.out");\nint main() { int a, b; fin >> a >> b; fout << a + b << "\\n"; }',
      '2 3',
    );
    expect(file, '5\n');
    expect(screen, '');
  }, skip: !gpp);

  test('with freopen too, even though stdout then goes to the file', () async {
    final (screen, file) = await run(
      '#include <cstdio>\nint main() { freopen("x.in", "r", stdin); freopen("x.out", "w", stdout); int a, b; scanf("%d %d", &a, &b); printf("%d\\n", a * b); }',
      '4 5',
    );
    expect(file, '20\n');
    expect(screen, '');
  }, skip: !gpp);

  test('the keyboard is empty and the screen does not count', () async {
    final (screen, file) = await run(
      '#include <iostream>\nusing namespace std;\nint main() { int a = 0, b = 0; cin >> a >> b; cout << a + b << "\\n"; }',
      '2 3',
    );
    expect(file, isNull); // never created x.out
    expect(screen, '0\n');
  }, skip: !gpp);

  test('#define int long long and friends do not break the prelude', () async {
    final (_, file) = await run(
      '#include <bits/stdc++.h>\n#define int long long\nusing namespace std;\nint32_t main() { ifstream fin("x.in"); ofstream fout("x.out"); int a, b; fin >> a >> b; fout << a - b; return 0; }',
      '10 3',
    );
    expect(file, '7');
  }, skip: !gpp);

  test('compiler errors keep the line numbers of the student\'s code', () async {
    final dir = await Directory.systemTemp.createTemp('fileio');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/main.cpp').writeAsString(FileIo.wrap('int main() {\n  return x;\n}', 'x', '1'));
    final c = await Process.run('g++', ['main.cpp', '-o', 'main'], workingDirectory: dir.path);
    expect('${c.stderr}', contains('main.cpp:2:'));
  }, skip: !gpp);

  test('an input that holds the raw string end still goes in whole', () {
    final code = FileIo.wrap('int main() {}', 'x', 'a)IMIN"b');
    expect(code, contains('R"IMINX(a)IMIN"b)IMINX"'));
  });

  test('the problems with files pass every test with their official solution, through the server judge', () async {
    final details = jsonDecode(File('assets/data/exercise_details.json').readAsStringSync()) as Map<String, dynamic>;
    String norm(String s) => s.replaceAll('\r', '').split('\n').map((l) => l.trimRight()).join('\n').trim();
    var problems = 0;
    for (final grade in (details['Informatică'] as Map<String, dynamic>).values) {
      for (final p in (grade as Map<String, dynamic>).values) {
        final name = p['fisier'];
        if (name == null) continue;
        problems++;
        final code = '${p['official_solution']['code']}';
        expect(code, isNot(contains('cin')), reason: name);
        expect(code, isNot(contains('cout')), reason: name);
        final tests = [p['examples'], ...p['tests'] as List];
        for (final t in tests) {
          final dir = await Directory.systemTemp.createTemp('fileio');
          try {
            await File('${dir.path}/main.cpp').writeAsString(FileIo.wrap(code, name, '${t['input']}'));
            final c = await Process.run('g++', ['-std=c++17', '-O2', 'main.cpp', '-o', 'main'], workingDirectory: dir.path);
            expect(c.exitCode, 0, reason: '$name: ${c.stderr}');
            final r = await Process.run('${dir.path}/main', [], workingDirectory: dir.path);
            final (screen, file) = FileIo.split('${r.stdout}');
            expect(screen, '', reason: name);
            expect(norm(file ?? '<no file>'), norm('${t['output']}'), reason: name);
          } finally {
            await dir.delete(recursive: true);
          }
        }
      }
    }
    expect(problems, 4);
  }, skip: !gpp, timeout: const Timeout(Duration(minutes: 5)));
}
