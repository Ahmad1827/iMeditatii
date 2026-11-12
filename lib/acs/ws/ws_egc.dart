// =============================================================================
// EGC: TRANSFORMATIONS COMPOSED ON THE DRAWING, AND RASTERS LIT PIXEL BY PIXEL
//   Transformations: the student builds the list (T, R, S, F with their
//   numbers), in the order they are applied; the shape moves as the list
//   changes, towards the dashed target, and the product of matrices is
//   written as in the course. Any list with the right matrix is accepted.
//   Rasters: the pixels an algorithm lights (a segment, a circle) are
//   clicked on a grid, the ideal curve drawn over it.
// =============================================================================

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/egc.dart';
import 'ws_common.dart';

class TransformWorkspace extends AcsWorkspace {
  const TransformWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<TransformWorkspace> createState() => _TransformWorkspaceState();
}

class _Row {
  String kind;
  final TextEditingController a = TextEditingController(), b = TextEditingController();
  _Row(this.kind, [String a = '', String b = '']) {
    this.a.text = a;
    this.b.text = b;
  }
  double? _num(String t) => double.tryParse(t.trim().replaceAll(',', '.').replaceAll('°', ''));
  bool get ok => _num(a.text) != null && (kind == 'R' || _num(b.text) != null);
  Op? get op => ok ? Op(kind, _num(a.text)!, kind == 'R' ? 0 : _num(b.text)!) : null;
}

class _TransformWorkspaceState extends State<TransformWorkspace> {
  late final TransformTask _task = TransformTask.fromSpec(widget.problem.spec);
  final List<_Row> _rows = [];
  int? _upTo; // show the shape after only this many steps
  List<Check> _checks = const [];

  @override
  void initState() {
    super.initState();
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        setState(() {
          for (final j in json.decode(d) as List) {
            _add('${j['op']}', a: '${j['a']}', b: '${j['b']}', save: false);
          }
        });
      } catch (_) {
        // an old draft we can't read: start clean
      }
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.a.dispose();
      r.b.dispose();
    }
    super.dispose();
  }

  void _add(String kind, {String a = '', String b = '', bool save = true}) {
    final r = _Row(kind, a, b);
    r.a.addListener(_changed);
    r.b.addListener(_changed);
    _rows.add(r);
    if (save) _changed();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      _checks = const [];
      _upTo = null;
    });
    AcsProgress.saveDraft(widget.problem, json.encode([for (final r in _rows) {'op': r.kind, 'a': r.a.text, 'b': r.b.text}]));
  }

  List<Op> get _ops => [for (final r in _rows) if (r.op != null) r.op!];

  void _verify() {
    if (_rows.any((r) => !r.ok)) {
      setState(() => _checks = const [Check('fiecare transformare are numerele completate', false, 'completează câmpurile goale sau șterge rândul')]);
      widget.onVerdict(false);
      return;
    }
    final r = _task.check(_ops);
    setState(() => _checks = [for (final (l, ok, d) in r) Check(l, ok, d)]);
    widget.onVerdict(r.every((c) => c.$2));
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final ops = _ops;
    final shown = _upTo == null ? ops : ops.take(_upTo!).toList();
    final m = compose(ops);
    String f(double v) => (v.abs() < 5e-10 ? 0.0 : v).toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '').padLeft(7);
    final hints = {'T': ('tx', 'ty'), 'R': ('grade', ''), 'S': ('sx', 'sy'), 'F': ('fx', 'fy')};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          title: ink.terminal ? 'gri: forma dată · plin: forma ta · punctat: ținta' : 'Gri: forma dată · plin: forma ta · punctat: ținta',
          color: ink.bg,
          padding: const EdgeInsets.all(4),
          child: AspectRatio(
            aspectRatio: widget.narrow ? 1.0 : 1.7,
            child: CustomPaint(painter: _PlanePainter(_task, compose(shown), ink)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
            ink.terminal
                ? '# transformările, în ordinea în care se aplică (prima de sus se aplică prima)'
                : 'Transformările, în ordinea în care se aplică (prima de sus se aplică prima). Rotația e în grade, în sens trigonometric, față de origine.',
            style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 8),
        for (final (i, r) in _rows.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ToolRow([
              SizedBox(width: 22, child: Text('${i + 1}.', style: ink.mono(14, color: ink.muted))),
              SizedBox(width: 96, child: Text('${r.kind} ${Op.names[r.kind]}', style: ink.mono(14, weight: FontWeight.w700, color: ink.accent))),
              AcsField(ink, r.a, width: 78, hint: hints[r.kind]!.$1, ok: r.a.text.isEmpty || r._num(r.a.text) != null ? null : false, onSubmitted: (_) => _verify()),
              if (r.kind != 'R') AcsField(ink, r.b, width: 78, hint: hints[r.kind]!.$2, ok: r.b.text.isEmpty || r._num(r.b.text) != null ? null : false, onSubmitted: (_) => _verify()),
              AcsButton(ink, '↑', i > 0 ? () => _move(i, -1) : null),
              AcsButton(ink, '↓', i < _rows.length - 1 ? () => _move(i, 1) : null),
              AcsButton(ink, 'șterge', () {
                final x = _rows.removeAt(i);
                x.a.dispose();
                x.b.dispose();
                _changed();
              }),
            ]),
          ),
        ToolRow([
          for (final k in const ['T', 'R', 'S', 'F'])
            if (_task.allowed.contains(k)) AcsButton(ink, '+ $k ${Op.names[k]}', () => _add(k)),
        ]),
        const SizedBox(height: 10),
        AcsBox(
          ink,
          title: productText(ops),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++) Text('│${f(m.m[i * 3])} ${f(m.m[i * 3 + 1])} ${f(m.m[i * 3 + 2])} │', style: ink.mono(14, color: ink.strong)),
              if (ops.length > 1) ...[
                const SizedBox(height: 8),
                ToolRow([
                  Text('arată forma după', style: ink.mono(13, color: ink.muted)),
                  for (var k = 0; k <= ops.length; k++)
                    AcsButton(ink, k == ops.length ? 'toate' : '$k', () => setState(() => _upTo = k == ops.length ? null : k), primary: (_upTo ?? ops.length) == k),
                ]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        ToolRow([AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check)]),
        if (_checks.isNotEmpty) ...[const SizedBox(height: 12), ChecksView(ink, _checks)],
      ],
    );
  }

  void _move(int i, int d) {
    final r = _rows.removeAt(i);
    _rows.insert(i + d, r);
    _changed();
  }
}

/// The plane: a grid with the axes, the shape as given, as the student's
/// transformations leave it, and where it should end.
class _PlanePainter extends CustomPainter {
  final TransformTask task;
  final Mat3 mine;
  final AcsInk ink;
  _PlanePainter(this.task, this.mine, this.ink);

  @override
  void paint(Canvas canvas, Size size) {
    List<(double, double)> through(Mat3 m) => [for (final (x, y) in task.shape) m.apply(x, y)];
    final given = task.shape, goal = through(task.target), now = through(mine);
    // the window: everything that has to be seen, and the origin
    var x0 = 0.0, x1 = 0.0, y0 = 0.0, y1 = 0.0;
    for (final (x, y) in [...given, ...goal]) {
      x0 = math.min(x0, x);
      x1 = math.max(x1, x);
      y0 = math.min(y0, y);
      y1 = math.max(y1, y);
    }
    x0 = x0.floorToDouble() - 1;
    y0 = y0.floorToDouble() - 1;
    x1 = x1.ceilToDouble() + 1;
    y1 = y1.ceilToDouble() + 1;
    final unit = math.min(size.width / (x1 - x0), size.height / (y1 - y0));
    final ox = (size.width - unit * (x1 - x0)) / 2 - x0 * unit, oy = size.height - (size.height - unit * (y1 - y0)) / 2 + y0 * unit;
    Offset at(double x, double y) => Offset(ox + x * unit, oy - y * unit);
    canvas.clipRect(Offset.zero & size);

    final grid = Paint()
      ..color = ink.line
      ..strokeWidth = 1;
    for (var x = x0; x <= x1; x++) {
      canvas.drawLine(at(x, y0), at(x, y1), grid);
    }
    for (var y = y0; y <= y1; y++) {
      canvas.drawLine(at(x0, y), at(x1, y), grid);
    }
    final axis = Paint()
      ..color = ink.muted
      ..strokeWidth = 1.6;
    canvas.drawLine(at(x0, 0), at(x1, 0), axis);
    canvas.drawLine(at(0, y0), at(0, y1), axis);
    void label(String t, Offset p) {
      final tp = TextPainter(text: TextSpan(text: t, style: ink.mono(10.5, color: ink.muted)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, p);
    }

    final every = unit < 16 ? 5 : (unit < 26 ? 2 : 1);
    for (var x = x0.toInt(); x <= x1; x++) {
      if (x != 0 && x % every == 0) label('$x', at(x.toDouble(), 0) + const Offset(2, 2));
    }
    for (var y = y0.toInt(); y <= y1; y++) {
      if (y != 0 && y % every == 0) label('$y', at(0, y.toDouble()) + const Offset(3, -12));
    }
    label('O', at(0, 0) + const Offset(3, 2));

    Path poly(List<(double, double)> pts) {
      final p = Path();
      for (final (i, (x, y)) in pts.indexed) {
        final o = at(x, y);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    canvas.drawPath(poly(given), Paint()..color = ink.muted.withValues(alpha: 0.22));
    canvas.drawPath(
        poly(given),
        Paint()
          ..color = ink.muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // the target, dashed: short pieces along each edge
    final dash = Paint()
      ..color = ink.good
      ..strokeWidth = 2;
    for (var i = 0; i < goal.length; i++) {
      final a = at(goal[i].$1, goal[i].$2), b = at(goal[(i + 1) % goal.length].$1, goal[(i + 1) % goal.length].$2);
      final len = (b - a).distance;
      for (var d = 0.0; d < len; d += 9) {
        canvas.drawLine(a + (b - a) * (d / len), a + (b - a) * (math.min(d + 5, len) / len), dash);
      }
    }
    canvas.drawPath(poly(now), Paint()..color = ink.accent.withValues(alpha: 0.28));
    canvas.drawPath(
        poly(now),
        Paint()
          ..color = ink.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // the first vertex marked, so a mirrored shape is told from a rotated one
    canvas.drawCircle(at(given.first.$1, given.first.$2), 3.5, Paint()..color = ink.muted);
    canvas.drawCircle(at(goal.first.$1, goal.first.$2), 4.5, Paint()..color = ink.good);
    canvas.drawCircle(at(now.first.$1, now.first.$2), 3.5, Paint()..color = ink.accent);
  }

  @override
  bool shouldRepaint(_PlanePainter old) => true;
}

// ---------------------------------------------------------------- raster
class RasterWorkspace extends AcsWorkspace {
  const RasterWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<RasterWorkspace> createState() => _RasterWorkspaceState();
}

class _RasterWorkspaceState extends State<RasterWorkspace> {
  late final RasterTask _task = RasterTask.fromSpec(widget.problem.spec);
  late final Set<(int, int)> _lit = {..._task.given};
  List<Check> _checks = const [];

  @override
  void initState() {
    super.initState();
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        setState(() => _lit.addAll([for (final p in json.decode(d) as List) ((p[0] as num).toInt(), (p[1] as num).toInt())]));
      } catch (_) {
        // an old draft we can't read: start clean
      }
    });
  }

  void _toggle((int, int) p) {
    if (_task.given.contains(p) || p.$1 < 0 || p.$2 < 0 || p.$1 >= _task.width || p.$2 >= _task.height) return;
    setState(() {
      _lit.contains(p) ? _lit.remove(p) : _lit.add(p);
      _checks = const [];
    });
    AcsProgress.saveDraft(widget.problem, json.encode([for (final (x, y) in _lit) [x, y]]));
  }

  void _verify() {
    final r = _task.check(_lit);
    setState(() => _checks = [for (final (l, ok, d) in r) Check(l, ok, d)]);
    widget.onVerdict(r.every((c) => c.$2));
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final spec = widget.problem.spec;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            ink.terminal
                ? '# apasă pe pixelii pe care îi aprinde algoritmul (originea e jos, în stânga)'
                : 'Apasă pe pixelii pe care îi aprinde algoritmul. Originea e jos, în stânga; pixelii dați sunt deja aprinși.',
            style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final cell = math.min(38.0, (c.maxWidth - 28) / _task.width);
          final w = cell * _task.width + 28, h = cell * _task.height + 22;
          return Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTapUp: (e) => _toggle((((e.localPosition.dx - 28) / cell).floor(), _task.height - 1 - (e.localPosition.dy / cell).floor())),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CustomPaint(size: Size(w, h), painter: _GridPainter(_task, _lit, ink, cell, spec)),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check),
          AcsConfirmButton(ink, 'stinge tot', () {
            setState(() {
              _lit
                ..clear()
                ..addAll(_task.given);
              _checks = const [];
            });
            AcsProgress.saveDraft(widget.problem, '[]');
          }),
          Text('${_lit.length} pixeli aprinși', style: ink.mono(13, color: ink.muted)),
        ]),
        if (_checks.isNotEmpty) ...[const SizedBox(height: 12), ChecksView(ink, _checks)],
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final RasterTask task;
  final Set<(int, int)> lit;
  final AcsInk ink;
  final double cell;
  final Map<String, dynamic> spec;
  _GridPainter(this.task, this.lit, this.ink, this.cell, this.spec);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0;
    Rect box(int x, int y) => Rect.fromLTWH(left + x * cell, (task.height - 1 - y) * cell, cell, cell);
    Offset mid(num x, num y) => Offset(left + (x + 0.5) * cell, (task.height - 0.5 - y) * cell);
    for (var y = 0; y < task.height; y++) {
      for (var x = 0; x < task.width; x++) {
        final on = lit.contains((x, y));
        canvas.drawRect(box(x, y).deflate(0.5), Paint()..color = on ? (task.given.contains((x, y)) ? ink.strong : ink.accent) : ink.panel);
        canvas.drawRect(
            box(x, y),
            Paint()
              ..color = ink.line
              ..style = PaintingStyle.stroke);
      }
    }
    void label(String t, Offset center) {
      final tp = TextPainter(text: TextSpan(text: t, style: ink.mono(10.5, color: ink.muted)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }

    for (var x = 0; x < task.width; x++) {
      label('$x', Offset(left + (x + 0.5) * cell, task.height * cell + 10));
    }
    for (var y = 0; y < task.height; y++) {
      label('$y', Offset(12, (task.height - 0.5 - y) * cell));
    }
    // the ideal curve, through the centres of the pixels
    final ideal = Paint()
      ..color = ink.good
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final line = spec['line'] as List?;
    if (line != null) canvas.drawLine(mid(line[0] as num, line[1] as num), mid(line[2] as num, line[3] as num), ideal);
    final circle = spec['circle'] as List?;
    if (circle != null) canvas.drawCircle(mid(circle[0] as num, circle[1] as num), (circle[2] as num) * cell, ideal);
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
