// What the first load depends on: web/index.html asks early for files the app
// will need, and the problems' data stays small enough to open a page with.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final page = File('web/index.html').readAsStringSync();

  test('index.html preloads the Firebase version that firebase_core loads', () {
    final config = jsonDecode(File('.dart_tool/package_config.json').readAsStringSync()) as Map<String, dynamic>;
    final pkg = (config['packages'] as List).firstWhere((p) => p['name'] == 'firebase_core_web') as Map;
    var root = Uri.parse('${pkg['rootUri']}');
    if (!root.isAbsolute) root = Directory('.dart_tool').absolute.uri.resolveUri(root);
    final source = File.fromUri(root.replace(path: '${root.path}/lib/src/firebase_sdk_version.dart')).readAsStringSync();
    final version = RegExp(r"supportedFirebaseJsSdkVersion = '([^']+)'").firstMatch(source)!.group(1)!;

    final preloaded = RegExp(r'firebasejs/([0-9.]+)/firebase-').allMatches(page).map((m) => m.group(1)).toSet();
    expect(preloaded, {version}, reason: 'firebase_core changed version: update the modulepreload links in web/index.html');
  });

  test('the splash uses fonts that come with the app', () {
    for (final m in RegExp(r"url\('assets/([^']+)'\)").allMatches(page)) {
      expect(File(m.group(1)!).existsSync(), isTrue, reason: m.group(1));
    }
    expect(page.contains('fonts.googleapis.com'), isFalse, reason: 'a stylesheet from another site holds back the first paint');
  });

  test('a grade of problems is a small file: big tests are kept apart (python3 tool/details.py resplit)', () {
    const dir = 'assets/data/details';
    final index = jsonDecode(File('$dir/index.json').readAsStringSync()) as Map<String, dynamic>;
    for (final grades in index.values) {
      for (final files in (grades as Map).values) {
        for (final f in files as List) {
          final file = File('$dir/$f');
          expect(file.lengthSync(), lessThan(2000000), reason: '$f');
          for (final p in (jsonDecode(file.readAsStringSync()) as Map).values) {
            final apart = (p as Map)['tests_file'];
            if (apart != null) {
              expect(p.containsKey('tests'), isFalse, reason: '$f: tests twice');
              expect(File('$dir/$apart').existsSync(), isTrue, reason: '$apart');
            }
          }
        }
      }
    }
  });
}
