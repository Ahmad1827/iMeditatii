// =============================================================================
// WHAT EVERY ACS WORKSPACE SHARES
//   A workspace gets its problem, the colours, and [Verdict]: it calls it with
//   true when the problem is solved (the page marks it and says so), false
//   when a check failed. [ChecksView] lists what was checked, ✓ or ✗.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../acs_data.dart';
import '../acs_kit.dart';

typedef Verdict = void Function(bool solved);

abstract class AcsWorkspace extends StatefulWidget {
  final AcsProblem problem;
  final AcsInk ink;
  final Verdict onVerdict;
  final bool narrow;
  const AcsWorkspace({super.key, required this.problem, required this.ink, required this.onVerdict, required this.narrow});
}

class Check {
  final String label;
  final bool ok;
  final String detail;
  const Check(this.label, this.ok, [this.detail = '']);
}

/// The checks, one per line: `[✓] label` or `[✗] label` with what was found.
class ChecksView extends StatelessWidget {
  final AcsInk ink;
  final List<Check> checks;
  final String? title;
  const ChecksView(this.ink, this.checks, {super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final ok = checks.isNotEmpty && checks.every((c) => c.ok);
    final passed = checks.where((c) => c.ok).length;
    return AcsBox(
      ink,
      title: title ?? (ok ? 'verificare: totul e corect' : 'verificare: $passed din ${checks.length}'),
      color: ink.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.ok ? '[✓] ' : '[✗] ', style: ink.mono(14, weight: FontWeight.w700, color: c.ok ? ink.good : ink.bad)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label, style: ink.mono(14, color: c.ok ? ink.fg : ink.strong)),
                        if (!c.ok && c.detail.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(c.detail, style: ink.mono(13, color: ink.muted)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A row of command buttons that wraps on a phone.
class ToolRow extends StatelessWidget {
  final List<Widget> children;
  final Widget? trailing;
  const ToolRow(this.children, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: children)),
          if (trailing != null) trailing!,
        ],
      );
}

/// A plain monospace text field in the section's look (a number, a short expression).
class AcsField extends StatelessWidget {
  final AcsInk ink;
  final TextEditingController controller;
  final String? hint;
  final double width;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool? ok; // green or red border after a check
  final TextAlign align;
  final FocusNode? focusNode;
  const AcsField(this.ink, this.controller,
      {super.key, this.hint, this.width = 160, this.onChanged, this.onSubmitted, this.ok, this.align = TextAlign.left, this.focusNode});

  @override
  Widget build(BuildContext context) {
    final border = ok == null ? ink.line : (ok! ? ink.good : ink.bad);
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        // Enter keeps the keyboard here, for the next line
        onEditingComplete: onSubmitted == null ? null : () {},
        textAlign: align,
        style: ink.mono(14.5, color: ink.strong),
        cursorColor: ink.accent,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: ink.mono(14, color: ink.dim),
          filled: true,
          fillColor: ink.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: border), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ok == null ? ink.accent : border, width: 1.5), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
        ),
      ),
    );
  }
}

/// A multi-line code editor in the section's look: line numbers, Tab indents,
/// a colour for comments, strings and keywords of [keywords].
class AcsCodeEditor extends StatefulWidget {
  final AcsInk ink;
  final TextEditingController controller;
  final double minHeight;
  final Set<String> keywords;
  final String comment; // '//', ';', '%' or '#'
  final VoidCallback? onRun; // Ctrl/Cmd+Enter
  final VoidCallback? onSave; // Ctrl/Cmd+S
  final int? markLine; // 1-based: the line being run (the emulator's step)
  final FocusNode? focusNode;
  const AcsCodeEditor(this.ink, this.controller,
      {super.key, this.minHeight = 320, this.keywords = const {}, this.comment = '//', this.onRun, this.onSave, this.markLine, this.focusNode});

  @override
  State<AcsCodeEditor> createState() => _AcsCodeEditorState();
}

class _HlController extends TextEditingController {
  final AcsInk Function() ink;
  final Set<String> Function() keywords;
  final String Function() comment;
  _HlController(String text, this.ink, this.keywords, this.comment) : super(text: text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final k = ink();
    final kw = keywords();
    final cm = comment();
    final spans = <TextSpan>[];
    final re = RegExp(
        '(${RegExp.escape(cm)}[^\\n]*${cm == '//' ? r'|/\*[\s\S]*?\*/' : ''})|("(?:[^"\\\\\\n]|\\\\.)*"|\'(?:[^\'\\\\\\n]|\\\\.)*\')|(\\b[A-Za-z_][A-Za-z0-9_.]*\\b)|(\\b\\d[\\w.]*\\b)|(#\\s*\\w+)');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final t = m[0]!;
      Color? c;
      FontWeight? w;
      if (m[1] != null) {
        c = k.dim;
      } else if (m[2] != null) {
        c = k.warn;
      } else if (m[3] != null) {
        if (kw.contains(t) || kw.contains(t.toLowerCase())) {
          c = k.accent;
          w = FontWeight.w700;
        }
      } else if (m[4] != null) {
        c = k.terminal ? k.warn : k.accent;
      } else if (m[5] != null) {
        c = k.muted;
      }
      spans.add(TextSpan(text: t, style: TextStyle(color: c, fontWeight: w)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }
}

class _AcsCodeEditorState extends State<AcsCodeEditor> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  final ScrollController _h = ScrollController();

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    _h.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final ctrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final c = widget.controller;
    if (ctrl && e.logicalKey == LogicalKeyboardKey.enter && widget.onRun != null) {
      widget.onRun!();
      return KeyEventResult.handled;
    }
    if (ctrl && e.logicalKey == LogicalKeyboardKey.keyS && widget.onSave != null) {
      widget.onSave!();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab) {
      final sel = c.selection;
      if (!sel.isValid) return KeyEventResult.handled;
      final shift = HardwareKeyboard.instance.isShiftPressed;
      if (!shift && sel.isCollapsed) {
        c.value = c.value.replaced(sel, '    ');
        return KeyEventResult.handled;
      }
      // indent or dedent the selected lines
      final text = c.text;
      final start = text.lastIndexOf('\n', sel.start - 1) + 1;
      final endNl = text.indexOf('\n', sel.end);
      final end = endNl < 0 ? text.length : endNl;
      final block = text.substring(start, end).split('\n');
      final changed = [for (final l in block) shift ? l.replaceFirst(RegExp(r'^ {1,4}|^\t'), '') : '    $l'].join('\n');
      c.value = TextEditingValue(text: text.replaceRange(start, end, changed), selection: TextSelection(baseOffset: start, extentOffset: start + changed.length));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter && !ctrl) {
      // keep the indentation of the line
      final sel = c.selection;
      if (!sel.isValid) return KeyEventResult.ignored;
      final text = c.text;
      final ls = text.lastIndexOf('\n', sel.start - 1) + 1;
      final indent = RegExp(r'^[ \t]*').stringMatch(text.substring(ls, sel.start)) ?? '';
      final before = text.substring(ls, sel.start).trimRight();
      final extra = before.endsWith('{') ? '    ' : '';
      c.value = c.value.replaced(sel, '\n$indent$extra');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    const size = 14.0;
    const lineH = 1.5;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final lines = '\n'.allMatches(widget.controller.text).length + 1;
        final gutter = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 1; i <= lines; i++)
              Container(
                color: widget.markLine == i ? ink.accent.withValues(alpha: 0.18) : null,
                padding: const EdgeInsets.only(right: 8, left: 6),
                child: Text('$i', style: ink.mono(size, color: widget.markLine == i ? ink.accent : ink.dim, height: lineH)),
              ),
          ],
        );
        return Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          decoration: BoxDecoration(color: ink.panel, border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(4)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 10), child: gutter),
              Container(width: 1, color: ink.line, constraints: BoxConstraints(minHeight: widget.minHeight)),
              Expanded(
                child: Focus(
                  onKeyEvent: _key,
                  skipTraversal: true,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    maxLines: null,
                    minLines: (widget.minHeight / (size * lineH)).floor() - 1,
                    keyboardType: TextInputType.multiline,
                    style: ink.mono(size, color: ink.strong, height: lineH),
                    strutStyle: const StrutStyle(fontFamily: acsFont, fontSize: size, height: lineH, forceStrutHeight: true),
                    cursorColor: ink.accent,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartQuotesType: SmartQuotesType.disabled,
                    smartDashesType: SmartDashesType.disabled,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10)),
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

/// A controller that colours [keywords] for [AcsCodeEditor].
TextEditingController acsCodeController(String text, Set<String> keywords, {String comment = '//'}) =>
    _HlController(text, () => AcsInk.current, () => keywords, () => comment);

/// True on a phone or tablet, where focusing a field opens the keyboard
/// (so nothing is focused before the student taps).
bool get acsTouchDevice => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

/// A console that takes the keyboard without a click: typing anywhere on the
/// page, while no other text field has the focus and the console is on the
/// screen, goes into [consoleInput] (the first character included).
mixin TypeToConsole<T extends StatefulWidget> on State<T> {
  FocusNode get consoleFocus;
  TextEditingController get consoleInput;

  /// The console's box, to know it is on the screen.
  final GlobalKey consoleKey = GlobalKey();

  /// False while something else is shown in its place (an editor).
  bool get consoleActive => true;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_typed);
    if (!acsTouchDevice) WidgetsBinding.instance.addPostFrameCallback((_) => focusConsole());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_typed);
    super.dispose();
  }

  /// Gives the console the keyboard (on a computer; on a phone only when asked).
  void focusConsole({bool evenOnTouch = false}) {
    if (!mounted || !consoleActive || (acsTouchDevice && !evenOnTouch)) return;
    consoleFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => reattachKeyboard());
  }

  /// On the web the focus can stay on the field while the browser's own text
  /// input has let go (after Enter, say): the cursor blinks and nothing types.
  /// This hands the keyboard back to the field that has the focus.
  void reattachKeyboard() {
    if (!mounted || !consoleActive) return;
    if (!consoleFocus.hasFocus) consoleFocus.requestFocus();
    EditableTextState? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is EditableTextState && (e.widget as EditableText).focusNode == consoleFocus) {
        found = e.state as EditableTextState;
        return;
      }
      e.visitChildren(visit);
    }

    final root = consoleKey.currentContext;
    if (root is Element) root.visitChildren(visit);
    found?.requestKeyboard();
  }

  bool _onScreen() {
    final box = consoleKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.maybeOf(context)?.size.height ?? 0;
    return top < h && top + box.size.height > 0;
  }

  bool _typed(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted || !consoleActive || consoleFocus.hasFocus) return false;
    final kb = HardwareKeyboard.instance;
    if (kb.isControlPressed || kb.isMetaPressed || kb.isAltPressed) return false;
    final ch = e.character;
    if (ch == null || ch.isEmpty || ch.codeUnitAt(0) < 0x20 || ch.codeUnitAt(0) == 0x7F) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    // another text field is being typed in: leave it alone
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx != null && (ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null)) return false;
    if (!_onScreen()) return false;
    final v = consoleInput.value;
    final at = v.selection.isValid ? v.selection.end : v.text.length;
    final text = v.text.replaceRange(at, at, ch);
    consoleInput.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: at + ch.length));
    consoleFocus.requestFocus();
    return true;
  }
}

/// Focuses [focus] when the area is tapped (a click, not a drag that selects
/// text), even inside a [SelectionArea], whose own gestures would win.
class TapToFocus extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const TapToFocus({super.key, required this.onTap, required this.child});

  @override
  State<TapToFocus> createState() => _TapToFocusState();
}

class _TapToFocusState extends State<TapToFocus> {
  Offset? _down;

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _down = e.position,
        onPointerUp: (e) {
          final d = _down;
          _down = null;
          if (d == null || (e.position - d).distance >= 6) return;
          // after the gestures inside (a SelectionArea focuses itself on a tap)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onTap();
          });
          WidgetsBinding.instance.scheduleFrame();
        },
        onPointerCancel: (_) => _down = null,
        child: widget.child,
      );
}

/// A button that throws work away (the starter code back, the files reset):
/// the first click asks "sigur?", the second, within a few seconds, does it.
class AcsConfirmButton extends StatefulWidget {
  final AcsInk ink;
  final String label;
  final VoidCallback? onConfirm;
  const AcsConfirmButton(this.ink, this.label, this.onConfirm, {super.key});

  @override
  State<AcsConfirmButton> createState() => _AcsConfirmButtonState();
}

class _AcsConfirmButtonState extends State<AcsConfirmButton> {
  bool _asking = false;
  int _token = 0;

  void _tap() {
    if (_asking) {
      setState(() => _asking = false);
      widget.onConfirm?.call();
      return;
    }
    final t = ++_token;
    setState(() => _asking = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _token == t) setState(() => _asking = false);
    });
  }

  @override
  Widget build(BuildContext context) => AcsButton(
        widget.ink,
        _asking ? 'sigur? se pierde ce ai scris · apasă din nou' : widget.label,
        widget.onConfirm == null ? null : _tap,
        icon: _asking ? Icons.warning_amber_rounded : null,
      );
}

/// The editor's keys, in small print after a row of buttons (none on a phone).
Widget acsKeysHint(AcsInk ink, String text) => acsTouchDevice
    ? const SizedBox.shrink()
    : Padding(padding: const EdgeInsets.only(left: 4), child: Text(text, style: ink.mono(12, color: ink.dim)));
