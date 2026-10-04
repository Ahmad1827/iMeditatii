import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'app_colors.dart';
import 'design_system.dart';

// =============================================================================
// RetroLock — while the Retro style is selected, the app is blurred behind an
// "under construction" card. The bottom-left corner (where the DARK / STYLE
// buttons live) stays sharp and clickable, so pressing STYLE again switches
// back to Clean. The app underneath stays mounted, so no state is lost.
// =============================================================================
class RetroLock extends StatelessWidget {
  final bool locked;
  final Widget child;

  const RetroLock({super.key, required this.locked, required this.child});

  /// Area left uncovered for the style / theme buttons (bottom-left corner).
  static Rect holeFor(Size s) => Rect.fromLTWH(0, s.height - 96, math.min(290, s.width), 96);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: locked ? const _LockOverlay(key: ValueKey('lock')) : const SizedBox.shrink(key: ValueKey('free')),
          ),
        ),
      ],
    );
  }
}

class _LockOverlay extends StatefulWidget {
  const _LockOverlay({super.key});

  @override
  State<_LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<_LockOverlay> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _t.value = e.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) _ticker.muted = true;

    return _HoleHitTest(
      hole: RetroLock.holeFor,
      child: Stack(
        children: [
          // blur + tint everywhere except the corner with the buttons
          Positioned.fill(
            child: ClipPath(
              clipper: _HoleClipper(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: ColoredBox(color: (dark ? const Color(0xFF111214) : const Color(0xFFF2F4F6)).withOpacity(dark ? 0.55 : 0.5)),
              ),
            ),
          ),
          // pulsing outline around the corner + a pointer to it
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _HolePainter(_t)),
            ),
          ),
          // the card
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    decoration: BoxDecoration(
                      color: Pb.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Pb.border.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(dark ? 0.45 : 0.14), blurRadius: 40, offset: const Offset(0, 16)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 260,
                          height: 156,
                          child: CustomPaint(painter: _ConstructionPainter(_t, dark)),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.construction, size: 14, color: Color(0xFFD97706)),
                              SizedBox(width: 5),
                              Text('În construcție',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Stilul Retro nu e gata încă',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Îl refacem ca să arate la fel de bine ca restul site-ului. Până atunci, folosește stilul Clean.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        _BuildingBar(t: _t),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<double>(
                          valueListenable: _t,
                          builder: (_, t, child) => Transform.translate(
                            offset: Offset(-3 * math.sin(t * 4).abs(), 3 * math.sin(t * 4).abs()),
                            child: child,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.rotate(angle: math.pi * 0.75, child: Icon(Icons.arrow_upward, size: 18, color: Pb.primary)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Apasă din nou STYLE (stânga-jos) ca să revii la Clean.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ---------------------------------------------------------------- "building..." bar
class _BuildingBar extends StatelessWidget {
  final ValueNotifier<double> t;
  const _BuildingBar({required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            width: double.infinity,
            child: CustomPaint(painter: _StripesPainter(t)),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<double>(
          valueListenable: t,
          builder: (_, v, __) {
            const steps = ['Turnăm fundația', 'Ridicăm zidurile', 'Montăm pixelii', 'Vopsim totul în retro'];
            return Text(
              '${steps[(v / 2.2).floor() % steps.length]}…',
              style: TextStyle(fontSize: 12.5, color: Pb.muted),
            );
          },
        ),
      ],
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter(this.t) : super(repaint: t);
  final ValueNotifier<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF2A2A2A));
    final shift = (t.value * 26) % 16;
    final p = Paint()..color = const Color(0xFFF5B82E);
    for (var x = -16.0 - 16 + shift; x < size.width + 16; x += 16) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + 8, size.height)
        ..lineTo(x + 8 + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StripesPainter old) => false;
}

// ---------------------------------------------------------------- crane scene
class _ConstructionPainter extends CustomPainter {
  _ConstructionPainter(this.t, this.dark) : super(repaint: t);
  final ValueNotifier<double> t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final time = t.value;
    final ink = dark ? const Color(0xFFCBD2D9) : const Color(0xFF3A4048);
    const amber = Color(0xFFF59E0B);
    const orange = Color(0xFFEA7A2B);
    final ground = size.height - 22;

    final line = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ground + dust
    canvas.drawLine(Offset(4, ground), Offset(size.width - 4, ground), line..strokeWidth = 2.2);
    for (var i = 0; i < 5; i++) {
      final k = ((time * 0.6 + i / 5) % 1.0);
      canvas.drawCircle(
        Offset(150 + i * 14 + k * 20, ground - 4 - k * 14),
        2 + k * 4,
        Paint()..color = ink.withOpacity(0.18 * (1 - k)),
      );
    }

    // crane mast (lattice)
    const mastL = 44.0, mastR = 54.0, top = 20.0;
    canvas.drawLine(Offset(mastL, ground), const Offset(mastL, top), line..strokeWidth = 2);
    canvas.drawLine(Offset(mastR, ground), const Offset(mastR, top), line);
    for (var y = ground; y > top + 6; y -= 12) {
      canvas.drawLine(Offset(mastL, y), Offset(mastR, y - 12), line..strokeWidth = 1.2);
    }
    // jib + counter-jib + counterweight + cabin
    canvas.drawLine(const Offset(14, top), const Offset(232, top), line..strokeWidth = 3);
    canvas.drawLine(const Offset(49, top - 12), const Offset(232, top), line..strokeWidth = 1);
    canvas.drawLine(const Offset(49, top - 12), const Offset(14, top), line);
    canvas.drawRect(const Rect.fromLTWH(14, top, 20, 14), Paint()..color = ink.withOpacity(0.8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(54, top + 2, 16, 12), const Radius.circular(2)),
      Paint()..color = amber,
    );

    // trolley sliding on the jib
    final tx = 150 + math.sin(time * 0.7) * 50;
    canvas.drawRect(Rect.fromCenter(center: Offset(tx, top + 3), width: 12, height: 6), Paint()..color = ink);

    // swinging load
    final a = math.sin(time * 2.1) * 0.14;
    final len = 62 + math.sin(time * 0.9) * 14;
    final hook = Offset(tx + math.sin(a) * len, top + 6 + math.cos(a) * len);
    canvas.drawLine(Offset(tx, top + 6), hook, line..strokeWidth = 1.2);
    canvas.save();
    canvas.translate(hook.dx, hook.dy);
    canvas.rotate(a);
    final block = RRect.fromRectAndRadius(const Rect.fromLTWH(-22, 4, 44, 22), const Radius.circular(3));
    canvas.drawRRect(block, Paint()..color = amber);
    canvas.drawRRect(block, Paint()
      ..color = ink.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    final tp = TextPainter(
      text: const TextSpan(text: 'RETRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF2A2A2A), letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 15 - tp.height / 2));
    canvas.drawLine(const Offset(-6, 4), const Offset(0, -2), line..strokeWidth = 1);
    canvas.drawLine(const Offset(6, 4), const Offset(0, -2), line);
    canvas.restore();

    // barrier with stripes
    final barrier = Rect.fromLTWH(96, ground - 18, 70, 10);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(barrier, const Radius.circular(2)));
    canvas.drawRect(barrier, Paint()..color = Colors.white);
    for (var x = barrier.left - 10; x < barrier.right; x += 12) {
      final p = Path()
        ..moveTo(x, barrier.bottom)
        ..lineTo(x + 6, barrier.bottom)
        ..lineTo(x + 16, barrier.top)
        ..lineTo(x + 10, barrier.top)
        ..close();
      canvas.drawPath(p, Paint()..color = orange);
    }
    canvas.restore();
    canvas.drawLine(Offset(barrier.left + 6, barrier.bottom), Offset(barrier.left + 6, ground), line..strokeWidth = 2);
    canvas.drawLine(Offset(barrier.right - 6, barrier.bottom), Offset(barrier.right - 6, ground), line);
    // blinking light
    final blink = (time * 2).floor().isEven;
    canvas.drawCircle(Offset(barrier.left + 6, barrier.top - 4), 3.5, Paint()..color = blink ? amber : amber.withOpacity(0.25));
    if (blink) {
      canvas.drawCircle(
        Offset(barrier.left + 6, barrier.top - 4),
        9,
        Paint()
          ..color = amber.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // cones
    for (final x in const [196.0, 222.0]) {
      final cone = Path()
        ..moveTo(x - 8, ground)
        ..lineTo(x, ground - 20)
        ..lineTo(x + 8, ground)
        ..close();
      canvas.drawPath(cone, Paint()..color = orange);
      canvas.drawRect(Rect.fromLTWH(x - 5, ground - 11, 10, 3), Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstructionPainter old) => old.dark != dark;
}

// ---------------------------------------------------------------- the uncovered corner
class _HoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(RetroLock.holeFor(size), const Radius.circular(18)));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.t) : super(repaint: t);
  final ValueNotifier<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(t.value * 3);
    final r = RRect.fromRectAndRadius(RetroLock.holeFor(size).deflate(4), const Radius.circular(16));
    canvas.drawRRect(
      r,
      Paint()
        ..color = Pb.primary.withOpacity(0.35 + 0.45 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + pulse,
    );
    canvas.drawRRect(
      r.inflate(4 + 4 * pulse),
      Paint()
        ..color = Pb.primary.withOpacity(0.15 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) => false;
}

/// Lets pointer events through inside the hole, absorbs them everywhere else.
class _HoleHitTest extends SingleChildRenderObjectWidget {
  final Rect Function(Size) hole;
  const _HoleHitTest({required this.hole, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHoleHitTest(hole);

  @override
  void updateRenderObject(BuildContext context, _RenderHoleHitTest renderObject) => renderObject.hole = hole;
}

class _RenderHoleHitTest extends RenderProxyBox {
  _RenderHoleHitTest(this.hole);
  Rect Function(Size) hole;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (hole(size).contains(position)) return false; // fall through to the app below
    super.hitTest(result, position: position);
    result.add(BoxHitTestEntry(this, position)); // absorb everything else
    return true;
  }
}