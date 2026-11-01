// The grey suggestion after the caret. In the strings, | is the caret.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/code_complete.dart';

Ghost? local(String s, {String lang = 'cpp'}) {
  final c = s.indexOf('|');
  return CodeComplete.suggest(s.replaceFirst('|', ''), c, lang: lang);
}

Ghost? model(String raw, String s) {
  final c = s.indexOf('|');
  return CodeComplete.fromModel(raw, s.replaceFirst('|', ''), c);
}

/// The code after accepting, with | at the caret.
String accepted(Ghost g) {
  final v = TextEditingValue(text: g.forText, selection: TextSelection.collapsed(offset: g.at));
  final n = CodeComplete.apply(g, v);
  return n.text.replaceRange(n.selection.baseOffset, n.selection.baseOffset, '|');
}

void main() {
  group('built in, C++', () {
    test('a for loop finishes itself, with the file\'s n', () {
      expect(local('int n;\nfor (int i|)')!.text, ' = 0; i < n; i++');
      expect(local('int n;\nfor (|)')!.text, 'int i = 0; i < n; i++');
      expect(local('for (int i = 0; |)')!.text, 'i < n; i++');
      expect(local('for (int i = 0; i < n; |)')!.text, 'i++');
    });

    test('a for without the closing bracket gets one', () {
      expect(local('for (int i|')!.text, ' = 0; i < n; i++)');
    });

    test('the limit is the last int when there is no n', () {
      expect(local('int m;\nfor (int i|)')!.text, ' = 0; i < m; i++');
    });

    test('a loop inside a loop takes the next letter', () {
      expect(local('int n;\nfor (int i = 0; i < n; i++) {\n    for (|)\n}')!.text, 'int j = 0; j < n; j++');
    });

    test('cin reads the variable not read yet', () {
      expect(local('int n, m;\ncin >> |')!.text, 'n;');
      expect(local('int n, m;\ncin >> n;\ncin >> |')!.text, 'm;');
      expect(local('int n, m;\ncin >> n >> |')!.text, 'm;');
      expect(local('int n = 5;\ncin >> |'), isNull);
      expect(local('int main() {\n    int n, s = 0;\n    cin >> |')!.text, 'n;');
    });

    test('cout writes the last value computed', () {
      expect(local('int s = 0;\ns = s + 1;\ncout << |')!.text, 's << "\\n";');
    });

    test('return in main is return 0, elsewhere it is not guessed', () {
      expect(local('int main() {\n    return |')!.text, '0;');
      expect(local('int f(int x) {\n    return |'), isNull);
    });

    test('includes', () {
      expect(local('#inc|')!.text, 'lude <iostream>');
      expect(local('#include <iostream>\n#inc|')!.text, 'lude <fstream>');
      expect(local('#include <alg|')!.text, 'orithm>');
    });

    test('a keyword puts the caret where the code goes', () {
      expect(accepted(local('whi|')!), 'while (|)');
    });

    test('names from the file, the closest one above', () {
      expect(local('int suma_cifre = 0;\nint x = sum|')!.text, 'a_cifre');
    });

    test('a member after a dot', () {
      expect(accepted(local('v.pu|')!), 'v.push_back(|)');
      expect(local('v.si|')!.text, 'ze()');
    });

    test('quiet in comments, strings, an empty line and in the middle of a line', () {
      expect(local('// whi|'), isNull);
      expect(local('cout << "whi|'), isNull);
      expect(local('int n;\n    |'), isNull);
      expect(local('whi| x = 3;'), isNull);
    });

    test('one letter is not enough', () {
      expect(local('w|'), isNull);
    });
  });

  group('built in, Python', () {
    test('input and loops', () {
      expect(local('n = |', lang: 'python')!.text, 'int(input())');
      expect(local('a, b = |', lang: 'python')!.text, 'map(int, input().split())');
      expect(local('for i in |', lang: 'python')!.text, 'range(n):');
      expect(accepted(local('pri|', lang: 'python')!), 'print(|)');
      expect(local('n = int(|)', lang: 'python')!.text, 'input()');
    });

    test('quiet in a comment', () {
      expect(local('# pri|', lang: 'python'), isNull);
    });
  });

  group('what Claude answers', () {
    test('code fences go away', () {
      expect(model('```cpp\nreturn 0;\n```', 'int main() {\n    |')!.text, 'return 0;');
    });

    test('the indent is not doubled on an indented line', () {
      expect(model('    while (n) {\n        n--;\n    }', '    |')!.text, 'while (n) {\n        n--;\n    }');
    });

    test('tabs become spaces', () {
      expect(model('if (a) {\n\tb();\n}', '|')!.text, 'if (a) {\n    b();\n}');
    });

    test('what is on the line already is not written twice', () {
      expect(model('int s = 0;', '    int s|')!.text, ' = 0;');
    });

    test('a block\'s first line goes on a new line', () {
      expect(model('    return a;\n}', 'int f(int a) {|')!.text, '\n    return a;\n}');
    });

    test('a bracket the answer writes too replaces the one after the caret', () {
      final g = model('i < n; i++) {\n    cin >> v[i];\n}', 'for (int i = 0; |)')!;
      expect(accepted(g), 'for (int i = 0; i < n; i++) {\n    cin >> v[i];\n}|');
    });

    test('a bracket it does not write stays', () {
      expect(accepted(model('i < n; i++', 'for (int i = 0; |)')!), 'for (int i = 0; i < n; i++|)');
    });

    test('a closing line that already follows is dropped', () {
      expect(model('s += n;\n}', 'int f() {\n    |\n}')!.text, 's += n;');
    });

    test('several lines that would land before a bracket are refused', () {
      expect(model('a,\nb', 'f(|)'), isNull);
    });

    test('an empty answer is no suggestion', () {
      expect(model('  \n', 'int n;|'), isNull);
    });

    test('a very long answer is cut', () {
      final g = model(List.generate(40, (i) => 'x$i;').join('\n'), '|')!;
      expect('\n'.allMatches(g.text).length + 1, CodeComplete.maxLines);
    });
  });

  test('a suggestion is valid only for its own text and caret', () {
    final g = local('whi|')!;
    expect(g.matches(const TextEditingValue(text: 'whi', selection: TextSelection.collapsed(offset: 3))), isTrue);
    expect(g.matches(const TextEditingValue(text: 'whil', selection: TextSelection.collapsed(offset: 4))), isFalse);
    expect(g.matches(const TextEditingValue(text: 'whi', selection: TextSelection.collapsed(offset: 1))), isFalse);
  });
}
