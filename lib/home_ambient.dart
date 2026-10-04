import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'ui_components.dart';

// ============================================================================
// HomeSky — fundal + nori interactivi + păsări + armată care marșează
// + tab secret cu arc/praștie + buton care ascunde panourile.
// `blockers` = zonele cu conținut (carduri); acolo click-urile merg normal.
// ============================================================================
class HomeSky extends StatefulWidget {
  final Widget child;
  final List<GlobalKey> blockers;
  final bool cardsHidden;
  final VoidCallback? onToggleCards;

  const HomeSky({
    super.key,
    required this.child,
    this.blockers = const [],
    this.cardsHidden = false,
    this.onToggleCards,
  });

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

// ----------------------------------------------------------------- army
enum _Kind { banner, knight, foot }

class _Soldier {
  _Soldier(this.kind, this.dx, this.lane, this.seed, this.coat);
  final _Kind kind;
  final double dx; // distance behind the leader (to the right)
  final double lane; // small vertical offset, gives depth
  final double seed;
  final int coat; // horse coat colour
}

class _Army {
  _Army({required this.x, required this.cloth, required this.members, required this.length});
  double x; // x of the leader (leftmost)
  double t = 0;
  final int cloth;
  final List<_Soldier> members;
  final double length;
}

class _HomeSkyState extends State<HomeSky> with SingleTickerProviderStateMixin {
  static const double g = 900;

  // ---- army tuning
  static const double _armySpeed = 46; // px / second
  static const double _armyGroundFrac = 0.82; // where the feet walk (fraction of height)
  static const double _armyGap = 4; // seconds between armies
  static const List<int> _cloths = [0xFFA65A52, 0xFF5F7E99, 0xFFC2A25A, 0xFF76926E, 0xFF8A6A84];
  static const List<int> _coats = [0xFF8C7360, 0xFFB7A894, 0xFF5E5148, 0xFFCBBFA8, 0xFF7A6A58];

  final _rnd = math.Random();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker;
  final GlobalKey _tabKey = GlobalKey();
  final GlobalKey _btnKey = GlobalKey();

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

  _Army? _army;
  double _nextArmy = 2;
  double _armyRaise = 0; // 0..1, how far the arms are lifted to point
  bool _armyHint = false;

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

  // ------------------------------------------------------------------ army helpers
  double get _armyScale => (_size.height / 850).clamp(0.8, 1.3).toDouble();
  double _groundAt(double x) => _size.height * _armyGroundFrac + math.sin(x * 0.0045) * 6;
  Offset get _tabPoint => Offset(10, _size.height * 0.5 + 23);
  double get _pointStartX => math.min(_size.width * 0.55, 600.0);

  _Army _makeArmy() {
    final members = <_Soldier>[];
    var dx = 0.0;
    final riders = 2 + _rnd.nextInt(3); // 2..4
    for (var i = 0; i < riders; i++) {
      members.add(_Soldier(
        i == 0 ? _Kind.banner : _Kind.knight,
        dx,
        0,
        _rnd.nextDouble() * math.pi * 2,
        _coats[_rnd.nextInt(_coats.length)],
      ));
      dx += 74;
    }
    dx += 10;
    final foot = 4 + _rnd.nextInt(4); // 4..7
    for (var i = 0; i < foot; i++) {
      members.add(_Soldier(_Kind.foot, dx, i.isOdd ? 5 : 0, _rnd.nextDouble() * math.pi * 2, 0));
      dx += 30;
    }
    return _Army(
      x: _size.width + 60,
      cloth: _cloths[_rnd.nextInt(_cloths.length)],
      members: members,
      length: dx,
    );
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

    // ---- army: one at a time, next one comes _armyGap seconds after the last left
    if (!_reduce) {
      final a = _army;
      if (a == null) {
        if (_now >= _nextArmy) _army = _makeArmy();
      } else {
        a.x -= _armySpeed * dt;
        a.t += dt;
        if (a.x + a.length * _armyScale < -70) {
          _army = null;
          _nextArmy = _now + _armyGap;
        }
      }
    }
    final ar = _army;
    _armyRaise = ar == null ? 0.0 : ((_pointStartX - ar.x) / 70).clamp(0.0, 1.0).toDouble();
    final hint = ar != null && _armyRaise > 0.3 && ar.x > -40 && !_drawerOpen;
    if (hint != _armyHint) {
      _armyHint = hint;
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
    for (final k in [...widget.blockers, _tabKey, _btnKey]) {
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

  // buton: împinge panourile (exerciții + postări) în afara ecranului și înapoi
  Widget _cardsButton() {
    final hidden = widget.cardsHidden;
    return Positioned(
      top: 12,
      right: 16,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onToggleCards,
          child: Container(
            key: _btnKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Pb.surface.withOpacity(0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Pb.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16, color: Pb.muted),
                const SizedBox(width: 6),
                Text(
                  hidden ? 'Arată panourile' : 'Ascunde panourile',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secretTab() {
    final showHandle = _tabHover || _drawerOpen || _armyHint;

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
              _cardsButton(),
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

    final army = s._army;
    if (army != null) _paintArmy(canvas, s, army, dark);

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

// ============================================================================
// ARMY — medieval column (banner knight, knights on horses, spearmen).
// Everything is drawn facing +x in local coordinates; the painter mirrors it
// so the column marches to the left. Colours are blended toward a mist tone
// and the whole group is drawn translucent so it looks faded / painted-in.
// ============================================================================
class _Pal {
  _Pal(this.dark, this.clothV);
  final bool dark;
  final int clothV;

  Color f(int v, [double k = 0.30]) =>
      Color.lerp(Color(v), dark ? const Color(0xFF9AA8AE) : const Color(0xFFE0E7E8), k)!;

  late final Color steel = f(0xFF7C8A91);
  late final Color steelDark = f(0xFF55626A);
  late final Color cloth = f(clothV);
  late final Color wood = f(0xFF8A6D52);
  late final Color skin = f(0xFFD8B79B, 0.15);
  late final Color cream = f(0xFFE8DCC0, 0.10);
  late final Color hose = f(0xFF6B5E55);
}

Paint _pf(Color c) => Paint()..color = c;
Paint _ps(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

void _paintArmy(Canvas canvas, _HomeSkyState s, _Army a, bool dark) {
  final sc = s._armyScale;
  final size = s._size;
  final g = size.height * _HomeSkyState._armyGroundFrac;
  final left = a.x - 90 * sc;
  final right = a.x + a.length * sc + 90 * sc;
  final pal = _Pal(dark, a.cloth);
  final tab = s._tabPoint;
  final raise = s._armyRaise;

  canvas.saveLayer(
    Rect.fromLTRB(left, g - 150 * sc, right, g + 36 * sc),
    Paint()..color = Colors.white.withOpacity(dark ? 0.62 : 0.76),
  );

  for (var pass = 0; pass < 2; pass++) {
    for (final m in a.members.reversed) {
      if ((m.lane > 0 ? 1 : 0) != pass) continue;
      final wx = a.x + m.dx * sc;
      if (wx < -140 || wx > size.width + 140) continue;
      final wy = s._groundAt(wx) + m.lane * sc;
      final isFoot = m.kind == _Kind.foot;

      // ground shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(wx, wy + 1), width: (isFoot ? 22 : 62) * sc, height: 6 * sc),
        Paint()
          ..color = Colors.black.withOpacity(dark ? 0.22 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // angle from the shoulder to the secret tab (diagonal, up and to the left)
      final shoulder = isFoot ? 35.0 : 69.0;
      final dxw = tab.dx - wx;
      final dyw = tab.dy - (wy - shoulder * sc);
      final ang = math.atan2(dyw / sc, -dxw / sc).clamp(-0.95, -0.22).toDouble();

      canvas.save();
      canvas.translate(wx, wy);
      canvas.scale(-sc, sc); // mirror: marching left
      if (isFoot) {
        _drawFoot(canvas, pal, a.t * 8 + m.seed, raise, ang);
      } else {
        _drawRider(canvas, pal, m, a.t * 5.2 + m.seed, raise, ang, a.t);
      }
      canvas.restore();
    }
  }
  canvas.restore();

  // low mist around the feet
  canvas.drawOval(
    Rect.fromLTRB(left, g - 6 * sc, right, g + 24 * sc),
    Paint()
      ..color = (dark ? const Color(0xFF8FA0A8) : Colors.white).withOpacity(dark ? 0.16 : 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
  );
}

void _kite(Canvas c, _Pal p, double cx, double top, double w, double h) {
  final path = Path()
    ..moveTo(cx - w / 2, top)
    ..lineTo(cx + w / 2, top)
    ..lineTo(cx + w / 2, top + h * 0.45)
    ..quadraticBezierTo(cx + w / 2, top + h * 0.85, cx, top + h)
    ..quadraticBezierTo(cx - w / 2, top + h * 0.85, cx - w / 2, top + h * 0.45)
    ..close();
  c.drawPath(path, _pf(p.cream));
  c.save();
  c.clipPath(path);
  c.drawRect(Rect.fromLTWH(cx - w * 0.14, top, w * 0.28, h), _pf(p.cloth));
  c.restore();
  c.drawPath(path, _ps(p.steelDark, 1.1));
}

void _drawFoot(Canvas c, _Pal p, double ph, double raise, double ang) {
  final sw = math.sin(ph);
  final bob = -math.cos(ph * 2).abs() * 1.1;
  final fy = -bob; // keep the feet planted
  c.save();
  c.translate(0, bob);

  // far leg
  c.drawLine(const Offset(0, -16), Offset(-sw * 7, fy), _ps(Color.lerp(p.hose, Colors.black, 0.18)!, 4.0));

  // spear (held by the far hand)
  c.save();
  c.translate(7, -8);
  c.rotate(math.sin(ph * 0.5) * 0.02);
  c.drawLine(Offset.zero, const Offset(0, -66), _ps(p.wood, 1.8));
  final head = Path()
    ..moveTo(-1.8, -66)
    ..lineTo(0, -77)
    ..lineTo(1.8, -66)
    ..close();
  c.drawPath(head, _pf(p.steel));
  c.restore();

  // kite shield on the far arm
  _kite(c, p, 6, -37, 9, 20);

  // near leg
  c.drawLine(const Offset(0, -16), Offset(sw * 7, fy), _ps(p.hose, 4.2));

  // surcoat with a cross, belt and mail collar
  c.drawRRect(RRect.fromLTRBR(-5.8, -37, 5.8, -14, const Radius.circular(3)), _pf(p.cloth));
  final cross = _pf(p.cream.withOpacity(0.55));
  c.drawRect(Rect.fromLTWH(-1, -34, 2, 15), cross);
  c.drawRect(Rect.fromLTWH(-4, -31, 8, 2), cross);
  c.drawRect(Rect.fromLTWH(-6, -24, 12, 2), _pf(p.wood));
  c.drawOval(Rect.fromCenter(center: const Offset(0, -37), width: 12, height: 4.5), _pf(p.steel));

  // near arm: swings, then lifts to point at the tab
  const sh = Offset(1.5, -35);
  final swing = Offset(1.5 - sw * 4.5, -23);
  final dir = Offset(math.cos(ang), math.sin(ang));
  final hand = Offset.lerp(swing, sh + dir * 15, raise)!;
  c.drawLine(sh, hand, _ps(p.steel, 3.6));
  c.drawCircle(hand, 2.1, _pf(p.skin));
  if (raise > 0.6) c.drawLine(hand, hand + dir * 3.5, _ps(p.skin, 1.5));

  // head: coif, face, nasal helm
  c.drawCircle(const Offset(-0.5, -41.5), 5.4, _pf(p.steel));
  c.drawCircle(const Offset(2.3, -40.5), 3.0, _pf(p.skin));
  final helm = Path()
    ..moveTo(-5.6, -41.5)
    ..arcToPoint(const Offset(5.8, -41.5), radius: const Radius.circular(5.7), clockwise: true)
    ..close();
  c.drawPath(helm, _pf(p.steel));
  c.drawRect(Rect.fromLTWH(4.2, -43, 1.5, 6.5), _pf(p.steelDark));
  c.restore();
}

void _drawRider(Canvas c, _Pal p, _Soldier m, double ph, double raise, double ang, double t) {
  final coat = p.f(m.coat);
  final coatDark = Color.lerp(coat, Colors.black, 0.28)!;
  final coatFar = Color.lerp(coat, Colors.black, 0.18)!;
  final sw = math.sin(ph);
  final bob = math.sin(ph * 2) * 0.9;

  void leg(Offset hip, double phase, Color col) {
    final sp = math.sin(phase) * 11;
    final lift = math.max(0.0, math.cos(phase)) * 4;
    final knee = Offset(hip.dx + sp * 0.35, -13 - lift * 0.35);
    final hoof = Offset(hip.dx + sp, -lift);
    final path = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(hoof.dx, hoof.dy);
    c.drawPath(path, _ps(col, 3.4));
    c.drawCircle(hoof, 1.7, _pf(coatDark));
  }

  c.save();
  c.translate(0, bob);

  // far legs + tail
  leg(const Offset(14, -27), ph + math.pi, coatFar);
  leg(const Offset(-15, -27), ph, coatFar);
  final tail = Path()
    ..moveTo(-25, -42)
    ..quadraticBezierTo(-37, -38 + sw * 2, -34 + sw * 2, -17);
  c.drawPath(tail, _ps(coatDark, 3.4));

  // body
  c.drawOval(Rect.fromCenter(center: const Offset(0, -36), width: 56, height: 25), _pf(coat));

  // near legs
  leg(const Offset(14, -27), ph, coat);
  leg(const Offset(-15, -27), ph + math.pi, coat);

  // caparison (cloth over the horse)
  final cap = Path()
    ..moveTo(-21, -47)
    ..lineTo(15, -47)
    ..quadraticBezierTo(21, -46, 21.5, -38)
    ..lineTo(22, -15)
    ..lineTo(15, -18)
    ..lineTo(8, -14)
    ..lineTo(1, -18)
    ..lineTo(-6, -14)
    ..lineTo(-13, -18)
    ..lineTo(-20, -14)
    ..lineTo(-25, -17)
    ..lineTo(-26, -36)
    ..close();
  c.drawPath(cap, _pf(p.cloth));
  c.drawRect(Rect.fromLTWH(-25.5, -25, 47, 2.2), _pf(p.cream.withOpacity(0.6)));

  // saddle
  c.drawRRect(RRect.fromLTRBR(-6, -50, 6, -45, const Radius.circular(2)), _pf(p.wood));

  // neck, mane, head, ear, eye
  c.drawLine(const Offset(15, -43), const Offset(30, -62), _ps(coat, 11.5));
  c.drawLine(const Offset(12, -48), const Offset(26, -67), _ps(coatDark, 3.2));
  c.save();
  c.translate(32.5, -63 + sw * 0.8);
  c.rotate(0.95);
  c.drawOval(Rect.fromCenter(center: const Offset(5.5, 0), width: 18, height: 8.6), _pf(coat));
  c.drawOval(Rect.fromCenter(center: const Offset(11.5, 0.4), width: 6, height: 6), _pf(coatDark));
  c.drawCircle(const Offset(3.5, -1.6), 0.9, _pf(Colors.black.withOpacity(0.55)));
  c.restore();
  final ear = Path()
    ..moveTo(27, -67)
    ..lineTo(26, -74)
    ..lineTo(31, -69)
    ..close();
  c.drawPath(ear, _pf(coatDark));

  // ---- rider (seat at the saddle)
  c.save();
  c.translate(-1, -49);

  // banner or lance, held by the far hand
  final wave = math.sin(t * 3 + m.seed) * 2.2;
  if (m.kind == _Kind.banner) {
    c.drawLine(const Offset(9, 10), const Offset(9, -82), _ps(p.wood, 2.0));
    final flag = Path()
      ..moveTo(9, -80)
      ..quadraticBezierTo(22, -83 + wave, 36, -79 + wave * 1.4)
      ..lineTo(31, -72 + wave * 1.4)
      ..lineTo(36, -65 + wave * 1.4)
      ..quadraticBezierTo(22, -69 + wave, 9, -66)
      ..close();
    c.drawPath(flag, _pf(p.cloth));
    c.drawCircle(const Offset(9, -83), 1.7, _pf(p.steel));
  } else {
    c.save();
    c.rotate(0.06);
    c.drawLine(const Offset(9, 10), const Offset(9, -76), _ps(p.wood, 1.9));
    final lanceHead = Path()
      ..moveTo(7.4, -76)
      ..lineTo(9, -87)
      ..lineTo(10.6, -76)
      ..close();
    c.drawPath(lanceHead, _pf(p.steel));
    final pennon = Path()
      ..moveTo(9, -72)
      ..lineTo(21, -69 + wave)
      ..lineTo(9, -65)
      ..close();
    c.drawPath(pennon, _pf(p.cloth));
    c.restore();
  }

  // leg, stirrup, scabbard
  final legP = Path()
    ..moveTo(0, -1)
    ..lineTo(7, 9)
    ..lineTo(3, 20);
  c.drawPath(legP, _ps(p.hose, 4.4));
  c.drawRect(Rect.fromCenter(center: const Offset(4, 21), width: 6, height: 2.6), _pf(p.steelDark));
  c.drawLine(const Offset(-4, -5), const Offset(-15, 6), _ps(p.wood, 2.6));

  // shield, torso, belt, collar
  _kite(c, p, 8.5, -26, 10, 21);
  c.drawRRect(RRect.fromLTRBR(-6, -24, 6, 2, const Radius.circular(3.2)), _pf(p.cloth));
  final cross = _pf(p.cream.withOpacity(0.55));
  c.drawRect(Rect.fromLTWH(-1, -21, 2, 18), cross);
  c.drawRect(Rect.fromLTWH(-4.5, -16, 9, 2), cross);
  c.drawRect(Rect.fromLTWH(-6.2, -7, 12.4, 2), _pf(p.wood));
  c.drawOval(Rect.fromCenter(center: const Offset(0, -24), width: 12.5, height: 4.6), _pf(p.steel));

  // near arm: holds the reins, then lifts to point at the tab
  const sh = Offset(1.2, -21);
  const rein = Offset(8.5, -8);
  final dir = Offset(math.cos(ang), math.sin(ang));
  final hand = Offset.lerp(rein, sh + dir * 16, raise)!;
  if (raise < 0.95) {
    c.drawLine(rein, const Offset(37, -9), _ps(p.wood.withOpacity(1 - raise), 0.9));
  }
  c.drawLine(sh, hand, _ps(p.steel, 3.8));
  c.drawCircle(hand, 2.2, _pf(p.skin));
  if (raise > 0.6) c.drawLine(hand, hand + dir * 3.5, _ps(p.skin, 1.5));

  // great helm with a plume
  c.drawRRect(RRect.fromLTRBR(-4.6, -39, 4.8, -24.5, const Radius.circular(2)), _pf(p.steel));
  c.drawRect(Rect.fromLTWH(1.4, -39, 1.2, 14.5), _pf(p.steelDark));
  c.drawRect(Rect.fromLTWH(0.6, -34.2, 4.2, 1.3), _pf(p.steelDark));
  final plume = Path()
    ..moveTo(-1, -39)
    ..quadraticBezierTo(-9, -48 + sw * 1.2, -13, -37 + sw * 2)
    ..quadraticBezierTo(-7, -41, -1, -37)
    ..close();
  c.drawPath(plume, _pf(p.cloth));

  c.restore(); // rider
  c.restore(); // bob
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