// The editor's keys in the ACS languages: Octave, the shell, assembly, APD.
// | is the caret.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/code_keys.dart';

TextEditingValue v(String s) {
  final c = s.indexOf('|');
  return TextEditingValue(text: s.replaceFirst('|', ''), selection: TextSelection.collapsed(offset: c));
}

String show(TextEditingValue? r) {
  if (r == null) return 'NULL';
  return r.text.replaceRange(r.selection.start, r.selection.start, '|');
}

String type(String before, String ch, String lang) => show(CodeKeys.apply(v(before), key: LogicalKeyboardKey(ch.codeUnitAt(0)), character: ch, lang: lang));
String enter(String before, String lang) => show(CodeKeys.apply(v(before), key: LogicalKeyboardKey.enter, lang: lang));
String key(String before, LogicalKeyboardKey k, String lang, {bool ctrl = false, bool shift = false, bool alt = false}) =>
    show(CodeKeys.apply(v(before), key: k, ctrl: ctrl, shift: shift, alt: alt, lang: lang));

void main() {
  group('octave', () {
    test('Enter after an opener goes one step in', () {
      expect(enter('function y = f(x)|', 'octave'), 'function y = f(x)\n    |');
      expect(enter('    for i = 1:n|', 'octave'), '    for i = 1:n\n        |');
      expect(enter('    y = 2;|', 'octave'), '    y = 2;\n    |');
      expect(enter('for i = 1:x(end)|', 'octave'), 'for i = 1:x(end)\n    |');
      expect(enter('if x, y = 1; end|', 'octave'), 'if x, y = 1; end\n|');
    });
    test('end and else go under their opener on Enter', () {
      expect(enter('function f()\n    if x\n        y = 1;\n        else|', 'octave'), 'function f()\n    if x\n        y = 1;\n    else\n        |');
      expect(enter('function f()\n    y = 1;\n    end|', 'octave'), 'function f()\n    y = 1;\nend\n|');
      expect(enter('switch k\n    case 1\n        y = 1;\n        case 2|', 'octave'), 'switch k\n    case 1\n        y = 1;\n    case 2\n        |');
      expect(enter('switch k\n    case 1\n        y = 1;\n        end|', 'octave'), 'switch k\n    case 1\n        y = 1;\nend\n|');
    });
    test("' after a name is the transpose; a string otherwise", () {
      expect(type('B = A|', "'", 'octave'), 'NULL');
      expect(type('B = (A+1)|', "'", 'octave'), 'NULL');
      expect(type('disp(|)', "'", 'octave'), "disp('|')");
    });
    test('Ctrl+/ comments with %', () {
      expect(key('x = 1;|', LogicalKeyboardKey.slash, 'octave', ctrl: true), '% x = 1;|');
    });
    test('Shift+Alt+F aligns by keywords', () {
      const src = 'function x = f(A, b)\nn = size(A, 1);\nfor i = n:-1:1\nif A(i,i) == 0\nerror("0");\nend\nx(i) = b(i) / A(i,i);\nend\nend';
      const want = 'function x = f(A, b)\n    n = size(A, 1);\n    for i = n:-1:1\n        if A(i,i) == 0\n            error("0");\n        end\n        x(i) = b(i) / A(i,i);\n    end\nend';
      expect(CodeKeys.formatAs(src, 'octave'), want);
      expect(CodeKeys.formatAs("B = A';\nif x\ny = 'a';\nend", 'octave'), "B = A';\nif x\n    y = 'a';\nend");
      expect(CodeKeys.formatAs('switch k\ncase 1\ny = 1;\notherwise\ny = 2;\nend', 'octave'), 'switch k\n    case 1\n        y = 1;\n    otherwise\n        y = 2;\nend');
    });
  });

  group('shell', () {
    test('Enter after then, do, { goes in; fi and done come back', () {
      expect(enter('if [ -f x ]; then|', 'shell'), 'if [ -f x ]; then\n    |');
      expect(enter('for f in *; do|', 'shell'), 'for f in *; do\n    |');
      expect(enter('f() {|', 'shell'), 'f() {\n    |');
      expect(enter('if [ -f x ]; then\n    echo a\n    fi|', 'shell'), 'if [ -f x ]; then\n    echo a\nfi\n|');
      expect(enter('while read l; do\n    echo \$l\n    done|', 'shell'), 'while read l; do\n    echo \$l\ndone\n|');
      expect(enter('for f in *; do echo \$f; done|', 'shell'), 'for f in *; do echo \$f; done\n|');
    });
    test('a word starting like a keyword is left alone', () {
      expect(enter('if x; then\n    file=a|', 'shell'), 'if x; then\n    file=a\n    |');
    });
    test('case branches', () {
      expect(enter('case \$1 in|', 'shell'), 'case \$1 in\n    |');
      expect(enter('case \$1 in\n    a)|', 'shell'), 'case \$1 in\n    a)\n        |');
      expect(enter('case \$1 in\n    a)\n        echo a\n        ;;|', 'shell'), 'case \$1 in\n    a)\n        echo a\n        ;;\n    |');
      expect(CodeKeys.formatAs('case \$1 in\na)\necho a\n;;\n*) echo b ;;\nesac', 'shell'), 'case \$1 in\n    a)\n        echo a\n        ;;\n    *) echo b ;;\nesac');
    });
    test('Shift+Alt+F keeps a here-document as written', () {
      expect(CodeKeys.formatAs('if x; then\ncat <<EOF\n      raw\nEOF\nfi', 'shell'), 'if x; then\n    cat <<EOF\n      raw\nEOF\nfi');
    });
  });

  group('asm', () {
    test('a label goes to the margin; Enter after it goes in', () {
      expect(type('    loop|', ':', 'asm'), 'loop:|');
      expect(type('    mov eax|', ':', 'asm'), 'NULL');
      expect(enter('loop:|', 'asm'), 'loop:\n    |');
      expect(enter('    mov eax, 1|', 'asm'), '    mov eax, 1\n    |');
    });
    test('Ctrl+/ comments with ;', () {
      expect(key('    ret|', LogicalKeyboardKey.slash, 'asm', ctrl: true), '    ; ret|');
    });
    test('Shift+Alt+F: labels and directives at the margin, instructions in', () {
      const src = 'section .text\n  global f\n; f(a)\n f:\npush ebp\n      mov ebp,esp\n  ; body\nmov eax,[ebp+8]\nret\nsection .data\n   msg db "a,b",0';
      const want = 'section .text\nglobal f\n; f(a)\nf:\n    push ebp\n    mov ebp, esp\n    ; body\n    mov eax, [ebp+8]\n    ret\nsection .data\nmsg db "a,b", 0';
      expect(CodeKeys.formatAs(src, 'asm'), want);
    });
  });

  group('apd', () {
    test('Enter after "thread A:" goes in by the file\'s own step', () {
      expect(enter('shared x = 0\nthread A:\n  x = x + 1\nthread B:|', 'apd'), 'shared x = 0\nthread A:\n  x = x + 1\nthread B:\n  |');
      expect(type('thread A:\n  lock|', '(', 'apd'), 'thread A:\n  lock(|)');
      expect(key('thread A:\n  |', LogicalKeyboardKey.backspace, 'apd'), 'thread A:\n|');
    });
  });

  test('a file\'s language by its name', () {
    expect(CodeLang.forFile('/home/s/a.c'), 'cpp');
    expect(CodeLang.forFile('run.sh'), 'shell');
    expect(CodeLang.forFile('notes.txt'), 'text');
    expect(CodeLang.forFile('Makefile'), 'text');
  });
}
