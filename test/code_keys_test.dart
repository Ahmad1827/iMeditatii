// The editor's keys, as in VS Code. In the strings, | is the caret, and
// [ ... ] marks a selection when the test needs one.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/code_keys.dart';

TextEditingValue v(String s) {
  final a = s.indexOf('«'), b = s.indexOf('»');
  if (a >= 0 && b >= 0) {
    final t = s.replaceAll('«', '').replaceAll('»', '');
    return TextEditingValue(text: t, selection: TextSelection(baseOffset: a, extentOffset: b - 1));
  }
  final c = s.indexOf('|');
  return TextEditingValue(text: s.replaceFirst('|', ''), selection: TextSelection.collapsed(offset: c));
}

String show(TextEditingValue? r) {
  if (r == null) return 'NULL';
  final s = r.selection;
  if (s.isCollapsed) return r.text.replaceRange(s.start, s.start, '|');
  return r.text.replaceRange(s.end, s.end, '»').replaceRange(s.start, s.start, '«');
}

String type(String before, String ch) => show(CodeKeys.apply(v(before), key: LogicalKeyboardKey(ch.codeUnitAt(0)), character: ch));
String key(String before, LogicalKeyboardKey k, {bool ctrl = false, bool shift = false, bool alt = false}) =>
    show(CodeKeys.apply(v(before), key: k, ctrl: ctrl, shift: shift, alt: alt));

void main() {
  group('brackets and quotes', () {
    test('an opener closes itself', () {
      expect(type('int main|', '('), 'int main(|)');
      expect(type('a = |;', '['), 'a = [|];');
      expect(type('int main() |', '{'), 'int main() {|}');
      expect(type('cout << |;', '"'), 'cout << "|";');
    });
    test('not before a word, not a quote right after a letter', () {
      expect(type('|x', '('), 'NULL');
      expect(type("don|", "'"), 'NULL');
    });
    test('inside a string or a comment it stays a single character', () {
      expect(type('cout << "a |";', '('), 'NULL');
      expect(type('// vezi |', '"'), 'NULL');
    });
    test('around a selection it wraps it', () {
      expect(type('x = «a + b»;', '('), 'x = («a + b»);');
    });
    test('a closer that is already there is stepped over', () {
      expect(type('f(x|)', ')'), 'f(x)|');
      expect(type('"ab|"', '"'), '"ab"|');
    });
    test('#include <|>', () {
      expect(type('#include |', '<'), '#include <|>');
      expect(type('if (a |', '<'), 'NULL');
    });
    test('backspace deletes an empty pair, or one indent level', () {
      expect(key('f(|)', LogicalKeyboardKey.backspace), 'f|');
      expect(key('    |', LogicalKeyboardKey.backspace), '|');
      expect(key('        |x', LogicalKeyboardKey.backspace), '    |x');
      expect(key('ab|', LogicalKeyboardKey.backspace), 'NULL');
    });
  });

  group('lines and indentation', () {
    test('enter keeps the indent and adds one after an opener', () {
      expect(key('    x = 1;|', LogicalKeyboardKey.enter), '    x = 1;\n    |');
      expect(key('int main() {|', LogicalKeyboardKey.enter), 'int main() {\n    |');
      expect(key('int main() {|}', LogicalKeyboardKey.enter), 'int main() {\n    |\n}');
      expect(key('    if (x > 0)|', LogicalKeyboardKey.enter), '    if (x > 0)\n        |');
      expect(key('    } else|', LogicalKeyboardKey.enter), '    } else\n        |');
    });
    test('a closing brace on an empty line goes under its opening brace', () {
      expect(type('int main() {\n    x;\n    |', '}'), 'int main() {\n    x;\n}|');
      expect(type('    if (a) {\n        x;\n        |', '}'), '    if (a) {\n        x;\n    }|');
      // the } that "{" already put below is not doubled
      expect(type('int main() {\n    x;\n    |\n}', '}'), 'int main() {\n    x;\n}|');
      expect(type('    if (a) {\n        |\n    }\n}', '}'), '    if (a) {\n    }|\n}');
    });
    test('tab and shift+tab indent and outdent the lines', () {
      expect(key('«a\nb»', LogicalKeyboardKey.tab), '«    a\n    b»');
      expect(key('«    a\n    b»', LogicalKeyboardKey.tab, shift: true), '«a\nb»');
      expect(key('    a|', LogicalKeyboardKey.tab, shift: true), 'a|');
    });
    test('ctrl+/ comments and uncomments, the marks lined up', () {
      expect(key('«    a;\n        b;»', LogicalKeyboardKey.slash, ctrl: true), '«    // a;\n    //     b;»');
      expect(key('    // a;|', LogicalKeyboardKey.slash, ctrl: true), '    a;|');
    });
    test('alt+arrows move a line, shift+alt+arrows copy it, ctrl+shift+K deletes it', () {
      expect(key('a\nb|\nc', LogicalKeyboardKey.arrowUp, alt: true), 'b|\na\nc');
      expect(key('a|\nb\nc', LogicalKeyboardKey.arrowDown, alt: true), 'b\na|\nc');
      expect(key('a|\nb', LogicalKeyboardKey.arrowDown, alt: true, shift: true), 'a\na|\nb');
      expect(key('a\nb|\nc', LogicalKeyboardKey.keyK, ctrl: true, shift: true), 'a\n|c');
    });
    test('home goes to the first character, then to the margin', () {
      expect(key('    x = 1;|', LogicalKeyboardKey.home), '    |x = 1;');
      expect(key('    |x = 1;', LogicalKeyboardKey.home), '|    x = 1;');
    });
  });

  group('align the code (Shift+Alt+F)', () {
    test('re-indents by braces, a switch, one-line bodies and preprocessor lines', () {
      const messy = '''
  #include <iostream>
using namespace std;
int main() {
int n;
      cin >> n;
for (int i = 0; i < n; i++) {
if (i % 2 == 0)
cout << i;
else
cout << -i;
     }
switch (n) {
case 1:
cout << "unu";
break;
default:
cout << "{nu}";
}
    return 0;
        }''';
      const tidy = '''
#include <iostream>
using namespace std;
int main() {
    int n;
    cin >> n;
    for (int i = 0; i < n; i++) {
        if (i % 2 == 0)
            cout << i;
        else
            cout << -i;
    }
    switch (n) {
        case 1:
            cout << "unu";
            break;
        default:
            cout << "{nu}";
    }
    return 0;
}''';
      expect(CodeKeys.format(messy), tidy);
      expect(CodeKeys.format(tidy), tidy); // already aligned: nothing changes
    });
    test('a block inside a one-line body keeps the body\'s indent; a { on its own line too', () {
      const nested = 'int main() {\nfor (int i = 0; i < n; i++)\nfor (int j = 0; j < n; j++) {\ncin >> x;\n}\ncout << s;\n}';
      expect(CodeKeys.format(nested),
          'int main() {\n    for (int i = 0; i < n; i++)\n        for (int j = 0; j < n; j++) {\n            cin >> x;\n        }\n    cout << s;\n}');
      const allman = 'int main()\n{\nif (x)\n{\na;\n}\nb;\n}';
      expect(CodeKeys.format(allman), 'int main()\n{\n    if (x)\n    {\n        a;\n    }\n    b;\n}');
      expect(CodeKeys.format('}\nint x;'), '}\nint x;'); // a stray } does not break it
      const dangling = 'for (i = 0; i < n; i++)\nif (a) x = 1;\nelse x = 2;\ny = 3;';
      expect(CodeKeys.format(dangling), 'for (i = 0; i < n; i++)\n    if (a) x = 1;\n    else x = 2;\ny = 3;');
      const elseBody = 'if (a)\nx = 1;\nelse\nx = 2;\ny = 3;';
      expect(CodeKeys.format(elseBody), 'if (a)\n    x = 1;\nelse\n    x = 2;\ny = 3;');
    });
    test('the caret stays on its token', () {
      final r = CodeKeys.apply(v('int main() {\nreturn |0;\n}'), key: LogicalKeyboardKey.keyF, shift: true, alt: true);
      expect(show(r), 'int main() {\n    return |0;\n}');
    });
  });
}
