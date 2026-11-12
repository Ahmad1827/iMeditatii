import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_run.dart';
import 'code_assistant.dart';
import 'code_complete.dart';
import 'code_keys.dart';
import 'code_style.dart';
import 'judge0.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, CodeHighlighter, showPbModal;

// =============================================================================
// CODE EDITOR — line numbers, syntax colours, no soft wrap, IDE-style keys.
// =============================================================================
class CodeController extends TextEditingController {
  CodeController({super.text, String lang = 'cpp'}) : _lang = lang;

  String _lang;
  String get lang => _lang;
  set lang(String v) {
    if (v == _lang) return;
    _lang = v;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    return CodeHighlighter.span(text, style ?? const TextStyle(), lang: _lang);
  }

  /// Replaces [start, end) and puts the caret (or a selection) after it.
  void replace(int start, int end, String insert, {int? caret, int? selectTo}) {
    final t = text.replaceRange(start, end, insert);
    final c = (caret ?? start + insert.length).clamp(0, t.length);
    value = TextEditingValue(
      text: t,
      selection: selectTo == null
          ? TextSelection.collapsed(offset: c)
          : TextSelection(baseOffset: c, extentOffset: selectTo.clamp(0, t.length)),
    );
  }

  /// Inserts a multi-line snippet at the caret, indenting it like the current
  /// line. A `|` in the snippet marks where the caret lands.
  void insertSnippet(String snippet) {
    final sel = selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
    final indent = RegExp(r'^[ \t]*').stringMatch(text.substring(lineStart, start)) ?? '';
    var body = snippet.replaceAll('\n', '\n$indent');
    final mark = body.indexOf('|');
    if (mark >= 0) body = body.replaceFirst('|', '');
    replace(start, end, body, caret: mark >= 0 ? start + mark : null);
  }
}

class CodeEditor extends StatefulWidget {
  final CodeController controller;
  final UndoHistoryController? undoController;
  final FocusNode? focusNode;
  final bool readOnly;
  final double fontSize;
  final VoidCallback? onRun; // Ctrl/Cmd + Enter
  final List<StyleIssue> issues; // drawn as squiggles, explained on hover
  final CodeAssistant? assistant; // the grey suggestion after the caret

  const CodeEditor({
    super.key,
    required this.controller,
    this.undoController,
    this.focusNode,
    this.readOnly = false,
    this.fontSize = 14.5,
    this.onRun,
    this.issues = const [],
    this.assistant,
  });

  static Color colorOf(IssueLevel l) => switch (l) {
        IssueLevel.error => const Color(0xFFE5484D),
        IssueLevel.warning => const Color(0xFFF59E0B),
        IssueLevel.hint => const Color(0xFF3B82F6),
      };

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  static const double _lineH = 1.55;
  static const double _padV = 12;
  static const double _padH = 12;

  final ScrollController _v = ScrollController();
  final ScrollController _h = ScrollController();
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  CodeController get _c => widget.controller;
  StyleIssue? _hover;
  final GlobalKey _fieldKey = GlobalKey();
  double _textTop = _padV; // where the field really draws its first line
  // what the field really lays out, read from it: browsers round the line height,
  // so fontSize * _lineH drifts further from the code on every line
  double? _rowH;
  double? _rowHFor; // the font size _rowH was read at
  double? _baseline; // from the top of a row to the code's baseline

  @override
  void initState() {
    super.initState();
    _c.addListener(_changed);
    widget.assistant?.addListener(_changed); // its suggestion is drawn here
  }

  @override
  void didUpdateWidget(CodeEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      _c.addListener(_changed);
    }
    if (old.assistant != widget.assistant) {
      old.assistant?.removeListener(_changed);
      widget.assistant?.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    widget.assistant?.removeListener(_changed);
    _v.dispose();
    _h.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  int get _caret {
    final o = _c.selection.baseOffset;
    return o < 0 || o > _c.text.length ? -1 : o;
  }

  int get _currentLine => _caret < 0 ? 0 : '\n'.allMatches(_c.text.substring(0, _caret)).length + 1;

  // ---------------------------------------------------------------- keys
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final kb = HardwareKeyboard.instance;
    final ctrl = kb.isControlPressed || kb.isMetaPressed;
    final shift = kb.isShiftPressed;
    final key = e.logicalKey;

    if (ctrl && key == LogicalKeyboardKey.enter) {
      widget.onRun?.call();
      return KeyEventResult.handled;
    }
    if (widget.readOnly) return KeyEventResult.ignored;

    final ai = widget.assistant;
    if (ai != null) {
      if (ctrl && key == LogicalKeyboardKey.space) {
        ai.requestNow();
        return KeyEventResult.handled;
      }
      final g = _ghost;
      if (g != null && key == LogicalKeyboardKey.tab && !shift && !ctrl) {
        _c.value = CodeComplete.apply(g, _c.value);
        return KeyEventResult.handled;
      }
      if (g != null && key == LogicalKeyboardKey.escape) {
        ai.dismiss();
        return KeyEventResult.handled;
      }
    }

    final next = CodeKeys.apply(_c.value, key: key, character: e.character, ctrl: ctrl, shift: shift, alt: kb.isAltPressed, lang: _c.lang);
    if (next == null) return KeyEventResult.ignored;
    _c.value = next;
    return KeyEventResult.handled;
  }

  /// The suggestion to show now; one made for older text is not shown.
  Ghost? get _ghost {
    final g = widget.assistant?.ghost;
    return g != null && g.matches(_c.value) ? g : null;
  }

  /// Reads where the field draws its text, so the suggestion sits exactly on it.
  void _measureText(TextStyle style, StrutStyle strut, double rowH) {
    if (!mounted) return;
    final first = _c.text.indexOf(RegExp(r'\S'));
    if (first < 0) return;
    final field = _fieldKey.currentContext?.findRenderObject();
    if (field is! RenderBox) return;
    RenderEditable? editable;
    void look(RenderObject o) {
      if (o is RenderEditable) {
        editable = o;
      } else if (editable == null) {
        o.visitChildren(look);
      }
    }

    look(field);
    final e = editable;
    if (e == null || !e.hasSize) return;
    final boxes = e.getBoxesForSelection(TextSelection(baseOffset: first, extentOffset: first + 1));
    if (boxes.isEmpty) return;
    // the same character alone, as the suggestion draws it: the difference is
    // where the suggestion's first line has to start
    final probe = TextPainter(text: TextSpan(text: _c.text[first], style: style), strutStyle: strut, textDirection: TextDirection.ltr)..layout();
    final own = probe.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1));
    probe.dispose();
    if (own.isEmpty) return;
    final line = '\n'.allMatches(_c.text.substring(0, first)).length;
    var row = rowH;
    final lastAt = _c.text.lastIndexOf(RegExp(r'\S'));
    final lastLine = '\n'.allMatches(_c.text.substring(0, lastAt)).length;
    if (lastLine > line) {
      final lastBoxes = e.getBoxesForSelection(TextSelection(baseOffset: lastAt, extentOffset: lastAt + 1));
      if (lastBoxes.isNotEmpty) row = (lastBoxes.first.top - boxes.first.top) / (lastLine - line);
    }
    final top = e.localToGlobal(Offset(0, boxes.first.top), ancestor: field).dy - own.first.top - line * row;
    // getDistanceToBaseline may only be called by a parent during layout; here layout is over
    // ignore: invalid_use_of_protected_member
    final fromTop = e.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final base = e.localToGlobal(Offset(0, fromTop), ancestor: field).dy - top;
    final fs = widget.fontSize;
    if ((top - _textTop).abs() > 0.1 || (row - rowH).abs() > 0.001 || _rowHFor != fs || (base - (_baseline ?? -1)).abs() > 0.1) {
      setState(() {
        _textTop = top;
        _rowH = row;
        _rowHFor = fs;
        _baseline = base;
      });
    }
  }

  /// The suggestion over the code: its first line continues the caret's line
  /// (what followed the caret moves after it), the others cover the lines below.
  List<Widget> _ghostLayers(Ghost g, TextStyle style, StrutStyle strut, double rowH, double charW) {
    final parts = g.text.split('\n');
    final before = _c.text.substring(0, g.at);
    final lineStart = before.lastIndexOf('\n') + 1;
    final col = g.at - lineStart;
    final line = '\n'.allMatches(before).length;
    final nl = _c.text.indexOf('\n', g.at);
    final rest = _c.text.substring(g.at + g.consume, nl < 0 ? _c.text.length : nl);
    final grey = style.copyWith(color: Pb.muted);
    final lineBg = Color.alphaBlend(Pb.editorActiveLine.withOpacity(0.35), Pb.editorBg);
    final top = _textTop + line * rowH;
    final hides = g.consume > 0 || rest.isNotEmpty; // what followed the caret moves
    return [
      Positioned(
        left: _padH + col * charW,
        top: top,
        height: rowH,
        child: IgnorePointer(
          child: ColoredBox(
            color: hides ? lineBg : Colors.transparent,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: parts.first, style: grey),
                if (parts.length == 1) TextSpan(text: rest, style: style),
              ]),
              maxLines: 1,
              softWrap: false,
              strutStyle: strut,
            ),
          ),
        ),
      ),
      if (parts.length > 1)
        Positioned(
          left: 0,
          right: 0,
          top: top + rowH,
          height: (parts.length - 1) * rowH,
          child: IgnorePointer(
            child: ColoredBox(
              color: Pb.editorBg,
              child: Padding(
                padding: const EdgeInsets.only(left: _padH),
                child: Text(parts.skip(1).join('\n'), style: grey, strutStyle: strut, softWrap: false),
              ),
            ),
          ),
        ),
    ];
  }

  /// The top of the first row as the eye sees it: centred on the letters. The
  /// field's own line box has its extra space below them, so a band drawn from
  /// it looks shifted up.
  double _rowTop(double rowH) {
    final base = _baseline;
    return base == null ? _textTop : _textTop + base - rowH / 2 - widget.fontSize * 0.33;
  }

  /// The issue under the mouse at [p] (in the text's coordinates).
  StyleIssue? _issueAt(Offset p, double rowH, double charW, List<String> lines) {
    final line = ((p.dy - _rowTop(rowH)) / rowH).floor() + 1;
    final col = ((p.dx - _padH) / charW).floor();
    StyleIssue? best;
    for (final i in widget.issues) {
      if (i.line != line) continue;
      final len = i.len == 0 ? (line <= lines.length ? lines[line - 1].length : 0) : i.len;
      if (col < i.col - 1 || col > i.col + math.max(1, len)) continue;
      if (best == null || i.level.index < best.level.index) best = i;
    }
    return best;
  }

  Map<int, Color> _worstByLine() {
    final worst = <int, IssueLevel>{};
    for (final i in widget.issues) {
      final w = worst[i.line];
      if (w == null || i.level.index < w.index) worst[i.line] = i.level;
    }
    return worst.map((k, v) => MapEntry(k, CodeEditor.colorOf(v)));
  }

  Widget _bubble(StyleIssue i) {
    final c = CodeEditor.colorOf(i.level);
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      decoration: BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: c, width: 3), top: BorderSide(color: Pb.border), right: BorderSide(color: Pb.border), bottom: BorderSide(color: Pb.border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(i.message.replaceAll('`', ''), style: TextStyle(fontSize: 13, color: Pb.text, height: 1.35)),
          if (i.detail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(i.detail, style: Pb.mono(11.5, color: Pb.muted)),
          ],
          if (i.fix != null) ...[
            const SizedBox(height: 3),
            Text('Se poate repara din tab-ul Stil.', style: TextStyle(fontSize: 11.5, color: Pb.muted)),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final fs = widget.fontSize;
    // spelled out: a TextField otherwise takes 0.5 from the theme, and then charW
    // below would not be the real width of a character
    final style = Pb.mono(fs, height: _lineH).copyWith(letterSpacing: 0.5);
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    final rowH = _rowHFor == fs && _rowH != null ? _rowH! : fs * _lineH;

    final lines = _c.text.split('\n');
    final lineCount = lines.length;
    final longest = lines.fold<int>(0, (m, l) => math.max(m, l.length));
    final digits = math.max(2, '$lineCount'.length);

    final probe = TextPainter(text: TextSpan(text: '0' * 20, style: style), textDirection: TextDirection.ltr)..layout();
    final charW = probe.width / 20;
    probe.dispose();
    final gutterW = (digits * charW + 22).ceilToDouble();
    final cur = _currentLine;
    final ghost = _ghost;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureText(style, strut, rowH));
    // the numbers sit on the code's baseline; until the field is read, a guess
    final rowProbe = TextPainter(text: TextSpan(text: '0', style: style), strutStyle: strut, textDirection: TextDirection.ltr)..layout();
    final baseline = _baseline ?? rowProbe.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    rowProbe.dispose();
    final rowTop = _rowTop(rowH);
    final ghostParts = ghost?.text.split('\n') ?? const <String>[];
    final ghostLong = ghostParts.fold<int>(0, (m, l) => math.max(m, l.length));
    final ghostCol = ghost == null ? 0 : ghost.at - (_c.text.lastIndexOf('\n', math.max(0, ghost.at - 1)) + 1);

    return LayoutBuilder(
      builder: (context, box) {
        final viewH = box.maxHeight.isFinite ? box.maxHeight : 420.0;
        final viewW = box.maxWidth.isFinite ? box.maxWidth : 600.0;
        final textW = math.max(viewW - gutterW, (longest + ghostCol + ghostLong) * charW + 60);
        final contentH = math.max(viewH, (lineCount + ghostParts.length) * rowH + _padV * 2 + viewH * 0.35);

        final field = Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: Pb.primary.withOpacity(0.25),
              cursorColor: Pb.text,
              selectionHandleColor: Pb.primary,
            ),
          ),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: TextField(
              key: _fieldKey,
              controller: _c,
              focusNode: _focus,
              undoController: widget.undoController,
              readOnly: widget.readOnly,
              showCursor: !widget.readOnly,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              cursorColor: Pb.text,
              cursorWidth: 2,
              strutStyle: strut,
              style: style,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
              ),
            ),
          ),
        );

        return ColoredBox(
          color: Pb.editorBg,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: gutterW,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Pb.editorGutter, border: Border(right: BorderSide(color: Pb.border))),
                ),
              ),
              Scrollbar(
                controller: _v,
                child: SingleChildScrollView(
                  controller: _v,
                  child: SizedBox(
                    height: contentH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: gutterW,
                          child: CustomPaint(
                            painter: _GutterPainter(
                              scroll: _v,
                              viewH: viewH,
                              lineCount: lineCount,
                              current: cur,
                              rowH: rowH,
                              padV: rowTop,
                              baseline: _baseline == null ? baseline : _textTop + _baseline! - rowTop,
                              style: Pb.mono(fs - 2, color: Pb.muted, height: _lineH),
                              activeStyle: Pb.mono(fs - 2, color: Pb.text, height: _lineH),
                              activeBg: Pb.editorActiveLine,
                              marks: _worstByLine(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _h,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: textW,
                              child: Stack(
                                children: [
                                  if (cur > 0 && !widget.readOnly)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: rowTop + (cur - 1) * rowH,
                                      height: rowH,
                                      child: ColoredBox(color: Pb.editorActiveLine.withOpacity(0.35)),
                                    ),
                                  Positioned.fill(
                                    child: MouseRegion(
                                      opaque: false,
                                      onHover: widget.issues.isEmpty
                                          ? null
                                          : (e) {
                                              final h = _issueAt(e.localPosition, rowH, charW, lines);
                                              if (h != _hover) setState(() => _hover = h);
                                            },
                                      onExit: (_) {
                                        if (_hover != null) setState(() => _hover = null);
                                      },
                                      child: field,
                                    ),
                                  ),
                                  if (widget.issues.isNotEmpty)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: _SquigglePainter(widget.issues, lines, rowH: rowH, charW: charW, padV: rowTop, padH: _padH),
                                        ),
                                      ),
                                    ),
                                  if (ghost != null) ..._ghostLayers(ghost, style, strut, rowH, charW),
                                  if (_hover != null && widget.issues.contains(_hover))
                                    Positioned(
                                      left: math.max(0, math.min(_padH + _hover!.col * charW, textW - 340)),
                                      top: rowTop + _hover!.line * rowH + 2,
                                      child: IgnorePointer(child: _bubble(_hover!)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GutterPainter extends CustomPainter {
  final ScrollController scroll;
  final double viewH;
  final int lineCount;
  final int current;
  final double rowH;
  final double padV;
  final double baseline; // from the top of a row to the code's baseline
  final TextStyle style;
  final TextStyle activeStyle;
  final Color activeBg;
  final Map<int, Color> marks; // line -> colour of its worst issue

  _GutterPainter({
    required this.scroll,
    required this.viewH,
    required this.lineCount,
    required this.current,
    required this.rowH,
    required this.padV,
    required this.baseline,
    required this.style,
    required this.activeStyle,
    required this.activeBg,
    this.marks = const {},
  }) : super(repaint: scroll);

  @override
  void paint(Canvas canvas, Size size) {
    final off = scroll.hasClients ? scroll.offset : 0.0;
    final first = math.max(0, ((off - padV) / rowH).floor() - 2);
    final last = math.min(lineCount - 1, ((off + viewH - padV) / rowH).ceil() + 2);
    for (var i = first; i <= last; i++) {
      final active = i + 1 == current;
      final top = padV + i * rowH;
      if (active) canvas.drawRect(Rect.fromLTWH(0, top, size.width - 1, rowH), Paint()..color = activeBg);
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: active ? activeStyle : style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - 10 - tp.width, top + baseline - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
      tp.dispose();
      final m = marks[i + 1];
      if (m != null) canvas.drawCircle(Offset(5, top + rowH / 2), 3, Paint()..color = m);
    }
  }

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.lineCount != lineCount ||
      old.current != current ||
      old.rowH != rowH ||
      old.padV != padV ||
      old.baseline != baseline ||
      old.viewH != viewH ||
      old.style != style ||
      old.activeBg != activeBg ||
      !_sameMarks(old.marks, marks);

  static bool _sameMarks(Map<int, Color> a, Map<int, Color> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}

/// Wavy underlines under the issues (a whole-line issue: under the line's text).
class _SquigglePainter extends CustomPainter {
  final List<StyleIssue> issues;
  final List<String> lines;
  final double rowH, charW, padV, padH;

  _SquigglePainter(this.issues, this.lines, {required this.rowH, required this.charW, required this.padV, required this.padH});

  @override
  void paint(Canvas canvas, Size size) {
    for (final i in issues) {
      if (i.line < 1 || i.line > lines.length) continue;
      final text = lines[i.line - 1];
      var col = i.col;
      var len = i.len;
      if (len == 0) {
        col = text.length - text.trimLeft().length;
        len = math.max(1, text.trim().length);
      }
      final x0 = padH + col * charW;
      final x1 = x0 + math.max(1, len) * charW;
      final y = padV + i.line * rowH - 3;
      final c = CodeEditor.colorOf(i.level);
      if (text.trim().isEmpty && i.len == 0) {
        canvas.drawRect(Rect.fromLTWH(0, y - rowH + 3, size.width, rowH), Paint()..color = c.withOpacity(0.07));
        continue;
      }
      final path = Path()..moveTo(x0, y);
      const w = 3.0, h = 1.6;
      var up = true;
      for (var x = x0; x < x1; x += w) {
        path.lineTo(math.min(x + w, x1), y + (up ? -h : h));
        up = !up;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = i.level == IssueLevel.error ? 1.5 : 1.2,
      );
      if (i.level == IssueLevel.error) {
        canvas.drawRect(Rect.fromLTRB(x0 - 1, y - rowH + 4, x1 + 1, y + 1), Paint()..color = c.withOpacity(0.10));
      }
    }
  }

  @override
  bool shouldRepaint(_SquigglePainter old) => true; // cheap, and the text under it moves
}

// =============================================================================
// CODE WORKBENCH — editor + toolbar + input/output console, runs on Judge0.
// Used by the teacher's Atelier and by the student's copy of a sent file.
// =============================================================================
class CodeWorkbench extends StatefulWidget {
  final String initialCode;
  final String initialLang;
  final String initialStdin;
  final bool readOnly;
  final bool compact; // phone layout
  final ValueChanged<String>? onCodeChanged;
  final ValueChanged<String>? onLangChanged; // null = language is fixed
  final ValueChanged<String>? onStdinChanged;
  final List<Widget> actions; // extra buttons before "Rulează"
  final bool styleCheck; // the Stil tab: the coding style, drawn in the code
  final bool sideConsole; // on a wide screen, input and output beside the code
  final bool autocomplete; // the grey suggestions, built in or from Claude Code

  const CodeWorkbench({
    super.key,
    required this.initialCode,
    this.initialLang = 'cpp',
    this.initialStdin = '',
    this.readOnly = false,
    this.compact = false,
    this.onCodeChanged,
    this.onLangChanged,
    this.onStdinChanged,
    this.actions = const [],
    this.styleCheck = false,
    this.sideConsole = false,
    this.autocomplete = false,
  });

  @override
  State<CodeWorkbench> createState() => _CodeWorkbenchState();
}

class _CodeWorkbenchState extends State<CodeWorkbench> {
  static const String _fontKey = 'ide_font_size';
  static const Color _green = Color(0xFF10B981);
  static const Color _red = Color(0xFFE5484D);
  static const Color _amber = Color(0xFFF59E0B);

  static const Map<String, List<(String, String)>> _snippets = {
    'cpp': [
      ('Citește o valoare', 'cin >> |;'),
      ('Afișează o valoare', 'cout << | << "\\n";'),
      ('for', 'for (int i = 0; i < n; i++) {\n    |\n}'),
      ('while', 'while (|) {\n    \n}'),
      ('if / else', 'if (|) {\n    \n} else {\n    \n}'),
      ('Funcție', 'int f(int x) {\n    |\n    return 0;\n}'),
      ('Citește un vector', 'int n;\ncin >> n;\nvector<int> v(n);\nfor (int i = 0; i < n; i++) {\n    cin >> v[i];\n}|'),
      ('Fișiere', 'ifstream fin("date.in");\nofstream fout("date.out");|'),
      ('Program complet', '#include <iostream>\nusing namespace std;\n\nint main() {\n    |\n    return 0;\n}'),
    ],
    'python': [
      ('Citește un număr', 'n = int(input())|'),
      ('Citește o listă', 'v = list(map(int, input().split()))|'),
      ('Afișează', 'print(|)'),
      ('for', 'for i in range(n):\n    |'),
      ('while', 'while |:\n    '),
      ('if / elif / else', 'if |:\n    \nelif :\n    \nelse:\n    '),
      ('Funcție', 'def f(x):\n    |\n    return 0'),
    ],
  };

  late final CodeController _code = CodeController(text: widget.initialCode, lang: widget.initialLang);
  late final TextEditingController _stdin = TextEditingController(text: widget.initialStdin);
  final UndoHistoryController _undo = UndoHistoryController();
  final FocusNode _focus = FocusNode();

  double _font = 14.5;
  double _consoleH = 190;
  double _sideW = 420;
  int _tab = 0; // 0 input, 1 output, 2 style
  bool _running = false;
  RunResult? _result;
  String _lastText = '';
  List<StyleIssue> _style = const [];
  List<StyleIssue> _compile = const []; // the last run's errors, until the code changes
  Timer? _lint;
  CodeAssistant? _ai;

  @override
  void initState() {
    super.initState();
    _lastText = _code.text;
    _code.addListener(_onCode);
    if (widget.autocomplete && !widget.readOnly) {
      _ai = CodeAssistant(_code); // the editor and the status line listen to it themselves
    }
    _relint();
    BrowserRun.warm(_code.lang);
    SharedPreferences.getInstance().then((p) {
      final f = p.getDouble(_fontKey);
      if (f != null && mounted) setState(() => _font = f.clamp(11.0, 22.0).toDouble());
    });
  }

  @override
  void dispose() {
    _lint?.cancel();
    _ai?.dispose();
    _code.removeListener(_onCode);
    _code.dispose();
    _stdin.dispose();
    _undo.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onCode() {
    if (_code.text != _lastText) {
      _lastText = _code.text;
      widget.onCodeChanged?.call(_code.text);
      _lint?.cancel();
      _lint = Timer(const Duration(milliseconds: 400), _relint);
      // the compiler's marks are for the old text; only then is there anything
      // here to redraw: the editor and the status line follow the code themselves
      if (_compile.isNotEmpty && mounted) setState(() => _compile = const []);
    }
  }

  void _relint() {
    if (!widget.styleCheck) return;
    final issues = CodeStyle.check(_code.text, lang: _code.lang);
    if (mounted) setState(() => _style = issues);
  }

  List<StyleIssue> get _issues => [..._compile, if (widget.styleCheck) ..._style];

  /// Puts the caret at [i] in the code.
  void _jump(StyleIssue i) {
    final lines = _code.text.split('\n');
    if (i.line < 1 || i.line > lines.length) return;
    var at = 0;
    for (var k = 0; k < i.line - 1; k++) {
      at += lines[k].length + 1;
    }
    at += math.min(i.col, lines[i.line - 1].length);
    _code.selection = TextSelection.collapsed(offset: at);
    _focus.requestFocus();
  }

  void _applyFix(StyleIssue i) {
    final f = i.fix;
    if (f == null || f.end > _code.text.length) return;
    _code.value = TextEditingValue(
      text: _code.text.replaceRange(f.start, f.end, f.text),
      selection: TextSelection.collapsed(offset: f.start + f.text.length),
    );
    _lint?.cancel();
    _relint();
  }

  void _fixAll() {
    // fixes can make new ones possible (an indent after a line was split): a few rounds
    var t = _code.text;
    for (var round = 0; round < 4; round++) {
      final issues = CodeStyle.check(t, lang: _code.lang);
      if (!issues.any((i) => i.fix != null)) break;
      t = CodeStyle.fixAll(t, issues);
    }
    if (t == _code.text) return;
    _code.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: math.min(_code.selection.baseOffset, t.length).clamp(0, t.length)));
    _lint?.cancel();
    _relint();
  }

  void _setFont(double d) {
    setState(() => _font = (_font + d).clamp(11.0, 22.0).toDouble());
    SharedPreferences.getInstance().then((p) => p.setDouble(_fontKey, _font));
  }

  void _setLang(String lang) {
    if (lang == _code.lang) return;
    setState(() => _code.lang = lang);
    _relint();
    BrowserRun.warm(lang);
    widget.onLangChanged?.call(lang);
  }

  Future<void> _run() async {
    if (_running || _code.text.trim().isEmpty) return;
    setState(() {
      _running = true;
      _tab = 1;
    });
    final code = _code.text;
    final r = await Judge0.run(code: code, stdin: _stdin.text, lang: _code.lang);
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = r;
      _compile = code == _code.text ? CodeStyle.fromCompiler(r.error, code, lang: _code.lang) : const [];
    });
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what copiat.'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
  }

  (int, int) get _lnCol {
    final o = _code.selection.baseOffset;
    if (o < 0 || o > _code.text.length) return (1, 1);
    final before = _code.text.substring(0, o);
    final ln = '\n'.allMatches(before).length + 1;
    return (ln, o - (before.lastIndexOf('\n') + 1) + 1);
  }

  // ---------------------------------------------------------------- pieces
  Widget _icon(IconData i, String tip, VoidCallback? f) => IconButton(
        icon: Icon(i, size: 18),
        color: Pb.muted,
        disabledColor: Pb.muted.withOpacity(0.35),
        tooltip: tip,
        splashRadius: 17,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
        onPressed: f,
      );

  Widget _langPill() {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: Pb.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code, size: 15, color: Pb.primary),
          const SizedBox(width: 6),
          Text(_code.lang == 'python' ? 'Python 3' : 'C++', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
          if (widget.onLangChanged != null && !widget.readOnly) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 18, color: Pb.muted),
          ],
        ],
      ),
    );
    if (widget.onLangChanged == null || widget.readOnly) return pill;
    return PopupMenuButton<String>(
      tooltip: 'Limbaj',
      color: Pb.surface,
      padding: EdgeInsets.zero,
      onSelected: _setLang,
      itemBuilder: (_) => [
        PopupMenuItem(value: 'cpp', child: Text('C++', style: TextStyle(fontSize: 14, color: Pb.text))),
        PopupMenuItem(value: 'python', child: Text('Python 3', style: TextStyle(fontSize: 14, color: Pb.text))),
      ],
      child: pill,
    );
  }

  Widget _header() {
    final small = widget.compact;
    return SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            _langPill(),
            // Tools scroll sideways on narrow screens; Run always stays visible.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.readOnly) ...[
                      PopupMenuButton<String>(
                        tooltip: 'Inserează un șablon',
                        color: Pb.surface,
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.add_box_outlined, size: 18, color: Pb.muted),
                        onSelected: (s) {
                          _code.insertSnippet(s);
                          _focus.requestFocus();
                        },
                        itemBuilder: (_) => [
                          for (final s in _snippets[_code.lang] ?? const <(String, String)>[])
                            PopupMenuItem(value: s.$2, height: 38, child: Text(s.$1, style: TextStyle(fontSize: 13.5, color: Pb.text))),
                        ],
                      ),
                      ValueListenableBuilder<UndoHistoryValue>(
                        valueListenable: _undo,
                        builder: (_, v, __) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _icon(Icons.undo, 'Anulează (Ctrl+Z)', v.canUndo ? _undo.undo : null),
                            _icon(Icons.redo, 'Refă (Ctrl+Y)', v.canRedo ? _undo.redo : null),
                          ],
                        ),
                      ),
                    ],
                    if (!small) ...[
                      _icon(Icons.text_decrease, 'Text mai mic', () => _setFont(-1)),
                      _icon(Icons.text_increase, 'Text mai mare', () => _setFont(1)),
                      _icon(Icons.copy_all_outlined, 'Copiază codul', () => _copy(_code.text, 'Codul a fost')),
                    ],
                    ...widget.actions,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Rulează (Ctrl+Enter)',
              child: PbButton(
                text: _running ? 'Rulează...' : 'Rulează',
                icon: Icons.play_arrow,
                variant: PbVariant.success,
                size: PbSize.sm,
                loading: _running,
                onPressed: _running ? null : _run,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consoleTab(int i, String label, {Widget? trailing}) {
    final sel = _tab == i;
    return InkWell(
      onTap: () => setState(() => _tab = i),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? Pb.primary : Colors.transparent, width: 2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing],
          ],
        ),
      ),
    );
  }

  (String, Color) _statusOf(RunResult r) {
    final problem = r.problem;
    if (problem != null) return (problem, r.timedOut ? _amber : _red);
    final s = r.status;
    if (s == 'Accepted') return ('Rulat cu succes', _green);
    return (s.isEmpty ? 'Terminat' : s, _amber);
  }

  Widget _output() {
    if (_running) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)),
            const SizedBox(width: 10),
            Text(
              _code.lang == 'python' && !BrowserRun.ready('python') ? 'Se pregătește Python (doar prima dată)...' : 'Se compilează și se rulează...',
              style: TextStyle(fontSize: 13.5, color: Pb.muted),
            ),
          ],
        ),
      );
    }
    final r = _result;
    if (r == null) {
      return Center(
        child: Text('Apasă Rulează ca să vezi ce afișează programul.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
      );
    }
    final (label, color) = _statusOf(r);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(999)),
              child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
            ),
            if (r.seconds != null) Text('${(r.seconds! * 1000).round()} ms', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            if (r.memoryKb != null) Text('${(r.memoryKb! / 1024).toStringAsFixed(1)} MB', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
          ],
        ),
        if (r.stdout.isNotEmpty) ...[
          const SizedBox(height: 10),
          SelectableText(r.stdout, style: Pb.mono(13.5)),
        ] else if (r.error.isEmpty) ...[
          const SizedBox(height: 10),
          Text('Programul nu a afișat nimic.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
        ],
        if (_compile.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final i in _compile) _issueRow(i),
        ],
        if (r.error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _red.withOpacity(0.07), borderRadius: BorderRadius.circular(8), border: Border.all(color: _red.withOpacity(0.3))),
            child: SelectableText(r.error, style: Pb.mono(12.5, color: Pb.dangerText)),
          ),
        ],
      ],
    );
  }

  Color get _worstColor => _style.isEmpty ? _green : CodeEditor.colorOf(_style.map((i) => i.level).reduce((a, b) => a.index < b.index ? a : b));

  Widget _issueRow(StyleIssue i) {
    final c = CodeEditor.colorOf(i.level);
    final icon = switch (i.level) { IssueLevel.error => Icons.error_outline, IssueLevel.warning => Icons.warning_amber_rounded, IssueLevel.hint => Icons.lightbulb_outline };
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _jump(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: c)),
            const SizedBox(width: 8),
            SizedBox(width: 58, child: Text('Linia ${i.line}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.message.replaceAll('`', ''), style: TextStyle(fontSize: 13, color: Pb.text, height: 1.35)),
                  if (i.detail.isNotEmpty) Text(i.detail, style: Pb.mono(11.5, color: Pb.muted)),
                ],
              ),
            ),
            if (i.fix != null && !widget.readOnly)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: TextButton(
                  onPressed: () => _applyFix(i),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    foregroundColor: Pb.primary,
                  ),
                  child: const Text('Repară', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _styleView() {
    final score = CodeStyle.score(_style);
    final color = score >= 90 ? _green : (score >= 70 ? _amber : _red);
    final fixable = _style.where((i) => i.fix != null).length;
    int count(IssueLevel l) => _style.where((i) => i.level == l).length;
    Widget chip(IssueLevel l, String label) {
      final n = count(l);
      if (n == 0) return const SizedBox.shrink();
      final c = CodeEditor.colorOf(l);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
        child: Text('$n $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      children: [
        Row(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: score / 100, strokeWidth: 4.5, color: color, backgroundColor: color.withOpacity(0.15)),
                  Center(child: Text('$score', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _style.isEmpty ? 'Cod scris îngrijit' : (score >= 90 ? 'Aproape perfect' : (score >= 70 ? 'Câteva lucruri de aranjat' : 'Codul are nevoie de ordine')),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text),
                  ),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    chip(IssueLevel.error, count(IssueLevel.error) == 1 ? 'eroare' : 'erori'),
                    chip(IssueLevel.warning, count(IssueLevel.warning) == 1 ? 'avertisment' : 'avertismente'),
                    chip(IssueLevel.hint, count(IssueLevel.hint) == 1 ? 'sugestie' : 'sugestii'),
                  ]),
                ],
              ),
            ),
            if (fixable > 0 && !widget.readOnly)
              PbButton(text: 'Repară tot ($fixable)', icon: Icons.auto_fix_high, variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _fixAll),
          ],
        ),
        const SizedBox(height: 10),
        if (_style.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Indentarea, spațiile și parantezele sunt în regulă.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
          )
        else
          for (final i in _style) _issueRow(i),
      ],
    );
  }

  Widget _console() {
    final r = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Pb.border))),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Flexible(child: _consoleTab(0, 'Date de intrare')),
              Flexible(
                child: _consoleTab(
                  1,
                  'Rezultat',
                  trailing: r == null || _running
                      ? null
                      : Container(width: 7, height: 7, decoration: BoxDecoration(color: _statusOf(r).$2, shape: BoxShape.circle)),
                ),
              ),
              if (widget.styleCheck)
                Flexible(
                  child: _consoleTab(
                    2,
                    'Stil',
                    trailing: _style.isEmpty
                        ? const Icon(Icons.check, size: 14, color: _green)
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: _worstColor.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                            child: Text('${_style.length}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _worstColor)),
                          ),
                  ),
                ),
              const Spacer(),
              if (_tab == 1 && r != null && r.stdout.isNotEmpty) _icon(Icons.copy_outlined, 'Copiază rezultatul', () => _copy(r.stdout, 'Rezultatul a fost')),
              if (_tab == 1 && r != null) _icon(Icons.delete_sweep_outlined, 'Golește', () => setState(() => _result = null)),
            ],
          ),
        ),
        Expanded(
          child: _tab == 2
              ? _styleView()
              : _tab == 0
              ? TextField(
                  controller: _stdin,
                  onChanged: widget.onStdinChanged,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: Pb.mono(13.5),
                  cursorColor: Pb.text,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Ce citește programul de la tastatură (opțional)',
                    hintStyle: TextStyle(fontSize: 13.5, color: Pb.muted),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                )
              : _output(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- autocomplete
  static String _aiLabel(CodeAssistant ai) {
    if (!ai.enabled) return 'Completare oprită';
    return switch (ai.link) {
      ClaudeLink.off => 'Completare',
      ClaudeLink.connecting => 'Caut Claude Code...',
      ClaudeLink.ready => ai.thinking ? 'Claude scrie...' : 'Claude',
      ClaudeLink.unreachable => 'Claude Code oprit',
    };
  }

  static Color _aiColor(CodeAssistant ai) {
    if (!ai.enabled) return Pb.muted;
    return switch (ai.link) {
      ClaudeLink.ready => ai.problem != null ? _amber : Pb.primary,
      ClaudeLink.unreachable => _amber,
      _ => Pb.muted,
    };
  }

  Widget _aiChip(CodeAssistant ai) {
    final c = _aiColor(ai);
    return Tooltip(
      message: 'Sugestii în cod: Tab acceptă, Esc renunță',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _aiDialog(ai),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: c),
              const SizedBox(width: 5),
              Text(_aiLabel(ai), style: TextStyle(fontSize: 12, color: c, fontWeight: ai.link == ClaudeLink.ready ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  void _aiDialog(CodeAssistant ai) {
    showPbModal<void>(
      context,
      title: 'Completare automată',
      actions: (ctx) => [PbButton(text: 'Gata', size: PbSize.sm, onPressed: () => Navigator.of(ctx).pop())],
      body: ListenableBuilder(
        listenable: ai,
        builder: (_, __) {
          final muted = TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Sugestii în timp ce scrii', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text))),
                  Switch(value: ai.enabled, activeColor: Pb.primary, onChanged: ai.setEnabled),
                ],
              ),
              Text('Tab acceptă sugestia, Esc renunță, Ctrl+Space cere una acum. Merge din prima, fără cont și fără internet.', style: muted),
              const SizedBox(height: 16),
              Container(height: 1, color: Pb.border),
              const SizedBox(height: 14),
              Text('Mai inteligent, cu Claude Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
              const SizedBox(height: 4),
              if (ai.link == ClaudeLink.off) ...[
                Text('Dacă ai Claude Code pe calculator, el poate scrie sugestiile, folosind contul tău. Codul din IDE ajunge atunci la Claude.', style: muted),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PbButton(text: 'Conectează', icon: Icons.link, size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => ai.connect()),
                ),
              ] else ...[
                if (ai.link == ClaudeLink.ready)
                  Text('Conectat. Sugestiile vin de la Claude la aproximativ 2 secunde după ce te oprești din scris.', style: muted)
                else if (ai.link == ClaudeLink.connecting)
                  Text('Caut Claude Code pe calculatorul tău...', style: muted)
                else ...[
                  Text('Nu l-am găsit. Rulează asta într-un terminal și lasă-l deschis (îți trebuie Node și Claude Code):', style: muted),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                    decoration: BoxDecoration(color: Pb.editorBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: Pb.border)),
                    child: Row(
                      children: [
                        Expanded(child: SelectableText(CodeAssistant.setupCommand, style: Pb.mono(12, color: Pb.text))),
                        _icon(Icons.copy_all_outlined, 'Copiază comanda', () => _copy(CodeAssistant.setupCommand, 'Comanda a fost')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Dacă browserul întreabă de acces la rețeaua locală, permite. Safari nu lasă paginile să ajungă la calculatorul tău: folosește Chrome, Edge sau Firefox.', style: muted),
                ],
                if (ai.problem != null) ...[
                  const SizedBox(height: 8),
                  Text(ai.problem!, style: TextStyle(fontSize: 13, color: _amber, height: 1.35)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (ai.link != ClaudeLink.ready) ...[
                      PbButton(text: 'Verifică din nou', size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => ai.connect()),
                      const SizedBox(width: 8),
                    ],
                    PbButton(text: 'Deconectează', size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: ai.disconnect),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editor = CodeEditor(
      controller: _code,
      undoController: _undo,
      focusNode: _focus,
      readOnly: widget.readOnly,
      fontSize: widget.compact ? math.min(_font, 13.5) : _font,
      onRun: _run,
      issues: _issues,
      assistant: _ai,
    );

    // the status line follows the caret by itself, so moving it or typing
    // does not redraw the toolbar, the console and the panels
    final status = ListenableBuilder(
      listenable: Listenable.merge([_code, _ai]),
      builder: (context, _) {
        final (ln, col) = _lnCol;
        final lines = '\n'.allMatches(_code.text).length + 1;
        final here = _issues.where((i) => i.line == ln).toList()..sort((a, b) => a.level.index - b.level.index);
        return Container(
      decoration: BoxDecoration(color: Pb.hoverBg, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text('Ln $ln, Col $col', style: TextStyle(fontSize: 12, color: Pb.muted)),
          const SizedBox(width: 14),
          Text('$lines ${lines == 1 ? 'linie' : 'linii'}', style: TextStyle(fontSize: 12, color: Pb.muted)),
          const SizedBox(width: 14),
          if (_ai != null) ...[_aiChip(_ai!), const SizedBox(width: 14)],
          // the issue on the caret's line, so it is read without the mouse (on a phone too)
          Expanded(
            child: here.isEmpty
                ? (widget.compact
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Text('Tab: 4 spații  ·  Ctrl+/ comentează', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.muted)),
                      ))
                : InkWell(
                    onTap: () => setState(() => _tab = here.first.fromCompiler ? 1 : 2),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: CodeEditor.colorOf(here.first.level)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(here.first.message.replaceAll('`', ''),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.text)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
      },
    );

    return LayoutBuilder(
      builder: (context, box) {
        final side = widget.sideConsole && box.maxWidth >= 900;
        if (side) {
          final sideW = _sideW.clamp(300.0, box.maxWidth * 0.55).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Container(height: 1, color: Pb.border),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: editor), status])),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (d) => setState(() => _sideW = (sideW - d.delta.dx).clamp(300.0, box.maxWidth * 0.55).toDouble()),
                        child: Container(
                          width: 9,
                          decoration: BoxDecoration(color: Pb.surface, border: Border(left: BorderSide(color: Pb.border))),
                          alignment: Alignment.center,
                          child: Container(width: 3, height: 34, decoration: BoxDecoration(color: Pb.inputBorder, borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    ),
                    SizedBox(width: sideW, child: ColoredBox(color: Pb.surface, child: _console())),
                  ],
                ),
              ),
            ],
          );
        }
        final maxConsole = box.maxHeight.isFinite ? math.max(110.0, box.maxHeight * 0.65) : 320.0;
        final consoleH = _consoleH.clamp(96.0, maxConsole).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Container(height: 1, color: Pb.border),
            Expanded(child: editor),
            status,
            // drag handle
            MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) => setState(() => _consoleH = (consoleH - d.delta.dy).clamp(96.0, maxConsole).toDouble()),
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border))),
                  alignment: Alignment.center,
                  child: Container(width: 34, height: 3, decoration: BoxDecoration(color: Pb.inputBorder, borderRadius: BorderRadius.circular(2))),
                ),
              ),
            ),
            SizedBox(height: consoleH, child: ColoredBox(color: Pb.surface, child: _console())),
          ],
        );
      },
    );
  }
}
