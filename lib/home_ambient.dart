import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'ui_components.dart';

// ============================================================================
// HomeSky — fundal + nori interactivi + păsări + tab secret cu arc/praștie.
// `blockers` = zonele cu conținut (carduri); acolo click-urile merg normal.
// ============================================================================
class HomeSky extends StatefulWidget {
  final Widget child;
  final List<GlobalKey> blockers;

  const HomeSky({super.key, required this.child, this.blockers = const []});

  @override
  State<HomeSky> createState() => _HomeSkyState();
}

enum _Weapon { bow, sling }

class _Cloud {
  _Cloud({required this.x, required this.y, required this.scale, required this.speed});
  double x;
  double y;
  final double scale;
  final double speed;
  double vx = 0;
  double puff = 0;
  double rainUntil = 0;
  bool held = false;
  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: 250 * scale, height: 72 * scale);
}

class _Bird {
  _Bird({required this.x, required this.y, required this.vx, required this.phase});
  double x;
  double y;
  double vx;
  double vy = 0;
  final double phase;
  bool startled = false;
}

class _Drop {
  _Drop(this.x, this.y, this.born);
  double x;
  double y;
  final double born;
}

class _Feather {
  _Feather({required this.x, required this.y, required this.vx, required this.vy, required this.born});
  double x, y, vx, vy;
  double rot = 0;
  final double born;
}

class _Shot {
  _Shot(this.start, this.v0, this.born, this.flight, this.kind);
  final Offset start;
  final Offset v0;
  final double born;
  final double flight;
  final _Weapon kind;
  bool landed = false;
  double landedAt = 0;

  Offset pos(double t) =>
      Offset(start.dx + v0.dx * t, start.dy + v0.dy * t + 0.5 * _HomeSkyState.g * t * t);
  double angle(double t) => math.atan2(v0.dy + _HomeSkyState.g * t, v0.dx);
}

class _Spark {
  _Spark(this.at, this.color, this.born);
  final Offset at;
  final Color color;
  final double born;
}

class _Knight {
  double x = 0;
  double y = 0;
  int phase = 3; // 0 walk in, 1 point, 2 walk out, 3 idle
  double phaseT = 0;
  double walk = 0;
  double tip = 0;
  bool get active => phase != 3;
  bool get pointing => phase == 1;
  bool get facingLeft => phase == 0 || phase == 1;
}

class _HomeSkyState extends State<HomeSky> with SingleTickerProviderStateMixin {
  static const double g = 900;

  final _rnd = math.Random();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker;
  final GlobalKey _tabKey = GlobalKey();

  double _now = 0;
  double _last = 0;
  Size _size = Size.zero;
  bool _reduce = false;

  final List<_Cloud> _clouds = [];
  final List<_Bird> _birds = [];
  final List<_Drop> _drops = [];
  final List<_Feather> _feathers = [];
  final List<_Shot> _shots = [];
  final List<_Spark> _sparks = [];
  double _nextFlock = 4;

  final _Knight _knight = _Knight();
  double _nextKnight = 9; // first visit after 9 s (set to 1 to test)
  static const double _kTargetX = 64;
  static const double _kClimbStart = 460;
  bool _knightHint = false;

  double get _kBaseY => _size.height * 0.80;
  double get _kTabY => _size.height * 0.5 + 58;

  double _kYFor(double x) {
    if (x >= _kClimbStart) return _kBaseY;
    final k = ((_kClimbStart - x) / (_kClimbStart - _kTargetX)).clamp(0.0, 1.0).toDouble();
    final e = k * k * (3 - 2 * k);
    return _kBaseY + (_kTabY - _kBaseY) * e;
  }

  _Weapon? _weapon;
  bool _drawerOpen = false;
  bool _tabHover = false;
  int _hits = 0;
  Offset _aim = Offset.zero;
  bool _aimValid = false;

  _Cloud? _held;
  Offset _grabOffset = Offset.zero;
  Offset _downPos = Offset.zero;
  bool _moved = false;
  Offset _lastMovePos = Offset.zero;
  double _lastMoveTime = 0;
  double _throwVx = 0;
  bool _hoverThing = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape && _weapon != null) {
      setState(() => _weapon = null);
      return true;
    }
    return false;
  }

  Offset get _origin => Offset(_size.width - 70, _size.height - 64);

  double _flightFor(double dist) => _weapon == _Weapon.sling ? 0.22 + dist / 2600 : 0.35 + dist / 1800;

  Offset _v0For(Offset target, double flight) {
    final d = target - _origin;
    return Offset(d.dx / flight, (d.dy - 0.5 * g * flight * flight) / flight);
  }

  void _ensureClouds() {
    if (_clouds.isNotEmpty) return;
    for (var i = 0; i < 6; i++) {
      _clouds.add(_Cloud(
        x: _rnd.nextDouble() * _size.width,
        y: _size.height * (0.06 + _rnd.nextDouble() * 0.30),
        scale: 0.7 + _rnd.nextDouble() * 0.7,
        speed: 6 + _rnd.nextDouble() * 8,
      ));
    }
  }

  // ------------------------------------------------------------------ loop
  void _tick(Duration e) {
    _now = e.inMicroseconds / 1e6;
    final dt = math.min(_now - _last, 0.05);
    _last = _now;
    if (_size == Size.zero) return;
    _ensureClouds();

    final drift = _reduce ? 0.0 : 1.0;
    final decay = math.pow(0.15, dt).toDouble();

    for (final c in _clouds) {
      c.puff = math.max(0.0, c.puff - dt * 2.5);
      if (_now < c.rainUntil && _drops.length < 400) {
        for (var i = 0; i < 2; i++) {
          _drops.add(_Drop(c.x + (_rnd.nextDouble() - 0.5) * 170 * c.scale, c.y + 20 * c.scale, _now));
        }
      }
      if (c.held) continue;
      c.x += (c.speed * drift + c.vx) * dt;
      c.vx *= decay;
      final half = 125 * c.scale;
      if (c.x - half > _size.width + 40) c.x = -half - 30;
      if (c.x + half < -60) c.x = _size.width + half + 30;
    }

    for (final d in _drops) {
      d.y += 460 * dt;
      d.x -= 20 * dt;
    }
    _drops.removeWhere((d) => _now - d.born > 1.3 || d.y > _size.height);

    if (!_reduce && _now >= _nextFlock) {
      final y0 = _size.height * (0.10 + _rnd.nextDouble() * 0.18);
      final speed = 70 + _rnd.nextDouble() * 20;
      for (var i = 0; i < 3; i++) {
        _birds.add(_Bird(
          x: -40.0 - i * 30,
          y: y0 + (i.isOdd ? 14.0 : -6.0) * i,
          vx: speed,
          phase: _rnd.nextDouble() * math.pi * 2,
        ));
      }
      _nextFlock = _now + 22 + _rnd.nextDouble() * 8;
    }
    for (final b in _birds) {
      b.x += b.vx * dt;
      b.y += b.vy * dt + math.sin(_now * 1.5 + b.phase) * 6 * dt;
    }
    _birds.removeWhere((b) => b.x > _size.width + 60 || b.y < -60);

    for (final f in _feathers) {
      f.x += f.vx * dt;
      f.y += f.vy * dt;
      f.vy += 30 * dt;
      f.rot += dt * 3;
    }
    _feathers.removeWhere((f) => _now - f.born > 1.8);

    for (final s in _shots) {
      if (!s.landed && _now - s.born >= s.flight) {
        s.landed = true;
        s.landedAt = _now;
        _impact(s.pos(s.flight));
      }
    }
    _shots.removeWhere((s) => s.landed && _now - s.landedAt > (s.kind == _Weapon.bow ? 2.5 : 0.0));
    _sparks.removeWhere((sp) => _now - sp.born > 0.5);

    final kn = _knight;
    if (!_reduce) {
      if (!kn.active) {
        if (_now >= _nextKnight && !_drawerOpen && _weapon == null) {
          kn.phase = 0;
          kn.phaseT = 0;
          kn.x = _size.width + 40;
          kn.y = _kYFor(kn.x);
        }
      } else {
        kn.phaseT += dt;
        kn.walk += dt * 6.5;
        kn.tip = math.max(0.0, kn.tip - dt * 1.6);
        if (kn.phase == 0) {
          kn.x -= 58 * dt;
          kn.y = _kYFor(kn.x);
          if (kn.x <= _kTargetX) {
            kn.x = _kTargetX;
            kn.y = _kYFor(kn.x);
            kn.phase = 1;
            kn.phaseT = 0;
          }
        } else if (kn.phase == 1) {
          if (kn.phaseT > 4.8 || _drawerOpen) {
            kn.phase = 2;
            kn.phaseT = 0;
          }
        } else if (kn.phase == 2) {
          kn.x += 58 * dt;
          kn.y = _kYFor(kn.x);
          if (kn.x > _size.width + 60) {
            kn.phase = 3;
            _nextKnight = _now + 60 + _rnd.nextDouble() * 30;
          }
        }
      }
    }
    final hint = kn.pointing && !_drawerOpen;
    if (hint != _knightHint) {
      _knightHint = hint;
      if (mounted) setState(() {});
    }

    _frame.value++;
  }

  void _startle(_Bird b) {
    b.startled = true;
    b.vx *= 2.2;
    b.vy = -160;
    for (var i = 0; i < 6; i++) {
      _feathers.add(_Feather(
        x: b.x,
        y: b.y,
        vx: (_rnd.nextDouble() - 0.5) * 60,
        vy: -20 + _rnd.nextDouble() * 30,
        born: _now,
      ));
    }
  }

  void _impact(Offset p) {
    var hit = false;
    for (final c in _clouds) {
      if (c.rect.inflate(6).contains(p)) {
        c.puff = 1;
        c.rainUntil = _now + 2.5;
        hit = true;
        break;
      }
    }
    for (final b in _birds) {
      if (!b.startled && (Offset(b.x, b.y) - p).distance < 26) {
        _startle(b);
        hit = true;
      }
    }
    _sparks.add(_Spark(p, hit ? const Color(0xFFF4D06F) : const Color(0xFF9A8F7A), _now));
    if (hit && mounted) setState(() => _hits++);
  }

  // ------------------------------------------------------------------ input
  _Cloud? _cloudAt(Offset p) {
    for (final c in _clouds.reversed) {
      if (c.rect.contains(p)) return c;
    }
    return null;
  }

  _Bird? _birdAt(Offset p) {
    for (final b in _birds) {
      if ((Offset(b.x, b.y) - p).distance < 24) return b;
    }
    return null;
  }

  bool _blocked(Offset global) {
    for (final k in [...widget.blockers, _tabKey]) {
      final ro = k.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize) {
        final r = ro.localToGlobal(Offset.zero) & ro.size;
        if (r.contains(global)) return true;
      }
    }
    return false;
  }

  void _shoot(Offset target) {
    if (_shots.length > 30) return;
    final flight = _flightFor((target - _origin).distance);
    _shots.add(_Shot(_origin, _v0For(target, flight), _now, flight, _weapon!));
  }

  void _onDown(PointerDownEvent e) {
    if (_blocked(e.position)) return;
    final p = e.localPosition;
    if (_weapon != null) {
      _shoot(p);
      return;
    }
    if (_knight.active &&
        Rect.fromCenter(center: Offset(_knight.x, _knight.y - 24), width: 40, height: 60).contains(p)) {
      _knight.tip = 1;
      return;
    }
    final b = _birdAt(p);
    if (b != null && !b.startled) {
      _startle(b);
      return;
    }
    final c = _cloudAt(p);
    if (c != null) {
      _held = c;
      c.held = true;
      _grabOffset = Offset(c.x, c.y) - p;
      _downPos = p;
      _moved = false;
      _lastMovePos = p;
      _lastMoveTime = e.timeStamp.inMicroseconds / 1e6;
      _throwVx = 0;
      setState(() {});
    }
  }

  void _onMove(PointerMoveEvent e) {
    final c = _held;
    if (c == null || e.kind == PointerDeviceKind.touch) return;
    final p = e.localPosition;
    if ((p - _downPos).distance > 6) _moved = true;
    final t = e.timeStamp.inMicroseconds / 1e6;
    final dtm = math.max(t - _lastMoveTime, 0.008);
    _throwVx = (p.dx - _lastMovePos.dx) / dtm;
    _lastMovePos = p;
    _lastMoveTime = t;
    final np = p + _grabOffset;
    c.x = np.dx;
    c.y = np.dy.clamp(30.0, _size.height * 0.6).toDouble();
  }

  void _release() {
    final c = _held;
    if (c == null) return;
    c.held = false;
    _held = null;
    if (!_moved) {
      c.puff = 1;
      c.rainUntil = _now + 2.5;
    } else {
      c.vx = _throwVx.clamp(-500.0, 500.0).toDouble();
    }
    setState(() {});
  }

  void _onHover(PointerHoverEvent e) {
    _aim = e.localPosition;
    final blocked = _blocked(e.position);
    _aimValid = !blocked;
    final over = !blocked && (_cloudAt(_aim) != null || _birdAt(_aim) != null);
    if (over != _hoverThing) setState(() => _hoverThing = over);
  }

  // ------------------------------------------------------------------ UI
  Widget _background() => Image.asset(
        'assets/images/background.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) {
            debugPrint('iMeditatii: nu găsesc assets/images/background.png sau .jpg (verifică pubspec.yaml)');
            return const SizedBox.shrink();
          },
        ),
      );

  Widget _secretTab() {
    final showHandle = _tabHover || _drawerOpen || _knightHint;

    final handle = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _tabHover = true),
      onExit: (_) => setState(() => _tabHover = false),
      child: GestureDetector(
        onTap: () => setState(() {
          _drawerOpen = !_drawerOpen;
          if (!_drawerOpen) _weapon = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: showHandle ? 24 : 7,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Pb.text.withOpacity(showHandle ? 0.75 : 0.09),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
          ),
          child: showHandle
              ? Icon(_drawerOpen ? Icons.chevron_left : Icons.chevron_right, size: 16, color: Pb.surface)
              : null,
        ),
      ),
    );

    Widget btn(_Weapon w, String label) {
      final sel = _weapon == w;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _weapon = sel ? null : w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: sel ? Pb.primary.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? Pb.primary : Pb.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 30, height: 30, child: CustomPaint(painter: _IconPainter(w, sel ? Pb.primary : Pb.text))),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: sel ? Pb.link : Pb.text)),
              ],
            ),
          ),
        ),
      );
    }

    final drawer = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Pb.surface.withOpacity(0.96),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        border: Border.all(color: Pb.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(_Weapon.bow, 'Arc'),
          const SizedBox(height: 6),
          btn(_Weapon.sling, 'Praștie'),
          const SizedBox(height: 8),
          Text('Ținte: $_hits', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Pb.text)),
          const SizedBox(height: 2),
          Text('Esc = stop', style: TextStyle(fontSize: 10.5, color: Pb.muted)),
        ],
      ),
    );

    return Positioned(
      left: 0,
      top: _size.height * 0.5,
      child: Container(
        key: _tabKey,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [if (_drawerOpen) drawer, handle],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _reduce = MediaQuery.of(context).disableAnimations;
    final dark = AppColors.isDark;

    final MouseCursor cursor = _weapon != null
        ? SystemMouseCursors.precise
        : (_held != null ? SystemMouseCursors.grabbing : (_hoverThing ? SystemMouseCursors.grab : MouseCursor.defer));

    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return MouseRegion(
        cursor: cursor,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          onPointerHover: _onHover,
          child: Stack(
            children: [
              Positioned.fill(child: _background()),
              if (dark) Positioned.fill(child: ColoredBox(color: Pb.page.withOpacity(0.62))),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: CustomPaint(painter: _SkyPainter(this, _frame, dark))),
                ),
              ),
              Positioned.fill(child: widget.child),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: CustomPaint(painter: _WeaponPainter(this, _frame))),
                ),
              ),
              _secretTab(),
            ],
          ),
        ),
      );
    });
  }
}

// ============================================================================
// PAINTERS
// ============================================================================
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.s, Listenable repaint, this.dark) : super(repaint: repaint);
  final _HomeSkyState s;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final now = s._now;

    if (s._knight.active) _paintKnight(canvas, s._knight, dark);

    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(dark ? 0.12 : 0.62)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final rainBelly = Paint()
      ..color = const Color(0xFF9FB4C4).withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    for (final c in s._clouds) {
      final sc = c.scale * (1 + 0.15 * math.sin(c.puff * math.pi));
      final x = c.x;
      final y = c.y;
      if (now < c.rainUntil) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 6 * sc), width: 210 * sc, height: 44 * sc), rainBelly);
      }
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 220 * sc, height: 50 * sc), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 55 * sc, y + 6 * sc), width: 140 * sc, height: 40 * sc), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 60 * sc, y - 10 * sc), width: 130 * sc, height: 46 * sc), cloudPaint);
    }

    final rain = Paint()
      ..color = const Color(0xFF7FB2D9).withOpacity(dark ? 0.5 : 0.75)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final d in s._drops) {
      canvas.drawLine(Offset(d.x, d.y), Offset(d.x + 2, d.y - 8), rain);
    }

    final bird = Paint()
      ..color = (dark ? const Color(0xFFB8C4BA) : const Color(0xFF5B6B60)).withOpacity(0.65)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final b in s._birds) {
      final flap = math.sin(now * (b.startled ? 16 : 7) + b.phase) * 4.5;
      final path = Path()
        ..moveTo(b.x - 8, b.y - 2 + flap)
        ..quadraticBezierTo(b.x - 4, b.y - 4, b.x, b.y)
        ..quadraticBezierTo(b.x + 4, b.y - 4, b.x + 8, b.y - 2 + flap);
      canvas.drawPath(path, bird);
    }

    for (final f in s._feathers) {
      final k = ((now - f.born) / 1.8).clamp(0.0, 1.0).toDouble();
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.rotate(f.rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 2.6),
        Paint()..color = const Color(0xFF8A8F86).withOpacity(1 - k),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.dark != dark;
}

class _WeaponPainter extends CustomPainter {
  _WeaponPainter(this.s, Listenable repaint) : super(repaint: repaint);
  final _HomeSkyState s;

  @override
  void paint(Canvas canvas, Size size) {
    final now = s._now;

    for (final sp in s._sparks) {
      final k = ((now - sp.born) / 0.5).clamp(0.0, 1.0).toDouble();
      final paint = Paint()..color = sp.color.withOpacity(1 - k);
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        canvas.drawCircle(sp.at + Offset(math.cos(a), math.sin(a)) * 18 * k, 2.5 * (1 - k) + 0.6, paint);
      }
    }

    for (final shot in s._shots) {
      if (shot.kind == _Weapon.bow) {
        final t = shot.landed ? shot.flight : now - shot.born;
        final fade = shot.landed ? (1 - (now - shot.landedAt) / 2.5).clamp(0.0, 1.0).toDouble() : 1.0;
        canvas.save();
        canvas.translate(shot.pos(t).dx, shot.pos(t).dy);
        canvas.rotate(shot.angle(t));
        _drawArrow(canvas, 30, fade);
        canvas.restore();
      } else if (!shot.landed) {
        canvas.drawCircle(shot.pos(now - shot.born), 4, Paint()..color = const Color(0xFF6B6255));
      }
    }

    final w = s._weapon;
    if (w == null) return;
    final o = s._origin;

    if (s._aimValid) {
      final flight = s._flightFor((s._aim - o).distance);
      final v0 = s._v0For(s._aim, flight);
      final dot = Paint()..color = Pb.text.withOpacity(0.25);
      for (var i = 1; i <= 12; i++) {
        final t = flight * i / 12;
        canvas.drawCircle(Offset(o.dx + v0.dx * t, o.dy + v0.dy * t + 0.5 * _HomeSkyState.g * t * t), 1.6, dot);
      }
    }

    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(math.atan2(s._aim.dy - o.dy, s._aim.dx - o.dx));
    canvas.scale(1.4);
    if (w == _Weapon.bow) {
      _drawBow(canvas, Pb.text);
    } else {
      _drawSling(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeaponPainter old) => false;
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.kind, this.color);
  final _Weapon kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 4);
    canvas.scale(0.5);
    if (kind == _Weapon.bow) {
      _drawBow(canvas, color);
    } else {
      _drawSling(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.kind != kind || old.color != color;
}

void _paintKnight(Canvas canvas, _Knight k, bool dark) {
  final a = dark ? 0.78 : 0.9;
  final armor = (dark ? const Color(0xFF8FA0A8) : const Color(0xFF6F8088)).withOpacity(a);
  final tunic = (dark ? const Color(0xFF7FA088) : const Color(0xFF6E9577)).withOpacity(a);
  final plume = const Color(0xFFB5645A).withOpacity(a);
  final wood = const Color(0xFF8B6B4A).withOpacity(a);
  final skin = const Color(0xFFD9B79A).withOpacity(a);

  canvas.drawOval(
    Rect.fromCenter(center: Offset(k.x, k.y + 1), width: 30, height: 7),
    Paint()
      ..color = Colors.black.withOpacity(dark ? 0.25 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );

  canvas.save();
  canvas.translate(k.x, k.y);
  if (k.facingLeft) canvas.scale(-1, 1);
  final walking = !k.pointing;
  final sw = walking ? math.sin(k.walk) : 0.0;
  canvas.translate(0, walking ? math.cos(k.walk * 2).abs() * -1.2 : 0.0);

  final limb = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 4.2
    ..style = PaintingStyle.stroke;

  limb.color = armor.withOpacity(a * 0.75);
  canvas.drawLine(const Offset(0, -15), Offset(-sw * 6, 0), limb);
  limb.color = armor;
  canvas.drawLine(const Offset(0, -15), Offset(sw * 6, 0), limb);

  final shield = Path()
    ..moveTo(-9, -33)
    ..lineTo(-2, -33)
    ..lineTo(-2, -22)
    ..quadraticBezierTo(-5.5, -18, -9, -22)
    ..close();
  canvas.drawPath(shield, Paint()..color = plume.withOpacity(a * 0.9));

  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -35, 10, 21), const Radius.circular(4)),
    Paint()..color = tunic,
  );
  canvas.drawRect(const Rect.fromLTWH(-5, -22, 10, 2), Paint()..color = wood);

  final arm = Paint()
    ..color = armor
    ..strokeWidth = 3.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  if (k.pointing) {
    final ang = -0.32 + math.sin(k.phaseT * 3.2) * 0.06;
    final tip = Offset(4 + math.cos(ang) * 17, -31 + math.sin(ang) * 17);
    canvas.drawLine(const Offset(3, -31), tip, arm);
    canvas.drawCircle(tip, 2.2, Paint()..color = skin);
  } else {
    canvas.drawLine(const Offset(3, -31), Offset(3 - sw * 5, -22), arm);
  }

  // head: lifts a bit when tipped
  final lift = k.tip > 0 ? -3.5 * math.sin(k.tip * math.pi) : 0.0;
  canvas.save();
  canvas.translate(0, lift);
  canvas.drawCircle(const Offset(0, -41), 6.2, Paint()..color = armor);
  canvas.drawRect(const Rect.fromLTWH(0.5, -42.2, 5.5, 1.6), Paint()..color = const Color(0xFF2E3A40).withOpacity(a));
  final plumePath = Path()
    ..moveTo(-1, -47)
    ..quadraticBezierTo(-8, -53 + (walking ? sw * 1.5 : 0), -10, -45)
    ..quadraticBezierTo(-6, -47, -1, -45)
    ..close();
  canvas.drawPath(plumePath, Paint()..color = plume);
  canvas.restore();

  canvas.restore();
}

// săgeată orientată spre +x, cu vârful în origine
void _drawArrow(Canvas c, double len, double opacity) {
  final shaft = Paint()
    ..color = const Color(0xFF6E5A45).withOpacity(opacity)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(-len, 0), Offset.zero, shaft);
  final head = Path()
    ..moveTo(0, 0)
    ..lineTo(-8, -4)
    ..lineTo(-8, 4)
    ..close();
  c.drawPath(head, Paint()..color = const Color(0xFF4A4A4A).withOpacity(opacity));
  final fletch = Paint()
    ..color = const Color(0xFFC0564B).withOpacity(opacity)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(-len, 0), Offset(-len - 5, -4), fletch);
  c.drawLine(Offset(-len, 0), Offset(-len - 5, 4), fletch);
  c.drawLine(Offset(-len + 4, 0), Offset(-len - 1, -4), fletch);
  c.drawLine(Offset(-len + 4, 0), Offset(-len - 1, 4), fletch);
}

void _drawBow(Canvas c, Color stringColor) {
  final wood = Paint()
    ..color = const Color(0xFF8B5E3C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round;
  final string = Paint()
    ..color = stringColor.withOpacity(0.7)
    ..strokeWidth = 1.1;
  final bow = Path()
    ..moveTo(-4, -26)
    ..quadraticBezierTo(18, 0, -4, 26);
  c.drawPath(bow, wood);
  c.drawLine(const Offset(-4, -26), const Offset(-12, 0), string);
  c.drawLine(const Offset(-12, 0), const Offset(-4, 26), string);
  c.save();
  c.translate(26, 0);
  _drawArrow(c, 38, 1);
  c.restore();
}

void _drawSling(Canvas c) {
  final wood = Paint()
    ..color = const Color(0xFF8B5E3C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(-24, 0), Offset.zero, wood);
  c.drawLine(Offset.zero, const Offset(12, -11), wood);
  c.drawLine(Offset.zero, const Offset(12, 11), wood);
  final band = Paint()
    ..color = const Color(0xFFB04A3A)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;
  final p = Path()
    ..moveTo(12, -11)
    ..lineTo(-6, 0)
    ..lineTo(12, 11);
  c.drawPath(p, band);
  c.drawCircle(const Offset(-6, 0), 3.5, Paint()..color = const Color(0xFF6B6255));
}
