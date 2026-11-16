// =============================================================================
// A COURSE'S THEORY: lessons to read before (or beside) the problems
//   assets/data/acs/teorie/<code>.json, made by tool/acs/<code>_teorie.py:
//   {"code", "title", "intro", "parts": [{title, about, test, lessons: [id]}],
//    "chapters": {problem chapter: lesson id},
//    "lessons": [{id, title, summary, curs, minutes, goals: [...],
//                 practice: [problem id],
//                 sections: [{id, title, key: [...], blocks: [{t: ..., ...}]}]}]}
//   goals say what the lesson teaches and key is a section's takeaway: the
//   short layer read first (and alone, in the "esențial" mode).
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
  final List<String> key;
  final List<Map<String, dynamic>> blocks;
  const TeorieSection(this.id, this.title, this.blocks, {this.key = const []});
}

class TeorieLesson {
  final String id, title, summary, curs;
  final int minutes;
  final List<String> practice;
  final List<TeorieSection> sections;
  final List<String> goals;
  const TeorieLesson(this.id, this.title, this.summary, this.curs, this.minutes, this.practice, this.sections, {this.goals = const []});

  int get vizCount => sections.fold(0, (a, s) => a + s.blocks.where((b) => b['t'] == 'viz').length);
}

class TeoriePart {
  final String title, about, test;
  final List<String> lessons;
  const TeoriePart(this.title, this.about, this.lessons, {this.test = ''});
}

class TeorieCourse {
  final String code, title, intro;
  final List<TeoriePart> parts;
  final List<TeorieLesson> lessons;
  final Map<String, String> chapters; // a problem chapter -> the lesson to read for it
  const TeorieCourse(this.code, this.title, this.intro, this.parts, this.lessons, {this.chapters = const {}});

  TeoriePart? partOf(TeorieLesson l) {
    for (final p in parts) {
      if (p.lessons.contains(l.id)) return p;
    }
    return null;
  }

  /// The lesson for a problem's chapter, if there is one.
  TeorieLesson? forChapter(String chapter) => chapters[chapter] == null ? null : byId(chapters[chapter]!);

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
          TeoriePart('${p['title']}', '${p['about'] ?? ''}', [for (final l in p['lessons'] as List) '$l'], test: '${p['test'] ?? ''}'),
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
                TeorieSection('${s['id']}', '${s['title']}', [for (final b in s['blocks'] as List) (b as Map).cast<String, dynamic>()],
                    key: [for (final k in s['key'] as List? ?? const []) '$k']),
            ],
            goals: [for (final g in l['goals'] as List? ?? const []) '$g'],
          ),
      ],
      chapters: {for (final e in (j['chapters'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
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

/// A study guide kept as a PDF in web/materiale/ (built from tool/acs/ghid_*), shown on its course's page.
class AcsGhid {
  final String title;
  final String about;
  final String path; // from the site's root
  const AcsGhid(this.title, this.about, this.path);
}

const Map<String, List<AcsGhid>> acsGhiduri = {
  'lfa': [
    AcsGhid(
      'Testul 1 · Limbaje regulate',
      'Tot ce intră la test, pe itemi: ER și automate, conversii cu automatele desenate, închidere, algoritmi, pompare, fișa seminarului rezolvată, un test simulat cu barem și o foaie de memorat. 37 de pagini.',
      '/materiale/lfa-testul-1-lr.pdf',
    ),
    AcsGhid(
      'Testul 1 · Culegere de exerciții rezolvate',
      '140 de exerciții pe itemii testului, fiecare cu rezolvarea explicată pas cu pas: AFD, AFN și ER, conversii cu tabelele algoritmilor, închidere, algoritmi, pompare, bonus, grilele vechi explicate și două teste simulate cu barem. 50 de pagini.',
      '/materiale/lfa-testul-1-culegere.pdf',
    ),
  ],
};

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

  /// Esențial (false) or complet (true), as last chosen.
  static Future<bool> full() async {
    try {
      return (await SharedPreferences.getInstance()).getBool('acs-teorie-complet') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setFull(bool v) async => (await SharedPreferences.getInstance()).setBool('acs-teorie-complet', v);

  static Future<String?> last(String code) async => (await SharedPreferences.getInstance()).getString('acs-teorie-ultima:$code');
  static Future<void> setLast(String code, String id) async => (await SharedPreferences.getInstance()).setString('acs-teorie-ultima:$code', id);
}
