import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_run.dart';
import 'judge0.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, CodeHighlighter;

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

  const CodeEditor({
    super.key,
    required this.controller,
    this.undoController,
    this.focusNode,
    this.readOnly = false,
    this.fontSize = 14.5,
    this.onRun,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  static const double _lineH = 1.55;
  static const double _padV = 12;
  static const String _tab = '    ';
  static const Map<String, String> _pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};

  final ScrollController _v = ScrollController();
  final ScrollController _h = ScrollController();
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  CodeController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_changed);
  }

  @override
  void didUpdateWidget(CodeEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      _c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
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

  int _lineStart(int pos) => pos <= 0 ? 0 : _c.text.lastIndexOf('\n', pos - 1) + 1;

  int _lineEnd(int pos) {
    final i = _c.text.indexOf('\n', pos);
    return i < 0 ? _c.text.length : i;
  }

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

    final sel = _c.selection;
    if (!sel.isValid) return KeyEventResult.ignored;
    final text = _c.text;

    if (ctrl && key == LogicalKeyboardKey.slash) {
      _toggleComment();
      return KeyEventResult.handled;
    }
    if (ctrl || kb.isAltPressed) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.tab) {
      if (sel.isCollapsed && !shift) {
        _c.replace(sel.start, sel.end, _tab);
      } else {
        _indentLines(outdent: shift);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      final pos = sel.start;
      final line = text.substring(_lineStart(pos), pos);
      final base = RegExp(r'^[ \t]*').stringMatch(line) ?? '';
      final trimmed = line.trimRight();
      final opens = trimmed.endsWith('{') || trimmed.endsWith('(') || trimmed.endsWith('[') || (_c.lang == 'python' && trimmed.endsWith(':'));
      final next = sel.end < text.length ? text[sel.end] : '';
      if (opens && (next == '}' || next == ')' || next == ']')) {
        // "{|}" -> body on its own indented line, closer back on the base indent.
        _c.replace(pos, sel.end, '\n$base$_tab\n$base', caret: pos + 1 + base.length + _tab.length);
      } else {
        _c.replace(pos, sel.end, '\n$base${opens ? _tab : ''}');
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace && sel.isCollapsed && sel.start > 0) {
      final pos = sel.start;
      final prev = text[pos - 1];
      final next = pos < text.length ? text[pos] : '';
      if (_pairs[prev] == next && next.isNotEmpty) {
        _c.replace(pos - 1, pos + 1, '');
        return KeyEventResult.handled;
      }
      final before = text.substring(_lineStart(pos), pos);
      if (before.isNotEmpty && before.trim().isEmpty && before.length % _tab.length == 0 && !before.contains('\t')) {
        _c.replace(pos - _tab.length, pos, '');
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final ch = e.character;
    if (ch != null && ch.length == 1) {
      final next = sel.end < text.length ? text[sel.end] : '';
      // Typing a closer that is already there just steps over it.
      if (sel.isCollapsed && next == ch && _pairs.containsValue(ch)) {
        final isQuote = ch == '"' || ch == "'";
        if (!isQuote || (sel.start > 0 && text[sel.start - 1] != '\\')) {
          _c.selection = TextSelection.collapsed(offset: sel.start + 1);
          return KeyEventResult.handled;
        }
      }
      final close = _pairs[ch];
      if (close != null) {
        if (!sel.isCollapsed) {
          final inner = text.substring(sel.start, sel.end);
          _c.replace(sel.start, sel.end, '$ch$inner$close', caret: sel.start + 1, selectTo: sel.end + 1);
          return KeyEventResult.handled;
        }
        final isQuote = ch == '"' || ch == "'";
        final prev = sel.start > 0 ? text[sel.start - 1] : '';
        final roomAfter = next.isEmpty || RegExp(r'[\s)\]};,]').hasMatch(next);
        final wordBefore = RegExp(r'[A-Za-z0-9_\\]').hasMatch(prev);
        if (roomAfter && !(isQuote && wordBefore)) {
          _c.replace(sel.start, sel.end, '$ch$close', caret: sel.start + 1);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _indentLines({required bool outdent}) {
    final sel = _c.selection;
    final text = _c.text;
    final from = _lineStart(sel.start);
    // A selection that ends at column 0 does not include that last line.
    final lastPos = !sel.isCollapsed && sel.end > sel.start && text[sel.end - 1] == '\n' ? sel.end - 1 : sel.end;
    final to = _lineEnd(lastPos);
    final lines = text.substring(from, to).split('\n');
    var firstDelta = 0;
    var total = 0;
    for (var i = 0; i < lines.length; i++) {
      var d = 0;
      if (outdent) {
        final lead = RegExp(r'^ {1,4}|^\t').stringMatch(lines[i]) ?? '';
        lines[i] = lines[i].substring(lead.length);
        d = -lead.length;
      } else if (lines[i].isNotEmpty) {
        lines[i] = '$_tab${lines[i]}';
        d = _tab.length;
      }
      if (i == 0) firstDelta = d;
      total += d;
    }
    final out = lines.join('\n');
    _c.value = TextEditingValue(
      text: text.replaceRange(from, to, out),
      selection: TextSelection(
        baseOffset: math.max(from, sel.start + firstDelta),
        extentOffset: math.max(from, sel.end + total),
      ),
    );
  }

  void _toggleComment() {
    final mark = _c.lang == 'python' ? '#' : '//';
    final sel = _c.selection;
    final text = _c.text;
    final from = _lineStart(sel.start);
    final lastPos = !sel.isCollapsed && sel.end > sel.start && text[sel.end - 1] == '\n' ? sel.end - 1 : sel.end;
    final to = _lineEnd(lastPos);
    final lines = text.substring(from, to).split('\n');
    final live = lines.where((l) => l.trim().isNotEmpty);
    final allCommented = live.isNotEmpty && live.every((l) => l.trimLeft().startsWith(mark));
    var firstDelta = 0;
    var total = 0;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      final lead = l.length - l.trimLeft().length;
      String next;
      if (allCommented) {
        var rest = l.substring(lead + mark.length);
        if (rest.startsWith(' ')) rest = rest.substring(1);
        next = l.substring(0, lead) + rest;
      } else {
        next = '${l.substring(0, lead)}$mark ${l.substring(lead)}';
      }
      final d = next.length - l.length;
      if (i == 0) firstDelta = d;
      total += d;
      lines[i] = next;
    }
    _c.value = TextEditingValue(
      text: text.replaceRange(from, to, lines.join('\n')),
      selection: TextSelection(
        baseOffset: math.max(from, sel.start + firstDelta),
        extentOffset: math.max(from, sel.end + total),
      ),
    );
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final fs = widget.fontSize;
    final style = Pb.mono(fs, height: _lineH);
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    final rowH = fs * _lineH;

    final lines = _c.text.split('\n');
    final lineCount = lines.length;
    final longest = lines.fold<int>(0, (m, l) => math.max(m, l.length));
    final digits = math.max(2, '$lineCount'.length);

    final probe = TextPainter(text: TextSpan(text: '0' * 20, style: style), textDirection: TextDirection.ltr)..layout();
    final charW = probe.width / 20;
    probe.dispose();
    final gutterW = (digits * charW + 22).ceilToDouble();
    final cur = _currentLine;

    return LayoutBuilder(
      builder: (context, box) {
        final viewH = box.maxHeight.isFinite ? box.maxHeight : 420.0;
        final viewW = box.maxWidth.isFinite ? box.maxWidth : 600.0;
        final textW = math.max(viewW - gutterW, longest * charW + 60);
        final contentH = math.max(viewH, lineCount * rowH + _padV * 2 + viewH * 0.35);

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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: _padV),
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
                              padV: _padV,
                              style: Pb.mono(fs - 2, color: Pb.muted, height: _lineH),
                              activeStyle: Pb.mono(fs - 2, color: Pb.text, height: _lineH),
                              activeBg: Pb.editorActiveLine,
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
                                      top: _padV + (cur - 1) * rowH,
                                      height: rowH,
                                      child: ColoredBox(color: Pb.editorActiveLine.withOpacity(0.35)),
                                    ),
                                  Positioned.fill(child: field),
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
  final TextStyle style;
  final TextStyle activeStyle;
  final Color activeBg;

  _GutterPainter({
    required this.scroll,
    required this.viewH,
    required this.lineCount,
    required this.current,
    required this.rowH,
    required this.padV,
    required this.style,
    required this.activeStyle,
    required this.activeBg,
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
      tp.paint(canvas, Offset(size.width - 10 - tp.width, top + (rowH - tp.height) / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.lineCount != lineCount ||
      old.current != current ||
      old.rowH != rowH ||
      old.viewH != viewH ||
      old.style != style ||
      old.activeBg != activeBg;
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
  int _tab = 0; // 0 input, 1 output
  bool _running = false;
  RunResult? _result;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _lastText = _code.text;
    _code.addListener(_onCode);
    BrowserRun.warm(_code.lang);
    SharedPreferences.getInstance().then((p) {
      final f = p.getDouble(_fontKey);
      if (f != null && mounted) setState(() => _font = f.clamp(11.0, 22.0).toDouble());
    });
  }

  @override
  void dispose() {
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
    }
    if (mounted) setState(() {}); // Ln / Col
  }

  void _setFont(double d) {
    setState(() => _font = (_font + d).clamp(11.0, 22.0).toDouble());
    SharedPreferences.getInstance().then((p) => p.setDouble(_fontKey, _font));
  }

  void _setLang(String lang) {
    if (lang == _code.lang) return;
    setState(() => _code.lang = lang);
    BrowserRun.warm(lang);
    widget.onLangChanged?.call(lang);
  }

  Future<void> _run() async {
    if (_running || _code.text.trim().isEmpty) return;
    setState(() {
      _running = true;
      _tab = 1;
    });
    final r = await Judge0.run(code: _code.text, stdin: _stdin.text, lang: _code.lang);
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = r;
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
    if (r.failed) return ('Nu s-a putut rula', _red);
    final s = r.status;
    if (s == 'Accepted') return ('Rulat cu succes', _green);
    if (s == 'Compilation Error') return ('Eroare de compilare', _red);
    if (s.startsWith('Time Limit')) return ('Timp depășit', _amber);
    if (s.startsWith('Runtime Error')) return ('Eroare la rulare', _red);
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
              const Spacer(),
              if (_tab == 1 && r != null && r.stdout.isNotEmpty) _icon(Icons.copy_outlined, 'Copiază rezultatul', () => _copy(r.stdout, 'Rezultatul a fost')),
              if (_tab == 1 && r != null) _icon(Icons.delete_sweep_outlined, 'Golește', () => setState(() => _result = null)),
            ],
          ),
        ),
        Expanded(
          child: _tab == 0
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

  @override
  Widget build(BuildContext context) {
    final (ln, col) = _lnCol;
    final lines = '\n'.allMatches(_code.text).length + 1;

    return LayoutBuilder(
      builder: (context, box) {
        final maxConsole = box.maxHeight.isFinite ? math.max(110.0, box.maxHeight * 0.65) : 320.0;
        final consoleH = _consoleH.clamp(96.0, maxConsole).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Container(height: 1, color: Pb.border),
            Expanded(
              child: CodeEditor(
                controller: _code,
                undoController: _undo,
                focusNode: _focus,
                readOnly: widget.readOnly,
                fontSize: widget.compact ? math.min(_font, 13.5) : _font,
                onRun: _run,
              ),
            ),
            // status bar
            Container(
              decoration: BoxDecoration(color: Pb.hoverBg, border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text('Ln $ln, Col $col', style: TextStyle(fontSize: 12, color: Pb.muted)),
                  const SizedBox(width: 14),
                  Text('$lines ${lines == 1 ? 'linie' : 'linii'}', style: TextStyle(fontSize: 12, color: Pb.muted)),
                  const Spacer(),
                  if (!widget.compact) Text('Tab: 4 spații  ·  Ctrl+/ comentează', style: TextStyle(fontSize: 12, color: Pb.muted)),
                ],
              ),
            ),
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
