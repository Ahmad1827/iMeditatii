import 'dart:math' as math;

import 'code_keys.dart';

// =============================================================================
// CODING STYLE CHECK
//   What a teacher would circle on a printed program: indentation, spaces
//   around operators and after commas, brackets without a pair, two
//   statements on one line... Each issue has its place in the code (drawn as
//   a squiggle in the editor) and, when there is one, a fix. Pure: code in,
//   issues out, so it is tested without a widget.
//
//   [CodeStyle.fromCompiler] turns the compiler's (or Python's) errors into
//   issues of the same kind, explained in Romanian.
// =============================================================================

enum IssueLevel { error, warning, hint }

/// Replace [start, end) of the code with [text].
class StyleFix {
  final int start;
  final int end;
  final String text;
  const StyleFix(this.start, this.end, this.text);
}

class StyleIssue {
  final int line; // 1-based
  final int col; // 0-based, in the line
  final int len; // 0 = the whole line
  final IssueLevel level;
  final String message;
  final String detail; // the compiler's own words, for its errors
  final StyleFix? fix;
  final bool fromCompiler;

  const StyleIssue(this.line, this.col, this.len, this.level, this.message, {this.detail = '', this.fix, this.fromCompiler = false});

  @override
  String toString() => '$line:$col ${level.name} $message';
}

class CodeStyle {
  static const int maxLine = 100;

  /// The style issues of [code], in the order of the lines.
  static List<StyleIssue> check(String code, {String lang = 'cpp'}) {
    if (code.trim().isEmpty) return const [];
    final c = _Check(code, lang);
    lang == 'python' ? c.python() : c.cpp();
    c.out.sort((a, b) => a.line != b.line ? a.line - b.line : a.col - b.col);
    return c.out;
  }

  /// 100 for a clean program; an error costs 10, a warning 3, a hint 1.
  static int score(List<StyleIssue> issues) {
    var s = 100;
    for (final i in issues) {
      s -= switch (i.level) { IssueLevel.error => 10, IssueLevel.warning => 3, IssueLevel.hint => 1 };
    }
    return math.max(0, s);
  }

  /// [code] with the fixes of [issues] applied (the ones that don't overlap).
  static String fixAll(String code, List<StyleIssue> issues) {
    final fixes = [for (final i in issues) if (i.fix != null) i.fix!]..sort((a, b) => b.start - a.start);
    var out = code;
    var limit = code.length + 1;
    for (final f in fixes) {
      if (f.end > limit || f.end > out.length) continue; // overlaps a fix already made
      out = out.replaceRange(f.start, f.end, f.text);
      limit = f.start;
    }
    return out;
  }

  // ---------------------------------------------------------------- compiler
  static final RegExp _gcc = RegExp(r'^[^\n:]*:(\d+):(\d+):\s*(fatal error|error|warning):\s*(.+)$', multiLine: true);
  static final RegExp _pyLine = RegExp(r'line (\d+)');

  /// The errors in a run's [output] (compile errors, a Python traceback) as
  /// issues on the lines of [code].
  static List<StyleIssue> fromCompiler(String output, String code, {String lang = 'cpp'}) {
    if (output.trim().isEmpty) return const [];
    final lines = code.split('\n');
    final out = <StyleIssue>[];
    if (lang == 'python') {
      final at = _pyLine.allMatches(output).toList();
      if (at.isEmpty) return const [];
      final line = int.parse(at.last.group(1)!);
      final last = output.trim().split('\n').last.trim();
      final text = line <= lines.length ? lines[line - 1] : '';
      final col = text.length - text.trimLeft().length;
      out.add(StyleIssue(line, col, math.max(1, text.trim().length), IssueLevel.error, _explainPython(last), detail: last, fromCompiler: true));
      return out;
    }
    final seen = <String>{};
    for (final m in _gcc.allMatches(output)) {
      final line = int.parse(m.group(1)!);
      if (line < 1 || line > lines.length) continue;
      final col = math.max(0, int.parse(m.group(2)!) - 1);
      final raw = m.group(4)!.trim();
      if (!seen.add('$line:$col:$raw')) continue;
      final text = lines[line - 1];
      final word = RegExp(r'^\w+').stringMatch(col < text.length ? text.substring(col) : '') ?? '';
      out.add(StyleIssue(
        line,
        math.min(col, text.length),
        math.max(1, word.length),
        m.group(3) == 'warning' ? IssueLevel.warning : IssueLevel.error,
        _explainCpp(raw),
        detail: raw,
        fromCompiler: true,
      ));
    }
    return out;
  }

  static String _name(String msg) => RegExp(r"[‘'`]([^’'`]+)[’'`]").firstMatch(msg)?.group(1) ?? '';

  static String _explainCpp(String msg) {
    final m = msg.toLowerCase();
    final name = _name(msg);
    if (m.contains("expected ';'")) return 'Lipsește `;` (de obicei la sfârșitul instrucțiunii de dinainte).';
    if (m.contains("expected '}'")) return 'Lipsește o acoladă `}`.';
    if (m.contains("expected ')'")) return 'Lipsește o paranteză `)`.';
    if (m.contains("expected ']'")) return 'Lipsește o paranteză `]`.';
    if (m.contains('was not declared') || m.contains('undeclared identifier')) {
      if (const {'cout', 'cin', 'endl', 'vector', 'string', 'sort', 'max', 'min', 'swap', 'ifstream', 'ofstream'}.contains(name)) {
        return '`$name` nu e cunoscut: lipsește `#include`-ul potrivit sau `using namespace std;`.';
      }
      return name.isEmpty ? 'Un nume nu e declarat.' : '`$name` nu e declarat: declară-l (de ex. `int $name;`) sau verifică scrierea.';
    }
    if (m.contains('redefinition') || m.contains('conflicting declaration')) {
      return name.isEmpty ? 'Un nume e declarat de două ori.' : '`$name` e declarat de două ori.';
    }
    if (m.contains('too few arguments')) return 'Funcția primește mai multe argumente decât i-ai dat.';
    if (m.contains('too many arguments')) return 'Funcția primește mai puține argumente decât i-ai dat.';
    if (m.contains('cannot convert') || m.contains('no viable conversion') || m.contains('invalid conversion')) {
      return 'Tipurile nu se potrivesc (de ex. un șir pus într-un `int`).';
    }
    if (m.contains('no match for') || m.contains('invalid operands')) return 'Operația nu merge pentru tipurile acestea.';
    if (m.contains('control reaches end') || m.contains('does not return a value')) {
      return 'Funcția poate ajunge la final fără `return`.';
    }
    if (m.contains('unused variable')) return name.isEmpty ? 'O variabilă nu e folosită.' : '`$name` e declarată, dar nu e folosită.';
    if (m.contains('uninitialized') || m.contains('may be used uninitialized')) {
      return name.isEmpty ? 'O variabilă e folosită înainte să primească o valoare.' : '`$name` e folosită înainte să primească o valoare.';
    }
    if (m.contains('expected expression') || m.contains('expected primary-expression')) return 'Aici lipsește o expresie.';
    if (m.contains('expected unqualified-id') || m.contains('expected identifier')) return 'Aici se aștepta un nume.';
    if (m.contains('comparison of integers of different signs') || m.contains('comparison of integer expressions of different signedness')) {
      return 'Compari un număr cu semn cu unul fără semn (de ex. `int` cu `.size()`).';
    }
    if (m.contains('file not found') || m.contains('no such file')) return 'Fișierul inclus nu există: verifică numele din `#include`.';
    if (m.contains('suggest parentheses') || m.contains('using the result of an assignment')) {
      return 'Ai scris `=` (atribuire) unde probabil voiai `==` (comparație).';
    }
    return 'Eroare de compilare.';
  }

  static String _explainPython(String last) {
    final name = _name(last);
    if (last.startsWith('NameError')) return name.isEmpty ? 'Un nume nu e definit.' : '`$name` nu e definit: atribuie-i o valoare înainte.';
    if (last.startsWith('IndentationError') || last.startsWith('TabError')) return 'Indentare greșită: blocurile se aliniază cu 4 spații.';
    if (last.startsWith('SyntaxError')) return 'Eroare de sintaxă (de ex. lipsește `:` sau o paranteză).';
    if (last.startsWith('ZeroDivisionError')) return 'Împărțire la zero.';
    if (last.startsWith('IndexError')) return 'Indicele e în afara listei.';
    if (last.startsWith('KeyError')) return 'Cheia nu există în dicționar.';
    if (last.startsWith('ValueError') && last.contains('invalid literal')) {
      return 'Datele de intrare nu sunt un număr: verifică tab-ul Date de intrare.';
    }
    if (last.startsWith('EOFError')) return 'Programul citește mai mult decât e în Date de intrare.';
    if (last.startsWith('TypeError')) return 'Tipuri nepotrivite (de ex. un număr adunat cu un șir).';
    if (last.startsWith('AttributeError')) return 'Obiectul nu are metoda sau câmpul acesta.';
    if (last.startsWith('RecursionError')) return 'Recursivitate prea adâncă: verifică oprirea funcției.';
    return 'Eroare la rulare.';
  }
}

class _Check {
  final String code;
  final String lang;
  final List<String> lines;
  final List<String> blank; // the lines with comments and strings blanked
  final List<int> starts; // offset of each line in [code]
  final out = <StyleIssue>[];

  _Check(this.code, this.lang)
      : lines = code.split('\n'),
        blank = (lang == 'python' ? _maskPython(code) : CodeKeys.mask(code)).split('\n'),
        starts = _starts(code);

  static List<int> _starts(String code) {
    final s = <int>[0];
    for (var i = 0; i < code.length; i++) {
      if (code.codeUnitAt(i) == 10) s.add(i + 1);
    }
    return s;
  }

  void add(int i, int col, int len, IssueLevel level, String msg, {StyleFix? fix}) =>
      out.add(StyleIssue(i + 1, col, len, level, msg, fix: fix));

  /// A fix on line [i], columns [a, b).
  StyleFix fixAt(int i, int a, int b, String text) => StyleFix(starts[i] + a, starts[i] + b, text);

  static String _lead(String s) => RegExp(r'^[ \t]*').stringMatch(s) ?? '';

  // ---------------------------------------------------------------- C++
  void cpp() {
    final balanced = brackets();
    if (balanced) indentation();
    for (var i = 0; i < lines.length; i++) {
      final b = i < blank.length ? blank[i] : lines[i];
      if (b.trimLeft().startsWith('#')) {
        common(i);
        continue;
      }
      common(i);
      commas(i, b);
      keywords(i, b);
      operators(i, b, stream: RegExp(r'\b(cin|cout|cerr|fin|fout)\b').hasMatch(b));
      forHeader(i, b);
      statements(i, b);
    }
    blankRuns();
  }

  /// Every ( [ { with its closer; false when one is missing.
  bool brackets() {
    const open = {'(': ')', '[': ']', '{': '}'};
    const name = {'(': 'Paranteza', '[': 'Paranteza', '{': 'Acolada', ')': 'Paranteza', ']': 'Paranteza', '}': 'Acolada'};
    final stack = <(String, int, int)>[];
    var ok = true;
    for (var i = 0; i < blank.length; i++) {
      final b = blank[i];
      if (b.trimLeft().startsWith('#')) continue;
      for (var j = 0; j < b.length; j++) {
        final ch = b[j];
        if (open.containsKey(ch)) {
          stack.add((ch, i, j));
        } else if (ch == ')' || ch == ']' || ch == '}') {
          if (stack.isEmpty) {
            add(i, j, 1, IssueLevel.error, '${name[ch]} `$ch` nu are pereche deschisă.');
            ok = false;
          } else if (open[stack.last.$1] != ch) {
            final o = stack.last;
            add(i, j, 1, IssueLevel.error, 'Se aștepta `${open[o.$1]}` (pentru `${o.$1}` de pe linia ${o.$2 + 1}), nu `$ch`.');
            ok = false;
            stack.removeLast();
          } else {
            stack.removeLast();
          }
        }
      }
    }
    for (final o in stack) {
      add(o.$2, o.$3, 1, IssueLevel.error, '${name[o.$1]} `${o.$1}` deschisă aici nu e închisă.');
      ok = false;
    }
    return ok;
  }

  /// Each line indented as Shift+Alt+F would indent it.
  void indentation() {
    final want = CodeKeys.format(code).split('\n');
    if (want.length != lines.length) return;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      final got = _lead(l);
      final exp = _lead(want[i]);
      if (got == exp) continue;
      final word = RegExp(r'^\S+').stringMatch(l.substring(got.length)) ?? '';
      final where = got.isEmpty ? (0, math.max(1, word.length)) : (0, got.length);
      final msg = got.contains('\t')
          ? 'Indentează cu spații, nu cu Tab (aici ${exp.length} spații).'
          : 'Indentare: aici ${exp.isEmpty ? 'fără spații la început' : '${exp.length} spații'}, nu ${got.length}.';
      add(i, where.$1, where.$2, IssueLevel.warning, msg, fix: fixAt(i, 0, got.length, exp));
    }
  }

  /// Trailing spaces and lines that are too long, in any language.
  void common(int i) {
    final l = lines[i];
    if (l.trim().isNotEmpty && l != l.trimRight()) {
      final t = l.trimRight().length;
      add(i, t, l.length - t, IssueLevel.hint, 'Spații la sfârșitul liniei.', fix: fixAt(i, t, l.length, ''));
    }
    if (l.length > CodeStyle.maxLine) {
      add(i, CodeStyle.maxLine, l.length - CodeStyle.maxLine, IssueLevel.hint,
          'Linie prea lungă (${l.length} caractere): împarte-o, sub ${CodeStyle.maxLine}.');
    }
  }

  void commas(int i, String b) {
    for (final m in RegExp(r',(?=[^\s\n])').allMatches(b)) {
      add(i, m.start, 1, IssueLevel.warning, 'Pune un spațiu după virgulă.', fix: fixAt(i, m.end, m.end, ' '));
    }
    for (final m in RegExp(r'(?<=\S)[ \t]+,').allMatches(b)) {
      add(i, m.start, m.end - m.start, IssueLevel.warning, 'Fără spațiu înainte de virgulă.', fix: fixAt(i, m.start, m.end - 1, ''));
    }
  }

  void keywords(int i, String b) {
    final kw = lang == 'python' ? r'if|elif|while|for|return|in|not|and|or' : r'if|for|while|switch|catch';
    for (final m in RegExp('\\b($kw)\\(').allMatches(b)) {
      final k = m.group(1)!;
      add(i, m.start, k.length + 1, IssueLevel.warning, 'Pune un spațiu între `$k` și `(`.', fix: fixAt(i, m.start + k.length, m.start + k.length, ' '));
    }
    if (lang == 'python') return;
    for (final m in RegExp(r'\)\{').allMatches(b)) {
      add(i, m.start, 2, IssueLevel.warning, 'Pune un spațiu înainte de `{`.', fix: fixAt(i, m.start + 1, m.start + 1, ' '));
    }
    for (final m in RegExp(r'\belse\{').allMatches(b)) {
      add(i, m.start, 5, IssueLevel.warning, 'Pune un spațiu între `else` și `{`.', fix: fixAt(i, m.start + 4, m.start + 4, ' '));
    }
    for (final m in RegExp(r'\}else\b').allMatches(b)) {
      add(i, m.start, 5, IssueLevel.warning, 'Pune un spațiu între `}` și `else`.', fix: fixAt(i, m.start + 1, m.start + 1, ' '));
    }
  }

  // % and / are always between two operands (+ - * are not: -x, *p, a++)
  static final RegExp _ops = RegExp(r'<<=|>>=|==|!=|<=|>=|&&|\|\||\+=|-=|\*=|/=|%=|<<|>>|(?<![=!<>+\-*/%&|^\[:])=(?!=)|%(?!=)|/(?![=/*])');
  static final RegExp _pyOps = RegExp(r'==|!=|<=|>=|\+=|-=|\*=|//=|/=|%=|(?<![=!<>+\-*/%&|^:])=(?!=)|//(?!=)|%(?!=)|/(?![=/])');

  /// Spaces around ==, =, &&, <<... (<< and >> only on lines that read or write).
  void operators(int i, String b, {bool stream = false, Set<int> skip = const {}}) {
    final re = lang == 'python' ? _pyOps : _ops;
    for (final m in re.allMatches(b)) {
      final op = m.group(0)!;
      if ((op == '<<' || op == '>>') && !stream) continue;
      if (skip.contains(m.start)) continue;
      if (m.start >= 8 && b.substring(m.start - 8, m.start) == 'operator') continue;
      final before = m.start == 0 || b.substring(0, m.start).trim().isEmpty || b[m.start - 1] == ' ';
      final after = m.end >= b.length || b[m.end] == ' ';
      if (before && after) continue;
      add(i, m.start, op.length, IssueLevel.warning, 'Pune câte un spațiu de o parte și de alta a lui `$op`.',
          fix: fixAt(i, m.start, m.end, '${before ? '' : ' '}$op${after ? '' : ' '}'));
    }
    if (lang == 'python') return;
    // < and > as comparisons, in the head of an if / for / while (no templates there)
    final head = RegExp(r'\b(if|for|while)\s*\(').firstMatch(b);
    if (head == null) return;
    // pair<int, int>, vector<vector<int>>: a type, not two comparisons
    final types = <int>{};
    for (final t in RegExp(r'(?<=\w)<[\w:, *&<>]*>').allMatches(b, head.end)) {
      for (var k = t.start; k < t.end; k++) {
        types.add(k);
      }
    }
    for (final m in RegExp(r'(?<![<>\-])[<>](?![<>=])').allMatches(b, head.end)) {
      if (types.contains(m.start)) continue;
      final op = m.group(0)!;
      final before = b[m.start - 1] == ' ';
      final after = m.end >= b.length || b[m.end] == ' ';
      if (before && after) continue;
      add(i, m.start, 1, IssueLevel.warning, 'Pune câte un spațiu de o parte și de alta a lui `$op`.',
          fix: fixAt(i, m.start, m.end, '${before ? '' : ' '}$op${after ? '' : ' '}'));
    }
  }

  /// for (i = 0;i < n;i++): a space after each ;
  void forHeader(int i, String b) {
    final head = RegExp(r'\bfor\s*\(').firstMatch(b);
    if (head == null) return;
    var depth = 1;
    for (var j = head.end; j < b.length && depth > 0; j++) {
      final ch = b[j];
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      if (ch == ';' && depth == 1 && j + 1 < b.length && b[j + 1] != ' ' && b[j + 1] != ')' && b[j + 1] != ';') {
        add(i, j, 1, IssueLevel.warning, 'Pune un spațiu după `;` în `for`.', fix: fixAt(i, j + 1, j + 1, ' '));
      }
    }
  }

  /// a = 1; b = 2;  on one line
  void statements(int i, String b) {
    var depth = 0;
    for (var j = 0; j < b.length; j++) {
      final ch = b[j];
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      if (ch != ';' || depth > 0) continue;
      final rest = b.substring(j + 1).trim();
      if (rest.isEmpty || rest.startsWith('}') || rest.startsWith(';')) continue;
      final next = b.indexOf(RegExp(r'\S'), j + 1);
      add(i, next, b.trimRight().length - next, IssueLevel.hint, 'O singură instrucțiune pe linie: mut-o pe linia următoare.',
          fix: fixAt(i, j + 1, next, '\n${_lead(lines[i])}'));
      return;
    }
  }

  /// More than one empty line in a row.
  void blankRuns() {
    var run = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) {
        run++;
        if (run == 2 && i + 1 < lines.length) {
          add(i, 0, 0, IssueLevel.hint, 'Cel mult o linie goală între bucăți de cod.', fix: StyleFix(starts[i], starts[i + 1], ''));
        }
      } else {
        run = 0;
      }
    }
  }

  // ---------------------------------------------------------------- Python
  void python() {
    var paren = 0; // open brackets before this line: a call over several lines
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final b = i < blank.length ? blank[i] : l;
      common(i);
      if (l.trim().isNotEmpty && paren == 0) {
        final lead = _lead(l);
        if (lead.contains('\t')) {
          final fixed = lead.replaceAll('\t', '    ');
          add(i, 0, lead.length, IssueLevel.warning, 'Indentează cu spații, nu cu Tab.', fix: fixAt(i, 0, lead.length, fixed));
        } else if (lead.length % 4 != 0) {
          add(i, 0, math.max(1, lead.length), IssueLevel.warning, 'Indentarea în Python: câte 4 spații pe nivel (aici ${lead.length}).');
        }
      }
      // = inside brackets is a keyword argument: f(x=1), no spaces there
      final skip = <int>{};
      var d = paren;
      for (var j = 0; j < b.length; j++) {
        final ch = b[j];
        if ('([{'.contains(ch)) d++;
        if (')]}'.contains(ch)) d--;
        if (ch == '=' && d > 0) skip.add(j);
      }
      commas(i, b);
      keywords(i, b);
      operators(i, b, skip: skip);
      if (RegExp(r';\s*\S').hasMatch(b)) {
        final at = b.indexOf(';');
        add(i, at, 1, IssueLevel.hint, 'O singură instrucțiune pe linie.');
      }
      paren = math.max(0, d);
    }
    blankRuns();
  }

  static String _maskPython(String text) {
    final b = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == '#') {
        while (i < text.length && text[i] != '\n') {
          b.write(' ');
          i++;
        }
        continue;
      }
      if (c == '"' || c == "'") {
        final triple = text.startsWith(c * 3, i);
        final close = triple ? c * 3 : c;
        b.write(close);
        i += close.length;
        while (i < text.length && !text.startsWith(close, i) && (triple || text[i] != '\n')) {
          if (text[i] == '\\' && i + 1 < text.length) {
            b.write(text[i + 1] == '\n' ? ' \n' : '  ');
            i += 2;
            continue;
          }
          b.write(text[i] == '\n' ? '\n' : ' ');
          i++;
        }
        if (text.startsWith(close, i)) {
          b.write(close);
          i += close.length;
        }
        continue;
      }
      b.write(c);
      i++;
    }
    return b.toString();
  }
}
