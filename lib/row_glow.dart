// =============================================================================
// A PROBLEM ROW'S GLOW in the problem list
//   Solved: a band of green light sweeps slowly across the row.
//   Tried and not solved yet: an amber glow breathes in from the left edge.
//   One animation drives the whole list; each row starts at its own point of
//   it, so the rows don't pulse in step. Without motion (the app's motion
//   button, or the system asking for less), the row keeps a still tint.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum RowGlow { solved, tried }

class RowGlowPainter extends CustomPainter {
  final RowGlow kind;
  final Color color;
  final Animation<double>? clock; // null: still
  final double phase; // 0..1, where this row starts in the shared animation
  final bool dark;

  RowGlowPainter({required this.kind, required this.color, this.clock, this.phase = 0, this.dark = false}) : super(repaint: clock);

  @override
  bool shouldRepaint(RowGlowPainter o) => o.kind != kind || o.color != color || o.clock != clock || o.phase != phase || o.dark != dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final moving = clock != null;
    final v = moving ? (clock!.value + phase) % 1.0 : 0.0;

    // the still part: a light tint and a coloured edge
    canvas.drawRect(rect, Paint()..color = color.withOpacity(dark ? 0.07 : 0.05));
    canvas.drawRect(Rect.fromLTWH(0, 0, 3, size.height), Paint()..color = color.withOpacity(0.85));

    if (kind == RowGlow.solved) {
      if (!moving) return;
      // a soft band of light, crossing the row and leaving it before coming back
      final band = math.max(size.width * 0.3, 180.0);
      final x = -band + v * (size.width + band * 2);
      final r = Rect.fromLTWH(x - band / 2, 0, band, size.height);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity(0), color.withOpacity(dark ? 0.22 : 0.16), color.withOpacity(0)],
            stops: const [0, 0.5, 1],
          ).createShader(r),
      );
    } else {
      // breathing in from the left: stronger, then softer
      final breathe = moving ? 0.5 - 0.5 * math.cos(2 * math.pi * v) : 0.5;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity((dark ? 0.10 : 0.07) + 0.14 * breathe), color.withOpacity(0)],
            stops: [0, 0.35 + 0.25 * breathe],
          ).createShader(rect),
      );
    }
  }
}
