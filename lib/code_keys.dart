import 'dart:math' as math;

import 'package:flutter/services.dart';

// =============================================================================
// EDITING KEYS, AS IN VS CODE
//   One place for what a key does to the code, shared by every editor in the
//   app (the problem page, the workbench, the ACS workspaces). Pure: text and
//   selection in, text and selection out, so it is tested without a widget.
//   [CodeLang] says what a language changes: its comment mark, what opens a
//   block (C's {, Python's and APD's :, Octave's if … end, the shell's
//   then … fi, an assembly label) and how Shift+Alt+F aligns it.
//
//   ( [ { " '        close themselves; around a selection they wrap it
//   ) ] } " '        typed before the same closer step over it
//   Backspace        deletes an empty pair, or one indent level of spaces
//   Enter            keeps the indent, one more after { ( [ or "else"/"if (…)"
//                    (Octave: if/for/function…, shell: then/do/case, asm: "loop:")
//   }                on an empty line lines up with its {
//   end, else, fi…   go under their block's opener on Enter (Octave, shell)
//   :                after a word alone on its line, the label goes to the margin (asm)
//   Tab / Shift+Tab  indent / outdent (the selected lines, or the caret's line)
//   Ctrl+/           comments or uncomments the lines
//   Alt+↑ / Alt+↓    moves the lines up / down
//   Shift+Alt+↑ / ↓  copies the lines up / down
//   Ctrl+Shift+K     deletes the lines
//   Ctrl+] / Ctrl+[  indent / outdent the lines
//   Home             to the first character of the line, then to column 0
//   Shift+Alt+F      aligns the whole file (see [CodeKeys.formatAs])
// =============================================================================

/// What the keys know of a language: its line comment, how its blocks open
/// and close, and whether Shift+Alt+F can align it.
class CodeLang {
  final String id;
  final String comment; // the line comment mark
  final bool braces; // C: lone bodies after if (…), #include <>, Shift+Alt+F by braces
  final bool colon; // Python, APD: a line ending in ':' opens a block
  final bool transpose; // Octave: ' after a name or a closer is the transpose, not a quote
  final bool detectIndent; // the indent step is read from the file (2 or 4 spaces)
  const CodeLang(this.id, this.comment, {this.braces = false, this.colon = false, this.transpose = false, this.detectIndent = false});

  static const c = CodeLang('cpp', '//', braces: true);
  static const python = CodeLang('python', '#', colon: true);
  static const apd = CodeLang('apd', '#', colon: true, detectIndent: true);
  static const asm = CodeLang('asm', ';');
  static const octave = CodeLang('octave', '%', transpose: true);
  static const shell = CodeLang('shell', '#', detectIndent: true);
  static const text = CodeLang('text', '#', detectIndent: true);

  static CodeLang of(String lang) => switch (lang) {
        'python' => python,
        'apd' => apd,
        'asm' => asm,
        'octave' || 'matlab' => octave,
        'shell' || 'bash' || 'sh' => shell,
        'text' || 'cfg' => text,
        _ => c,
      };

  /// The language of a file by its name (the shell's editor).
  static String forFile(String path) {
    final name = path.split('/').last.toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1);
    return switch (ext) {
      'c' || 'h' || 'cpp' || 'cc' || 'hpp' || 'java' || 'js' => 'cpp',
      'py' => 'python',
      'asm' || 's' || 'nasm' => 'asm',
      'm' => 'octave',
      'sh' || 'bash' || '' => name == 'makefile' ? 'text' : 'shell',
      _ => 'text',
    };
  }

  bool get keywords => this == octave || this == shell;
  bool get formats => braces || keywords || this == asm;
}

class CodeKeys {
  static const String tab = '    ';
  static const Map<String, String> pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};

  /// What [key] (with [character], the text it types) does to [v]; null when
  /// the text field should handle it itself.
  static TextEditingValue? apply(
    TextEditingValue v, {
    required LogicalKeyboardKey key,
    String? character,
    bool ctrl = false,
    bool shift = false,
    bool alt = false,
    String lang = 'cpp',
  }) {
    final sel = v.selection;
    if (!sel.isValid) return null;
    final text = v.text;
    final L = CodeLang.of(lang);
    final e = _Edit(text, sel, L, L.detectIndent ? indentOf(text) : tab);

    if (shift && alt && key == LogicalKeyboardKey.keyF) {
      return L.formats ? formatValue(v, lang: lang) : null;
    }
    if (ctrl && key == LogicalKeyboardKey.slash) return e.toggleComment(L.comment);
    if (ctrl && shift && key == LogicalKeyboardKey.keyK) return e.deleteLines();
    if (ctrl && key == LogicalKeyboardKey.bracketRight) return e.indentLines(outdent: false);
    if (ctrl && key == LogicalKeyboardKey.bracketLeft) return e.indentLines(outdent: true);
    if (alt && (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown)) {
      final down = key == LogicalKeyboardKey.arrowDown;
      return shift ? e.copyLines(down: down) : e.moveLines(down: down);
    }
    if (ctrl || alt) return null;

    if (key == LogicalKeyboardKey.home && !shift) return e.smartHome();

    if (key == LogicalKeyboardKey.tab) {
      if (sel.isCollapsed && !shift) return e.replace(sel.start, sel.end, e.tab);
      return e.indentLines(outdent: shift);
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (shift) return null;
      return e.newline();
    }

    if (key == LogicalKeyboardKey.backspace && sel.isCollapsed && sel.start > 0) {
      final pos = sel.start;
      final prev = text[pos - 1];
      final next = pos < text.length ? text[pos] : '';
      if (next.isNotEmpty && pairs[prev] == next) return e.replace(pos - 1, pos + 1, '');
      final before = text.substring(e.lineStart(pos), pos);
      if (before.isNotEmpty && before.trim().isEmpty && !before.contains('\t')) {
        final step = e.tab.length;
        final drop = before.length % step == 0 ? step : before.length % step;
        return e.replace(pos - drop, pos, '');
      }
      return null;
    }

    final ch = character;
    if (ch == null || ch.length != 1) return null;
    final next = sel.end < text.length ? text[sel.end] : '';
    final prev = sel.start > 0 ? text[sel.start - 1] : '';
    final isQuote = ch == '"' || ch == "'";

    // asm: a label ("loop:") goes back to the margin
    if (L == CodeLang.asm && ch == ':' && sel.isCollapsed) {
      final ls = e.lineStart(sel.start);
      final before = text.substring(ls, sel.start);
      final after = text.substring(sel.end, e.lineEnd(sel.end));
      if (RegExp(r'^[ \t]+[A-Za-z_.$][\w.$]*$').hasMatch(before) && after.trim().isEmpty) {
        final label = before.trimLeft();
        return TextEditingValue(text: text.replaceRange(ls, sel.end, '$label:'), selection: TextSelection.collapsed(offset: ls + label.length + 1));
      }
    }
    // Octave: A' is A transposed
    if (L.transpose && ch == "'" && sel.isCollapsed && RegExp(r"[A-Za-z0-9_)\]}'.]").hasMatch(prev)) {
      if (next == "'") return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: sel.start + 1));
      return null;
    }

    // a closing brace on an empty line goes under its opening brace
    if (ch == '}' && sel.isCollapsed) {
      final ls = e.lineStart(sel.start);
      final before = text.substring(ls, sel.start);
      final indent = before.trim().isEmpty ? _indentOfOpener(text, ls) ?? '' : '';
      if (before.trim().isEmpty) {
        // the brace typed is already there, just below (put by "{"): go past it
        final below = RegExp(r'^[ \t]*\n[ \t]*\}').firstMatch(text.substring(sel.start));
        if (below != null && (RegExp(r'^[ \t]*').stringMatch(text.substring(text.indexOf('\n', sel.start) + 1)) ?? '') == indent) {
          return TextEditingValue(
            text: text.replaceRange(ls, sel.start + below.end, '$indent}'),
            selection: TextSelection.collapsed(offset: ls + indent.length + 1),
          );
        }
      }
      if (before.trim().isEmpty && before.isNotEmpty) {
        if (indent != before) {
          final skip = next == '}';
          return TextEditingValue(
            text: text.replaceRange(ls, skip ? sel.start + 1 : sel.start, '$indent}'),
            selection: TextSelection.collapsed(offset: ls + indent.length + 1),
          );
        }
      }
    }

    // a closer that is already there: step over it
    if (sel.isCollapsed && next == ch && pairs.containsValue(ch)) {
      if (!isQuote || prev != '\\') return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: sel.start + 1));
    }

    // #include <|>
    if (L.braces && ch == '<' && sel.isCollapsed && RegExp(r'^\s*#\s*include\s*$').hasMatch(text.substring(e.lineStart(sel.start), sel.start)) && next != '>') {
      return e.replace(sel.start, sel.end, '<>', caret: sel.start + 1);
    }

    final close = pairs[ch];
    if (close == null) return null;
    if (!sel.isCollapsed) {
      final inner = text.substring(sel.start, sel.end);
      if (inner.contains('\n') && isQuote) return null;
      return e.replace(sel.start, sel.end, '$ch$inner$close', caret: sel.start + 1, selectTo: sel.end + 1);
    }
    if (_inCommentOrString(text, sel.start, L.comment) && (isQuote || ch == '(' || ch == '[')) return null;
    final roomAfter = next.isEmpty || RegExp(r'[\s)\]};,]').hasMatch(next);
    final wordBefore = RegExp(r'[A-Za-z0-9_\\]').hasMatch(prev);
    if (roomAfter && !(isQuote && wordBefore)) return e.replace(sel.start, sel.end, '$ch$close', caret: sel.start + 1);
    return null;
  }

  /// The indent of the line holding the `{` that a `}` at [lineStart] would close.
  static String? _indentOfOpener(String text, int lineStart) {
    var depth = 0;
    final scan = _code(text.substring(0, lineStart));
    for (var i = scan.length - 1; i >= 0; i--) {
      final c = scan[i];
      if (c == '}') depth++;
      if (c == '{') {
        if (depth == 0) {
          final ls = i == 0 ? 0 : text.lastIndexOf('\n', i - 1) + 1;
          return RegExp(r'^[ \t]*').stringMatch(text.substring(ls, i)) ?? '';
        }
        depth--;
      }
    }
    return null;
  }

  /// [text] with strings, characters and comments blanked out (same length), so
  /// only real braces and parentheses are counted.
  /// [text] with comments and the inside of strings blanked out (same
  /// length, newlines kept), so a brace or an operator in them doesn't count.
  static String mask(String text, {String comment = '//', bool transpose = false}) => _code(text, comment: comment, transpose: transpose);

  static String _code(String text, {String comment = '//', bool transpose = false}) {
    final b = StringBuffer();
    var i = 0;
    final block = comment == '//';
    while (i < text.length) {
      final c = text[i];
      if (text.startsWith(comment, i)) {
        while (i < text.length && text[i] != '\n') {
          b.write(' ');
          i++;
        }
        continue;
      }
      if (block && c == '/' && i + 1 < text.length && text[i + 1] == '*') {
        final end = text.indexOf('*/', i + 2);
        final stop = end < 0 ? text.length : end + 2;
        for (; i < stop; i++) {
          b.write(text[i] == '\n' ? '\n' : ' ');
        }
        continue;
      }
      if (c == "'" && transpose && i > 0 && RegExp(r"[A-Za-z0-9_)\]}'.]").hasMatch(text[i - 1])) {
        b.write(c);
        i++;
        continue;
      }
      if (c == '"' || c == "'") {
        b.write(c);
        i++;
        while (i < text.length && text[i] != c && text[i] != '\n') {
          if (text[i] == '\\' && i + 1 < text.length) {
            b.write('  ');
            i += 2;
            continue;
          }
          b.write(' ');
          i++;
        }
        if (i < text.length && text[i] == c) {
          b.write(c);
          i++;
        }
        continue;
      }
      b.write(c);
      i++;
    }
    return b.toString();
  }

  /// Whether [pos] is inside a string, a character literal or a // comment on its line.
  static bool _inCommentOrString(String text, int pos, [String comment = '//']) {
    final ls = pos == 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
    String? quote;
    for (var i = ls; i < pos; i++) {
      final c = text[i];
      if (quote != null) {
        if (c == '\\') {
          i++;
        } else if (c == quote) {
          quote = null;
        }
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (text.startsWith(comment, i) && i + comment.length <= pos) {
        return true;
      }
    }
    return quote != null;
  }

  // ---------------------------------------------------------------- format
  /// [v] with the whole text aligned; the caret stays on its line and token.
  static TextEditingValue formatValue(TextEditingValue v, {String lang = 'cpp'}) {
    final before = v.text.split('\n');
    final after = formatAs(v.text, lang).split('\n');
    if (after.length != before.length) return TextEditingValue(text: after.join('\n'), selection: TextSelection.collapsed(offset: after.join('\n').length));
    int map(int offset) {
      offset = offset.clamp(0, v.text.length);
      final line = '\n'.allMatches(v.text.substring(0, offset)).length;
      final col = offset - (line == 0 ? 0 : v.text.lastIndexOf('\n', offset - 1) + 1);
      final oldLead = before[line].length - before[line].trimLeft().length;
      final newLead = after[line].length - after[line].trimLeft().length;
      final newCol = math.max(newLead, math.min(after[line].length, col - oldLead + newLead));
      var start = 0;
      for (var i = 0; i < line; i++) {
        start += after[i].length + 1;
      }
      return start + newCol;
    }

    final sel = v.selection.isValid ? v.selection : const TextSelection.collapsed(offset: 0);
    return TextEditingValue(
      text: after.join('\n'),
      selection: TextSelection(baseOffset: map(sel.baseOffset), extentOffset: map(sel.extentOffset)),
    );
  }

  /// The indent step [text] is written with: two spaces when its smallest
  /// indent is two, four otherwise.
  static String indentOf(String text) {
    var least = 0;
    for (final m in RegExp(r'^( +)\S', multiLine: true).allMatches(text)) {
      final n = m[1]!.length;
      if (least == 0 || n < least) least = n;
    }
    return least == 2 ? '  ' : tab;
  }

  /// [code] aligned as [lang] is written: C by its braces, Octave and the shell
  /// by their keywords, assembly with labels and directives at the margin.
  static String formatAs(String code, String lang) {
    final L = CodeLang.of(lang);
    if (L.braces) return format(code);
    if (L.keywords) return KeywordBlocks.of(L).format(code, L.detectIndent ? indentOf(code) : tab);
    if (L == CodeLang.asm) return formatAsm(code);
    return code;
  }

  /// Assembly: labels, sections and directives at the margin, data
  /// definitions too, every instruction one step in; a comment line goes
  /// where the line of code after it goes; "mov eax,1" gets its space after the comma.
  static String formatAsm(String code) {
    final lines = code.replaceAll('\t', tab).split('\n');
    final margin = RegExp(
        r'^([A-Za-z_.$?@][\w.$?@]*:|(section|segment|global|extern|bits|default|org|%\w+|\.\w+)\b|[A-Za-z_.$][\w.$]*\s+(db|dw|dd|dq|dt|resb|resw|resd|resq|equ|times)\b)',
        caseSensitive: false);
    final out = List<String>.filled(lines.length, '');
    var next = ''; // the indent of the next line of code, for the comments above it
    for (var i = lines.length - 1; i >= 0; i--) {
      final t = lines[i].trim();
      if (t.isEmpty) continue;
      if (t.startsWith(';')) {
        out[i] = '$next$t';
        continue;
      }
      next = margin.hasMatch(t) ? '' : tab;
      out[i] = '$next${_asmCommas(t)}';
    }
    return out.join('\n');
  }

  /// One space after each comma of the operands (not in strings or the comment).
  static String _asmCommas(String t) {
    final b = StringBuffer();
    String? q;
    for (var i = 0; i < t.length; i++) {
      final c = t[i];
      if (q != null) {
        if (c == q) q = null;
        b.write(c);
        continue;
      }
      if (c == ';') {
        b.write(t.substring(i));
        break;
      }
      if (c == '"' || c == "'" || c == '`') q = c;
      b.write(c);
      if (c == ',' && i + 1 < t.length && t[i + 1] != ' ') b.write(' ');
    }
    return b.toString();
  }

  /// C/C++ [code] re-indented by its braces, 4 spaces a level: the body of a
  /// switch one level under its `case`, a lone statement after `if (…)`,
  /// `for (…)`, `while (…)` or `else` one level in, preprocessor lines at the
  /// margin, trailing spaces dropped. Nothing else is touched.
  static String format(String code) {
    final lines = code.replaceAll('\t', tab).split('\n');
    final blank = _code(code).split('\n');
    final out = <String>[];
    // for each open brace, the level of the line that opened it: its body is one
    // deeper, its } on that level (a brace opened in a one-line body keeps it)
    final open = <int>[];
    var paren = 0; // open parentheses before this line (a call split over lines)
    final caseAt = <int>{}; // depths at which a "case" label was seen
    var lone = 0; // pending one-statement bodies (if (…) without braces)
    var ifLone = 0; // the bodies around the last "if": its "else" goes on the same level
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final t = raw.trim();
      final b = i < blank.length ? blank[i].trim() : t;
      if (t.isEmpty) {
        out.add('');
        continue;
      }
      if (t.startsWith('#')) {
        out.add(t);
        continue;
      }
      final closesFirst = b.startsWith('}');
      final isCase = RegExp(r'^(case\b.*|default\s*):').hasMatch(t);
      final depth = open.length;
      var level = closesFirst && open.isNotEmpty ? open.last : (open.isEmpty ? 0 : open.last + 1);
      if (closesFirst) caseAt.removeWhere((d) => d >= depth);
      if (!isCase && !closesFirst && caseAt.contains(depth)) level++;
      if (isCase) caseAt.add(depth);
      level += paren > 0 ? 1 : 0;
      final isElse = RegExp(r'^else\b').hasMatch(b);
      if (isElse) lone = ifLone; // the body of the "if" is over: back to the "if"'s level
      if (RegExp(r'^(\}\s*)?(else\s+)?if\b').hasMatch(b)) ifLone = lone;
      if (lone > 0 && !b.startsWith('{')) level += lone;
      out.add('${tab * math.max(0, level)}$t');

      // what this line opens and closes
      for (final c in b.split('')) {
        if (c == '{') open.add(math.max(0, level));
        if (c == '}' && open.isNotEmpty) {
          open.removeLast();
          caseAt.removeWhere((d) => d > open.length);
        }
        if (c == '(') paren++;
        if (c == ')') paren = math.max(0, paren - 1);
      }
      // a body of one statement: "if (x)" / "for (…)" / "else" with nothing after
      final opensLone = paren == 0 &&
          !b.endsWith('{') &&
          !b.endsWith(';') &&
          (RegExp(r'^(\}\s*)?(else\s+)?(if|for|while)\b.*\)$').hasMatch(b) || RegExp(r'^(\}\s*)?else$').hasMatch(b));
      // a { (at the end, or alone on the next line) takes the pending bodies' level with it
      lone = opensLone ? lone + 1 : 0;
    }
    return out.join('\n');
  }
}

/// The text and selection being edited, with the line arithmetic the keys need.
class _Edit {
  final String text;
  final TextSelection sel;
  final CodeLang lang;
  final String tab; // one indent step
  _Edit(this.text, this.sel, [this.lang = CodeLang.c, this.tab = CodeKeys.tab]);

  int lineStart(int pos) => pos <= 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;

  int lineEnd(int pos) {
    final i = text.indexOf('\n', pos);
    return i < 0 ? text.length : i;
  }

  TextEditingValue replace(int start, int end, String insert, {int? caret, int? selectTo}) {
    final t = text.replaceRange(start, end, insert);
    final c = (caret ?? start + insert.length).clamp(0, t.length);
    return TextEditingValue(
      text: t,
      selection: selectTo == null ? TextSelection.collapsed(offset: c) : TextSelection(baseOffset: c, extentOffset: selectTo.clamp(0, t.length)),
    );
  }

  /// The first and the last line the selection touches (a selection ending at
  /// column 0 does not take that last line).
  (int, int) _block() {
    final from = lineStart(sel.start);
    final lastPos = !sel.isCollapsed && sel.end > sel.start && text[sel.end - 1] == '\n' ? sel.end - 1 : sel.end;
    return (from, lineEnd(lastPos));
  }

  /// The selection after its lines changed by [firstDelta] (the first line)
  /// and [total] (all of them): a start at the margin stays at the margin, as in VS Code.
  TextSelection _shifted(int from, int firstDelta, int total) {
    final forward = sel.baseOffset <= sel.extentOffset;
    int start(int o) => o == from ? from : math.max(from, o + firstDelta);
    final s = forward ? sel.baseOffset : sel.extentOffset, e = forward ? sel.extentOffset : sel.baseOffset;
    final ns = start(s), ne = sel.isCollapsed ? ns : math.max(ns, e + total);
    return forward ? TextSelection(baseOffset: ns, extentOffset: ne) : TextSelection(baseOffset: ne, extentOffset: ns);
  }

  TextEditingValue newline() {
    final pos = sel.start;
    final ls = lineStart(pos);
    final line = text.substring(ls, pos);
    var base = RegExp(r'^[ \t]*').stringMatch(line) ?? '';
    final L = lang;
    final trimmed = CodeKeys._code(line, comment: L.comment, transpose: L.transpose).trimRight();
    var opens = trimmed.endsWith('{') || trimmed.endsWith('(') || trimmed.endsWith('[') || (L.colon && trimmed.endsWith(':'));
    if (L == CodeLang.asm && RegExp(r'^\s*[A-Za-z_.$][\w.$]*:$').hasMatch(trimmed)) opens = true;
    if (L.keywords) {
      final blocks = KeywordBlocks.of(L);
      final t = trimmed.trim();
      // "end", "else", "fi"… go under the opener of their block, then the new
      // line starts at the indent the line leads to
      if (blocks.dedents(t)) {
        final want = blocks.indentFor(text, ls, t, tab);
        if (want != null && want != base) {
          final fixed = text.replaceRange(ls, ls + base.length, want);
          final d = want.length - base.length;
          return _Edit(fixed, TextSelection(baseOffset: sel.baseOffset + d, extentOffset: sel.extentOffset + d), L, tab).newline();
        }
      }
      if (blocks.opens(t)) opens = true;
      if (blocks.endsItem(t) && base.length >= tab.length) base = base.substring(tab.length);
    }
    final lone = L.braces &&
        (RegExp(r'^\s*(\}\s*)?(else\s+)?(if|for|while)\b.*\)$').hasMatch(trimmed) || RegExp(r'^\s*(\}\s*)?else$').hasMatch(trimmed));
    final next = sel.end < text.length ? text[sel.end] : '';
    if (opens && (next == '}' || next == ')' || next == ']')) {
      // "{|}": the body on its own indented line, the closer back on the base indent
      return replace(pos, sel.end, '\n$base$tab\n$base', caret: pos + 1 + base.length + tab.length);
    }
    // the spaces after the caret go: the new line starts at the indent
    var end = sel.end;
    while (end < text.length && text[end] == ' ') {
      end++;
    }
    return replace(pos, end, '\n$base${opens || lone ? tab : ''}');
  }

  TextEditingValue indentLines({required bool outdent}) {
    final (from, to) = _block();
    final lines = text.substring(from, to).split('\n');
    var firstDelta = 0, total = 0;
    for (var i = 0; i < lines.length; i++) {
      var d = 0;
      if (outdent) {
        final lead = RegExp('^ {1,${tab.length}}|^\t').stringMatch(lines[i]) ?? '';
        lines[i] = lines[i].substring(lead.length);
        d = -lead.length;
      } else if (lines[i].isNotEmpty || lines.length == 1) {
        lines[i] = '$tab${lines[i]}';
        d = tab.length;
      }
      if (i == 0) firstDelta = d;
      total += d;
    }
    return TextEditingValue(
      text: text.replaceRange(from, to, lines.join('\n')),
      selection: _shifted(from, firstDelta, total),
    );
  }

  TextEditingValue toggleComment(String mark) {
    final (from, to) = _block();
    final lines = text.substring(from, to).split('\n');
    final live = lines.where((l) => l.trim().isNotEmpty);
    final allCommented = live.isNotEmpty && live.every((l) => l.trimLeft().startsWith(mark));
    // like VS Code: the marks line up at the smallest indent of the block
    final indent = live.isEmpty ? 0 : live.map((l) => l.length - l.trimLeft().length).reduce(math.min);
    var firstDelta = 0, total = 0;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      String next;
      if (allCommented) {
        final lead = l.length - l.trimLeft().length;
        var rest = l.substring(lead + mark.length);
        if (rest.startsWith(' ')) rest = rest.substring(1);
        next = l.substring(0, lead) + rest;
      } else {
        next = '${l.substring(0, indent)}$mark ${l.substring(indent)}';
      }
      final d = next.length - l.length;
      if (i == 0) firstDelta = d;
      total += d;
      lines[i] = next;
    }
    return TextEditingValue(
      text: text.replaceRange(from, to, lines.join('\n')),
      selection: _shifted(from, firstDelta, total),
    );
  }

  TextEditingValue deleteLines() {
    final (from, to) = _block();
    final cut = to < text.length ? to + 1 : to;
    final start = cut == to && from > 0 ? from - 1 : from;
    final t = text.replaceRange(start, cut, '');
    final caret = math.min(start == from ? from : start + 1, t.length);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: math.max(0, math.min(caret, t.length))));
  }

  TextEditingValue moveLines({required bool down}) {
    final (from, to) = _block();
    if (down ? to >= text.length : from == 0) return TextEditingValue(text: text, selection: sel);
    final block = text.substring(from, to);
    if (down) {
      final nextEnd = lineEnd(to + 1);
      final nextLine = text.substring(to + 1, nextEnd);
      final t = text.replaceRange(from, nextEnd, '$nextLine\n$block');
      final d = nextLine.length + 1;
      return TextEditingValue(text: t, selection: TextSelection(baseOffset: sel.baseOffset + d, extentOffset: sel.extentOffset + d));
    }
    final prevStart = lineStart(from - 1);
    final prevLine = text.substring(prevStart, from - 1);
    final t = text.replaceRange(prevStart, to, '$block\n$prevLine');
    final d = prevLine.length + 1;
    return TextEditingValue(text: t, selection: TextSelection(baseOffset: sel.baseOffset - d, extentOffset: sel.extentOffset - d));
  }

  TextEditingValue copyLines({required bool down}) {
    final (from, to) = _block();
    final block = text.substring(from, to);
    final t = text.replaceRange(to, to, '\n$block');
    final d = down ? block.length + 1 : 0;
    return TextEditingValue(text: t, selection: TextSelection(baseOffset: sel.baseOffset + d, extentOffset: sel.extentOffset + d));
  }

  TextEditingValue smartHome() {
    final ls = lineStart(sel.extentOffset);
    final first = ls + (RegExp(r'^[ \t]*').stringMatch(text.substring(ls, lineEnd(ls))) ?? '').length;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: sel.extentOffset == first ? ls : first));
  }
}

// =============================================================================
// BLOCKS OPENED AND CLOSED BY WORDS (Octave, the shell)
//   if … end / endif, for … end, switch / case … end, function … end;
//   if … then … elif … else … fi, for/while … do … done, case … in … ;; … esac.
//   One walk over the lines keeps the open blocks; from it come where a line
//   that closes or continues a block goes, and the whole file aligned.
// =============================================================================

class _Frame {
  final String kind; // the opening word, "{" or "item" (a case's branch)
  final int level; // in the aligned file
  final String indent; // as written
  const _Frame(this.kind, this.level, this.indent);
}

class KeywordBlocks {
  final bool shell;
  const KeywordBlocks._(this.shell);
  static const _octave = KeywordBlocks._(false);
  static const _shell = KeywordBlocks._(true);
  static KeywordBlocks of(CodeLang l) => l == CodeLang.shell ? _shell : _octave;

  static const _oOpen = {'if', 'for', 'parfor', 'while', 'switch', 'function', 'try', 'do', 'unwind_protect'};
  static const _oClose = {'end', 'endif', 'endfor', 'endparfor', 'endwhile', 'endswitch', 'endfunction', 'end_try_catch', 'end_unwind_protect', 'until'};
  static const _oMiddle = {'else', 'elseif', 'catch', 'unwind_protect_cleanup'};
  static const _oItem = {'case', 'otherwise'};
  static const _sOpen = {'if', 'for', 'while', 'until', 'select', 'case'};
  static const _sClose = {'fi', 'done', 'esac'};
  static const _sMiddle = {'then', 'do', 'else', 'elif'};

  static String _word(String t) => RegExp(r'^[A-Za-z_]\w*').stringMatch(t) ?? '';

  Set<String> get _open => shell ? _sOpen : _oOpen;
  Set<String> get _close => shell ? _sClose : _oClose;
  Set<String> get _middle => shell ? _sMiddle : _oMiddle;

  /// The block is opened and closed on the same line: "if x, y = 1; end", "for f in *; do echo $f; done".
  bool _closedInline(String t) => shell ? RegExp(r'[;&|]\s*(fi|done|esac)\b').hasMatch(t) : RegExp(r'[,;]\s*(end\w*|until)\b').hasMatch(t);

  /// A shell case branch: "a|b)", "*)", "(x)".
  static bool _pattern(String t) => RegExp(r'^\(?[^\s;()][^;()]*\)').hasMatch(t) && !t.startsWith(';;');

  bool _isItem(String t, _Frame? top) {
    if (shell) {
      if (top == null || (top.kind != 'case' && top.kind != 'item')) return false;
      return _word(t) != 'esac' && _pattern(t);
    }
    return _oItem.contains(_word(t));
  }

  /// A line that goes back to its block's opener: end, else, fi, done, case…
  bool dedents(String t) {
    final w = _word(t);
    if (_close.contains(w) || _middle.contains(w)) return true;
    if (!shell && _oItem.contains(w)) return true;
    return shell && t.startsWith('}');
  }

  /// The line opens a block (or continues one: else, case…): the next line goes one step in.
  bool opens(String t) {
    final w = _word(t);
    if (_closedInline(t)) return false;
    if (!shell) return _oOpen.contains(w) || _oMiddle.contains(w) || _oItem.contains(w);
    if (w == 'case' || w == 'then' || w == 'do' || w == 'else') return true;
    if (RegExp(r'\b(then|do)$').hasMatch(t) || t.endsWith('{')) return true;
    return _pattern(t) && !t.endsWith(';;');
  }

  /// A case branch ends on this line (";;"): the next line goes one step out.
  bool endsItem(String t) => shell && t.endsWith(';;') && !_pattern(t);

  /// One line [t] (masked, trimmed) against the open blocks: its level and the
  /// indent its block asks for, the blocks updated.
  (int, String) _step(List<_Frame> st, String t, String raw, String tab) {
    final w = _word(t);
    final actual = RegExp(r'^[ \t]*').stringMatch(raw) ?? '';
    _Frame? top() => st.isEmpty ? null : st.last;
    (int, String) body() => st.isEmpty ? (0, '') : (st.last.level + 1, '${st.last.indent}$tab');

    if (_close.contains(w) || (shell && t.startsWith('}'))) {
      if (top()?.kind == 'item') st.removeLast();
      if (st.isEmpty) return (0, '');
      final f = st.removeLast();
      return (f.level, f.indent);
    }
    if (_isItem(t, top())) {
      if (top()?.kind == 'item') st.removeLast();
      final at = body();
      if (!(shell && t.endsWith(';;'))) st.add(_Frame('item', at.$1, at.$2));
      return at;
    }
    if (_middle.contains(w)) {
      final f = top();
      if (f == null) return (0, '');
      return (f.level, f.indent);
    }
    final at = body();
    if (shell && t.endsWith(';;') && top()?.kind == 'item') {
      st.removeLast();
      return at;
    }
    if (!_closedInline(t) && (_open.contains(w) || (shell && t.endsWith('{')))) {
      st.add(_Frame(_open.contains(w) ? w : '{', at.$1, actual));
    }
    return at;
  }

  List<String> _masked(String code) {
    final L = shell ? CodeLang.shell : CodeLang.octave;
    return CodeKeys.mask(code, comment: L.comment, transpose: L.transpose).split('\n');
  }

  /// The indent the line at [lineStart], reading [t], should have; null when
  /// no block is open there.
  String? indentFor(String text, int lineStart, String t, String tab) {
    final before = text.substring(0, lineStart);
    final raw = before.split('\n')..removeLast(); // the empty piece after the last \n
    final masked = _masked(before);
    final st = <_Frame>[];
    for (var i = 0; i < raw.length; i++) {
      final m = masked[i].trim();
      if (m.isEmpty) continue;
      _step(st, m, raw[i], tab);
    }
    if (st.isEmpty) return null;
    return _step(st, t, '', tab).$2;
  }

  /// [code] with every line at its block's level.
  String format(String code, String tab) {
    code = code.replaceAll('\t', tab);
    final lines = code.split('\n');
    final masked = _masked(code);
    final out = <String>[];
    final st = <_Frame>[];
    String? heredoc; // the shell's << WORD: its lines are kept as written
    var blockComment = false; // Octave's %{ … %}
    var cont = false; // the line before ended in ... or \
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final t = raw.trim();
      if (heredoc != null) {
        out.add(raw);
        if (t == heredoc) heredoc = null;
        continue;
      }
      if (!shell && (t == '%{' || blockComment)) {
        blockComment = t != '%}';
        out.add(raw.trimRight());
        continue;
      }
      if (t.isEmpty) {
        out.add('');
        continue;
      }
      final m = masked[i].trim();
      final mm = m.isEmpty ? t : m;
      var (level, _) = _step(st, mm, tab * (st.isEmpty ? 0 : st.last.level + 1), tab);
      if (cont) level++;
      out.add('${tab * level}$t');
      cont = shell ? mm.endsWith('\\') : mm.endsWith('...');
      if (shell) {
        final h = RegExp(r'''<<-?\s*['"]?(\w+)''').firstMatch(raw);
        if (h != null) heredoc = h[1];
      }
    }
    return out.join('\n');
  }
}
