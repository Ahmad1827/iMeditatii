// =============================================================================
// A COURSE'S THEORY: lessons to read before (or beside) the problems
//   assets/data/acs/teorie/<code>.json, made by tool/acs/<code>_teorie.py:
//   {"code", "title", "intro", "parts": [{title, about, lessons: [id]}],
//    "lessons": [{id, title, summary, curs, minutes, practice: [problem id],
//                 sections: [{id, title, blocks: [{t: ..., ...}]}]}]}
//   A block is prose (p), a definition (def), a theorem (thm, maybe with a
//   proof), an example (ex, maybe with a solution), a note (note: tip, warn,
//   info), a table, an algorithm's steps (steps), a question to check
//   oneself (quiz), an exam problem solved (exam), or a visualisation (viz,
//   by kind). What is read is kept on the device.
// =============================================================================

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeorieSection {
  final String id, title;
  final List<Map<String, dynamic>> blocks;
  const TeorieSection(this.id, this.title, this.blocks);
}

class TeorieLesson {
  final String id, title, summary, curs;
  final int minutes;
  final List<String> practice;
  final List<TeorieSection> sections;
  const TeorieLesson(this.id, this.title, this.summary, this.curs, this.minutes, this.practice, this.sections);

  int get vizCount => sections.fold(0, (a, s) => a + s.blocks.where((b) => b['t'] == 'viz').length);
}

class TeoriePart {
  final String title, about;
  final List<String> lessons;
  const TeoriePart(this.title, this.about, this.lessons);
}

class TeorieCourse {
  final String code, title, intro;
  final List<TeoriePart> parts;
  final List<TeorieLesson> lessons;
  const TeorieCourse(this.code, this.title, this.intro, this.parts, this.lessons);

  TeorieLesson? byId(String id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  int indexOf(TeorieLesson l) => lessons.indexWhere((x) => x.id == l.id);

  static TeorieCourse parse(String code, String text) {
    final j = json.decode(text) as Map<String, dynamic>;
    return TeorieCourse(
      code,
      '${j['title'] ?? ''}',
      '${j['intro'] ?? ''}',
      [
        for (final p in j['parts'] as List? ?? const [])
          TeoriePart('${p['title']}', '${p['about'] ?? ''}', [for (final l in p['lessons'] as List) '$l']),
      ],
      [
        for (final l in j['lessons'] as List)
          TeorieLesson(
            '${l['id']}',
            '${l['title']}',
            '${l['summary'] ?? ''}',
            '${l['curs'] ?? ''}',
            (l['minutes'] as num?)?.toInt() ?? 20,
            [for (final p in l['practice'] as List? ?? const []) '$p'],
            [
              for (final s in l['sections'] as List)
                TeorieSection('${s['id']}', '${s['title']}', [for (final b in s['blocks'] as List) (b as Map).cast<String, dynamic>()]),
            ],
          ),
      ],
    );
  }
}

final Map<String, TeorieCourse> _cache = {};

/// The course's theory, or null if it has none. What is read once is kept
/// (the value, not the future, so each caller gets a future of its own).
Future<TeorieCourse?> loadTeorie(String code) async {
  final had = _cache[code];
  if (had != null) return had;
  try {
    return _cache[code] = TeorieCourse.parse(code, await rootBundle.loadString('assets/data/acs/teorie/$code.json'));
  } catch (_) {
    return null;
  }
}

/// The courses that have theory pages (checked against the assets).
const Set<String> acsTeorieCourses = {'lfa'};

class TeorieProgress {
  static String _key(String code, String id) => 'acs-teorie:$code:$id';

  static Future<Set<String>> read(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final pre = 'acs-teorie:$code:';
    return {for (final k in prefs.getKeys()) if (k.startsWith(pre) && prefs.get(k) == true) k.substring(pre.length)};
  }

  static Future<void> mark(String code, String id, bool done) async {
    final prefs = await SharedPreferences.getInstance();
    if (done) {
      await prefs.setBool(_key(code, id), true);
    } else {
      await prefs.remove(_key(code, id));
    }
  }

  static Future<String?> last(String code) async => (await SharedPreferences.getInstance()).getString('acs-teorie-ultima:$code');
  static Future<void> setLast(String code, String id) async => (await SharedPreferences.getInstance()).setString('acs-teorie-ultima:$code', id);
}
