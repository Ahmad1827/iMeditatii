import 'dart:math' as math;

import 'package:flutter/services.dart';

// =============================================================================
// EDITING KEYS, AS IN VS CODE
//   One place for what a key does to the code, shared by every editor in the
//   app (the problem page, the workbench). Pure: text and selection in, text
//   and selection out, so it is tested without a widget.
//
//   ( [ { " '        close themselves; around a selection they wrap it
//   ) ] } " '        typed before the same closer step over it
//   Backspace        deletes an empty pair, or one indent level of spaces
//   Enter            keeps the indent, one more after { ( [ or "else"/"if (…)"
//   }                on an empty line lines up with its {
//   Tab / Shift+Tab  indent / outdent (the selected lines, or the caret's line)
//   Ctrl+/           comments or uncomments the lines
//   Alt+↑ / Alt+↓    moves the lines up / down
//   Shift+Alt+↑ / ↓  copies the lines up / down
//   Ctrl+Shift+K     deletes the lines
//   Ctrl+] / Ctrl+[  indent / outdent the lines
//   Home             to the first character of the line, then to column 0
//   Shift+Alt+F      aligns the whole file (see [CodeKeys.format])
// =============================================================================

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
    final e = _Edit(text, sel);

    if (shift && alt && key == LogicalKeyboardKey.keyF) {
      return lang == 'python' ? null : formatValue(v);
    }
    if (ctrl && key == LogicalKeyboardKey.slash) return e.toggleComment(lang == 'python' ? '#' : '//');
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
      if (sel.isCollapsed && !shift) return e.replace(sel.start, sel.end, tab);
      return e.indentLines(outdent: shift);
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (shift) return null;
      return e.newline(lang);
    }

    if (key == LogicalKeyboardKey.backspace && sel.isCollapsed && sel.start > 0) {
      final pos = sel.start;
      final prev = text[pos - 1];
      final next = pos < text.length ? text[pos] : '';
      if (next.isNotEmpty && pairs[prev] == next) return e.replace(pos - 1, pos + 1, '');
      final before = text.substring(e.lineStart(pos), pos);
      if (before.isNotEmpty && before.trim().isEmpty && !before.contains('\t')) {
        final drop = before.length % tab.length == 0 ? tab.length : before.length % tab.length;
        return e.replace(pos - drop, pos, '');
      }
      return null;
    }

    final ch = character;
    if (ch == null || ch.length != 1) return null;
    final next = sel.end < text.length ? text[sel.end] : '';
    final prev = sel.start > 0 ? text[sel.start - 1] : '';
    final isQuote = ch == '"' || ch == "'";

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
    if (ch == '<' && sel.isCollapsed && RegExp(r'^\s*#\s*include\s*$').hasMatch(text.substring(e.lineStart(sel.start), sel.start)) && next != '>') {
      return e.replace(sel.start, sel.end, '<>', caret: sel.start + 1);
    }

    final close = pairs[ch];
    if (close == null) return null;
    if (!sel.isCollapsed) {
      final inner = text.substring(sel.start, sel.end);
      if (inner.contains('\n') && isQuote) return null;
      return e.replace(sel.start, sel.end, '$ch$inner$close', caret: sel.start + 1, selectTo: sel.end + 1);
    }
    if (_inCommentOrString(text, sel.start) && (isQuote || ch == '(' || ch == '[')) return null;
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
  static String _code(String text) {
    final b = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == '/' && i + 1 < text.length && text[i + 1] == '/') {
        while (i < text.length && text[i] != '\n') {
          b.write(' ');
          i++;
        }
        continue;
      }
      if (c == '/' && i + 1 < text.length && text[i + 1] == '*') {
        final end = text.indexOf('*/', i + 2);
        final stop = end < 0 ? text.length : end + 2;
        for (; i < stop; i++) {
          b.write(text[i] == '\n' ? '\n' : ' ');
        }
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
  static bool _inCommentOrString(String text, int pos) {
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
      } else if (c == '/' && i + 1 < pos && text[i + 1] == '/') {
        return true;
      }
    }
    return quote != null;
  }

  // ---------------------------------------------------------------- format
  /// [v] with the whole text aligned; the caret stays on its line and token.
  static TextEditingValue formatValue(TextEditingValue v) {
    final before = v.text.split('\n');
    final after = format(v.text).split('\n');
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

  /// C/C++ [code] re-indented by its braces, 4 spaces a level: the body of a
  /// switch one level under its `case`, a lone statement after `if (…)`,
  /// `for (…)`, `while (…)` or `else` one level in, preprocessor lines at the
  /// margin, trailing spaces dropped. Nothing else is touched.
  static String format(String code) {
    final lines = code.replaceAll('\t', tab).split('\n');
    final blank = _code(code).split('\n');
    final out = <String>[];
    var depth = 0; // open braces before this line
    var paren = 0; // open parentheses before this line (a call split over lines)
    final caseAt = <int>{}; // depths at which a "case" label was seen
    var lone = 0; // pending one-statement bodies (if (…) without braces)
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
      var level = depth - (closesFirst ? 1 : 0);
      if (closesFirst) caseAt.removeWhere((d) => d >= depth);
      if (!isCase && !closesFirst && caseAt.contains(depth)) level++;
      if (isCase) caseAt.add(depth);
      level += paren > 0 ? 1 : 0;
      if (lone > 0 && !b.startsWith('{')) level += lone;
      out.add('${tab * math.max(0, level)}$t');

      // what this line opens and closes
      for (final c in b.split('')) {
        if (c == '{') depth++;
        if (c == '}') {
          depth = math.max(0, depth - 1);
          caseAt.removeWhere((d) => d > depth);
        }
        if (c == '(') paren++;
        if (c == ')') paren = math.max(0, paren - 1);
      }
      // a body of one statement: "if (x)" / "for (…)" / "else" with nothing after
      final opensLone = paren == 0 &&
          !b.endsWith('{') &&
          !b.endsWith(';') &&
          (RegExp(r'^(\}\s*)?(else\s+)?(if|for|while)\b.*\)$').hasMatch(b) || RegExp(r'^(\}\s*)?else$').hasMatch(b));
      if (opensLone) {
        lone++;
      } else if (!b.startsWith('{')) {
        lone = 0;
      }
    }
    return out.join('\n');
  }
}

/// The text and selection being edited, with the line arithmetic the keys need.
class _Edit {
  final String text;
  final TextSelection sel;
  _Edit(this.text, this.sel);

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

  TextEditingValue newline(String lang) {
    final pos = sel.start;
    final line = text.substring(lineStart(pos), pos);
    final base = RegExp(r'^[ \t]*').stringMatch(line) ?? '';
    final trimmed = CodeKeys._code(line).trimRight();
    final opens = trimmed.endsWith('{') || trimmed.endsWith('(') || trimmed.endsWith('[') || (lang == 'python' && trimmed.endsWith(':'));
    final lone = lang != 'python' &&
        (RegExp(r'^\s*(\}\s*)?(else\s+)?(if|for|while)\b.*\)$').hasMatch(trimmed) || RegExp(r'^\s*(\}\s*)?else$').hasMatch(trimmed));
    final next = sel.end < text.length ? text[sel.end] : '';
    if (opens && (next == '}' || next == ')' || next == ']')) {
      // "{|}": the body on its own indented line, the closer back on the base indent
      return replace(pos, sel.end, '\n$base${CodeKeys.tab}\n$base', caret: pos + 1 + base.length + CodeKeys.tab.length);
    }
    // the spaces after the caret go: the new line starts at the indent
    var end = sel.end;
    while (end < text.length && text[end] == ' ') {
      end++;
    }
    return replace(pos, end, '\n$base${opens || lone ? CodeKeys.tab : ''}');
  }

  TextEditingValue indentLines({required bool outdent}) {
    final (from, to) = _block();
    final lines = text.substring(from, to).split('\n');
    var firstDelta = 0, total = 0;
    for (var i = 0; i < lines.length; i++) {
      var d = 0;
      if (outdent) {
        final lead = RegExp(r'^ {1,4}|^\t').stringMatch(lines[i]) ?? '';
        lines[i] = lines[i].substring(lead.length);
        d = -lead.length;
      } else if (lines[i].isNotEmpty || lines.length == 1) {
        lines[i] = '${CodeKeys.tab}${lines[i]}';
        d = CodeKeys.tab.length;
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
