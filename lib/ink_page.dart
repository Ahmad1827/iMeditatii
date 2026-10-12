import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_components.dart' show Pb;
import 'workspace_models.dart';

// =============================================================================
// INK PAGE — a whole sheet you write on by hand, like a OneNote page.
//
// Everything is stored relative to the sheet's width, so the page looks the
// same on the teacher's monitor and on a student's phone.
//
// With [base] set, that page is shown underneath and cannot be changed: the
// student writes their solution on top of what the teacher sent.
// =============================================================================
const Color _paperColor = Color(0xFFFDFDFB);
const Color _ruleColor = Color(0xFFDCE3EC);

void _paintStroke(Canvas canvas, NoteStroke s) {
  final pts = s.points;
  if (pts.isEmpty) return;
  final paint = Paint()
    ..color = Color(s.color).withOpacity(s.marker ? 0.32 : 1)
    ..strokeWidth = s.width
    ..strokeCap = s.marker ? StrokeCap.square : StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  if (pts.length == 1) {
    canvas.drawCircle(pts.first, s.width / 2, paint..style = PaintingStyle.fill);
    return;
  }
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  if (s.straight) {
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
  } else {
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
  }
  canvas.drawPath(path, paint);
}

/// Ramer–Douglas–Peucker: drops points that do not change the shape.
List<Offset> simplifyStroke(List<Offset> pts, {double epsilon = 0.0005}) {
  if (pts.length < 3) return pts;
  final keep = List<bool>.filled(pts.length, false);
  keep[0] = keep[pts.length - 1] = true;
  final stack = <(int, int)>[(0, pts.length - 1)];
  while (stack.isNotEmpty) {
    final (a, b) = stack.removeLast();
    var worst = 0.0;
    var at = -1;
    final ab = pts[b] - pts[a];
    final len = ab.distance;
    for (var i = a + 1; i < b; i++) {
      final ap = pts[i] - pts[a];
      final d = len == 0 ? ap.distance : (ab.dx * ap.dy - ab.dy * ap.dx).abs() / len;
      if (d > worst) {
        worst = d;
        at = i;
      }
    }
    if (at >= 0 && worst > epsilon) {
      keep[at] = true;
      stack
        ..add((a, at))
        ..add((at, b));
    }
  }
  return [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i],
  ];
}

/// Lets the owner read the page without serialising it on every stroke.
class InkPageHandle {
  String Function()? _encode;
  bool Function()? _isEmpty;
  String? _last;
  bool _lastEmpty = true;

  String? read() => _encode != null ? _encode!() : _last;
  bool get isEmpty => _isEmpty != null ? _isEmpty!() : _lastEmpty;
}

class _Op {
  final List<NoteStroke> added;
  final List<(int, NoteStroke)> removed; // ascending index
  const _Op({this.added = const [], this.removed = const []});
}

class InkPage extends StatefulWidget {
  final String initialContent;
  final String? base; // locked page shown underneath
  final bool readOnly;
  final bool compact;
  final InkPageHandle? handle;
  final VoidCallback? onDirty;
  final int maxLength;

  const InkPage({
    super.key,
    required this.initialContent,
    this.base,
    this.readOnly = false,
    this.compact = false,
    this.handle,
    this.onDirty,
    this.maxLength = InkDoc.maxLength,
  });

  @override
  State<InkPage> createState() => _InkPageState();
}

class _InkPageState extends State<InkPage> {
  static const List<int> _colors = [0xFF1F2937, 0xFFE5484D, 0xFF3B82F6, 0xFF15803D, 0xFFF59E0B, 0xFF8B5CF6];
  static const List<double> _widths = [0.0018, 0.0034, 0.0064];
  static const List<double> _zooms = [0.5, 0.75, 1, 1.5, 2, 3];
  static const double _maxSheet = 1180;

  late final InkDoc _doc = InkDoc.parse(widget.initialContent);
  late final InkDoc? _base = widget.base == null ? null : InkDoc.parse(widget.base!);

  final ScrollController _v = ScrollController();
  final ScrollController _h = ScrollController();
  final FocusNode _focus = FocusNode();
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final List<_Op> _undo = [];
  final List<_Op> _redo = [];

  ui.Picture? _pic; // committed strokes, re-recorded only when they change
  ui.Picture? _basePic;

  String _tool = 'pen'; // pen | marker | eraser | line | rect | ellipse | hand
  int _color = _colors.first;
  int _size = 1;
  double _zoom = 1;
  bool _stylusSeen = false;

  int? _pointer;
  NoteStroke? _live;
  Offset? _anchor;
  List<(int, NoteStroke)> _erased = [];
  Offset? _eraseFrom;
  int _points = 0;

  bool get _editable => !widget.readOnly;
  double get _height => math.max(_doc.height, _base?.height ?? 0);
  String get _paper => _base?.paper ?? _doc.paper;

  @override
  void initState() {
    super.initState();
    _points = _doc.strokes.fold(0, (n, s) => n + s.points.length);
    widget.handle?._encode = _doc.encode;
    widget.handle?._isEmpty = () => _doc.strokes.isEmpty;
  }

  @override
  void dispose() {
    final h = widget.handle;
    if (h != null) {
      h._last = _doc.encode();
      h._lastEmpty = _doc.strokes.isEmpty;
      h._encode = null;
      h._isEmpty = null;
    }
    _pic?.dispose();
    _basePic?.dispose();
    _v.dispose();
    _h.dispose();
    _focus.dispose();
    _tick.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- state
  void _changed() {
    _pic?.dispose();
    _pic = null;
    _tick.value++;
    widget.onDirty?.call();
  }

  /// Rough size of the encoded page, without encoding it.
  int get _bytes => _points * 11 + _doc.strokes.length * 48 + 80;
  bool get _full => _bytes >= widget.maxLength;

  void _commit(_Op op) {
    _undo.add(op);
    if (_undo.length > 200) _undo.removeAt(0);
    _redo.clear();
    _changed();
    if (mounted) setState(() {});
  }

  void _undoOp() {
    if (_undo.isEmpty) return;
    final op = _undo.removeLast();
    for (final s in op.added) {
      _doc.strokes.remove(s);
      _points -= s.points.length;
    }
    for (final (i, s) in op.removed) {
      _doc.strokes.insert(i.clamp(0, _doc.strokes.length), s);
      _points += s.points.length;
    }
    _redo.add(op);
    _changed();
    setState(() {});
  }

  void _redoOp() {
    if (_redo.isEmpty) return;
    final op = _redo.removeLast();
    for (final (_, s) in op.removed.reversed) {
      _doc.strokes.remove(s);
      _points -= s.points.length;
    }
    for (final s in op.added) {
      _doc.strokes.add(s);
      _points += s.points.length;
    }
    _undo.add(op);
    _changed();
    setState(() {});
  }

  void _clear() {
    if (_doc.strokes.isEmpty) return;
    final removed = [for (var i = 0; i < _doc.strokes.length; i++) (i, _doc.strokes[i])];
    _doc.strokes.clear();
    _points = 0;
    _commit(_Op(removed: removed));
  }

  void _grow([double by = 0.7]) {
    setState(() => _doc.height = (_height + by).clamp(0.5, 40.0).toDouble());
    _changed();
  }

  void _setPaper() {
    setState(() => _doc.paper = const {'blank': 'grid', 'grid': 'lines', 'lines': 'blank'}[_doc.paper] ?? 'grid');
    _changed();
  }

  void _setZoom(int dir) {
    final i = _zooms.indexOf(_zoom);
    final j = (i + dir).clamp(0, _zooms.length - 1);
    if (j != i) setState(() => _zoom = _zooms[j]);
  }

  // ---------------------------------------------------------------- pointer
  bool _draws(PointerDownEvent e) {
    if (!_editable || _tool == 'hand' || _pointer != null) return false;
    switch (e.kind) {
      case PointerDeviceKind.mouse:
        return e.buttons == kPrimaryMouseButton;
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.touch:
        return !_stylusSeen; // once a pen is in use, fingers only scroll
      default:
        return false;
    }
  }

  void _down(PointerDownEvent e, double w) {
    if (e.kind == PointerDeviceKind.stylus || e.kind == PointerDeviceKind.invertedStylus) {
      if (!_stylusSeen) setState(() => _stylusSeen = true);
    }
    if (!_draws(e)) return;
    _focus.requestFocus();
    _pointer = e.pointer;
    final p = e.localPosition / w;
    final erasing = _tool == 'eraser' || e.kind == PointerDeviceKind.invertedStylus;
    if (erasing) {
      _erased = [];
      _eraseFrom = p;
      _eraseAt(p);
      return;
    }
    if (_full) {
      _pointer = null;
      setState(() {}); // shows the "page is full" notice
      return;
    }
    final marker = _tool == 'marker';
    _anchor = p;
    _live = NoteStroke(
      color: marker && _color == _colors.first ? 0xFFF59E0B : _color,
      width: _widths[_size] * (marker ? 5 : 1),
      marker: marker,
      straight: _tool == 'line' || _tool == 'rect' || _tool == 'ellipse',
      points: [p],
    );
    _tick.value++;
  }

  void _moveTo(PointerEvent e, double w) {
    if (e.pointer != _pointer) return;
    final p = Offset((e.localPosition.dx / w).clamp(0.0, 1.0), (e.localPosition.dy / w).clamp(0.0, _height));
    final s = _live;
    if (s == null) {
      // A fast move can jump right over a stroke, so sweep the path in small steps.
      final from = _eraseFrom ?? p;
      final steps = ((p - from).distance / 0.006).ceil().clamp(1, 400);
      for (var i = 1; i <= steps; i++) {
        _eraseAt(Offset.lerp(from, p, i / steps)!);
      }
      _eraseFrom = p;
      return;
    }
    final a = _anchor!;
    switch (_tool) {
      case 'line':
        s.points
          ..clear()
          ..addAll([a, p]);
        break;
      case 'rect':
        s.points
          ..clear()
          ..addAll([a, Offset(p.dx, a.dy), p, Offset(a.dx, p.dy), a]);
        break;
      case 'ellipse':
        final c = (a + p) / 2;
        final rx = (p.dx - a.dx).abs() / 2;
        final ry = (p.dy - a.dy).abs() / 2;
        s.points
          ..clear()
          ..addAll([for (var i = 0; i <= 48; i++) c + Offset(rx * math.cos(i * math.pi / 24), ry * math.sin(i * math.pi / 24))]);
        break;
      default:
        if ((s.points.last - p).distance < 0.0012) return;
        s.points.add(p);
    }
    _tick.value++;
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final s = _live;
    _live = null;
    _anchor = null;
    if (s == null) {
      if (_erased.isNotEmpty) {
        final removed = _erased..sort((a, b) => a.$1.compareTo(b.$1));
        _erased = [];
        _commit(_Op(removed: removed));
      }
      return;
    }
    if (s.straight && s.points.length < 2) {
      _tick.value++;
      return;
    }
    final done = s.straight
        ? s
        : NoteStroke(color: s.color, width: s.width, marker: s.marker, points: simplifyStroke(s.points));
    _doc.strokes.add(done);
    _points += done.points.length;
    // Writing near the bottom edge adds more paper.
    final lowest = done.points.fold<double>(0, (m, p) => math.max(m, p.dy));
    if (lowest > _height - 0.22) _doc.height = (_height + 0.7).clamp(0.5, 40.0).toDouble();
    _commit(_Op(added: [done]));
  }

  void _eraseAt(Offset p) {
    const r = 0.011;
    var hit = false;
    for (var i = _doc.strokes.length - 1; i >= 0; i--) {
      final s = _doc.strokes[i];
      final reach = r + s.width / 2;
      var touched = false;
      if (s.straight && s.points.length > 1) {
        for (var k = 0; k + 1 < s.points.length && !touched; k++) {
          touched = _segmentDistance(p, s.points[k], s.points[k + 1]) < reach;
        }
      } else {
        touched = s.points.any((q) => (q - p).distance < reach);
      }
      if (!touched) continue;
      // Index as it was before this gesture started, so undo puts it back in place.
      _erased.add((i + _erased.where((e) => e.$1 <= i).length, s));
      _doc.strokes.removeAt(i);
      _points -= s.points.length;
      hit = true;
    }
    if (hit) {
      _pic?.dispose();
      _pic = null;
      _tick.value++;
    }
  }

  static double _segmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (l2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / l2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  ui.Picture _record(List<NoteStroke> strokes) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final s in strokes) {
      _paintStroke(c, s);
    }
    return rec.endRecording();
  }

  // ---------------------------------------------------------------- toolbar
  Widget _btn(IconData icon, String tip, VoidCallback? onTap, {bool sel = false}) => Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: sel ? Pb.primary.withOpacity(0.14) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 19, color: onTap == null ? Pb.muted.withOpacity(0.35) : (sel ? Pb.primary : Pb.muted)),
          ),
        ),
      );

  Widget _sep() => Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 6), color: Pb.border);

  Widget _tool_(String id, IconData icon, String tip) => _btn(icon, tip, () => setState(() => _tool = id), sel: _tool == id);

  Widget _toolbar() {
    final drawingTool = _tool != 'eraser' && _tool != 'hand';
    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(bottom: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_editable) ...[
              _tool_('pen', Icons.edit_outlined, 'Stilou'),
              _tool_('marker', Icons.border_color_outlined, 'Marker'),
              _tool_('eraser', Icons.auto_fix_normal_outlined, 'Radieră'),
              _sep(),
              _tool_('line', Icons.horizontal_rule, 'Linie dreaptă'),
              _tool_('rect', Icons.crop_square, 'Dreptunghi'),
              _tool_('ellipse', Icons.circle_outlined, 'Cerc sau elipsă'),
              _sep(),
              for (final c in _colors)
                Tooltip(
                  message: 'Culoare',
                  waitDuration: const Duration(milliseconds: 600),
                  child: InkWell(
                    canRequestFocus: false,
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() {
                      _color = c;
                      if (!drawingTool) _tool = 'pen';
                    }),
                    child: SizedBox(
                      width: 28,
                      height: 34,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: _color == c ? 20 : 15,
                          height: _color == c ? 20 : 15,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(color: _color == c ? Pb.text : Pb.inputBorder, width: _color == c ? 2 : 1),
                          ),
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
                    canRequestFocus: false,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _size = i),
                    child: Container(
                      width: 30,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _size == i ? Pb.primary.withOpacity(0.14) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        width: 4.0 + i * 4,
                        height: 4.0 + i * 4,
                        decoration: BoxDecoration(color: _size == i ? Pb.primary : Pb.muted, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              _sep(),
              _btn(Icons.undo, 'Anulează (Ctrl+Z)', _undo.isEmpty ? null : _undoOp),
              _btn(Icons.redo, 'Refă (Ctrl+Y)', _redo.isEmpty ? null : _redoOp),
              _btn(Icons.delete_sweep_outlined, _base == null ? 'Șterge toată pagina' : 'Șterge tot ce ai scris tu', _doc.strokes.isEmpty ? null : _clear),
              _sep(),
            ],
            _tool_('hand', Icons.pan_tool_outlined, 'Mută pagina'),
            _btn(Icons.remove, 'Micșorează', _zoom == _zooms.first ? null : () => _setZoom(-1)),
            SizedBox(
              width: 44,
              child: Text('${(_zoom * 100).round()}%', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted)),
            ),
            _btn(Icons.add, 'Mărește', _zoom == _zooms.last ? null : () => _setZoom(1)),
            if (_editable && _base == null) ...[
              _sep(),
              _btn(
                _doc.paper == 'grid' ? Icons.grid_4x4 : (_doc.paper == 'lines' ? Icons.reorder : Icons.crop_din),
                'Hârtie: ${const {'blank': 'albă', 'grid': 'pătrățele', 'lines': 'liniată'}[_doc.paper] ?? 'pătrățele'}',
                _setPaper,
              ),
            ],
            if (_editable) _btn(Icons.vertical_align_bottom, 'Adaugă spațiu jos', _height >= 40 ? null : _grow),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build
  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent || !_editable) return KeyEventResult.ignored;
    final kb = HardwareKeyboard.instance;
    if (!(kb.isControlPressed || kb.isMetaPressed)) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.keyZ) {
      kb.isShiftPressed ? _redoOp() : _undoOp();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyY) {
      _redoOp();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Which devices scroll by dragging: everything with the hand tool or on a
    // read-only page; only fingers once a pen is in use; nothing while a
    // finger or the mouse is the pen (wheel, trackpad and scrollbar still work).
    final Set<PointerDeviceKind> drag = !_editable || _tool == 'hand'
        ? PointerDeviceKind.values.toSet()
        : {PointerDeviceKind.trackpad, if (_stylusSeen) PointerDeviceKind.touch};

    return Focus(
      focusNode: _focus,
      autofocus: _editable,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(),
          if (_editable && _bytes > widget.maxLength * 0.85)
            Container(
              color: Pb.warningBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text(
                _full ? 'Pagina e plină. Continuă pe o pagină nouă sau șterge din ce ai scris.' : 'Pagina e aproape plină. Mai e loc de puțin, apoi continuă pe o pagină nouă.',
                style: TextStyle(fontSize: 13, color: Pb.warningText),
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: Pb.page,
              child: LayoutBuilder(
                builder: (context, box) {
                  final pad = widget.compact ? 8.0 : 20.0;
                  final w = (math.min(box.maxWidth - pad * 2, _maxSheet) * _zoom).floorToDouble();
                  final h = w * _height;
                  final cursor = !_editable
                      ? SystemMouseCursors.basic
                      : (_tool == 'hand' ? SystemMouseCursors.grab : (_tool == 'eraser' ? SystemMouseCursors.cell : SystemMouseCursors.precise));

                  final sheet = Container(
                    width: w,
                    height: h,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _paperColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    // Drawn over the sheet, so the border does not shift the ink by a pixel.
                    foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Pb.border)),
                    child: MouseRegion(
                      cursor: cursor,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) => _down(e, w),
                        onPointerMove: (e) => _moveTo(e, w),
                        onPointerUp: _up,
                        onPointerCancel: _up,
                        child: CustomPaint(
                          size: Size(w, h),
                          painter: _SheetPainter(
                            width: w,
                            paper: _paper,
                            base: _base == null ? null : (_basePic ??= _record(_base.strokes)),
                            committed: () => _pic ??= _record(_doc.strokes),
                            live: () => _live,
                            repaint: _tick,
                          ),
                        ),
                      ),
                    ),
                  );

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: drag),
                    child: Scrollbar(
                      controller: _v,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _v,
                        padding: EdgeInsets.fromLTRB(0, pad, 0, 130),
                        child: SingleChildScrollView(
                          controller: _h,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: box.maxWidth),
                            child: Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: sheet)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  final double width;
  final String paper;
  final ui.Picture? base;
  final ui.Picture Function() committed;
  final NoteStroke? Function() live;

  _SheetPainter({
    required this.width,
    required this.paper,
    required this.base,
    required this.committed,
    required this.live,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paper == 'grid' || paper == 'lines') {
      final rule = Paint()
        ..color = _ruleColor
        ..strokeWidth = 1;
      final step = width / (paper == 'grid' ? 40 : 26);
      for (var y = step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(width, y), rule);
      }
      if (paper == 'grid') {
        for (var x = step; x < width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), rule);
        }
      }
    }
    canvas.save();
    canvas.scale(width);
    if (base != null) canvas.drawPicture(base!);
    canvas.drawPicture(committed());
    final l = live();
    if (l != null) _paintStroke(canvas, l);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheetPainter old) => old.width != width || old.paper != paper || old.base != base;
}
