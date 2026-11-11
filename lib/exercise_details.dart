import 'dart:convert';

import 'package:flutter/services.dart';

/// The problems that come with the app, split in assets/data/details/ by subject and grade;
/// index.json says which files hold which grade. A grade's file is small: tests that
/// run to megabytes are kept apart (tests/, one file per problem, named by "tests_file")
/// and are read only for the problem that is opened. See tool/details.py.
const detailsDir = 'assets/data/details';

Future<Map<String, dynamic>>? _index;
final Map<String, Future<Map<String, dynamic>>> _parts = {};

Future<Map<String, dynamic>> _loadIndex() =>
    _index ??= rootBundle.loadString('$detailsDir/index.json').then((s) => json.decode(s) as Map<String, dynamic>);

// kept once read; a load that failed (offline) is tried again next time
Future<Map<String, dynamic>> _part(String file) => _parts[file] ??= rootBundle
        .loadString('$detailsDir/$file', cache: false)
        .then((s) => json.decode(s) as Map<String, dynamic>)
        .catchError((Object e) {
      _parts.remove(file);
      throw e;
    });

/// The problems of one grade, id → problem (empty if there are none). A problem
/// with many tests has "tests_file" in place of "tests": see [loadProblem].
Future<Map<String, dynamic>> loadGradeDetails(String subject, String grade) async {
  final files = (await _loadIndex())[subject]?[grade];
  if (files is! List) return {};
  final parts = await Future.wait([for (final f in files) _part('$f')]);
  return parts.length == 1 ? parts.first : {for (final p in parts) ...p};
}

/// One problem with its tests, or null if the app doesn't have it.
Future<Map<String, dynamic>?> loadProblem(String subject, String grade, String id) async {
  final p = (await loadGradeDetails(subject, grade))[id];
  if (p is! Map) return null;
  final problem = Map<String, dynamic>.from(p);
  await loadTests(problem);
  return problem;
}

/// Puts a problem's tests in it when they are kept apart. False when they
/// couldn't be read (offline, and never opened before): the statement is still
/// good, and this can be called again before the solution is checked.
Future<bool> loadTests(Map<String, dynamic> problem) async {
  final file = problem['tests_file'];
  if (file == null || problem['tests'] != null) return true;
  try {
    problem['tests'] = json.decode(await rootBundle.loadString('$detailsDir/$file', cache: false));
    return true;
  } catch (_) {
    return false;
  }
}

/// Every problem: subject → grade → id → problem, as the single file used to be
/// (without the tests kept apart).
Future<Map<String, dynamic>> loadAllDetails() async {
  final index = await _loadIndex();
  final out = <String, dynamic>{};
  await Future.wait([
    for (final s in index.entries)
      for (final g in (s.value as Map).keys)
        loadGradeDetails(s.key, '$g').then((d) => ((out[s.key] ??= <String, dynamic>{}) as Map)['$g'] = d),
  ]);
  // in the index's order, whichever file came first
  return {
    for (final s in index.entries)
      if (out[s.key] != null) s.key: {for (final g in (s.value as Map).keys) '$g': (out[s.key] as Map)['$g']},
  };
}
