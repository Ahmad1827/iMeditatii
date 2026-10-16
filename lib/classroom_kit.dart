import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'clean_kit.dart' show CkHover;
import 'ui_components.dart' show Pb;

// =============================================================================
// CLASSROOM — the pieces that make the classes pages look like a classroom:
//   Chalkboard    wooden frame, green board, chalk tray, today's date
//   ChalkStat     a number written in chalk, with a chalk box around it
//   ChalkButton   a button that sits on the board
//   NotebookPaper ruled lines and the red margin of a school notebook
//   StickyNote    a yellow note stuck on with a bit of tape
//   BinderSpine   the coloured spine of a ring binder
// =============================================================================

/// Off in widget tests, where Google Fonts can't be downloaded.
bool classroomHandFont = true;

/// Handwriting, for what is "written" on the board or on notes.
TextStyle chalk(double size, {Color color = const Color(0xF2FFFFFF), FontWeight weight = FontWeight.w700, double? height}) {
  final base = TextStyle(fontSize: size, color: color, fontWeight: weight, height: height);
  if (!classroomHandFont) return base.copyWith(fontFamily: 'Caveat'); // used if a test loads it
  return GoogleFonts.caveat(textStyle: base);
}

const Color chalkWhite = Color(0xF2FFFFFF);
const Color chalkYellow = Color(0xFFFFE89A);
const Color chalkPink = Color(0xFFFFB4C8);
const Color chalkBlue = Color(0xFFA9D8FF);
const Color chalkGreen = Color(0xFFB6F0C2);
const Color _board = Color(0xFF2E4A3A);
const Color _boardDeep = Color(0xFF243D30);
const Color _wood = Color(0xFF9A6A3F);
const Color _woodDark = Color(0xFF7A512D);

const _days = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
const _months = ['ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie', 'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'];

/// "Vineri, 16 octombrie", the way it's written in the corner of the board.
String boardDate([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${_days[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]}';
}

// ----------------------------------------------------------------- board
class Chalkboard extends StatelessWidget {
  final Widget child;
  final bool showDate;
  const Chalkboard({super.key, required this.child, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final frame = isMobile ? 8.0 : 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(frame),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_wood, _woodDark, _wood]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 26, offset: const Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CustomPaint(
              painter: _BoardTexture(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 18 : 30, isMobile ? 16 : 22, isMobile ? 18 : 30, isMobile ? 20 : 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDate)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(boardDate(), style: chalk(isMobile ? 17 : 21, color: chalkWhite.withOpacity(0.75), weight: FontWeight.w600)),
                      ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
        // the chalk tray under the board
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 40),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_wood, _woodDark]),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _stick(left: 30, color: chalkWhite, width: 34),
                _stick(left: 74, color: chalkYellow, width: 24),
                _stick(left: 106, color: chalkPink, width: 28),
                Positioned(
                  right: 26,
                  top: -9,
                  child: Container(
                    width: 52,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A6A7A),
                      borderRadius: BorderRadius.circular(3),
                      border: const Border(bottom: BorderSide(color: Color(0xFFDADADA), width: 5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stick({required double left, required Color color, required double width}) => Positioned(
        left: left,
        top: -5,
        child: Container(
          width: width,
          height: 7,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
      );
}

/// Green with a few faint, half-erased smudges, so it reads as a real board.
class _BoardTexture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(center: Alignment(-0.3, -0.5), radius: 1.4, colors: [_board, _boardDeep]).createShader(rect),
    );
    final rnd = math.Random(7);
    final smudge = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    for (var i = 0; i < 7; i++) {
      smudge.color = Colors.white.withOpacity(0.025 + rnd.nextDouble() * 0.03);
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawOval(Rect.fromCenter(center: c, width: 120 + rnd.nextDouble() * 220, height: 30 + rnd.nextDouble() * 50), smudge);
    }
    final wipe = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + rnd.nextDouble() * 0.6);
      final x = rnd.nextDouble() * size.width * 0.6;
      canvas.drawLine(Offset(x, y), Offset(x + 90 + rnd.nextDouble() * 160, y - 8 + rnd.nextDouble() * 16), wipe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: chalk(17, color: chalkWhite.withOpacity(0.85), weight: FontWeight.w600)),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(n, style: chalk(32, color: color, height: 1.0)),
                  const SizedBox(width: 8),
                  Text(label, style: chalk(21, color: chalkWhite.withOpacity(0.85), weight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _ChalkBox extends CustomPainter {
  final Color color;
  _ChalkBox(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    // slightly wobbly, like it was drawn by hand
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(2, 3)
      ..quadraticBezierTo(w * 0.5, 0, w - 1, 2)
      ..quadraticBezierTo(w + 1, h * 0.5, w - 2, h - 1)
      ..quadraticBezierTo(w * 0.5, h + 1.5, 1, h - 2)
      ..quadraticBezierTo(-1, h * 0.5, 2, 3);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _ChalkBox old) => old.color != color;
}

/// A button that lives on the board: white chalk outline, or filled with
/// chalk for the main action.
class ChalkButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color color;
  const ChalkButton({super.key, required this.text, this.icon, this.onTap, this.filled = false, this.color = chalkWhite});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: text,
      child: CkHover(
        onTap: onTap,
        builder: (h) {
          final fg = filled ? _board : color;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: filled ? color.withOpacity(enabled ? (h ? 1 : 0.92) : 0.5) : (h ? Colors.white.withOpacity(0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(filled ? 0 : 0.7), width: 1.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 7)],
                Flexible(
                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: fg)),
                ),
              ],
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
