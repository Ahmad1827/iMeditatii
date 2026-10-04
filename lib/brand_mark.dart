import 'package:flutter/material.dart';

// =============================================================================
// iMeditații logo (Clean style)
//
//   BrandMark      the icon alone: an open book with a spark above it,
//                  on a green → teal tile. Drawn with a painter, so it stays
//                  sharp at any size and needs no image asset.
//   BrandWordmark  the "iMeditații" text, with the "i" in the accent colour.
//   BrandLogo      icon + text together (navbar, login, signup, mobile menu).
//
// The same drawing is used for the favicon, the loading screen (index.html)
// and the PNG icons in web/.
// =============================================================================

class BrandMark extends StatelessWidget {
  final double size;

  /// Soft green glow under the tile (use on large sizes / hover).
  final bool glow;

  const BrandMark({super.key, this.size = 28, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandMarkPainter(glow: glow)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  final bool glow;

  const _BrandMarkPainter({required this.glow});

  static const Color _from = Color(0xFF22C55E);
  static const Color _to = Color(0xFF0F766E);
  static const Color _spark = Color(0xFFFDE68A);

  @override
  void paint(Canvas canvas, Size size) {
    // Everything below is drawn on a 64 × 64 grid.
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);

    const box = Rect.fromLTWH(0, 0, 64, 64);
    final tile = RRect.fromRectAndRadius(box, const Radius.circular(18));

    if (glow) {
      canvas.drawRRect(
        tile.shift(const Offset(0, 5)).deflate(4),
        Paint()
          ..color = const Color(0x7010B981)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_from, _to],
        ).createShader(box),
    );

    // Left page.
    final left = Path()
      ..moveTo(32, 31)
      ..cubicTo(27, 27, 20, 26, 13, 28)
      ..lineTo(13, 49)
      ..cubicTo(20, 47, 27, 48, 32, 52)
      ..close();
    canvas.drawPath(left, Paint()..color = Colors.white);

    // Right page, slightly see-through so the book has depth.
    final right = Path()
      ..moveTo(32, 31)
      ..cubicTo(37, 27, 44, 26, 51, 28)
      ..lineTo(51, 49)
      ..cubicTo(44, 47, 37, 48, 32, 52)
      ..close();
    canvas.drawPath(right, Paint()..color = Colors.white.withOpacity(0.78));

    // Spark.
    final spark = Path()
      ..moveTo(32, 9)
      ..quadraticBezierTo(33.3, 16.7, 41, 18)
      ..quadraticBezierTo(33.3, 19.3, 32, 27)
      ..quadraticBezierTo(30.7, 19.3, 23, 18)
      ..quadraticBezierTo(30.7, 16.7, 32, 9)
      ..close();
    canvas.drawPath(spark, Paint()..color = _spark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.glow != glow;
}

class BrandWordmark extends StatelessWidget {
  final double fontSize;

  /// Colour of "Meditații".
  final Color color;

  /// Colour of the leading "i".
  final Color accent;

  const BrandWordmark({
    super.key,
    required this.color,
    this.accent = const Color(0xFF16A34A),
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'i', style: TextStyle(color: accent)),
          const TextSpan(text: 'Meditații'),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.1),
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final Color color;
  final Color accent;
  final bool glow;

  const BrandLogo({
    super.key,
    required this.color,
    this.accent = const Color(0xFF16A34A),
    this.markSize = 30,
    this.fontSize = 17,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize, glow: glow),
        SizedBox(width: markSize * 0.32),
        BrandWordmark(color: color, accent: accent, fontSize: fontSize),
      ],
    );
  }
}