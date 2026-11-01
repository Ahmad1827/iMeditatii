import 'package:flutter/services.dart';

// =============================================================================
// CODE COMPLETION: the grey text after the caret, accepted with Tab.
//   Pure: text and caret in, a suggestion out, so it is tested without a widget.
//
//   CodeComplete.suggest    the built-in completer: reads the file and needs no
//                           network (for (int i → = 0; i < n; i++,
//                           cin >> → the variable not read yet, wor → a name
//                           already in the file, whi → while ())
//   CodeComplete.fromModel  cleans what Claude answered so it fits at the caret
//   CodeComplete.apply      what accepting a suggestion does to the code
// =============================================================================

/// A suggestion, valid only for the exact text and caret it was made for.
class Ghost {
  final String text; // shown and inserted at the caret
  final int consume; // characters after the caret that it replaces
  final int? caret; // where the caret lands inside [text]; null = at its end
  final bool fromClaude;
  final String forText;
  final int at;

  const Ghost({
    required this.text,
    required this.forText,
    required this.at,
    this.consume = 0,
    this.caret,
    this.fromClaude = false,
  });

  bool matches(TextEditingValue v) => v.selection.isCollapsed && v.selection.baseOffset == at && v.text == forText;
}

class CodeComplete {
  static const int maxLines = 12;

  static final RegExp _closersOnly = RegExp(r'''^[)\]}"';,\s]*$''');

  static String _before(String text, int caret) => text.substring(text.lastIndexOf('\n', caret - 1 < 0 ? 0 : caret - 1) + 1, caret);

  static String _after(String text, int caret) {
    final nl = text.indexOf('\n', caret);
    return text.substring(caret, nl < 0 ? text.length : nl);
  }

  /// A suggestion fits only where nothing but closing brackets follows the caret.
  static bool canComplete(String text, int caret) {
    if (caret < 0 || caret > text.length) return false;
    return _closersOnly.hasMatch(_after(text, caret));
  }

  /// The change accepting [g] makes to [v].
  static TextEditingValue apply(Ghost g, TextEditingValue v) {
    final t = v.text.replaceRange(g.at, g.at + g.consume, g.text);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: g.at + (g.caret ?? g.text.length)));
  }

  // ------------------------------------------------------------ built in
  /// The built-in suggestion for the caret at [caret], or null.
  static Ghost? suggest(String text, int caret, {String lang = 'cpp'}) {
    if (!canComplete(text, caret)) return null;
    final before = _before(text, caret);
    if (before.trim().isEmpty) return null;
    final python = lang == 'python';
    if (before.contains(python ? '#' : '//')) return null; // in a comment
    if (_inString(before)) return null;
    final s = python ? _python(text, caret, before) : _cpp(text, caret, before);
    if (s == null || s.replaceAll('|', '').isEmpty) return null;
    final mark = s.indexOf('|');
    return Ghost(text: s.replaceFirst('|', ''), caret: mark < 0 ? null : mark, forText: text, at: caret);
  }

  static bool _inString(String before) {
    var open = false;
    for (var i = 0; i < before.length; i++) {
      final c = before[i];
      if (c == r'\') {
        i++;
      } else if (c == '"') {
        open = !open;
      }
    }
    return open;
  }

  static String? _rest(String word, String full) => full.length > word.length && full.startsWith(word) ? full.substring(word.length) : null;

  static String? _word(String before) => RegExp(r'[A-Za-z_]\w*$').stringMatch(before);

  /// The name in the file that starts with [word], closest above the caret.
  static String? _nameInFile(String text, int caret, String word) {
    final above = text.substring(0, caret - word.length);
    final below = text.substring(caret);
    bool fits(String n) => n.length > word.length && n.startsWith(word) && n.length >= 3;
    String? found;
    for (final m in RegExp(r'[A-Za-z_]\w*').allMatches(above)) {
      if (fits(m[0]!)) found = m[0];
    }
    if (found != null) return found;
    for (final m in RegExp(r'[A-Za-z_]\w*').allMatches(below)) {
      if (fits(m[0]!)) return m[0];
    }
    return null;
  }

  static String? _fromWords(String text, int caret, String before, List<String> statements, List<String> words, Map<String, String> members) {
    final word = _word(before);
    if (word == null) return null;
    if (before.length > word.length && before[before.length - word.length - 1] == '.') {
      if (word.length < 2) return null;
      for (final e in members.keys) {
        final r = _rest(word, e);
        if (r != null) return r + members[e]!;
      }
      return null;
    }
    if (word.length < 2) return null;
    if (before.trimLeft() == word) {
      for (final s in statements) {
        final r = _rest(word, s);
        if (r != null) return r;
      }
    }
    final name = _nameInFile(text, caret, word);
    if (name != null) return name.substring(word.length);
    for (final s in words) {
      final r = _rest(word, s);
      if (r != null) return r;
    }
    return null;
  }

  // ----------------------------------------------------------------- C++
  static const List<String> _libs = ['iostream', 'fstream', 'vector', 'algorithm', 'string', 'cstring', 'cmath', 'iomanip', 'map', 'set', 'queue', 'stack', 'bits/stdc++.h'];
  static const List<String> _cppStatements = [
    'return ',
    'while (|)',
    'if (|)',
    'else',
    'cout << ',
    'cin >> ',
    'using namespace std;',
    'break;',
    'continue;',
    'ifstream fin("date.in");',
    'ofstream fout("date.out");',
    'sort(v.begin(), v.end());',
    'struct ',
    'switch (|)',
  ];
  static const List<String> _cppWords = ['vector<int> ', 'string ', 'double ', 'long long ', 'bool ', 'char ', 'float ', 'void ', 'const ', 'endl', 'true', 'false', 'sizeof(|)', 'swap(|)', 'min(|)', 'max(|)', 'abs(|)', 'sqrt(|)', 'pow(|)', 'strlen(|)', 'getline(cin, |)'];
  static const Map<String, String> _cppMembers = {'push_back': '(|)', 'pop_back': '()', 'size': '()', 'begin': '()', 'end': '()', 'empty': '()', 'clear': '()', 'length': '()', 'substr': '(|)', 'insert': '(|)', 'erase': '(|)', 'first': '', 'second': '', 'back': '()', 'front': '()'};

  static String? _cpp(String text, int caret, String before) {
    final above = text.substring(0, caret);

    if (RegExp(r'^\s*#\s*\w*$').hasMatch(before)) {
      final word = RegExp(r'\w*$').stringMatch(before)!;
      if (word.isEmpty) return null;
      final r = 'include'.startsWith(word) ? 'include'.substring(word.length) : null;
      if (r == null) return null;
      return '$r <${_nextLib(text)}>';
    }
    final inc = RegExp(r'^\s*#\s*include\s*<([\w./+]*)$').firstMatch(before);
    if (inc != null) {
      final got = inc[1]!;
      if (got.isEmpty) return '${_nextLib(text)}>';
      for (final l in _libs) {
        final r = _rest(got, l);
        if (r != null) return '$r>';
      }
      return null;
    }

    final loop = _cppFor(above, before, _after(text, caret));
    if (loop != null) return loop;

    if (RegExp(r'(^\s*|[;{]\s*)cin(\s*>>\s*\w+(\[\w+\])?)*\s*>>\s*$').hasMatch(before)) {
      final v = _unread(above);
      return v == null ? null : '$v;';
    }
    if (RegExp(r'^\s*cout\s*<<\s*$').hasMatch(before)) {
      final v = _lastAssigned(above);
      return v == null ? null : '$v << "\\n";';
    }
    if (RegExp(r'^\s*return\s+$').hasMatch(before)) {
      return _enclosingFunction(above) == 'main' ? '0;' : null;
    }

    final word = _word(before);
    if (word != null && before.trimLeft() == word && !text.contains(RegExp(r'\bmain\b'))) {
      final r = _rest(word, 'int main() {');
      if (r != null && word.length >= 2) return r;
    }
    if (word != null && before.trimLeft() == word && word.length >= 2) {
      final r = _rest(word, 'for (${_loopVar(above)} = 0; ${_loopName(above)} < ${_bound(above)}; ${_loopName(above)}++)');
      if (r != null) return r;
    }
    return _fromWords(text, caret, before, _cppStatements, _cppWords, _cppMembers);
  }

  static String _nextLib(String text) => _libs.firstWhere((l) => !text.contains('<$l>'), orElse: () => 'iostream');

  static String _loopName(String above) {
    final used = <String>{};
    final lines = above.split('\n');
    var indent = lines.last.length - lines.last.trimLeft().length;
    for (var i = lines.length - 2; i >= 0 && indent > 0; i--) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      final d = l.length - l.trimLeft().length;
      if (d < indent) {
        indent = d;
        final m = RegExp(r'^\s*for\s*\(\s*(?:\w+\s+)?(\w+)').firstMatch(l);
        if (m != null) used.add(m[1]!);
      }
    }
    return ['i', 'j', 'k', 'l'].firstWhere((v) => !used.contains(v), orElse: () => 'i');
  }

  static String _loopVar(String above) => 'int ${_loopName(above)}';

  /// The upper limit of a new loop: n if the file has it, or the last declared int.
  static String _bound(String above) {
    final names = _declared(above, intsOnly: true);
    if (names.contains('n')) return 'n';
    return names.isEmpty ? 'n' : names.last;
  }

  static String? _cppFor(String above, String before, String after) {
    const head = r'^\s*for\s*\(\s*';
    const name = r'(?:(?:int|long long)\s+)?(\w+)';
    final open = RegExp('$head\$').hasMatch(before);
    final closer = after.startsWith(')') ? '' : ')';
    final n = _bound(above);
    if (open) {
      final v = _loopName(above);
      return 'int $v = 0; $v < $n; $v++$closer';
    }
    var m = RegExp('$head$name\$').firstMatch(before);
    if (m != null) {
      final w = m[1]!;
      if (w == 'in' || w == 'int') {
        final v = _loopName(above);
        return '${w == 'in' ? 't' : ''} $v = 0; $v < $n; $v++$closer';
      }
      return ' = 0; $w < $n; $w++$closer';
    }
    m = RegExp('$head$name\\s*=\\s*\$').firstMatch(before);
    if (m != null) return '0; ${m[1]} < $n; ${m[1]}++$closer';
    m = RegExp('$head$name\\s*=\\s*[^;]+;\\s*\$').firstMatch(before);
    if (m != null) return '${m[1]} < $n; ${m[1]}++$closer';
    m = RegExp('$head$name\\s*=\\s*[^;]+;\\s*(\\w+)\$').firstMatch(before);
    if (m != null && m[1] == m[2]) return ' < $n; ${m[1]}++$closer';
    m = RegExp('$head$name\\s*=\\s*[^;]+;\\s*(\\w+)\\s*<=?\\s*\$').firstMatch(before);
    if (m != null && m[1] == m[2]) return '$n; ${m[1]}++$closer';
    m = RegExp('$head$name\\s*=\\s*[^;]+;\\s*\\w+\\s*[<>]=?\\s*[^;]+;\\s*\$').firstMatch(before);
    if (m != null) return '${m[1]}++$closer';
    return null;
  }

  /// The plain variables declared above the caret, in order (not loop counters).
  static List<String> _declared(String above, {bool intsOnly = false}) {
    final types = intsOnly ? r'int|long long|long' : r'int|long long|long|double|float|char|string|bool';
    final out = <String>[];
    for (final line in above.split('\n')) {
      final l = line.trim();
      if (l.startsWith('for')) continue;
      for (final m in RegExp('(?:^|[;{]\\s*)(?:$types)\\s+([^;()]+);').allMatches(l)) {
        for (final part in m[1]!.split(',')) {
          final n = RegExp(r'^\s*(\w+)\s*(=.*)?$').firstMatch(part);
          if (n != null) out.add(n[1]!);
        }
      }
    }
    return out;
  }

  /// The first variable declared without a value and not read with cin yet.
  static String? _unread(String above) {
    final types = r'int|long long|long|double|float|char|string|bool';
    final read = {
      for (final c in RegExp(r'cin((?:\s*>>\s*\w+(?:\[[^\]]*\])?)+)').allMatches(above))
        for (final m in RegExp(r'>>\s*(\w+)').allMatches(c[1]!)) m[1]!,
      ...RegExp(r'>>\s*(\w+)').allMatches(above.split('\n').last).map((m) => m[1]!),
    };
    for (final line in above.split('\n')) {
      final l = line.trim();
      if (l.startsWith('for')) continue;
      for (final m in RegExp('(?:^|[;{]\\s*)(?:$types)\\s+([^;()]+);').allMatches(l)) {
        for (final part in m[1]!.split(',')) {
          final n = RegExp(r'^\s*(\w+)\s*$').firstMatch(part);
          if (n != null && !read.contains(n[1])) return n[1];
        }
      }
    }
    return null;
  }

  static String? _lastAssigned(String above) {
    String? last;
    for (final line in above.split('\n')) {
      final l = line.trim();
      if (l.startsWith('for') || l.startsWith('if') || l.startsWith('while')) continue;
      final m = RegExp(r'^(?:[\w<>]+\s+)?(\w+)\s*(?:[-+*/%]?=(?!=)|\+\+|--)').firstMatch(l);
      if (m != null) last = m[1];
      final c = RegExp(r'^cin(?:\s*>>\s*\w+)*\s*>>\s*(\w+)').firstMatch(l);
      if (c != null) last = c[1];
    }
    return last;
  }

  static String? _enclosingFunction(String above) {
    String? name;
    for (final m in RegExp(r'^\s*[\w:<>]+\s+(\w+)\s*\([^;]*\)\s*\{?\s*$', multiLine: true).allMatches(above)) {
      if (!const {'if', 'for', 'while', 'switch'}.contains(m[1])) name = m[1];
    }
    return name;
  }

  // -------------------------------------------------------------- Python
  static const List<String> _pyStatements = [
    'for i in range(n):',
    'while |:',
    'if |:',
    'elif |:',
    'else:',
    'def |():',
    'return ',
    'import math',
    'from math import ',
    'print(|)',
    'break',
    'continue',
    'class |:',
  ];
  static const List<String> _pyWords = ['range(|)', 'input()', 'print(|)', 'len(|)', 'int(|)', 'str(|)', 'float(|)', 'list(|)', 'map(int, input().split())', 'sorted(|)', 'sum(|)', 'min(|)', 'max(|)', 'abs(|)', 'True', 'False', 'None'];
  static const Map<String, String> _pyMembers = {'append': '(|)', 'split': '()', 'sort': '()', 'strip': '()', 'join': '(|)', 'pop': '()', 'insert': '(|)', 'upper': '()', 'lower': '()', 'replace': '(|)', 'items': '()', 'keys': '()', 'values': '()', 'count': '(|)', 'index': '(|)'};

  static String? _python(String text, int caret, String before) {
    if (RegExp(r'^\s*for\s+\w+\s+in\s+$').hasMatch(before)) return 'range(n):';
    if (RegExp(r'^\s*\w+\s*,\s*\w+(\s*,\s*\w+)*\s*=\s*$').hasMatch(before)) return 'map(int, input().split())';
    if (RegExp(r'^\s*\w+\s*=\s*$').hasMatch(before)) return 'int(input())';
    if (RegExp(r'^\s*\w+\s*=\s*int\($').hasMatch(before)) return _after(text, caret).startsWith(')') ? 'input()' : 'input())';
    if (RegExp(r'^\s*\w+\s*=\s*list\($').hasMatch(before)) return _after(text, caret).startsWith(')') ? 'map(int, input().split())' : 'map(int, input().split()))';
    return _fromWords(text, caret, before, _pyStatements, _pyWords, _pyMembers);
  }

  // -------------------------------------------------------------- Claude
  /// What the model answered, made to fit at [caret]; null when nothing is left.
  static Ghost? fromModel(String raw, String text, int caret) {
    if (!canComplete(text, caret)) return null;
    final before = _before(text, caret);
    final after = _after(text, caret);

    var s = raw.replaceAll('\r', '').replaceAll('\t', '    ').replaceAll('<CURSOR>', '');
    s = s.replaceFirst(RegExp(r'^\s*```[\w+]*[ \t]*\n'), '').replaceFirst(RegExp(r'\n?```\s*$'), '');

    // it may repeat what is already on the line
    final typed = before.trimLeft();
    if (typed.isNotEmpty && s.trimLeft().startsWith(typed)) s = s.trimLeft().substring(typed.length);
    if (before.trim().isEmpty) {
      s = s.trimLeft(); // the caret is already indented
    } else if (RegExp(r'[{:]\s*$').hasMatch(before) && s.startsWith(' ')) {
      s = '\n$s'; // a block's first line, answered without its line break
    }
    s = s.trimRight();

    final lines = s.split('\n');
    if (lines.length > maxLines) lines.removeRange(maxLines, lines.length);

    // closing brackets already written, on the line
    var consume = 0;
    final tail = after.trimRight();
    if (tail.isNotEmpty && _hasInOrder(lines.join('\n'), tail)) consume = after.length;

    // and on the following lines
    var next = text.substring(caret + consume).trimLeft();
    while (lines.length > 1) {
      final last = lines.last.trim();
      if (last.isEmpty || !RegExp(r'^[)\]};]+$').hasMatch(last) || !next.startsWith(last)) break;
      lines.removeLast();
      next = next.substring(last.length).trimLeft();
    }

    s = lines.join('\n').trimRight();
    if (s.trim().isEmpty) return null;
    if (consume == 0 && tail.isNotEmpty && s.contains('\n')) return null; // would land before the bracket
    return Ghost(text: s, consume: consume, fromClaude: true, forText: text, at: caret);
  }

  static bool _hasInOrder(String s, String chars) {
    var from = 0;
    for (final c in chars.split('')) {
      if (c.trim().isEmpty) continue;
      final i = s.indexOf(c, from);
      if (i < 0) return false;
      from = i + 1;
    }
    return true;
  }
}
