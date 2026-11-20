// =============================================================================
// THE PROBLEM LIST'S SUBCATEGORIES AND SEARCH
//   Read from what a problem already says about itself (its source, chapter,
//   title, statement): the year ("BAC 2026 · ...", "AcadNet 2024 · ..."), the
//   kind of paper (model, simulare, sesiunea din august, test de antrenament,
//   olimpiadă, exercițiu), the classes of a contest. A grade shows a row of
//   these only where its problems differ in them.
//   The search wants every word typed, anywhere, forgives a letter wrong in
//   the longer words, and ranks the title above the statement.
// =============================================================================

import 'ide_statement.dart' show ProblemRef;

/// The views of the list, in the order they are offered.
enum ExView { lista, carduri, compact, tabla, ani }

class ExFacets {
  /// Lowercase and without diacritics, one character for one (so the places
  /// found in it are the places in the text shown).
  static String fold(String s) => ProblemRef.fold(s);

  /// The year of a paper or contest, when the source names one.
  static int? year(String sursa) {
    final f = fold(sursa);
    if (!(f.startsWith('bac') || f.startsWith('acadnet') || f.contains('olimpiad') || f.contains('oji'))) return null;
    final m = RegExp(r'\b(19|20)\d\d\b').firstMatch(sursa);
    return m == null ? null : int.parse(m.group(0)!);
  }

  /// The kind of paper or problem it is, from its source (and its chapter).
  static String type(String sursa, String category) {
    final f = fold(sursa);
    final c = fold(category);
    if (f.startsWith('bac')) {
      if (f.contains('test de antrenament')) return 'Test de antrenament';
      if (f.contains('model')) return 'Model';
      if (f.contains('simulare')) return 'Simulare';
      if (f.contains('speciala')) return 'Sesiunea specială';
      if (f.contains('rezerva')) return 'Rezervă';
      if (f.contains('iunie')) return 'Iunie–iulie';
      if (f.contains('august')) return 'August';
      return 'BAC';
    }
    if (f.startsWith('acadnet')) {
      for (final e in const ['locala', 'judeteana', 'interjudeteana', 'nationala']) {
        if (f.contains('etapa $e')) return 'Etapa ${_etapa[e]}';
      }
      return 'AcadNet';
    }
    if (f.contains('olimpiad') || f.contains('(oji)') || c.contains('olimpiad')) return 'Olimpiadă';
    if (f.contains('antrenament')) return 'Antrenament';
    if (f.isNotEmpty) return 'Problemă clasică';
    return 'Exercițiu';
  }

  static const Map<String, String> _etapa = {
    'locala': 'locală',
    'judeteana': 'județeană',
    'interjudeteana': 'interjudețeană',
    'nationala': 'națională',
  };

  /// The classes a contest problem is for ("9–10", "11–12"), when said.
  static String? classes(String sursa) {
    final m = RegExp(r'clasele\s+([0-9IVX]+\s*[–-]\s*[0-9IVX]+)').firstMatch(sursa);
    return m?.group(1)?.replaceAll(' ', '').replaceAll('-', '–');
  }

  /// The order the kinds are offered in: the papers of the year first.
  static const List<String> typeOrder = [
    'Model', 'Simulare', 'Sesiunea specială', 'Iunie–iulie', 'Rezervă', 'August', 'Test de antrenament', 'BAC',
    'Etapa locală', 'Etapa județeană', 'Etapa interjudețeană', 'Etapa națională', 'AcadNet',
    'Exercițiu', 'Antrenament', 'Problemă clasică', 'Olimpiadă',
  ];

  static int typeRank(String t) {
    final i = typeOrder.indexOf(t);
    return i < 0 ? typeOrder.length : i;
  }

  /// 0 easy, 1 medium, 2 hard, 3 not said.
  static int diffRank(String d) {
    final l = fold(d);
    if (l.startsWith('u') || l.startsWith('e')) return 0;
    if (l.startsWith('m')) return 1;
    if (l.startsWith('g') || l.startsWith('h') || l.startsWith('d')) return 2;
    return 3;
  }
}

/// A search typed in the list: every word must be found in the problem, the
/// longer ones forgiving a letter (two in a long word); `#61` asks for the id.
class ExSearch {
  final String raw;
  final List<String> words;
  ExSearch(this.raw) : words = ExFacets.fold(raw).split(RegExp(r'[\s,;]+')).where((w) => w.isNotEmpty).toList();

  bool get isEmpty => words.isEmpty;

  /// How well the problem answers (0: it does not). The title counts most,
  /// then the id, the source, the chapter, and last the statement.
  int score({required String id, required String title, String category = '', String sursa = '', String statement = '', String difficulty = ''}) {
    if (words.isEmpty) return 1;
    final fields = [
      (ExFacets.fold(title), 6),
      (ExFacets.fold(sursa), 3),
      (ExFacets.fold(category), 2),
      (ExFacets.fold(difficulty), 2),
      (ExFacets.fold(statement), 1),
    ];
    var total = 0;
    for (final w in words) {
      if (w.startsWith('#')) {
        if (w.length > 1 && id.toLowerCase() == w.substring(1)) {
          total += 20;
          continue;
        }
        return 0;
      }
      var best = 0;
      if (id.toLowerCase() == w) best = 10;
      for (final (hay, weight) in fields) {
        if (hay.isEmpty) continue;
        if (hay.contains(w)) {
          // a whole word or its start counts more than a piece inside one
          final at = RegExp('(^|[^a-z0-9])${RegExp.escape(w)}').hasMatch(hay);
          final s = weight * (at ? 3 : 2);
          if (s > best) best = s;
        } else if (w.length >= 4 && _near(hay, w)) {
          if (weight > best) best = weight;
        }
      }
      if (best == 0) return 0;
      total += best;
    }
    return total;
  }

  /// A word of the text at most one edit away (two for a word of 8 or more),
  /// or a word starting so.
  static bool _near(String hay, String w) {
    final max = w.length >= 8 ? 2 : 1;
    for (final t in hay.split(RegExp(r'[^a-z0-9]+'))) {
      if (t.length < w.length - max) continue;
      final cut = t.length > w.length + max ? t.substring(0, w.length) : t;
      if (_edits(cut, w, max) <= max) return true;
    }
    return false;
  }

  /// Levenshtein, giving up past [max].
  static int _edits(String a, String b, int max) {
    if ((a.length - b.length).abs() > max) return max + 1;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      var low = cur[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final v = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
        cur[j] = v;
        if (v < low) low = v;
      }
      if (low > max) return max + 1;
      prev = cur;
    }
    return prev[b.length];
  }

  /// Where the words are in [text], to show them marked: (start, end) pairs,
  /// in order and not overlapping.
  List<(int, int)> marks(String text) {
    if (words.isEmpty) return const [];
    final f = ExFacets.fold(text);
    if (f.length != text.length) return const [];
    final found = <(int, int)>[];
    for (final w in words) {
      if (w.startsWith('#') || w.length < 2) continue;
      var i = f.indexOf(w);
      if (i < 0 && w.length >= 4) {
        // not there as typed: the words a letter or two away ("fibonaci" marks "Fibonacci")
        final max = w.length >= 8 ? 2 : 1;
        for (final m in RegExp(r'[a-z0-9]+').allMatches(f)) {
          final t = m.group(0)!;
          if (t.length < w.length - max) continue;
          final cut = t.length > w.length + max ? t.substring(0, w.length) : t;
          if (_edits(cut, w, max) <= max) found.add((m.start, m.start + cut.length));
        }
      }
      while (i >= 0) {
        found.add((i, i + w.length));
        i = f.indexOf(w, i + w.length);
      }
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    final out = <(int, int)>[];
    for (final r in found) {
      if (out.isNotEmpty && r.$1 <= out.last.$2) {
        if (r.$2 > out.last.$2) out[out.length - 1] = (out.last.$1, r.$2);
      } else {
        out.add(r);
      }
    }
    return out;
  }
}
