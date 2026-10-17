import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'clean_kit.dart' show CkHover;
import 'ui_components.dart' show Pb;

// =============================================================================
// CLASSROOM — the pieces that make the classes pages look like a classroom,
// drawn in ink on paper, the way you'd sketch it in a notebook:
//   Pen           a hand: lines bow a little and run past the corners
//   Chalkboard    the board drawn as a frame, a tray with chalk under it
//   ChalkStat     a number on the board, in a hand-drawn box
//   ChalkButton   a button in a hand-drawn outline
//   NotebookPaper ruled lines and the red margin of a school notebook
//   StickyNote    a yellow note stuck on with a bit of tape
//   BinderSpine   the coloured spine of a ring binder
// =============================================================================

/// The ink everything is drawn with, and the paper it's drawn on.
Color get inkColor => AppColors.isDark ? const Color(0xFFE4E1D9) : const Color(0xFF26262A);
Color get paperColor => AppColors.isDark ? const Color(0xFF1F2022) : const Color(0xFFFCFBF7);

/// Text written on the board or on a note, in the site's font. Sizes are
/// given on a handwriting scale and shrunk to match the site's type.
TextStyle chalk(double size, {Color? color, FontWeight weight = FontWeight.w600, double? height}) => TextStyle(
      fontSize: math.max(12, (size * 0.68).roundToDouble()),
      color: color ?? inkColor,
      fontWeight: size >= 40 ? FontWeight.w700 : weight,
      height: height,
      letterSpacing: size >= 40 ? -0.6 : null,
    );

const Color chalkWhite = Color(0xF2FFFFFF);
const Color chalkYellow = Color(0xFFFFE89A);
const Color chalkPink = Color(0xFFFFB4C8);
const Color chalkBlue = Color(0xFFA9D8FF);
const Color chalkGreen = Color(0xFFB6F0C2);

const _days = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
const _months = ['ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie', 'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'];

/// "Vineri, 16 octombrie", the way it's written in the corner of the board.
String boardDate([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${_days[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]}';
}

// ----------------------------------------------------------------- pen
/// Draws like a hand holding a fine pen: every line bows a little, runs a
/// touch past where it should end, and is gone over a second time, lightly.
/// The same [seed] always draws the same lines.
class Pen {
  final Canvas canvas;
  final Color color;
  final double width;
  final math.Random _rnd;
  Pen(this.canvas, {required this.color, this.width = 1.3, int seed = 1}) : _rnd = math.Random(seed);

  double _j(double a) => (_rnd.nextDouble() - 0.5) * 2 * a;

  Paint _paint(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Path _line(Offset a, Offset b, double over) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return Path();
    final u = d / len;
    final n = Offset(-u.dy, u.dx);
    final a2 = a - u * (over * (0.3 + _rnd.nextDouble() * 0.7)) + n * _j(0.5);
    final b2 = b + u * (over * (0.3 + _rnd.nextDouble() * 0.7)) + n * _j(0.5);
    final m = Offset.lerp(a2, b2, 0.5)! + n * _j(math.min(2.0, len * 0.02));
    return Path()
      ..moveTo(a2.dx, a2.dy)
      ..quadraticBezierTo(m.dx, m.dy, b2.dx, b2.dy);
  }

  /// A line from [a] to [b], running [over] past both ends.
  void line(Offset a, Offset b, {double over = 0, Color? color, double? width}) {
    final c = color ?? this.color;
    final w = width ?? this.width;
    canvas.drawPath(_line(a, b, over), _paint(c, w));
    canvas.drawPath(_line(a, b, over * 0.5), _paint(c.withOpacity(c.opacity * 0.3), w * 0.7));
  }

  /// Straight sides through [pts], each one drawn on its own so the corners
  /// cross. Filled with [fill] first, so it hides what's behind it.
  void shape(List<Offset> pts, {bool closed = true, double over = 2.5, Color? fill, Color? color, double? width}) {
    if (fill != null) canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = fill);
    for (var i = 0; i < pts.length - (closed ? 0 : 1); i++) {
      line(pts[i], pts[(i + 1) % pts.length], over: over, color: color, width: width);
    }
  }

  void rect(Rect r, {double over = 2.5, Color? fill, Color? color, double? width}) =>
      shape([r.topLeft, r.topRight, r.bottomRight, r.bottomLeft], over: over, fill: fill, color: color, width: width);

  /// Any path, gone over twice.
  void path(Path p, {Color? fill, Color? color, double? width}) {
    final c = color ?? this.color;
    final w = width ?? this.width;
    if (fill != null) canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(p, _paint(c, w));
    canvas.drawPath(p.shift(Offset(_j(0.7), _j(0.7))), _paint(c.withOpacity(c.opacity * 0.3), w * 0.7));
  }

  /// A circle that doesn't quite close: it starts anywhere and overlaps itself.
  void ring(Offset c, double r, {Color? fill, Color? color, double? width}) {
    if (fill != null) canvas.drawCircle(c, r, Paint()..color = fill);
    final start = _rnd.nextDouble() * math.pi * 2;
    final phase = _rnd.nextDouble() * math.pi * 2;
    final p = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = start + (math.pi * 2 + 0.45) * i / steps;
      final rr = r * (1 + 0.035 * math.sin(2 * t + phase)) + i / steps * r * 0.04;
      final o = c + Offset(math.cos(t), math.sin(t)) * rr;
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    final col = color ?? this.color;
    final w = width ?? this.width;
    canvas.drawPath(p, _paint(col, w));
  }

  /// Parallel strokes inside [clip], for shade or hair.
  void hatch(Path clip, {double gap = 4, double angle = -0.9, Color? color, double? width}) {
    final b = clip.getBounds();
    final c = color ?? this.color.withOpacity(this.color.opacity * 0.5);
    final w = width ?? this.width * 0.7;
    canvas.save();
    canvas.clipPath(clip);
    final u = Offset(math.cos(angle), math.sin(angle));
    final n = Offset(-u.dy, u.dx);
    final span = b.longestSide * 1.5;
    for (var d = -span / 2; d <= span / 2; d += gap) {
      final m = b.center + n * d;
      canvas.drawPath(_line(m - u * span / 2, m + u * span / 2, 0), _paint(c, w));
    }
    canvas.restore();
  }

  /// A loose wavy line, for steam, wood grain, a smudge.
  void wave(Offset a, Offset b, {double amp = 2, double waves = 2, Color? color, double? width}) {
    final d = b - a;
    final n = Offset(-d.dy, d.dx) / d.distance;
    final p = Path()..moveTo(a.dx, a.dy);
    for (var i = 1; i <= 24; i++) {
      final t = i / 24;
      final o = a + d * t + n * (math.sin(t * math.pi * 2 * waves) * amp);
      p.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(p, _paint(color ?? this.color, width ?? this.width));
  }
}

// ----------------------------------------------------------------- board
class Chalkboard extends StatelessWidget {
  final Widget child;
  final bool showDate;
  const Chalkboard({super.key, required this.child, this.showDate = true});

  static const double _tray = 20;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final pad = isMobile ? 20.0 : 32.0;
    return CustomPaint(
      painter: _BoardSketch(ink: inkColor, tray: _tray),
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, isMobile ? 18 : 24, pad, (isMobile ? 22 : 28) + _tray),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate)
              Align(
                alignment: Alignment.centerRight,
                child: Text(boardDate(), style: chalk(isMobile ? 17 : 20, color: inkColor.withOpacity(0.45), weight: FontWeight.w500)),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// The board as a sketch: a double frame, its shadow side hatched, and the
/// tray with a stick of chalk and the eraser.
class _BoardSketch extends CustomPainter {
  final Color ink;
  final double tray;
  _BoardSketch({required this.ink, required this.tray});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Pen(canvas, color: ink, width: 1.5, seed: 11);
    final w = size.width, h = size.height - tray;
    const f = 8.0; // between the two frames
    canvas.drawRect(Rect.fromLTWH(f, f, w - f * 2, h - f * 2), Paint()..color = ink.withOpacity(0.025));
    pen.rect(Rect.fromLTWH(0, 0, w, h), over: 7);
    pen.rect(Rect.fromLTWH(f, f, w - f * 2, h - f * 2), over: 3, color: ink.withOpacity(0.45), width: 0.9);
    // the frame's shadow side
    pen.hatch(
      Path()
        ..addRect(Rect.fromLTWH(w - f, f, f, h - f))
        ..addRect(Rect.fromLTWH(f, h - f, w - f * 2, f)),
      gap: 3.2,
      color: ink.withOpacity(0.35),
      width: 0.8,
    );
    // the tray, a stick of chalk and the eraser
    final y = h + tray * 0.55;
    pen.line(Offset(14, y), Offset(w - 14, y), over: 4);
    pen.line(Offset(22, y + 4), Offset(w - 22, y + 4), color: ink.withOpacity(0.35), width: 0.8);
    pen.rect(Rect.fromLTWH(38, y - 5, 26, 4.5), over: 1, fill: Pb.surface, width: 1);
    final eraser = Rect.fromLTWH(w - 88, y - 10, 40, 9.5);
    pen.rect(eraser, over: 1.5, fill: Pb.surface, width: 1.1);
    pen.hatch(Path()..addRect(Rect.fromLTWH(eraser.left, eraser.top + 5, eraser.width, 4.5)), gap: 2.2, color: ink.withOpacity(0.5), width: 0.7);
  }

  @override
  bool shouldRepaint(covariant _BoardSketch old) => old.ink != ink || old.tray != tray;
}

/// "3 de făcut" written on the board, in a hand-drawn box.
class ChalkStat extends StatelessWidget {
  final String n;
  final String label;
  final Color color;
  const ChalkStat(this.n, this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return CustomPaint(
      painter: _ChalkBox(color),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 8),
        child: isMobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(n, style: chalk(28, color: color, height: 1.0)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: chalk(17, color: inkColor.withOpacity(0.7))),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(n, style: chalk(32, color: color, height: 1.0)),
                  const SizedBox(width: 8),
                  Text(label, style: chalk(21, color: inkColor.withOpacity(0.7))),
                ],
              ),
      ),
    );
  }
}

class _ChalkBox extends CustomPainter {
  final Color color;
  final Color? fill;
  final double opacity;
  _ChalkBox(this.color, {this.fill, this.opacity = 0.55});

  @override
  void paint(Canvas canvas, Size size) {
    // slightly wobbly, like it was drawn by hand
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(2, 3)
      ..quadraticBezierTo(w * 0.5, 0, w - 1, 2)
      ..quadraticBezierTo(w + 1, h * 0.5, w - 2, h - 1)
      ..quadraticBezierTo(w * 0.5, h + 1.5, 1, h - 2)
      ..quadraticBezierTo(-1, h * 0.5, 2, 3);
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChalkBox old) => old.color != color || old.fill != fill || old.opacity != opacity;
}

/// A button in a hand-drawn outline, or filled with ink for the main action.
class ChalkButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color? color;
  const ChalkButton({super.key, required this.text, this.icon, this.onTap, this.filled = false, this.color});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = color ?? inkColor;
    return Semantics(
      button: true,
      label: text,
      child: CkHover(
        onTap: onTap,
        builder: (h) {
          final fg = filled ? paperColor : c;
          return CustomPaint(
            painter: _ChalkBox(
              c,
              fill: filled ? c.withOpacity(enabled ? (h ? 1 : 0.88) : 0.4) : (h ? c.withOpacity(0.07) : null),
              opacity: filled ? 0 : 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 7)],
                  Flexible(
                    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- paper
/// The ruled lines and red margin of a school notebook, painted behind
/// [child]. [margin] is where the red line goes, from the left.
class NotebookPaper extends StatelessWidget {
  final Widget child;
  final double margin;
  final double radius;
  final Color? border;
  const NotebookPaper({super.key, required this.child, this.margin = 71, this.radius = 16, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? Pb.border.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.35 : 0.08), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: CustomPaint(painter: _Ruled(margin, AppColors.isDark), child: child),
    );
  }
}

class _Ruled extends CustomPainter {
  final double margin;
  final bool dark;
  _Ruled(this.margin, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = (dark ? const Color(0xFF7FA6D6) : const Color(0xFF8BB4E8)).withOpacity(dark ? 0.1 : 0.17)
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    if (margin > 0) {
      final red = Paint()
        ..color = const Color(0xFFE5484D).withOpacity(dark ? 0.35 : 0.45)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(margin, 0), Offset(margin, size.height), red);
    }
  }

  @override
  bool shouldRepaint(covariant _Ruled old) => old.margin != margin || old.dark != dark;
}

/// A sticky note with a strip of tape on top.
class StickyNote extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double angle; // in degrees
  const StickyNote({super.key, required this.child, this.color, this.angle = -1.2});

  static Color get yellow => AppColors.isDark ? const Color(0xFF4A4426) : const Color(0xFFFFF4B8);
  static Color get ink => AppColors.isDark ? const Color(0xFFF3EBC4) : const Color(0xFF3D3A2A);
  static Color get inkMuted => AppColors.isDark ? const Color(0xFFCFC69C) : const Color(0xFF6B6650);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: color ?? yellow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.4 : 0.12), blurRadius: 14, offset: const Offset(2, 8)),
              ],
            ),
            child: child,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: 2.5 * math.pi / 180,
                child: Container(
                  width: 84,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(AppColors.isDark ? 0.18 : 0.55),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The coloured spine of a ring binder, for class cards.
class BinderSpine extends StatelessWidget {
  final Color color;
  final double width;
  const BinderSpine({super.key, required this.color, this.width = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color.lerp(color, Colors.black, 0.15)!, color, Color.lerp(color, Colors.white, 0.1)!]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Pb.surface,
                border: Border.all(color: Colors.black.withOpacity(0.15)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small heading that stays readable over the meadow background.
Widget paperLabel(String text, {Color? dot, String? count, Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Flexible(
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Pb.surface.withOpacity(0.88),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Pb.border.withOpacity(0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 8)],
                Flexible(
                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text)),
                ),
                if (count != null) ...[const SizedBox(width: 6), Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.muted))],
              ],
            ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), const Spacer(), trailing],
        ],
      ),
    );
