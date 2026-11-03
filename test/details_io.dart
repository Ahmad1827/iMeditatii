import 'dart:convert';
import 'dart:io';

/// Every problem in assets/data/details/, merged as the app sees it: subject → grade → id → problem.
Map<String, dynamic> readAllDetails() {
  const dir = 'assets/data/details';
  final index = jsonDecode(File('$dir/index.json').readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final s in index.entries)
      s.key: {
        for (final g in (s.value as Map).entries)
          '${g.key}': {
            for (final f in g.value as List) ...(jsonDecode(File('$dir/$f').readAsStringSync()) as Map<String, dynamic>),
          },
      },
  };
}
