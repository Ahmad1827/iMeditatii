import 'dart:convert';
import 'dart:io';

/// Every problem in assets/data/details/, merged as the app sees it: subject → grade → id → problem,
/// each with its tests (those kept apart in tests/ are put back, as loadProblem does).
Map<String, dynamic> readAllDetails() {
  const dir = 'assets/data/details';
  final index = jsonDecode(File('$dir/index.json').readAsStringSync()) as Map<String, dynamic>;
  Map<String, dynamic> part(String f) {
    final problems = jsonDecode(File('$dir/$f').readAsStringSync()) as Map<String, dynamic>;
    for (final p in problems.values) {
      final file = (p as Map<String, dynamic>).remove('tests_file');
      if (file != null) p['tests'] = jsonDecode(File('$dir/$file').readAsStringSync());
    }
    return problems;
  }

  return {
    for (final s in index.entries)
      s.key: {
        for (final g in (s.value as Map).entries)
          '${g.key}': {
            for (final f in g.value as List) ...part('$f'),
          },
      },
  };
}
