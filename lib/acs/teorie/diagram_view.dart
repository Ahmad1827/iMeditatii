// =============================================================================
// A STATE DIAGRAM: what every theory page draws automata with
//   States where the diagram puts them (scaled to the space there is), the
//   start marked by an arrow, final states doubled. An arrow is straight
//   unless another state is in its way or it has a way back; then it bends.
//   Some states and arrows can be lit (where a word has got to, what a step
//   just made) and some faded (what is about to go).
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/lfa_algo.dart';

/// The places the drawing must hold, in grid units: the states, and the
/// highest point of every arrow given a fixed bend.
List<(double, double)> _extent(Diagram d) {
  final out = [...d.pos];
  final bends = d.bends;
  if (bends == null) return out;
  for (final (k, (f, t, _)) in d.edges.indexed) {
    final b = k < bends.length ? bends[k] : null;
    if (b == null || f == t) continue;
    final (px, py) = d.pos[f];
    final (qx, qy) = d.pos[t];
    final dx = qx - px, dy = qy - py;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) continue;
    // the normal (-u.dy, u.dx); a quadratic arc reaches half its control's distance
    out.add(((px + qx) / 2 - dy / len * b / 2, (py + qy) / 2 + dx / len * b / 2));
  }
  return out;
}

class DiagramView extends StatelessWidget {
  final AcsInk ink;
  final Diagram d;
  final Set<int> active; // states lit
  final Set<int> hot; // arrows lit, by index in d.edges
  final Set<int> faded; // states drawn pale
  final Set<int> marked; // states ringed in the warning colour
  final double maxHeight;
  final void Function(int state)? onTapState;
  const DiagramView(this.ink, this.d,
      {super.key, this.active = const {}, this.hot = const {}, this.faded = const {}, this.marked = const {}, this.maxHeight = 380, this.onTapState});

  (double, double, double, double) get _box {
    if (d.pos.isEmpty) return (0, 0, 1, 1);
    var x0 = double.infinity, y0 = double.infinity, x1 = -double.infinity, y1 = -double.infinity;
    for (final (x, y) in _extent(d)) {
      x0 = math.min(x0, x);
      y0 = math.min(y0, y);
      x1 = math.max(x1, x);
      y1 = math.max(y1, y);
    }
    return (x0, y0, x1, y1);
  }

  /// The most lines a loop's label has: loops need room above or below their row.
  int get _loopLines => d.edges.where((e) => e.$1 == e.$2).fold(0, (m, e) => math.max(m, e.$3.split('\n').length));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final (x0, y0, x1, y1) = _box;
      final w = c.maxWidth;
      final unitW = (w - 120) / math.max(0.8, x1 - x0);
      final unit = math.min(120.0, unitW);
      final loops = _loopLines;
      final h = ((y1 - y0) * unit + 130 + (loops == 0 ? 0 : 2 * (14.0 * loops + 10))).clamp(150.0, maxHeight + 28.0 * loops);
      final painter = _DiagramPainter(ink, d, active, hot, faded, marked);
      final paint = CustomPaint(size: Size(w, h), painter: painter);
      if (onTapState == null) return SizedBox(width: w, height: h, child: paint);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (e) {
          final s = painter.hit(Size(w, h), e.localPosition);
          if (s != null) onTapState!(s);
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: SizedBox(width: w, height: h, child: paint)),
      );
    });
  }
}

class _DiagramPainter extends CustomPainter {
  final AcsInk ink;
  final Diagram d;
  final Set<int> active, hot, faded, marked;
  _DiagramPainter(this.ink, this.d, this.active, this.hot, this.faded, this.marked);

  late List<Offset> _at;
  late double _r;
  late double _scale;
  late List<double> _halfW; // half the width of each state's shape

  void _layout(Size size) {
    var x0 = double.infinity, y0 = double.infinity, x1 = -double.infinity, y1 = -double.infinity;
    for (final (x, y) in _extent(d)) {
      x0 = math.min(x0, x);
      y0 = math.min(y0, y);
      x1 = math.max(x1, x);
      y1 = math.max(y1, y);
    }
    if (d.pos.isEmpty) {
      _at = const [];
      _r = 18;
      _halfW = const [];
      return;
    }
    final loops = d.edges.where((e) => e.$1 == e.$2).fold(0, (m, e) => math.max(m, e.$3.split('\n').length));
    const mx = 62.0;
    final my = loops == 0 ? 50.0 : 62.0 + 14.0 * loops;
    final bw = math.max(0.0001, x1 - x0), bh = math.max(0.0001, y1 - y0);
    final sx = (size.width - 2 * mx) / bw, sy = (size.height - 2 * my) / bh;
    var s = math.min(sx, sy);
    if (x1 - x0 < 0.001) s = sy;
    if (y1 - y0 < 0.001) s = sx;
    s = math.min(s, 130);
    final ox = (size.width - bw * s) / 2, oy = (size.height - bh * s) / 2;
    _at = [for (final (x, y) in d.pos) Offset(ox + (x - x0) * s, oy + (y - y0) * s)];
    _r = (s * 0.26).clamp(13.0, 20.0);
    _scale = s;
    _halfW = [for (final name in d.names) math.max(_r, _text(name, 12.5, ink.strong, bold: true).width / 2 + 8)];
  }

  int? hit(Size size, Offset p) {
    _layout(size);
    for (var i = 0; i < _at.length; i++) {
      if ((p - _at[i]).dx.abs() <= _halfW[i] + 4 && (p - _at[i]).dy.abs() <= _r + 4) return i;
    }
    return null;
  }

  TextPainter _text(String t, double size, Color c, {bool bold = false}) =>
      TextPainter(text: TextSpan(text: t, style: ink.mono(size, color: c, weight: bold ? FontWeight.w700 : FontWeight.w500, height: 1.15)), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();

  /// Where a ray from the centre of state [i] towards [dir] leaves its shape.
  Offset _rim(int i, Offset dir) {
    final u = dir / math.max(0.0001, dir.distance);
    final hw = _halfW[i];
    if (hw <= _r + 0.5) return _at[i] + u * _r;
    // a stadium: the straight part is 2(hw - r) wide
    final t = math.min(u.dx.abs() < 1e-6 ? double.infinity : (hw) / u.dx.abs(), u.dy.abs() < 1e-6 ? double.infinity : _r / u.dy.abs());
    return _at[i] + u * t;
  }

  void _arrowHead(Canvas canvas, Offset tip, Offset dir, Color c) {
    final u = dir / math.max(0.0001, dir.distance);
    final n = Offset(-u.dy, u.dx);
    canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - u.dx * 9 + n.dx * 4.2, tip.dy - u.dy * 9 + n.dy * 4.2)
          ..lineTo(tip.dx - u.dx * 9 - n.dx * 4.2, tip.dy - u.dy * 9 - n.dy * 4.2)
          ..close(),
        Paint()..color = c);
  }

  void _label(Canvas canvas, String t, Offset at, Color c) {
    final tp = _text(t, 12, c);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: tp.width + 6, height: tp.height + 2), const Radius.circular(3)), Paint()..color = ink.bg.withValues(alpha: 0.92));
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  Offset _bez(Offset a, Offset c, Offset b, double t) => a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

  @override
  void paint(Canvas canvas, Size size) {
    _layout(size);
    if (_at.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    final centre = _at.fold(Offset.zero, (a, b) => a + b) / _at.length.toDouble();
    final pairs = {for (final (f, t, _) in d.edges) (f, t)};

    for (final (k, (f, t, label)) in d.edges.indexed) {
      final lit = hot.contains(k);
      final pale = faded.contains(f) || faded.contains(t);
      final c = lit ? ink.accent : (pale ? ink.dim : ink.muted);
      final line = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = lit ? 2.4 : 1.4;
      if (f == t) {
        // a loop, straight up (down for the states below the middle of the drawing)
        final out = Offset(0, _at[f].dy > centre.dy + 1 ? 1 : -1);
        final n = Offset(-out.dy, out.dx);
        final base = _rim(f, out);
        final a = base + n * 9, b = base - n * 9;
        final c1 = a + out * 34 + n * 14, c2 = b + out * 34 - n * 14;
        canvas.drawPath(Path()..moveTo(a.dx, a.dy)..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy), line);
        _arrowHead(canvas, b, b - c2, c);
        final lines = label.split('\n').length;
        _label(canvas, label, base + out * (40 + 7.0 * lines), lit ? ink.accent : ink.fg);
        continue;
      }
      final p = _at[f], q = _at[t];
      final v = q - p;
      final dist = v.distance;
      final u = v / dist;
      final n = Offset(-u.dy, u.dx);
      var bend = 0.0;
      final fixed = d.bends != null && k < d.bends!.length ? d.bends![k] : null;
      if (pairs.contains((t, f))) bend = math.min(34, dist * 0.2);
      // another state on the way: go around it, on the side it is not
      for (var i = 0; i < _at.length; i++) {
        if (i == f || i == t) continue;
        final w = _at[i] - p;
        final along = w.dx * u.dx + w.dy * u.dy;
        final across = w.dx * n.dx + w.dy * n.dy;
        if (along > 0 && along < dist && across.abs() < _r * 1.6) {
          final need = (_r * 2.4 + across.abs()) * 2;
          final sign = across >= 0 ? -1.0 : 1.0;
          if (need > bend.abs()) bend = sign * math.min(need, dist * 0.6);
        }
      }
      if (fixed != null) bend = fixed * _scale;
      final ctrl = (p + q) / 2 + n * (bend * 1.0);
      final from = _rim(f, ctrl - p), to = _rim(t, ctrl - q);
      final ctrl2 = (from + to) / 2 + n * bend;
      canvas.drawPath(Path()..moveTo(from.dx, from.dy)..quadraticBezierTo(ctrl2.dx, ctrl2.dy, to.dx, to.dy), line);
      _arrowHead(canvas, to, to - _bez(from, ctrl2, to, 0.92), c);
      final mid = _bez(from, ctrl2, to, 0.5);
      final lines = label.split('\n').length;
      final off = bend == 0 ? n * (8.0 + 6.0 * lines) : n * (bend.sign * (6.0 + 6.0 * lines));
      _label(canvas, label, mid + (bend == 0 ? -off : off), lit ? ink.accent : ink.fg);
    }

    for (var i = 0; i < _at.length; i++) {
      final on = active.contains(i);
      final pale = faded.contains(i);
      final warn = marked.contains(i);
      final hw = _halfW[i];
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: _at[i], width: hw * 2, height: _r * 2), Radius.circular(_r));
      canvas.drawRRect(rect, Paint()..color = on ? ink.accent.withValues(alpha: ink.dark ? 0.28 : 0.18) : (warn ? ink.warn.withValues(alpha: 0.16) : ink.panel));
      final edge = Paint()
        ..color = on ? ink.accent : (warn ? ink.warn : (pale ? ink.dim : ink.strong))
        ..style = PaintingStyle.stroke
        ..strokeWidth = on || warn ? 2.3 : 1.5;
      canvas.drawRRect(rect, edge);
      if (d.finals.contains(i)) canvas.drawRRect(rect.deflate(3.5), edge);
      final tp = _text(d.names[i], 12.5, on ? ink.accent : (pale ? ink.dim : ink.strong), bold: true);
      tp.paint(canvas, _at[i] - Offset(tp.width / 2, tp.height / 2));
      if (i == d.start) {
        final tip = _at[i] - Offset(hw, 0);
        final line = Paint()
          ..color = ink.muted
          ..strokeWidth = 1.4;
        canvas.drawLine(tip - const Offset(24, 0), tip, line);
        _arrowHead(canvas, tip, const Offset(1, 0), ink.muted);
      }
    }
  }

  @override
  bool shouldRepaint(_DiagramPainter old) => true;
}
