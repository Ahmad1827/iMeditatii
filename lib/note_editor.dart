import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'code_workbench.dart' show CodeController;
import 'ui_components.dart' show Pb, CodeHighlighter;
import 'workspace_models.dart';

// =============================================================================
// NOTE EDITOR — a page made of blocks (text, headings, lists, checklists,
// callouts, code and handwriting), in the spirit of OneNote.
//
// NoteEditor  editable, used in the teacher's Atelier
// NoteView    read-only, used for the copy a student receives
// =============================================================================

// ----------------------------------------------------------------- inline marks
final RegExp _inlineRe = RegExp(
  r'(\*\*(.+?)\*\*)' // 1,2 bold
  r'|(`([^`\n]+)`)' // 3,4 code
  r'|(==(.+?)==)' // 5,6 highlight
  r'|(~~(.+?)~~)' // 7,8 strike
  r'|(\*([^*\s][^*\n]*?)\*)', // 9,10 italic
);

/// Renders **bold**, *italic*, `code`, ==highlight== and ~~strike~~.
/// With [showMarkers] the markers stay in the text (dimmed) so the caret maps
/// one-to-one onto the raw string; without it they are dropped.
TextSpan noteInlineSpan(String text, TextStyle base, {required bool showMarkers}) {
  final children = <InlineSpan>[];
  final dim = base.copyWith(color: Pb.muted.withOpacity(0.55), fontWeight: FontWeight.w400, fontStyle: FontStyle.normal);
  var last = 0;

  for (final m in _inlineRe.allMatches(text)) {
    if (m.start > last) children.add(TextSpan(text: text.substring(last, m.start)));
    String mark;
    String inner;
    TextStyle st;
    if (m.group(1) != null) {
      mark = '**';
      inner = m.group(2)!;
      st = base.copyWith(fontWeight: FontWeight.w700);
    } else if (m.group(3) != null) {
      mark = '`';
      inner = m.group(4)!;
      st = Pb.mono((base.fontSize ?? 16) * 0.9, color: Pb.text, height: base.height ?? 1.5).copyWith(backgroundColor: Pb.codeChip);
    } else if (m.group(5) != null) {
      mark = '==';
      inner = m.group(6)!;
      st = base.copyWith(backgroundColor: const Color(0xFFFDE047).withOpacity(0.55), color: const Color(0xFF1F2937));
    } else if (m.group(7) != null) {
      mark = '~~';
      inner = m.group(8)!;
      st = base.copyWith(decoration: TextDecoration.lineThrough, color: Pb.muted);
    } else {
      mark = '*';
      inner = m.group(10)!;
      st = base.copyWith(fontStyle: FontStyle.italic);
    }
    if (showMarkers) children.add(TextSpan(text: mark, style: dim));
    children.add(TextSpan(text: inner, style: st));
    if (showMarkers) children.add(TextSpan(text: mark, style: dim));
    last = m.end;
  }
  if (last < text.length) children.add(TextSpan(text: text.substring(last)));
  return TextSpan(style: base, children: children);
}

class InlineController extends TextEditingController {
  InlineController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    return noteInlineSpan(text, style ?? const TextStyle(), showMarkers: true);
  }
}

// ----------------------------------------------------------------- shared look
TextStyle noteTextStyle(NoteBlock b, {bool done = false}) {
  switch (b.type) {
    case NoteBlock.h1:
      return TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: Pb.text, height: 1.3, letterSpacing: -0.4);
    case NoteBlock.h2:
      return TextStyle(fontSize: 20.5, fontWeight: FontWeight.w700, color: Pb.text, height: 1.35, letterSpacing: -0.2);
    case NoteBlock.quote:
      return TextStyle(fontSize: 16, color: Pb.muted, height: 1.6, fontStyle: FontStyle.italic);
    case NoteBlock.code:
      return Pb.mono(13.5, height: 1.55);
    case NoteBlock.todo:
      return TextStyle(
        fontSize: 16,
        color: done ? Pb.muted : Pb.text,
        height: 1.6,
        decoration: done ? TextDecoration.lineThrough : null,
      );
    default:
      return TextStyle(fontSize: 16, color: Pb.text, height: 1.6);
  }
}

const Color _calloutColor = Color(0xFFF59E0B);

/// Wraps a block's content with whatever sits around it: bullet, number,
/// checkbox, quote bar, callout box, code frame.
Widget noteBlockShell({
  required NoteBlock b,
  required int number,
  required Widget child,
  bool done = false,
  ValueChanged<bool>? onCheck,
  Widget? codeHeader,
}) {
  Widget lead(Widget w) => SizedBox(width: 30, height: 16 * 1.6, child: Align(alignment: Alignment.centerLeft, child: w));

  switch (b.type) {
    case NoteBlock.bullet:
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        lead(Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: Pb.text, shape: BoxShape.circle)),
        )),
        Expanded(child: child),
      ]);
    case NoteBlock.numbered:
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        lead(Text('$number.', style: TextStyle(fontSize: 16, color: Pb.muted, height: 1.6))),
        Expanded(child: child),
      ]);
    case NoteBlock.todo:
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        lead(
          MouseRegion(
            cursor: onCheck == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onCheck == null ? null : () => onCheck(!done),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: done ? Pb.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: done ? Pb.primary : Pb.inputBorder, width: 1.6),
                ),
                child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ]);
    case NoteBlock.quote:
      return Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: Pb.inputBorder, width: 3))),
        child: child,
      );
    case NoteBlock.callout:
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: _calloutColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _calloutColor.withOpacity(0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 3, right: 10), child: Icon(Icons.lightbulb_outline, size: 19, color: _calloutColor)),
          Expanded(child: child),
        ]),
      );
    case NoteBlock.code:
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Pb.codeBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (codeHeader != null) codeHeader,
            Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: child),
          ],
        ),
      );
    default:
      return child;
  }
}

double _blockGap(NoteBlock b) {
  switch (b.type) {
    case NoteBlock.h1:
      return 14;
    case NoteBlock.h2:
      return 12;
    case NoteBlock.code:
    case NoteBlock.callout:
    case NoteBlock.draw:
    case NoteBlock.divider:
      return 8;
    default:
      return 1;
  }
}

Widget _dividerLine() => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Container(height: 1, color: Pb.border));

// =============================================================================
// INK
// =============================================================================
const Color _paper = Color(0xFFFDFDFB);
const Color _paperRule = Color(0xFFDCE3EC);

class _InkPainter extends CustomPainter {
  final List<NoteStroke> strokes;
  final String paper;

  _InkPainter({required this.strokes, required this.paper, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rule = Paint()
      ..color = _paperRule
      ..strokeWidth = 1;
    if (paper == 'grid' || paper == 'lines') {
      final step = w / (paper == 'grid' ? 30 : 22);
      for (var y = step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(w, y), rule);
      }
      if (paper == 'grid') {
        for (var x = step; x < w; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), rule);
        }
      }
    }

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(s.color).withOpacity(s.marker ? 0.32 : 1)
        ..strokeWidth = math.max(1, s.width * w)
        ..strokeCap = s.marker ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final pts = s.points;
      if (pts.length == 1) {
        canvas.drawCircle(pts.first * w, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(pts.first.dx * w, pts.first.dy * w);
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = (pts[i] + pts[i + 1]) / 2;
        path.quadraticBezierTo(pts[i].dx * w, pts[i].dy * w, mid.dx * w, mid.dy * w);
      }
      path.lineTo(pts.last.dx * w, pts.last.dy * w);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => old.strokes != strokes || old.paper != paper;
}

/// Claims the pointer straight away, so drawing never turns into page scrolling.
class _EagerPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _InkView extends StatelessWidget {
  final NoteBlock block;
  const _InkView({required this.block});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(color: _paper, border: Border.all(color: Pb.border), borderRadius: BorderRadius.circular(10)),
        child: AspectRatio(
          aspectRatio: 1 / block.ratio,
          child: CustomPaint(painter: _InkPainter(strokes: block.strokes, paper: block.paper)),
        ),
      ),
    );
  }
}

class _InkPad extends StatefulWidget {
  final NoteBlock block;
  final VoidCallback onChanged;
  const _InkPad({super.key, required this.block, required this.onChanged});

  @override
  State<_InkPad> createState() => _InkPadState();
}

class _InkPadState extends State<_InkPad> {
  static const List<int> _colors = [0xFF1F2937, 0xFFE5484D, 0xFF3B82F6, 0xFF15803D, 0xFFF59E0B];
  static const List<double> _widths = [0.003, 0.006, 0.012];

  final ValueNotifier<int> _tick = ValueNotifier(0);
  int _color = _colors.first;
  int _size = 0;
  String _tool = 'pen'; // pen | marker | eraser
  NoteStroke? _live;
  List<NoteStroke>? _cleared; // one-step restore after "clear"

  NoteBlock get _b => widget.block;

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _start(Offset p) {
    if (_tool == 'eraser') return _erase(p);
    _cleared = null;
    _live = NoteStroke(
      color: _tool == 'marker' && _color == _colors.first ? 0xFFF59E0B : _color,
      width: _widths[_size] * (_tool == 'marker' ? 4 : 1),
      marker: _tool == 'marker',
      points: [p],
    );
    _b.strokes.add(_live!);
    _tick.value++;
  }

  void _move(Offset p) {
    if (_tool == 'eraser') return _erase(p);
    final s = _live;
    if (s == null) return;
    if ((s.points.last - p).distance < 0.0022) return;
    s.points.add(p);
    _tick.value++;
  }

  void _end() {
    if (_live != null) widget.onChanged();
    _live = null;
  }

  void _erase(Offset p) {
    const r = 0.014;
    final before = _b.strokes.length;
    _b.strokes.removeWhere((s) => s.points.any((q) => (q - p).distance < r + s.width / 2));
    if (_b.strokes.length != before) {
      _tick.value++;
      widget.onChanged();
    }
  }

  void _undo() {
    setState(() {
      if (_cleared != null) {
        _b.strokes.addAll(_cleared!);
        _cleared = null;
      } else if (_b.strokes.isNotEmpty) {
        _b.strokes.removeLast();
      }
    });
    _tick.value++;
    widget.onChanged();
  }

  void _clear() {
    if (_b.strokes.isEmpty) return;
    setState(() {
      _cleared = List.of(_b.strokes);
      _b.strokes.clear();
    });
    _tick.value++;
    widget.onChanged();
  }

  void _resize(double d) {
    setState(() => _b.ratio = (_b.ratio + d).clamp(0.2, 1.6).toDouble());
    widget.onChanged();
  }

  Widget _btn(IconData icon, String tip, VoidCallback? onTap, {bool sel = false}) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: sel ? Pb.primary.withOpacity(0.14) : Colors.transparent, borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 17, color: onTap == null ? Pb.muted.withOpacity(0.4) : (sel ? Pb.primary : Pb.muted)),
          ),
        ),
      );

  Widget _sep() => Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 5), color: Pb.border);

  @override
  Widget build(BuildContext context) {
    final tools = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _btn(Icons.edit_outlined, 'Stilou', () => setState(() => _tool = 'pen'), sel: _tool == 'pen'),
          _btn(Icons.border_color_outlined, 'Marker', () => setState(() => _tool = 'marker'), sel: _tool == 'marker'),
          _btn(Icons.auto_fix_normal_outlined, 'Radieră', () => setState(() => _tool = 'eraser'), sel: _tool == 'eraser'),
          _sep(),
          for (final c in _colors)
            Tooltip(
              message: 'Culoare',
              child: InkWell(
                onTap: () => setState(() {
                  _color = c;
                  if (_tool == 'eraser') _tool = 'pen';
                }),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: _color == c ? 18 : 14,
                    height: _color == c ? 18 : 14,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == c ? Pb.text : Pb.inputBorder, width: _color == c ? 2 : 1),
                    ),
                  ),
                ),
              ),
            ),
          _sep(),
          for (var i = 0; i < _widths.length; i++)
            Tooltip(
              message: const ['Subțire', 'Mediu', 'Gros'][i],
              child: InkWell(
                onTap: () => setState(() => _size = i),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 28,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _size == i ? Pb.primary.withOpacity(0.14) : Colors.transparent, borderRadius: BorderRadius.circular(7)),
                  child: Container(
                    width: 4.0 + i * 3.5,
                    height: 4.0 + i * 3.5,
                    decoration: BoxDecoration(color: _size == i ? Pb.primary : Pb.muted, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          _sep(),
          _btn(Icons.undo, 'Anulează ultima linie', _b.strokes.isEmpty && _cleared == null ? null : _undo),
          _btn(Icons.delete_sweep_outlined, 'Șterge tot desenul', _b.strokes.isEmpty ? null : _clear),
          _sep(),
          _btn(
            _b.paper == 'grid' ? Icons.grid_4x4 : (_b.paper == 'lines' ? Icons.reorder : Icons.crop_din),
            'Hârtie: ${const {'blank': 'albă', 'grid': 'pătrățele', 'lines': 'liniată'}[_b.paper] ?? 'albă'}',
            () {
              setState(() => _b.paper = const {'blank': 'grid', 'grid': 'lines', 'lines': 'blank'}[_b.paper] ?? 'blank');
              _tick.value++;
              widget.onChanged();
            },
          ),
          _btn(Icons.unfold_less, 'Mai scund', _b.ratio <= 0.2 ? null : () => _resize(-0.14)),
          _btn(Icons.unfold_more, 'Mai înalt', _b.ratio >= 1.6 ? null : () => _resize(0.14)),
        ],
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: Pb.hoverBg, border: Border(bottom: BorderSide(color: Pb.border))),
            child: tools,
          ),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              Offset norm(Offset local) => Offset((local.dx / w).clamp(0.0, 1.0), (local.dy / w).clamp(0.0, _b.ratio));
              return SizedBox(
                height: w * _b.ratio,
                child: MouseRegion(
                  cursor: _tool == 'eraser' ? SystemMouseCursors.cell : SystemMouseCursors.precise,
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      _EagerPan: GestureRecognizerFactoryWithHandlers<_EagerPan>(
                        () => _EagerPan(),
                        (r) => r
                          ..onDown = ((d) => _start(norm(d.localPosition)))
                          ..onUpdate = ((d) => _move(norm(d.localPosition)))
                          ..onEnd = ((_) => _end())
                          ..onCancel = _end,
                      ),
                    },
                    child: ColoredBox(
                      color: _paper,
                      child: CustomPaint(
                        size: Size(w, w * _b.ratio),
                        painter: _InkPainter(strokes: _b.strokes, paper: _b.paper, repaint: _tick),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// READ-ONLY VIEW
// =============================================================================
class NoteView extends StatelessWidget {
  final String content;
  final Map<String, bool> checks;
  final void Function(String blockId, bool value)? onCheck;

  const NoteView({super.key, required this.content, this.checks = const {}, this.onCheck});

  @override
  Widget build(BuildContext context) {
    final blocks = NoteContent.parse(content);
    final children = <Widget>[];
    var n = 0;
    for (final b in blocks) {
      n = b.type == NoteBlock.numbered ? n + 1 : 0;
      final done = b.type == NoteBlock.todo && (checks[b.id] ?? b.checked);
      Widget body;
      if (b.type == NoteBlock.divider) {
        body = _dividerLine();
      } else if (b.type == NoteBlock.draw) {
        body = _InkView(block: b);
      } else if (b.type == NoteBlock.code) {
        body = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText.rich(CodeHighlighter.span(b.text, noteTextStyle(b), lang: b.lang)),
        );
      } else {
        if (b.text.isEmpty) {
          children.add(SizedBox(height: 16 * 1.6 * (b.type == NoteBlock.p ? 0.6 : 1)));
          continue;
        }
        body = SelectableText.rich(noteInlineSpan(b.text, noteTextStyle(b, done: done), showMarkers: false));
      }
      children.add(Padding(
        padding: EdgeInsets.only(top: _blockGap(b), bottom: _blockGap(b) > 1 ? 4 : 1),
        child: noteBlockShell(
          b: b,
          number: n,
          done: done,
          onCheck: onCheck == null ? null : (v) => onCheck!(b.id, v),
          codeHeader: b.type == NoteBlock.code ? _CodeBar(lang: b.lang, text: b.text) : null,
          child: body,
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _CodeBar extends StatelessWidget {
  final String lang;
  final String text;
  final ValueChanged<String>? onLang;
  const _CodeBar({required this.lang, required this.text, this.onLang});

  @override
  Widget build(BuildContext context) {
    final label = Text(lang == 'python' ? 'Python' : 'C++', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pb.muted));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 3, 4, 3),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Pb.border))),
      child: Row(
        children: [
          if (onLang == null)
            label
          else
            InkWell(
              onTap: () => onLang!(lang == 'python' ? 'cpp' : 'python'),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [label, const SizedBox(width: 4), Icon(Icons.swap_horiz, size: 14, color: Pb.muted)]),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Copiază codul',
            icon: Icon(Icons.copy_outlined, size: 15, color: Pb.muted),
            splashRadius: 15,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 26),
            padding: EdgeInsets.zero,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.maybeOf(context)
                ?..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Codul a fost copiat.'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating));
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EDITOR
// =============================================================================
/// Lets the owner read the page without the editor having to serialise it on
/// every keystroke (drawings can make a page large).
class NoteEditorHandle {
  String Function()? _encode;
  String? _last;

  /// Current content as JSON, or the last known content once the editor is gone.
  String? read() => _encode != null ? _encode!() : _last;
}

class NoteEditor extends StatefulWidget {
  final String initialContent;
  final NoteEditorHandle handle;
  final VoidCallback onDirty;
  final Widget? header; // scrolls with the page (title field)
  final bool compact;

  const NoteEditor({
    super.key,
    required this.initialContent,
    required this.handle,
    required this.onDirty,
    this.header,
    this.compact = false,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _EB {
  final NoteBlock b;
  TextEditingController c;
  final FocusNode f = FocusNode();
  _EB(this.b) : c = _make(b);

  static TextEditingController _make(NoteBlock b) =>
      b.type == NoteBlock.code ? CodeController(text: b.text, lang: b.lang) : InlineController(text: b.text);

  void dispose() {
    c.dispose();
    f.dispose();
  }
}

class _NoteEditorState extends State<NoteEditor> {
  final ScrollController _scroll = ScrollController();
  late final List<_EB> _blocks;
  String? _curId;

  @override
  void initState() {
    super.initState();
    _blocks = [for (final b in NoteContent.parse(widget.initialContent)) _wire(_EB(b))];
    _curId = _blocks.first.b.id;
    widget.handle._encode = _encode;
  }

  @override
  void dispose() {
    widget.handle._last = _encode();
    widget.handle._encode = null;
    for (final e in _blocks) {
      e.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _encode() => NoteContent.encode([for (final e in _blocks) e.b]);

  _EB _wire(_EB e) {
    e.f.addListener(() {
      if (e.f.hasFocus && _curId != e.b.id && mounted) setState(() => _curId = e.b.id);
    });
    return e;
  }

  int get _cur {
    final i = _blocks.indexWhere((e) => e.b.id == _curId);
    return i < 0 ? _blocks.length - 1 : i;
  }

  void _dirty() => widget.onDirty();

  void _focus(_EB e, {int? caret}) {
    _curId = e.b.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_blocks.contains(e)) return;
      e.f.requestFocus();
      final off = (caret ?? e.c.text.length).clamp(0, e.c.text.length);
      e.c.selection = TextSelection.collapsed(offset: off);
    });
  }

  _EB _insertAfter(int i, NoteBlock b) {
    final e = _wire(_EB(b));
    _blocks.insert(i + 1, e);
    return e;
  }

  void _remove(_EB e) {
    _blocks.remove(e);
    if (_blocks.isEmpty) _blocks.add(_wire(_EB(NoteBlock())));
    // The field may still be mounted this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => e.dispose());
  }

  void _setText(_EB e, String text, {int? caret}) {
    e.b.text = text;
    e.c.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: (caret ?? text.length).clamp(0, text.length)));
  }

  void _setType(_EB e, String type) {
    if (!e.b.hasText || e.b.type == type) return;
    final wasCode = e.b.type == NoteBlock.code;
    final toCode = type == NoteBlock.code;
    e.b.type = type;
    if (type != NoteBlock.todo) e.b.checked = false;
    if (wasCode != toCode) {
      final old = e.c;
      final sel = old.selection;
      // A code block keeps its line breaks; anything else is a single paragraph.
      if (!toCode) e.b.text = e.b.text.replaceAll('\n', ' ');
      e.c = _EB._make(e.b);
      if (sel.isValid && sel.end <= e.c.text.length) e.c.selection = sel;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  // ---------------------------------------------------------------- typing
  static final List<(RegExp, String)> _shortcuts = [
    (RegExp(r'^## '), NoteBlock.h2),
    (RegExp(r'^# '), NoteBlock.h1),
    (RegExp(r'^[-*] '), NoteBlock.bullet),
    (RegExp(r'^1[.)] '), NoteBlock.numbered),
    (RegExp(r'^\[ ?\] '), NoteBlock.todo),
    (RegExp(r'^> '), NoteBlock.quote),
    (RegExp(r'^! '), NoteBlock.callout),
    (RegExp(r'^```'), NoteBlock.code),
  ];

  void _onText(_EB e, String v) {
    final b = e.b;
    if (b.type != NoteBlock.code && v.contains('\n')) {
      _split(e, v);
      _dirty();
      return;
    }
    b.text = v;
    if (b.type == NoteBlock.p) {
      if (v == '---') {
        setState(() {
          b.type = NoteBlock.divider;
          b.text = '';
          final i = _blocks.indexOf(e);
          final next = _insertAfter(i, NoteBlock());
          _focus(next, caret: 0);
        });
      } else {
        for (final (re, type) in _shortcuts) {
          final m = re.firstMatch(v);
          if (m == null) continue;
          setState(() {
            _setText(e, v.substring(m.end), caret: 0);
            _setType(e, type);
            _focus(e, caret: 0);
          });
          break;
        }
      }
    }
    _dirty();
  }

  void _split(_EB e, String v) {
    final parts = v.split('\n');
    final b = e.b;
    setState(() {
      // Enter on an empty list item ends the list.
      if (b.isList && parts.length == 2 && parts[0].isEmpty && parts[1].isEmpty) {
        _setText(e, '');
        _setType(e, NoteBlock.p);
        _focus(e, caret: 0);
        return;
      }
      _setText(e, parts.first);
      var i = _blocks.indexOf(e);
      final nextType = b.isList ? b.type : NoteBlock.p;
      late _EB last;
      for (final part in parts.skip(1)) {
        last = _insertAfter(i, NoteBlock(type: nextType, text: part));
        i++;
      }
      _focus(last, caret: parts.length == 2 ? 0 : null);
    });
  }

  KeyEventResult _onKey(_EB e, KeyEvent ev) {
    if (ev is KeyUpEvent) return KeyEventResult.ignored;
    final kb = HardwareKeyboard.instance;
    final ctrl = kb.isControlPressed || kb.isMetaPressed;
    final key = ev.logicalKey;
    final sel = e.c.selection;
    if (!sel.isValid) return KeyEventResult.ignored;
    final i = _blocks.indexOf(e);
    final isCode = e.b.type == NoteBlock.code;

    if (ctrl && !isCode) {
      if (key == LogicalKeyboardKey.keyB) return _wrapK(e, '**');
      if (key == LogicalKeyboardKey.keyI) return _wrapK(e, '*');
      if (key == LogicalKeyboardKey.keyE) return _wrapK(e, '`');
      if (key == LogicalKeyboardKey.keyH && kb.isShiftPressed) return _wrapK(e, '==');
    }

    if (isCode && !ctrl) {
      if (key == LogicalKeyboardKey.tab) {
        (e.c as CodeController).replace(sel.start, sel.end, '    ');
        e.b.text = e.c.text;
        _dirty();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter) {
        final t = e.c.text;
        final ls = sel.start == 0 ? 0 : t.lastIndexOf('\n', sel.start - 1) + 1;
        final line = t.substring(ls, sel.start);
        final indent = RegExp(r'^[ \t]*').stringMatch(line) ?? '';
        final more = line.trimRight().endsWith('{') || line.trimRight().endsWith(':');
        (e.c as CodeController).replace(sel.start, sel.end, '\n$indent${more ? '    ' : ''}');
        e.b.text = e.c.text;
        _dirty();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.backspace && sel.isCollapsed && sel.start == 0) {
      if (e.b.type != NoteBlock.p) {
        if (isCode && e.c.text.isNotEmpty) return KeyEventResult.ignored;
        setState(() {
          _setType(e, NoteBlock.p);
          _focus(e, caret: 0);
        });
        _dirty();
        return KeyEventResult.handled;
      }
      if (i == 0) return KeyEventResult.ignored;
      final prev = _blocks[i - 1];
      setState(() {
        if (prev.b.hasText && prev.b.type != NoteBlock.code) {
          final at = prev.c.text.length;
          _setText(prev, prev.c.text + e.c.text, caret: at);
          _remove(e);
          _focus(prev, caret: at);
        } else if (e.c.text.isEmpty) {
          _remove(e);
          if (prev.b.hasText) {
            _focus(prev);
          } else {
            _curId = prev.b.id;
          }
        } else if (!prev.b.hasText && prev.b.type == NoteBlock.divider) {
          _remove(prev);
        }
      });
      _dirty();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp && sel.isCollapsed && !e.c.text.substring(0, sel.start).contains('\n') && sel.start == 0) {
      for (var j = i - 1; j >= 0; j--) {
        if (_blocks[j].b.hasText) {
          _focus(_blocks[j]);
          return KeyEventResult.handled;
        }
      }
    }
    if (key == LogicalKeyboardKey.arrowDown && sel.isCollapsed && sel.start == e.c.text.length) {
      for (var j = i + 1; j < _blocks.length; j++) {
        if (_blocks[j].b.hasText) {
          _focus(_blocks[j], caret: 0);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _wrapK(_EB e, String mark) {
    _wrap(e, mark);
    return KeyEventResult.handled;
  }

  void _wrap(_EB e, String mark) {
    if (!e.b.hasText || e.b.type == NoteBlock.code) return;
    final t = e.c.text;
    final sel = e.c.selection;
    final s = sel.isValid ? sel.start : t.length;
    final en = sel.isValid ? sel.end : t.length;
    final inner = t.substring(s, en);
    final n = mark.length;
    String next;
    TextSelection ns;
    // Pressing the same mark again takes it off.
    if (s >= n && en + n <= t.length && t.substring(s - n, s) == mark && t.substring(en, en + n) == mark) {
      next = t.replaceRange(en, en + n, '').replaceRange(s - n, s, '');
      ns = TextSelection(baseOffset: s - n, extentOffset: en - n);
    } else {
      next = t.replaceRange(s, en, '$mark$inner$mark');
      ns = TextSelection(baseOffset: s + n, extentOffset: en + n);
    }
    e.b.text = next;
    e.c.value = TextEditingValue(text: next, selection: ns);
    e.f.requestFocus();
    _dirty();
  }

  // ---------------------------------------------------------------- structure
  void _toolbarType(String type) {
    final e = _blocks[_cur];
    setState(() {
      if (!e.b.hasText) {
        final n = _insertAfter(_cur, NoteBlock(type: type));
        _focus(n, caret: 0);
      } else {
        _setType(e, e.b.type == type ? NoteBlock.p : type);
        _focus(e, caret: e.c.selection.isValid ? e.c.selection.end : null);
      }
    });
    _dirty();
  }

  void _insertSpecial(String type) {
    setState(() {
      var i = _cur;
      final cur = _blocks[i];
      // An empty paragraph is replaced rather than left dangling above.
      if (cur.b.type == NoteBlock.p && cur.c.text.isEmpty) {
        _remove(cur);
        i--;
      }
      final e = _insertAfter(i, NoteBlock(type: type));
      i = _blocks.indexOf(e);
      if (i == _blocks.length - 1 || !_blocks[i + 1].b.hasText) {
        final p = _insertAfter(i, NoteBlock());
        if (type == NoteBlock.divider) _focus(p, caret: 0);
      }
      if (type == NoteBlock.draw) {
        _curId = e.b.id;
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    _dirty();
  }

  void _move(_EB e, int d) {
    final i = _blocks.indexOf(e);
    final j = i + d;
    if (j < 0 || j >= _blocks.length) return;
    setState(() {
      _blocks.removeAt(i);
      _blocks.insert(j, e);
      _curId = e.b.id;
    });
    _dirty();
  }

  void _duplicate(_EB e) {
    e.b.text = e.c.text;
    setState(() {
      final n = _insertAfter(_blocks.indexOf(e), e.b.copy());
      _curId = n.b.id;
    });
    _dirty();
  }

  void _delete(_EB e) {
    final i = _blocks.indexOf(e);
    setState(() {
      _remove(e);
      _curId = _blocks[math.min(i, _blocks.length - 1)].b.id;
    });
    _dirty();
  }

  void _tapBelow() {
    final last = _blocks.last;
    if (last.b.hasText && last.c.text.isEmpty) {
      _focus(last);
    } else {
      setState(() => _focus(_insertAfter(_blocks.length - 1, NoteBlock()), caret: 0));
      _dirty();
    }
  }

  // ---------------------------------------------------------------- toolbar
  Widget _tb(IconData icon, String tip, VoidCallback onTap, {bool sel = false, String? label}) => Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 32,
            constraints: const BoxConstraints(minWidth: 32),
            padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 8),
            decoration: BoxDecoration(color: sel ? Pb.primary.withOpacity(0.13) : Colors.transparent, borderRadius: BorderRadius.circular(7)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: sel ? Pb.primary : Pb.muted),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Pb.primary : Pb.text)),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _tsep() => Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6), color: Pb.border);

  Widget _toolbar() {
    final e = _blocks[_cur];
    final t = e.b.type;
    void wrap(String m) => _wrap(_blocks[_cur], m);

    return TextFieldTapRegion(
      child: Container(
        decoration: BoxDecoration(color: Pb.surface, border: Border(bottom: BorderSide(color: Pb.border))),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tb(Icons.title, 'Titlu  (#  apoi spațiu)', () => _toolbarType(NoteBlock.h1), sel: t == NoteBlock.h1),
              _tb(Icons.text_fields, 'Subtitlu  (##  apoi spațiu)', () => _toolbarType(NoteBlock.h2), sel: t == NoteBlock.h2),
              _tsep(),
              _tb(Icons.format_list_bulleted, 'Listă  (-  apoi spațiu)', () => _toolbarType(NoteBlock.bullet), sel: t == NoteBlock.bullet),
              _tb(Icons.format_list_numbered, 'Listă numerotată  (1.  apoi spațiu)', () => _toolbarType(NoteBlock.numbered), sel: t == NoteBlock.numbered),
              _tb(Icons.check_box_outlined, 'De făcut  ([]  apoi spațiu)', () => _toolbarType(NoteBlock.todo), sel: t == NoteBlock.todo),
              _tsep(),
              _tb(Icons.format_quote, 'Citat  (>  apoi spațiu)', () => _toolbarType(NoteBlock.quote), sel: t == NoteBlock.quote),
              _tb(Icons.lightbulb_outline, 'Reține  (!  apoi spațiu)', () => _toolbarType(NoteBlock.callout), sel: t == NoteBlock.callout),
              _tb(Icons.code, 'Bloc de cod  (```)', () => _toolbarType(NoteBlock.code), sel: t == NoteBlock.code),
              _tsep(),
              _tb(Icons.format_bold, 'Îngroșat (Ctrl+B)', () => wrap('**')),
              _tb(Icons.format_italic, 'Cursiv (Ctrl+I)', () => wrap('*')),
              _tb(Icons.format_strikethrough, 'Tăiat', () => wrap('~~')),
              _tb(Icons.border_color_outlined, 'Evidențiat (Ctrl+Shift+H)', () => wrap('==')),
              _tb(Icons.data_object, 'Cod în text (Ctrl+E)', () => wrap('`')),
              _tsep(),
              _tb(Icons.draw_outlined, 'Adaugă o zonă de scris de mână', () => _insertSpecial(NoteBlock.draw), label: 'Desen'),
              _tb(Icons.horizontal_rule, 'Linie despărțitoare  (---)', () => _insertSpecial(NoteBlock.divider)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- blocks
  Widget _field(_EB e, {required bool onlyBlock}) {
    final b = e.b;
    final isCode = b.type == NoteBlock.code;
    final style = noteTextStyle(b, done: b.checked);
    final hint = isCode
        ? 'Scrie cod'
        : (b.type == NoteBlock.h1
            ? 'Titlu'
            : (b.type == NoteBlock.h2
                ? 'Subtitlu'
                : (b.type == NoteBlock.callout
                    ? 'Ce merită reținut'
                    : (b.isList
                        ? 'Element'
                        : (b.type == NoteBlock.quote
                            ? 'Citat'
                            : (onlyBlock ? 'Scrie aici. Tastează # pentru titlu, - pentru listă, [] pentru bifă.' : ''))))));

    final field = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, ev) => _onKey(e, ev),
      child: TextField(
        controller: e.c,
        focusNode: e.f,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: isCode ? TextCapitalization.none : TextCapitalization.sentences,
        autocorrect: !isCode,
        enableSuggestions: !isCode,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        style: style,
        strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
        cursorColor: Pb.primary,
        cursorWidth: 1.8,
        onChanged: (v) => _onText(e, v),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: style.copyWith(color: Pb.muted.withOpacity(0.6), fontStyle: FontStyle.normal, decoration: TextDecoration.none),
        ),
      ),
    );
    if (!isCode) return field;
    return LayoutBuilder(
      builder: (context, box) {
        final longest = e.c.text.split('\n').fold<int>(0, (m, l) => math.max(m, l.length));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: math.max(box.maxWidth, longest * 8.4 + 40), child: field),
        );
      },
    );
  }

  Widget _row(_EB e, int number, {required bool onlyBlock}) {
    final b = e.b;
    final isCur = b.id == _curId;
    Widget body;
    if (b.type == NoteBlock.divider) {
      body = _dividerLine();
    } else if (b.type == NoteBlock.draw) {
      body = _InkPad(key: ValueKey('ink-${b.id}'), block: b, onChanged: _dirty);
    } else {
      body = noteBlockShell(
        b: b,
        number: number,
        done: b.checked,
        onCheck: (v) {
          setState(() => b.checked = v);
          _dirty();
        },
        codeHeader: b.type == NoteBlock.code
            ? _CodeBar(
                lang: b.lang,
                text: e.c.text,
                onLang: (l) {
                  setState(() {
                    b.lang = l;
                    (e.c as CodeController).lang = l;
                  });
                  _dirty();
                },
              )
            : null,
        child: _field(e, onlyBlock: onlyBlock),
      );
    }

    final i = _blocks.indexOf(e);
    return _BlockRow(
      key: ValueKey(b.id),
      current: isCur,
      gap: _blockGap(b),
      narrow: widget.compact,
      onSelect: b.hasText
          ? null
          : () {
              if (_curId != b.id) setState(() => _curId = b.id);
            },
      menu: (ctx) => [
        PopupMenuItem(value: 'add', height: 38, child: _mi(Icons.add, 'Adaugă un rând dedesubt')),
        if (i > 0) PopupMenuItem(value: 'up', height: 38, child: _mi(Icons.arrow_upward, 'Mută mai sus')),
        if (i < _blocks.length - 1) PopupMenuItem(value: 'down', height: 38, child: _mi(Icons.arrow_downward, 'Mută mai jos')),
        PopupMenuItem(value: 'dup', height: 38, child: _mi(Icons.copy_outlined, 'Duplică')),
        PopupMenuItem(value: 'del', height: 38, child: _mi(Icons.delete_outline, 'Șterge', danger: true)),
      ],
      onMenu: (v) {
        switch (v) {
          case 'add':
            setState(() => _focus(_insertAfter(_blocks.indexOf(e), NoteBlock()), caret: 0));
            _dirty();
            break;
          case 'up':
            _move(e, -1);
            break;
          case 'down':
            _move(e, 1);
            break;
          case 'dup':
            _duplicate(e);
            break;
          case 'del':
            _delete(e);
            break;
        }
      },
      child: body,
    );
  }

  Widget _mi(IconData icon, String text, {bool danger = false}) => Row(
        children: [
          Icon(icon, size: 17, color: danger ? Pb.danger : Pb.muted),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13.5, color: danger ? Pb.danger : Pb.text)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var n = 0;
    final only = _blocks.length == 1;
    for (final e in _blocks) {
      n = e.b.type == NoteBlock.numbered ? n + 1 : 0;
      rows.add(_row(e, n, onlyBlock: only));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(),
        Expanded(
          child: Scrollbar(
            controller: _scroll,
            child: SingleChildScrollView(
              controller: _scroll,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(widget.compact ? 6 : 20, widget.compact ? 14 : 26, widget.compact ? 12 : 44, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.header != null)
                          Padding(padding: EdgeInsets.only(left: widget.compact ? 26 : 34, bottom: 10), child: widget.header!),
                        ...rows,
                        MouseRegion(
                          cursor: SystemMouseCursors.text,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _tapBelow,
                            child: const SizedBox(height: 260),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One block plus its left-hand handle (shown on hover, or while it is current).
class _BlockRow extends StatefulWidget {
  final bool current;
  final bool narrow;
  final double gap;
  final Widget child;
  final VoidCallback? onSelect;
  final List<PopupMenuEntry<String>> Function(BuildContext) menu;
  final ValueChanged<String> onMenu;

  const _BlockRow({
    super.key,
    required this.current,
    required this.narrow,
    required this.gap,
    required this.child,
    required this.menu,
    required this.onMenu,
    this.onSelect,
  });

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final show = _hover || widget.current;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: widget.onSelect == null ? null : (_) => widget.onSelect!(),
        child: Padding(
          padding: EdgeInsets.only(top: widget.gap, bottom: widget.gap > 1 ? 4 : 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: widget.narrow ? 26 : 34,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: show ? 1 : 0,
                  child: TextFieldTapRegion(
                    child: PopupMenuButton<String>(
                      tooltip: 'Opțiuni rând',
                      color: Pb.surface,
                      padding: EdgeInsets.zero,
                      enabled: show,
                      onSelected: widget.onMenu,
                      itemBuilder: widget.menu,
                      child: Container(
                        height: 26,
                        alignment: Alignment.center,
                        child: Icon(Icons.drag_indicator, size: 17, color: Pb.muted.withOpacity(0.8)),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
