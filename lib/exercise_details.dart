import 'dart:convert';

import 'package:flutter/services.dart';

/// The problems that come with the app, split in assets/data/details/ by subject and grade
/// (no file gets near GitHub's 100 MB limit); index.json says which files hold which grade.
const detailsDir = 'assets/data/details';

Future<Map<String, dynamic>>? _index;

Future<Map<String, dynamic>> _loadIndex() =>
    _index ??= rootBundle.loadString('$detailsDir/index.json').then((s) => json.decode(s) as Map<String, dynamic>);

Future<Map<String, dynamic>> _part(String file) async =>
    json.decode(await rootBundle.loadString('$detailsDir/$file', cache: false)) as Map<String, dynamic>;

/// The problems of one grade, id → problem (empty if there are none).
Future<Map<String, dynamic>> loadGradeDetails(String subject, String grade) async {
  final files = (await _loadIndex())[subject]?[grade];
  final out = <String, dynamic>{};
  if (files is List) {
    for (final f in files) {
      out.addAll(await _part('$f'));
    }
  }
  return out;
}

/// Every problem: subject → grade → id → problem, as the single file used to be.
Future<Map<String, dynamic>> loadAllDetails() async {
  final out = <String, dynamic>{};
  for (final s in (await _loadIndex()).entries) {
    final grades = <String, dynamic>{};
    for (final g in (s.value as Map).keys) {
      grades['$g'] = await loadGradeDetails(s.key, '$g');
    }
    out[s.key] = grades;
  }
  return out;
}
