import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_colors.dart';
import 'ui_components.dart';

// ============================================================================
// AMBIENT — nori + păsări (light), licurici (dark). Doar decor.
// ============================================================================
class HomeAmbient extends StatefulWidget {
  const HomeAmbient({super.key});

  @override
  State<HomeAmbient> createState() => _HomeAmbientState();
}

class _HomeAmbientState extends State<HomeAmbient> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();
    return RepaintBoundary(
      child: CustomPaint(painter: _AmbientPainter(_time, AppColors.isDark), size: Size.infinite),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.time, this.dark) : super(repaint: time);

  final ValueListenable<double> time;
  final bool dark;

  // [x 0..1, y 0..1, viteză px/s, scară]
  static final List<List<double>> _clouds = () {
    final r = math.Random(11);
    return List.generate(6, (_) => [r.nextDouble(), 0.06 + r.nextDouble() * 0.30, 5 + r.nextDouble() * 9, 0.7 + r.nextDouble() * 0.7]);
  }();

  // [x 0..1, y 0..1, fază]
  static final List<List<double>> _flies = () {
    final r = math.Random(5);
    return List.generate(22, (_) => [r.nextDouble(), r.nextDouble(), r.nextDouble() * math.pi * 2]);
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (dark) {
      _paintFireflies(canvas, size, t);
    } else {
      _paintClouds(canvas, size, t);
      _paintBirds(canvas, size, t);
    }
  }

  void _paintClouds(Canvas canvas, Size size, double t) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final span = size.width + 500;
    for (final c in _clouds) {
      final x = (c[0] * span + t * c[2]) % span - 250;
      final y = c[1] * size.height;
      final s = c[3];
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 220 * s, height: 46 * s), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 50 * s, y + 6 * s), width: 140 * s, height: 36 * s), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 60 * s, y - 8 * s), width: 120 * s, height: 40 * s), paint);
    }
  }

  void _paintBirds(Canvas canvas, Size size, double t) {
    const cycle = 30.0;
    const fly = 16.0;
    final phase = t % cycle;
    if (phase > fly) return;
    final k = phase / fly;
    final paint = Paint()
      ..color = const Color(0xFF5B6B60).withOpacity(0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final baseX = -80 + k * (size.width + 160);
    final baseY = size.height * 0.2 - math.sin(k * math.pi) * 40;
    for (var i = 0; i < 3; i++) {
      final x = baseX - i * 28.0;
      final y = baseY + (i.isOdd ? 12.0 : -6.0) * i;
      final flap = math.sin(t * 7 + i) * 4;
      final path = Path()
        ..moveTo(x - 8, y - 2 + flap)
        ..quadraticBezierTo(x - 4, y - 4, x, y)
        ..quadraticBezierTo(x + 4, y - 4, x + 8, y - 2 + flap);
      canvas.drawPath(path, paint);
    }
  }

  void _paintFireflies(Canvas canvas, Size size, double t) {
    for (final f in _flies) {
      final x = f[0] * size.width + math.sin(t * 0.35 + f[2]) * 28;
      final y = size.height * (0.45 + f[1] * 0.5) + math.cos(t * 0.3 + f[2]) * 18;
      final a = 0.5 + 0.5 * math.sin(t * 1.6 + f[2] * 3);
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = const Color(0xFFFFE08A).withOpacity(0.18 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = const Color(0xFFFFE9A8).withOpacity(0.85 * a));
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) => old.dark != dark;
}

// ============================================================================
// MINI-JOC — baloane cu sume, doar în marginile libere ale ecranului
// ============================================================================
class BalloonGame extends StatefulWidget {
  /// Lățimea zonei de conținut din centru; baloanele apar doar în afara ei.
  final double contentWidth;
  const BalloonGame({super.key, required this.contentWidth});

  @override
  State<BalloonGame> createState() => _BalloonGameState();
}

class _Balloon {
  _Balloon(this.x, this.y, this.speed, this.value, this.color, this.phase);
  double x;
  double y;
  final double speed;
  final int value;
  final Color color;
  final double phase;
  static const double r = 22;
}

class _Pop {
  _Pop(this.x, this.y, this.color, this.born);
  final double x;
  final double y;
  final Color color;
  final double born;
}

class _BalloonGameState extends State<BalloonGame> with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFF8DB580),
    Color(0xFF8EC5E8),
    Color(0xFFF2A07B),
    Color(0xFFF4D06F),
    Color(0xFF6FB7A8),
  ];

  final _rnd = math.Random();
  final List<_Balloon> _balloons = [];
  final List<_Pop> _pops = [];
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker;

  double _now = 0;
  double _last = 0;
  double _nextSpawn = 0.8;
  Size _size = Size.zero;
  double _gutter = 0;

  int _target = 10;
  int _sum = 0;
  int _score = 0;
  String? _flash;
  bool _flashGood = false;
  bool _hidden = false;

  static const double _minGutter = 260;

  @override
  void initState() {
    super.initState();
    _newTarget();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _newTarget() => _target = 8 + _rnd.nextInt(13);

  Offset _pos(_Balloon b) => Offset(b.x + math.sin(_now * 1.3 + b.phase) * 8, b.y);

  void _tick(Duration e) {
    _now = e.inMicroseconds / 1e6;
    final dt = math.min(_now - _last, 0.05);
    _last = _now;
    if (_hidden || _gutter < _minGutter || _size == Size.zero) return;

    for (final b in _balloons) {
      b.y -= b.speed * dt;
    }
    _balloons.removeWhere((b) => b.y < -90);
    _pops.removeWhere((p) => _now - p.born > 0.5);

    if (_now >= _nextSpawn && _balloons.length < 7) {
      _spawn();
      _nextSpawn = _now + 1.2 + _rnd.nextDouble() * 1.2;
    }
    _frame.value++;
  }

  void _spawn() {
    final left = _rnd.nextBool();
    final lo = left ? 30.0 : _size.width - _gutter + 30;
    final hi = left ? _gutter - 30 : _size.width - 30;
    if (hi <= lo) return;
    _balloons.add(_Balloon(
      lo + _rnd.nextDouble() * (hi - lo),
      _size.height + 40,
      30 + _rnd.nextDouble() * 22,
      1 + _rnd.nextInt(9),
      _colors[_rnd.nextInt(_colors.length)],
      _rnd.nextDouble() * math.pi * 2,
    ));
  }

  _Balloon? _hit(Offset p) {
    for (final b in _balloons.reversed) {
      if ((_pos(b) - p).distance <= _Balloon.r + 4) return b;
    }
    return null;
  }

  void _onTap(TapDownDetails d) {
    final b = _hit(d.localPosition);
    if (b == null) return;
    final at = _pos(b);
    _balloons.remove(b);
    _pops.add(_Pop(at.dx, at.dy, b.color, _now));

    setState(() {
      _sum += b.value;
      if (_sum == _target) {
        _score++;
        _flash = 'Bravo! +1';
        _flashGood = true;
        _sum = 0;
        _newTarget();
        for (var i = 0; i < 3; i++) {
          _pops.add(_Pop(at.dx + (i - 1) * 24, at.dy - 14, _colors[i], _now));
        }
      } else if (_sum > _target) {
        _flash = 'Prea mult, încearcă din nou';
        _flashGood = false;
        _sum = 0;
      } else {
        _flash = null;
      }
    });

    final msg = _flash;
    if (msg != null) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && _flash == msg) setState(() => _flash = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      _gutter = (box.maxWidth - widget.contentWidth) / 2;
      if (_gutter < _minGutter) return const SizedBox.shrink();

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTapDown: _onTap,
              child: RepaintBoundary(child: CustomPaint(painter: _BalloonPainter(this, _frame))),
            ),
          ),
          Positioned(right: 16, bottom: 20, child: _hud(math.min(240.0, _gutter - 32))),
        ],
      );
    });
  }

  Widget _hud(double width) {
    BoxDecoration deco() => BoxDecoration(
          color: Pb.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Pb.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.08), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        );

    if (_hidden) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _hidden = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: deco(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bubble_chart_outlined, size: 18, color: Pb.link),
                const SizedBox(width: 6),
                Text('Baloane cu sume', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
              ],
            ),
          ),
        ),
      );
    }

    Widget pill(String label, String value, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
            child: Column(
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: Pb.muted)),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c)),
              ],
            ),
          ),
        );

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
      decoration: deco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Baloane cu sume', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ),
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 2),
              Text('$_score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text)),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: Pb.muted),
                tooltip: 'Ascunde jocul',
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                onPressed: () => setState(() {
                  _hidden = true;
                  _balloons.clear();
                  _pops.clear();
                }),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('Sparge baloane care adună exact ținta.',
                style: TextStyle(fontSize: 12, color: Pb.muted, height: 1.35)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                pill('Ținta', '$_target', Pb.link),
                const SizedBox(width: 8),
                pill('Suma ta', '$_sum', Pb.text),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _flash == null
                ? const SizedBox(key: ValueKey('none'), height: 0)
                : Padding(
                    key: ValueKey(_flash),
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _flash!,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _flashGood ? Pb.success : Pb.danger),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter(this.g, Listenable repaint) : super(repaint: repaint);

  final _BalloonGameState g;
  static final Map<int, TextPainter> _labels = {};

  TextPainter _label(int v) => _labels.putIfAbsent(v, () {
        return TextPainter(
          text: TextSpan(
            text: '$v',
            style: const TextStyle(color: Color(0xFF2F3B2F), fontSize: 17, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      });

  @override
  void paint(Canvas canvas, Size size) {
    if (g._hidden) return;
    final now = g._now;

    for (final p in g._pops) {
      final k = ((now - p.born) / 0.5).clamp(0.0, 1.0).toDouble();
      final paint = Paint()..color = p.color.withOpacity(1 - k);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawCircle(Offset(p.x + math.cos(a) * 30 * k, p.y + math.sin(a) * 30 * k), 3.5 * (1 - k) + 1, paint);
      }
    }

    final stringPaint = Paint()
      ..color = const Color(0x664A5A4A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final b in g._balloons) {
      final c = g._pos(b);
      const r = _Balloon.r;

      final string = Path()..moveTo(c.dx, c.dy + r * 1.15);
      string.quadraticBezierTo(c.dx + math.sin(now * 2 + b.phase) * 6, c.dy + r * 1.15 + 20, c.dx, c.dy + r * 1.15 + 40);
      canvas.drawPath(string, stringPaint);

      final rect = Rect.fromCenter(center: c, width: r * 2, height: r * 2.3);
      canvas.drawOval(
        rect.inflate(3),
        Paint()
          ..color = b.color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(rect, Paint()..color = b.color.withOpacity(0.92));
      canvas.drawCircle(Offset(c.dx, c.dy + r * 1.15), 2.5, Paint()..color = b.color);
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(-7, -10), width: 9, height: 13),
        Paint()..color = Colors.white.withOpacity(0.45),
      );

      final tp = _label(b.value);
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // Doar baloanele primesc click; restul trece la pagina de dedesubt.
  @override
  bool? hitTest(Offset position) => !g._hidden && g._hit(position) != null;

  @override
  bool shouldRepaint(covariant _BalloonPainter old) => false;
}
