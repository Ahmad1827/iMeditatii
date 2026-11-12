import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A card as it is on its screen (same size, corners and content), its fill
/// turned to frosted glass like the home panes: see-through, the sky behind it
/// blurred, a light edge, the shadow only outside. Narrow screens (phones) get
/// a denser pane and no blur, which is the costly part while the sky moves.
/// [dense] is for cards read closely (code, long text over a busy sky).
class GlassBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool dense;

  const GlassBox({super.key, required this.child, this.radius = 16, this.padding, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final blur = MediaQuery.of(context).size.width >= 700;
    final r = BorderRadius.circular(radius);
    final alpha = !blur ? (dark ? 0.9 : 0.92) : (dense ? (dark ? 0.8 : 0.84) : (dark ? 0.62 : 0.68));
    final pane = DecoratedBox(
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF202225) : Colors.white).withOpacity(alpha),
        borderRadius: r,
        border: Border.all(color: Colors.white.withOpacity(dark ? 0.11 : 0.75)),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    return CustomPaint(
      painter: GlassShadow(radius, Colors.black.withOpacity(dark ? 0.45 : 0.16)),
      child: ClipRRect(
        borderRadius: r,
        child: blur ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: pane) : pane,
      ),
    );
  }
}

/// A soft shadow under a glass card, drawn only outside it: a see-through card
/// would otherwise show its own shadow through itself.
class GlassShadow extends CustomPainter {
  final double radius;
  final Color color;

  const GlassShadow(this.radius, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (color.alpha == 0) return;
    final rect = Offset.zero & size;
    final box = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(90))
      ..addRRect(box));
    canvas.drawRRect(
      box.shift(const Offset(0, 16)).deflate(14),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassShadow old) => old.color != color || old.radius != radius;
}
