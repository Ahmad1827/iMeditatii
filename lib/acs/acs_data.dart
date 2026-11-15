// =============================================================================
// ACS DATA: a course's problems and what is solved on this device
//   Each course is one file, assets/data/acs/<code>.json (made by tool/acs/):
//   {"code", "chapters": [...], "problems": [{id, title, chapter, difficulty,
//   source, statement, hint, solution, kind, spec, test}], "tests": [{n, name,
//   about}]} (tests only where the seminar's tests split the problems). The kind says which
//   workspace solves it (shell, asm, c, logic, octave, rowops, math, circuit,
//   sim, ds, grila, lfa, threads, transform, raster, net, crypto, market,
//   calc) and spec holds what that workspace needs.
// =============================================================================

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcsProblem {
  final String course;
  final String id;
  final String title;
  final String chapter;
  final String difficulty; // ușoară, medie, grea
  final String source; // the exam it comes from; '' for the site's own
  final String statement;
  final String hint;
  final String solution;
  final String kind;
  final Map<String, dynamic> spec;
  final int test; // the seminar test it is for (see [AcsCourseData.tests]); 0: none
  final String topic; // the test's item it trains ([AcsTopic.id]); '' for none

  const AcsProblem({
    required this.course,
    required this.id,
    required this.title,
    required this.chapter,
    required this.difficulty,
    required this.source,
    required this.statement,
    required this.hint,
    required this.solution,
    required this.kind,
    required this.spec,
    this.test = 0,
    this.topic = '',
  });

  factory AcsProblem.fromJson(String course, Map<String, dynamic> j) => AcsProblem(
        course: course,
        id: '${j['id']}',
        title: j['title'] as String,
        chapter: j['chapter'] as String,
        difficulty: j['difficulty'] as String? ?? 'medie',
        source: j['source'] as String? ?? '',
        statement: j['statement'] as String,
        hint: j['hint'] as String? ?? '',
        solution: j['solution'] as String? ?? '',
        kind: j['kind'] as String,
        spec: (j['spec'] as Map?)?.cast<String, dynamic>() ?? const {},
        test: (j['test'] as num?)?.toInt() ?? 0,
        topic: j['topic'] as String? ?? '',
      );

  String get key => 'acs:$course:$id';
  String get route => '/acs/$course/$id';

  /// What the workspace is, in a word, for the list.
  String get kindLabel => acsKindLabels[kind] ?? kind;
}

const Map<String, String> acsKindLabels = {
  'shell': 'shell',
  'asm': 'asm x86',
  'c': 'cod C',
  'logic': 'logică',
  'fsm': 'automat',
  'octave': 'octave',
  'rowops': 'matrice',
  'math': 'calcul',
  'circuit': 'circuit',
  'sim': 'simulare',
  'ds': 'structuri',
  'grila': 'grilă',
  'lfa': 'limbaj',
  'threads': 'fire',
  'transform': 'transformări',
  'raster': 'raster',
  'net': 'adrese',
  'crypto': 'decodare',
  'market': 'calcul',
  'calc': 'calcul',
};

/// An item of a test: "P3 · Conversii", worth 2.5 points.
class AcsTopic {
  final String id, name;
  final double points; // 0: not announced
  const AcsTopic(this.id, this.name, this.points);
}

/// One of the seminar's tests: "Testul 1", "Limbaje regulate (LR)", and its items.
class AcsTest {
  final int n;
  final String name, about;
  final List<AcsTopic> topics;
  const AcsTest(this.n, this.name, this.about, {this.topics = const []});

  /// What is in the brackets of [about] ("LR"), or [about] itself.
  String get short => RegExp(r'\(([^)]+)\)').firstMatch(about)?.group(1) ?? about;
}

class AcsCourseData {
  final String code;
  final List<String> chapters;
  final List<AcsProblem> problems;
  final List<AcsTest> tests; // empty: the course's problems are not split by test
  const AcsCourseData(this.code, this.chapters, this.problems, {this.tests = const []});

  AcsProblem? byId(String id) {
    for (final p in problems) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The problem after [p] in the course, or null at the end.
  AcsProblem? after(AcsProblem p) {
    final i = problems.indexWhere((q) => q.id == p.id);
    return i >= 0 && i + 1 < problems.length ? problems[i + 1] : null;
  }

  static AcsCourseData parse(String code, String text) {
    final j = json.decode(text) as Map<String, dynamic>;
    return AcsCourseData(
      code,
      [for (final c in j['chapters'] as List) '$c'],
      [for (final p in j['problems'] as List) AcsProblem.fromJson(code, (p as Map).cast<String, dynamic>())],
      tests: [
        for (final t in j['tests'] as List? ?? const [])
          AcsTest((t['n'] as num).toInt(), '${t['name']}', '${t['about'] ?? ''}', topics: [
            for (final x in t['topics'] as List? ?? const []) AcsTopic('${x['id']}', '${x['name']}', (x['points'] as num?)?.toDouble() ?? 0),
          ]),
      ],
    );
  }
}

final Map<String, AcsCourseData> _cache = {};

/// The course's problems, or null if it has none yet. What is read once is
/// kept (the value, not the future, so each caller gets a future of its own).
Future<AcsCourseData?> loadAcsCourse(String code) async {
  final had = _cache[code];
  if (had != null) return had;
  try {
    return _cache[code] = AcsCourseData.parse(code, await rootBundle.loadString('assets/data/acs/$code.json'));
  } catch (_) {
    return null;
  }
}

/// What is solved or tried on this device.
class AcsProgress {
  static Future<bool> solved(AcsProblem p) async => (await SharedPreferences.getInstance()).getBool(p.key) ?? false;

  static Future<Set<String>> solvedIds(String course) async {
    final prefs = await SharedPreferences.getInstance();
    final pre = 'acs:$course:';
    return {for (final k in prefs.getKeys()) if (k.startsWith(pre) && prefs.get(k) == true) k.substring(pre.length)};
  }

  static Future<Set<String>> triedIds(String course) async {
    final prefs = await SharedPreferences.getInstance();
    final pre = 'acs-incercata:$course:';
    return {for (final k in prefs.getKeys()) if (k.startsWith(pre)) k.substring(pre.length)};
  }

  static Future<void> markSolved(AcsProblem p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(p.key, true);
    await prefs.remove('acs-incercata:${p.course}:${p.id}');
  }

  static Future<void> markTried(AcsProblem p) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(p.key) ?? false) return;
    await prefs.setBool('acs-incercata:${p.course}:${p.id}', true);
  }

  /// What the student left in the workspace (code, a shell's history...).
  static Future<String?> draft(AcsProblem p) async => (await SharedPreferences.getInstance()).getString('acs-ciorna:${p.course}:${p.id}');

  static Future<void> saveDraft(AcsProblem p, String text) async =>
      (await SharedPreferences.getInstance()).setString('acs-ciorna:${p.course}:${p.id}', text);
}
