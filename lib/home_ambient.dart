import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'ui_components.dart';

// ============================================================================
// HomeSky — fundal + nori interactivi + armate care marșează
// + tab secret cu arc/praștie + buton care ascunde TOT conținutul paginii.
//
// scene: HomeScene.meadow  -> păsări (pagina principală, lecții)
//        HomeScene.fantasy -> dragoni + licurici (probleme, autentificare)
//
// `blockers`    = zonele cu conținut (carduri); acolo click-urile merg normal.
// `cardsHidden` = true -> tot conținutul (child) coboară și dispare,
//                 ca să se vadă scena (dragoni, armate).
// `cheerSignal` = schimbă valoarea ca armata să strige și dragonii să scuipe foc.
// ============================================================================
enum HomeScene { meadow, fantasy }

class HomeSky extends StatefulWidget {
  final Widget child;
  final List<GlobalKey> blockers;
  final bool cardsHidden;
  final VoidCallback? onToggleCards;
  final bool armies;
  final String hideLabel;
  final String showLabel;
  final HomeScene scene;
  final int cheerSignal;

  const HomeSky({
    super.key,
    required this.child,
    this.blockers = const [],
    this.cardsHidden = false,
    this.onToggleCards,
    this.armies = true,
    this.hideLabel = 'Ascunde panourile',
    this.showLabel = 'Arată panourile',
    this.scene = HomeScene.meadow,
    this.cheerSignal = 0,
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

class _Dragon {
  _Dragon({
    required this.x,
    required this.y,
    required this.vx,
    required this.scale,
    required this.phase,
    required this.color,
    required this.nextBreath,
  });
  double x;
  double y;
  double vx;
  double vy = 0;
  final double scale;
  final double phase;
  final int color;
  double fire = 0;
  double nextBreath;
  bool fleeing = false;
}

class _Mote {
  _Mote(this.x, this.y, this.phase, this.warm);
  double x;
  double y;
  final double phase;
  final bool warm;
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

// ----------------------------------------------------------------- armies
enum _Faction { crusader, viking, saracen, mongol }

enum _Wpn { sword, saber, axe, spear, lance }

enum _Kind { rider, foot }

class _Soldier {
  _Soldier(this.kind, this.wpn, this.dx, this.lane, this.seed, this.coat, {this.banner = false});
  final _Kind kind;
  final _Wpn wpn;
  final double dx;
  final double lane;
  final double seed;
  final int coat;
  final bool banner;

  double walk = 0;
  double lag = 0;
  double downFor = 0;
  double downLeft = 0;
  double react = 0;
  double guard = 0;
}

class _Army {
  _Army({
    required this.x,
    required this.faction,
    required this.cloth,
    required this.trim,
    required this.members,
    required this.length,
  });
  double x;
  double t = 0;
  double cheer = 0;
  final _Faction faction;
  final int cloth;
  final int trim;
  final List<_Soldier> members;
  final double length;
}

class _HomeSkyState extends State<HomeSky> with SingleTickerProviderStateMixin {
  static const double g = 900;

  static const double _armySpeed = 50;
  static const double _armyGroundFrac = 0.82;
  static const double _armyGap = 4;
  static const double _cheerLen = 1.8;
  static const List<int> _coats = [0xFF8C7360, 0xFFB7A894, 0xFF5E5148, 0xFFCBBFA8, 0xFF7A6A58];
  static const List<int> _hairs = [0xFFC9A96A, 0xFF6B4F3A, 0xFFA0522D, 0xFF3E3028];

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

  final List<_Dragon> _dragons = [];
  final List<_Mote> _motes = [];
  double _nextDragon = 3;

  _Army? _army;
  double _nextArmy = 2;
  double _armyRaise = 0;
  bool _armyHint = false;
  _Faction? _lastFaction;

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
  bool _hoverClick = false;

  bool get _fantasy => widget.scene == HomeScene.fantasy;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(covariant HomeSky old) {
    super.didUpdateWidget(old);
    if (widget.cheerSignal != old.cheerSignal) _celebrate();
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

  void _celebrate() {
    final a = _army;
    if (a != null) a.cheer = _cheerLen;
    for (final d in _dragons) {
      d.fire = 1;
    }
  }

  Offset get _origin => Offset(_size.width - 70, _size.height - 64);

  double _flightFor(double dist) => _weapon == _Weapon.sling ? 0.22 + dist / 2600 : 0.35 + dist / 1800;

  Offset _v0For(Offset target, double flight) {
    final d = target - _origin;
    return Offset(d.dx / flight, (d.dy - 0.5 * g * flight * flight) / flight);
  }

  void _ensureClouds() {
    if (_clouds.isEmpty) {
      for (var i = 0; i < 6; i++) {
        _clouds.add(_Cloud(
          x: _rnd.nextDouble() * _size.width,
          y: _size.height * (0.06 + _rnd.nextDouble() * 0.30),
          scale: 0.7 + _rnd.nextDouble() * 0.7,
          speed: 6 + _rnd.nextDouble() * 8,
        ));
      }
    }
    if (_fantasy && _motes.isEmpty) {
      for (var i = 0; i < 26; i++) {
        _motes.add(_Mote(
          _rnd.nextDouble() * _size.width,
          _size.height * (0.5 + _rnd.nextDouble() * 0.45),
          _rnd.nextDouble() * math.pi * 2,
          i.isEven,
        ));
      }
    }
  }

  // ------------------------------------------------------------------ dragons
  _Dragon? _dragonAt(Offset p, {double slack = 0}) {
    for (final d in _dragons) {
      final head = Offset(d.x + (d.vx < 0 ? -1 : 1) * 34 * d.scale, d.y - 10 * d.scale);
      if ((Offset(d.x, d.y) - p).distance < 34 * d.scale + slack || (head - p).distance < 14 * d.scale + slack) return d;
    }
    return null;
  }

  void _spawnDragon() {
    final dir = _rnd.nextBool() ? 1.0 : -1.0;
    final y0 = _size.height * (0.08 + _rnd.nextDouble() * 0.22);
    final sp = 55 + _rnd.nextDouble() * 30;
    final col = _pick(const [0xFF4F7F6A, 0xFF9A4A44, 0xFF5B6B80, 0xFF8A7148, 0xFF6B5A86]);
    final sc = 0.85 + _rnd.nextDouble() * 0.45;
    void add(double back, double dy, double s) => _dragons.add(_Dragon(
          x: (dir > 0 ? -150.0 : _size.width + 150) - dir * back,
          y: y0 + dy,
          vx: dir * sp,
          scale: s,
          phase: _rnd.nextDouble() * math.pi * 2,
          color: col,
          nextBreath: _now + 3 + _rnd.nextDouble() * 6,
        ));
    add(0, 0, sc);
    if (_rnd.nextDouble() < 0.35) add(120, 28, sc * 0.6);
    _nextDragon = _now + 18 + _rnd.nextDouble() * 12;
  }

  void _hurtDragon(_Dragon d) {
    d.fire = 1;
    d.fleeing = true;
    d.vy = -110;
    d.vx *= 1.9;
    for (var i = 0; i < 8; i++) {
      _feathers.add(_Feather(
        x: d.x,
        y: d.y,
        vx: (_rnd.nextDouble() - 0.5) * 80,
        vy: -10 + _rnd.nextDouble() * 40,
        born: _now,
      ));
    }
  }

  // ------------------------------------------------------------------ army helpers
  double get _armyScale => (_size.height / 850).clamp(0.8, 1.3).toDouble();
  double _groundAt(double x) => _size.height * _armyGroundFrac + math.sin(x * 0.0045) * 6;
  Offset get _tabPoint => Offset(10, _size.height * 0.5 + 23);
  double get _pointStartX => math.min(_size.width * 0.55, 600.0);

  T _pick<T>(List<T> l) => l[_rnd.nextInt(l.length)];

  double _kFor(_Army a, _Soldier m) =>
      _armyScale * ((m.kind == _Kind.rider && a.faction == _Faction.mongol) ? 0.9 : 1.0);

  double _xOf(_Army a, _Soldier m) => a.x + m.dx * _armyScale + m.lag;

  _Wpn _weaponFor(_Faction f, bool rider) {
    final r = _rnd.nextDouble();
    if (f == _Faction.crusader) {
      if (rider) return r < 0.6 ? _Wpn.lance : _Wpn.sword;
      return r < 0.55 ? _Wpn.spear : _Wpn.sword;
    }
    if (f == _Faction.viking) {
      if (r < 0.6) return _Wpn.axe;
      return r < 0.85 ? _Wpn.spear : _Wpn.sword;
    }
    if (f == _Faction.saracen) {
      if (rider) return r < 0.4 ? _Wpn.lance : _Wpn.saber;
      return r < 0.4 ? _Wpn.spear : _Wpn.saber;
    }
    if (rider) return r < 0.5 ? _Wpn.saber : _Wpn.spear;
    return _Wpn.spear;
  }

  _Army _makeArmy() {
    var f = _pick(_Faction.values);
    if (f == _lastFaction) f = _Faction.values[(f.index + 1 + _rnd.nextInt(3)) % _Faction.values.length];
    _lastFaction = f;

    late int riders, foot, cloth, trim;
    late double rStep, fStep;
    switch (f) {
      case _Faction.crusader:
        riders = 3 + _rnd.nextInt(3);
        foot = 7 + _rnd.nextInt(4);
        rStep = 56;
        fStep = 24;
        cloth = 0xFFE4D9BE;
        trim = _pick(const [0xFFA65A52, 0xFF4F6F99]);
        break;
      case _Faction.viking:
        riders = 0;
        foot = 12 + _rnd.nextInt(5);
        rStep = 0;
        fStep = 24;
        cloth = _pick(const [0xFFC2A25A, 0xFF5F7E99, 0xFF76926E, 0xFFA65A52]);
        trim = 0xFFE8DCC0;
        break;
      case _Faction.saracen:
        riders = 4 + _rnd.nextInt(3);
        foot = 5 + _rnd.nextInt(4);
        rStep = 52;
        fStep = 24;
        cloth = _pick(const [0xFF4F8A86, 0xFFE8E0C8, 0xFF4F7F57, 0xFF4F5F8A]);
        trim = 0xFFC9A24A;
        break;
      case _Faction.mongol:
        riders = 9 + _rnd.nextInt(4);
        foot = _rnd.nextInt(3);
        rStep = 44;
        fStep = 24;
        cloth = _pick(const [0xFF7A5A40, 0xFF8A4A40, 0xFF56707F]);
        trim = 0xFFC9B58A;
        break;
    }

    final bannerWpn = f == _Faction.viking
        ? _Wpn.axe
        : (f == _Faction.saracen || f == _Faction.mongol ? _Wpn.saber : _Wpn.sword);

    final members = <_Soldier>[];
    var dx = 0.0;
    for (var i = 0; i < riders; i++) {
      final isBanner = i == 0;
      members.add(_Soldier(
        _Kind.rider,
        isBanner ? bannerWpn : _weaponFor(f, true),
        dx,
        i.isOdd ? 9.0 : 0.0,
        _rnd.nextDouble() * math.pi * 2,
        _pick(_coats),
        banner: isBanner,
      ));
      dx += rStep;
    }
    if (riders > 0 && foot > 0) dx += 14;
    for (var j = 0; j < foot; j++) {
      final isBanner = riders == 0 && j == 0;
      members.add(_Soldier(
        _Kind.foot,
        isBanner ? bannerWpn : _weaponFor(f, false),
        dx,
        (j % 3) * 5.0,
        _rnd.nextDouble() * math.pi * 2,
        _pick(_hairs),
        banner: isBanner,
      ));
      dx += fStep;
    }
    return _Army(x: _size.width + 60, faction: f, cloth: cloth, trim: trim, members: members, length: dx);
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

    if (_fantasy) {
      if (!_reduce && _now >= _nextDragon) _spawnDragon();
      for (final d in _dragons) {
        d.x += d.vx * dt;
        d.y += d.vy * dt + math.sin(_now * 1.2 + d.phase) * 14 * dt;
        d.fire = math.max(0.0, d.fire - dt * 0.9);
        if (!d.fleeing && _now >= d.nextBreath) {
          d.fire = 1;
          d.nextBreath = _now + 8 + _rnd.nextDouble() * 10;
        }
      }
      _dragons.removeWhere((d) => d.x < -280 || d.x > _size.width + 280 || d.y < -220);

      for (final m in _motes) {
        m.x += (math.sin(_now * 0.6 + m.phase) * 9 + 4) * dt * drift;
        m.y += math.sin(_now * 0.9 + m.phase * 1.7) * 6 * dt * drift;
        if (m.x > _size.width + 10) m.x = -10;
      }
    } else if (!_reduce && _now >= _nextFlock) {
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

    if (!_reduce && widget.armies) {
      final a = _army;
      if (a == null) {
        if (_now >= _nextArmy) _army = _makeArmy();
      } else {
        a.x -= _armySpeed * dt;
        a.t += dt;
        a.cheer = math.max(0.0, a.cheer - dt);
        final sc = _armyScale;
        var tail = 0.0;
        for (final m in a.members) {
          m.react = math.max(0.0, m.react - dt * 1.7);
          m.guard = math.max(0.0, m.guard - dt);
          if (m.downLeft > 0) {
            m.downLeft = math.max(0.0, m.downLeft - dt);
            m.lag += _armySpeed * dt;
          } else if (m.lag > 0) {
            m.lag = math.max(0.0, m.lag - _armySpeed * 0.9 * dt);
            m.walk += dt * 1.9;
          } else {
            m.walk += dt;
          }
          tail = math.max(tail, m.dx * sc + m.lag);
        }
        if (a.x + tail < -160) {
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

  bool _hitSoldier(_Army a, _Soldier m) {
    final hasShield = a.faction != _Faction.mongol;
    if (hasShield && m.guard > 0 && _rnd.nextDouble() < 0.55) {
      m.react = 0.5;
      m.guard = math.max(m.guard, 2.0);
      return false;
    }
    m.downFor = m.kind == _Kind.foot ? 2.4 : 1.6;
    m.downLeft = m.downFor;
    m.react = 0;
    final mx = _xOf(a, m);
    for (final o in a.members) {
      if (identical(o, m)) continue;
      if ((_xOf(a, o) - mx).abs() < 170 * _armyScale) o.guard = 3.0;
    }
    return true;
  }

  void _impact(Offset p) {
    var hit = false;
    var blocked = false;
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
    if (_fantasy) {
      final d = _dragonAt(p, slack: 6);
      if (d != null && !d.fleeing) {
        _hurtDragon(d);
        hit = true;
      }
    }
    final a = _army;
    if (a != null) {
      final m = _soldierAt(p, slack: 5);
      if (m != null && m.downLeft == 0) {
        if (_hitSoldier(a, m)) {
          hit = true;
        } else {
          blocked = true;
        }
      }
    }
    _sparks.add(_Spark(
      p,
      blocked ? const Color(0xFFDDE3E6) : (hit ? const Color(0xFFF4D06F) : const Color(0xFF9A8F7A)),
      _now,
    ));
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

  _Soldier? _soldierAt(Offset p, {double slack = 0}) {
    final a = _army;
    if (a == null) return null;
    final order = [...a.members]..sort((x, y) => y.lane.compareTo(x.lane));
    for (final m in order) {
      final isFoot = m.kind == _Kind.foot;
      final k = _kFor(a, m);
      final wx = _xOf(a, m);
      final wy = _groundAt(wx) + m.lane * _armyScale;
      Rect r;
      if (isFoot && m.downLeft > 0) {
        r = Rect.fromLTRB(wx - 4 * k, wy - 16 * k, wx + 50 * k, wy + 2 * k);
      } else if (isFoot) {
        r = Rect.fromLTRB(wx - 11 * k, wy - 52 * k, wx + 11 * k, wy);
      } else {
        r = Rect.fromLTRB(wx - 42 * k, wy - 102 * k, wx + 38 * k, wy);
      }
      if (r.inflate(slack).contains(p)) return m;
    }
    return null;
  }

  bool _clickableAt(Offset p) => _soldierAt(p) != null || (_fantasy && _dragonAt(p) != null);

  bool _blocked(Offset global) {
    // when the content is hidden, its cards no longer block the scene
    for (final k in [if (!widget.cardsHidden) ...widget.blockers, _tabKey, _btnKey]) {
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
    final a = _army;
    final s = _soldierAt(p);
    if (a != null && s != null) {
      if (s.downLeft > 0) {
        s.downLeft = math.min(s.downLeft, 0.35);
      } else if (s.banner) {
        a.cheer = _cheerLen;
      } else {
        s.react = 1;
      }
      return;
    }
    if (_fantasy) {
      final d = _dragonAt(p);
      if (d != null) {
        d.fire = 1;
        return;
      }
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
    final click = !blocked && _clickableAt(_aim);
    final over = !blocked && !click && (_cloudAt(_aim) != null || _birdAt(_aim) != null);
    if (over != _hoverThing || click != _hoverClick) {
      setState(() {
        _hoverThing = over;
        _hoverClick = click;
      });
    }
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
                  hidden ? widget.showLabel : widget.hideLabel,
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
    final hidden = widget.cardsHidden;

    final MouseCursor cursor = _weapon != null
        ? SystemMouseCursors.precise
        : (_held != null
            ? SystemMouseCursors.grabbing
            : (_hoverClick ? SystemMouseCursors.click : (_hoverThing ? SystemMouseCursors.grab : MouseCursor.defer)));

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
              // the whole page content sinks and fades out when hidden
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: hidden,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeInOutCubic,
                    offset: hidden ? const Offset(0, 0.3) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                      opacity: hidden ? 0 : 1,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: CustomPaint(painter: _WeaponPainter(this, _frame))),
                ),
              ),
              _secretTab(),
              if (widget.onToggleCards != null) _cardsButton(),
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
    final fantasy = s._fantasy;

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

    for (final d in s._dragons) {
      _paintDragon(canvas, d, now, dark);
    }

    for (final f in s._feathers) {
      final k = ((now - f.born) / 1.8).clamp(0.0, 1.0).toDouble();
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.rotate(f.rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 2.6),
        Paint()..color = (fantasy ? const Color(0xFF7A8C7E) : const Color(0xFF8A8F86)).withOpacity(1 - k),
      );
      canvas.restore();
    }

    if (fantasy) {
      for (final m in s._motes) {
        final tw = 0.5 + 0.5 * math.sin(now * 2.1 + m.phase * 3);
        final col = m.warm ? const Color(0xFFF4D06F) : const Color(0xFF9FE6D6);
        canvas.drawCircle(
          Offset(m.x, m.y),
          4.5,
          Paint()
            ..color = col.withOpacity((dark ? 0.35 : 0.22) * tw)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(Offset(m.x, m.y), 1.4, Paint()..color = col.withOpacity((dark ? 0.9 : 0.7) * tw));
      }
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
// DRAGON
// ============================================================================
Color _mist(Color c, bool dark, [double k = 0.35]) =>
    Color.lerp(c, dark ? const Color(0xFF9AA8AE) : const Color(0xFFE0E7E8), k)!;

void _dragonWing(Canvas c, double tipY, Color membrane, Color bone) {
  final p = Path()
    ..moveTo(6, -3)
    ..lineTo(-4, tipY * 0.55)
    ..lineTo(-24, tipY)
    ..quadraticBezierTo(-22, tipY * 0.45 + 2, -17, -1)
    ..quadraticBezierTo(-12, tipY * 0.22, -7, -1)
    ..quadraticBezierTo(-2, tipY * 0.12, 4, -1)
    ..close();
  c.drawPath(p, Paint()..color = membrane);
  final b = _ps(bone, 1.6);
  final elbow = Offset(-4, tipY * 0.55);
  c.drawLine(const Offset(6, -3), elbow, b);
  c.drawLine(elbow, Offset(-24, tipY), b);
  c.drawLine(elbow, const Offset(-17, -1), _ps(bone, 1.0));
  c.drawLine(elbow, const Offset(-7, -1), _ps(bone, 1.0));
}

void _paintDragon(Canvas canvas, _Dragon d, double now, bool dark) {
  final base = Color(d.color);
  final body = _mist(base, dark, 0.3);
  final dk = _mist(Color.lerp(base, Colors.black, 0.35)!, dark, 0.3);
  final belly = _mist(const Color(0xFFD9C79A), dark, 0.35);
  final wingFar = _mist(Color.lerp(base, Colors.black, 0.2)!, dark, 0.4);
  final wingNear = _mist(Color.lerp(base, Colors.white, 0.1)!, dark, 0.38);

  canvas.saveLayer(
    Rect.fromCenter(center: Offset(d.x, d.y), width: 320 * d.scale, height: 220 * d.scale),
    Paint()..color = Colors.white.withOpacity(dark ? 0.72 : 0.84),
  );
  canvas.translate(d.x, d.y);
  canvas.scale(d.vx < 0 ? -d.scale : d.scale, d.scale);

  final s = math.sin(now * (d.fleeing ? 11 : 6) + d.phase);
  final wingY = -46 + 64 * ((1 - s) / 2);

  canvas.save();
  canvas.translate(-3, -2);
  _dragonWing(canvas, wingY * 0.85, wingFar, dk);
  canvas.restore();

  final tw = math.sin(now * 3 + d.phase) * 5;
  final tail = Path()
    ..moveTo(-18, 0)
    ..cubicTo(-34, 5, -46, -6 + tw, -62, 2 + tw);
  canvas.drawPath(tail, _ps(body, 4.2));
  final tip = Offset(-62, 2 + tw);
  final spade = Path()
    ..moveTo(tip.dx + 2, tip.dy)
    ..lineTo(tip.dx - 6, tip.dy - 5)
    ..lineTo(tip.dx - 10, tip.dy)
    ..lineTo(tip.dx - 6, tip.dy + 5)
    ..close();
  canvas.drawPath(spade, _pf(dk));

  canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 48, height: 16), _pf(body));
  canvas.drawOval(Rect.fromCenter(center: const Offset(2, 3.5), width: 34, height: 6.5), _pf(belly));
  for (var i = 0; i < 5; i++) {
    final x = -14.0 + i * 7;
    final sp = Path()
      ..moveTo(x - 2.5, -7)
      ..lineTo(x, -11.5)
      ..lineTo(x + 2.5, -7)
      ..close();
    canvas.drawPath(sp, _pf(dk));
  }
  canvas.drawLine(const Offset(-9, 6), const Offset(-14, 13), _ps(dk, 2.4));
  canvas.drawLine(const Offset(8, 6), const Offset(5, 13), _ps(dk, 2.4));

  final neck = Path()
    ..moveTo(18, -2)
    ..quadraticBezierTo(28, -3, 32, -12);
  canvas.drawPath(neck, _ps(body, 7));
  final jaw = d.fire > 0 ? 3.0 * math.min(1.0, d.fire * 2) : 0.0;
  final head = Path()
    ..moveTo(28, -16)
    ..lineTo(44, -13)
    ..lineTo(46, -10)
    ..lineTo(31, -8)
    ..close();
  canvas.drawPath(head, _pf(body));
  final lower = Path()
    ..moveTo(31, -8)
    ..lineTo(45, -9 + jaw)
    ..lineTo(44, -7 + jaw)
    ..lineTo(31, -6)
    ..close();
  canvas.drawPath(lower, _pf(dk));
  canvas.drawLine(const Offset(30, -15), const Offset(24, -22), _ps(dk, 1.6));
  canvas.drawLine(const Offset(33, -15), const Offset(29, -23), _ps(dk, 1.6));
  canvas.drawCircle(const Offset(37, -12.5), 1.3, _pf(const Color(0xFFF4D06F)));

  _dragonWing(canvas, wingY, wingNear, dk);

  if (d.fire > 0) {
    final reach = math.min(1.0, (1 - d.fire) * 3 + 0.2);
    for (var i = 0; i < 9; i++) {
      final k = i / 8;
      final col = k < 0.35
          ? Color.lerp(const Color(0xFFFFF0A8), const Color(0xFFF7B955), k / 0.35)!
          : Color.lerp(const Color(0xFFF7B955), const Color(0xFFD9573A), (k - 0.35) / 0.65)!;
      canvas.drawCircle(
        Offset(46 + 74 * k * reach, -9 + 8 * k * k + math.sin(now * 20 + i) * 1.2),
        2.5 + 9 * k,
        Paint()
          ..color = col.withOpacity(d.fire * (1 - k * 0.6) * 0.85)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + 3 * k),
      );
    }
  }
  canvas.restore();
}

// ============================================================================
// ARMIES — Crusaders, Vikings, Saracens, Mongols.
// ============================================================================
class _Pal {
  _Pal(this.dark, this.faction, this.clothV, this.trimV);
  final bool dark;
  final _Faction faction;
  final int clothV;
  final int trimV;

  Color f(int v, [double k = 0.30]) =>
      Color.lerp(Color(v), dark ? const Color(0xFF9AA8AE) : const Color(0xFFE0E7E8), k)!;

  late final Color steel = f(0xFF7C8A91);
  late final Color steelDark = f(0xFF55626A);
  late final Color blade = f(0xFFC9D2D6, 0.18);
  late final Color cloth = f(clothV, faction == _Faction.crusader ? 0.12 : 0.30);
  late final Color trim = f(trimV);
  late final Color wood = f(0xFF8A6D52);
  late final Color cream = f(0xFFE8DCC0, 0.10);
  late final Color leather = f(0xFF7A5E44);
  late final Color fur = f(0xFF5A4636);
  late final Color skin = f(
    faction == _Faction.saracen ? 0xFFC49A74 : (faction == _Faction.mongol ? 0xFFBE9470 : 0xFFD8B79B),
    0.15,
  );
  late final Color hose = f(
    faction == _Faction.crusader
        ? 0xFF6B5E55
        : (faction == _Faction.viking ? 0xFF6A5A48 : (faction == _Faction.saracen ? 0xFFCFC3A8 : 0xFF4A3F36)),
  );
  late final Color sleeve = faction == _Faction.crusader
      ? steel
      : (faction == _Faction.saracen ? cloth : leather);
}

Paint _pf(Color c) => Paint()..color = c;
Paint _ps(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

double _lerpD(double a, double b, double t) => a + (b - a) * t;

double _restAngle(_Wpn w) {
  switch (w) {
    case _Wpn.sword:
      return -1.35;
    case _Wpn.saber:
      return -1.25;
    case _Wpn.axe:
      return -1.0;
    case _Wpn.spear:
      return -1.5;
    case _Wpn.lance:
      return -1.45;
  }
}

void _paintArmy(Canvas canvas, _HomeSkyState s, _Army a, bool dark) {
  final sc = s._armyScale;
  final size = s._size;
  final g = size.height * _HomeSkyState._armyGroundFrac;
  final tail = a.members.fold<double>(0, (t, m) => math.max(t, m.dx * sc + m.lag));
  final left = a.x - 140 * sc;
  final right = a.x + tail + 120 * sc;
  final pal = _Pal(dark, a.faction, a.cloth, a.trim);
  final tab = s._tabPoint;
  final raise = s._armyRaise;
  final order = [...a.members]..sort((p, q) => p.lane.compareTo(q.lane));

  final cheerK = a.cheer <= 0
      ? 0.0
      : math.min(1.0, a.cheer / 0.3) * math.min(1.0, (_HomeSkyState._cheerLen - a.cheer) / 0.2);

  canvas.saveLayer(
    Rect.fromLTRB(left, g - 200 * sc, right, g + 40 * sc),
    Paint()..color = Colors.white.withOpacity(dark ? 0.62 : 0.76),
  );

  for (final m in order) {
    final isFoot = m.kind == _Kind.foot;
    final wx = a.x + m.dx * sc + m.lag;
    if (wx < -160 || wx > size.width + 160) continue;
    final wy = s._groundAt(wx) + m.lane * sc;
    final k = s._kFor(a, m);
    final isDown = m.downLeft > 0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(wx + (isDown && isFoot ? 22 * k : 0), wy + 1),
        width: (isFoot ? (isDown ? 48 : 22) : 62) * k,
        height: 6 * k,
      ),
      Paint()
        ..color = Colors.black.withOpacity(dark ? 0.22 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final shoulder = isFoot ? 35.0 : 69.0;
    final dxw = tab.dx - wx;
    final dyw = tab.dy - (wy - shoulder * k);
    var ang = math.atan2(dyw / k, -dxw / k).clamp(-0.95, -0.22).toDouble();

    var rr = (isDown || m.lag > 0) ? 0.0 : raise;
    if (cheerK > 0 && !isDown) {
      rr = math.max(rr, cheerK);
      ang = _lerpD(ang, -1.45, cheerK);
    }
    final salute = m.react > 0 ? math.sin(m.react * math.pi) : 0.0;
    if (isFoot && salute > 0) {
      rr = math.max(rr, salute);
      ang = _lerpD(ang, -1.45, salute);
    }
    final gk = a.faction == _Faction.mongol ? 0.0 : math.min(1.0, m.guard / 0.3);
    final fall = isDown
        ? math.min(1.0, (m.downFor - m.downLeft) / 0.22) * math.min(1.0, m.downLeft / 0.35)
        : 0.0;

    canvas.save();
    canvas.translate(wx, wy);
    canvas.scale(-k, k);
    if (isFoot) {
      final hop = salute * 6 + (cheerK > 0 ? math.sin(a.t * 14 + m.seed).abs() * 4 * cheerK : 0.0);
      if (fall > 0) canvas.rotate(-1.45 * fall);
      canvas.translate(0, -hop);
      _drawFoot(canvas, pal, m, m.walk * 8 + m.seed, rr, ang, a.t, gk);
    } else {
      final rear = math.max(fall, math.max(salute, cheerK * 0.5 * math.sin(a.t * 6 + m.seed).abs()));
      if (rear > 0) {
        canvas.translate(-17, 0);
        canvas.rotate(-0.42 * rear);
        canvas.translate(17, 0);
      }
      _drawRider(canvas, pal, m, m.walk * 5.2 + m.seed, rr, ang, a.t, gk);
    }
    canvas.restore();
  }
  canvas.restore();

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
  c.drawRect(Rect.fromLTWH(cx - w * 0.14, top, w * 0.28, h), _pf(p.trim));
  c.restore();
  c.drawPath(path, _ps(p.steelDark, 1.1));
}

void _round(Canvas c, _Pal p, Offset o, double r) {
  c.drawCircle(o, r, _pf(p.cloth));
  final wedge = _pf(p.trim);
  for (var i = 0; i < 4; i++) {
    c.drawArc(Rect.fromCircle(center: o, radius: r), i * math.pi / 2, math.pi / 4, true, wedge);
  }
  c.drawCircle(o, r, _ps(p.steelDark, 1.2));
  c.drawCircle(o, r * 0.3, _pf(p.steel));
}

void _shield(Canvas c, _Pal p, double cx, double top) {
  switch (p.faction) {
    case _Faction.crusader:
      _kite(c, p, cx, top, 9.5, 20.5);
      break;
    case _Faction.viking:
      _round(c, p, Offset(cx + 0.5, top + 9.5), 8.5);
      break;
    case _Faction.saracen:
      _round(c, p, Offset(cx + 0.5, top + 9), 7);
      break;
    case _Faction.mongol:
      break;
  }
}

void _torso(Canvas c, _Pal p, double top, double bottom, double belt) {
  final h = bottom - top;
  switch (p.faction) {
    case _Faction.crusader:
      c.drawRRect(RRect.fromLTRBR(-5.8, top, 5.8, bottom, const Radius.circular(3)), _pf(p.cloth));
      final cr = _pf(p.trim.withOpacity(0.9));
      c.drawRect(Rect.fromLTWH(-1, top + 3, 2, h - 8), cr);
      c.drawRect(Rect.fromLTWH(-4, top + 6, 8, 2), cr);
      break;
    case _Faction.viking:
      c.drawRRect(RRect.fromLTRBR(-5.8, top, 5.8, bottom, const Radius.circular(3)), _pf(p.cloth));
      c.drawRect(Rect.fromLTWH(-5.8, bottom - 3, 11.6, 3), _pf(p.trim));
      c.drawRect(Rect.fromLTWH(-5.8, top + 2, 11.6, 3.5), _pf(p.leather));
      break;
    case _Faction.saracen:
      c.drawRRect(RRect.fromLTRBR(-6.4, top, 6.4, bottom + 2, const Radius.circular(3.5)), _pf(p.cloth));
      c.drawRect(Rect.fromLTWH(-6.4, belt - 1, 12.8, 3.2), _pf(p.trim));
      break;
    case _Faction.mongol:
      c.drawRRect(RRect.fromLTRBR(-5.8, top, 5.8, bottom, const Radius.circular(3)), _pf(p.leather));
      for (var y = top + 3; y < bottom - 2; y += 3) {
        c.drawLine(Offset(-5.4, y), Offset(5.4, y), _ps(p.steelDark.withOpacity(0.7), 0.7));
      }
      final skirt = Path()
        ..moveTo(-5.8, bottom - 5)
        ..lineTo(5.8, bottom - 5)
        ..lineTo(7.6, bottom + 3)
        ..lineTo(-7.6, bottom + 3)
        ..close();
      c.drawPath(skirt, _pf(p.cloth));
      break;
  }
  if (p.faction != _Faction.saracen) {
    c.drawRect(Rect.fromLTWH(-6, belt, 12, 2), _pf(p.wood));
  }
  final collar = p.faction == _Faction.mongol ? p.fur : (p.faction == _Faction.saracen ? p.cloth : p.steel);
  c.drawOval(Rect.fromCenter(center: Offset(0, top), width: 12, height: 4.5), _pf(collar));
}

void _head(Canvas c, _Pal p, double cy, {required bool great, required int hairV, required double sw}) {
  final skin = _pf(p.skin);
  switch (p.faction) {
    case _Faction.crusader:
      if (great) {
        c.drawRRect(RRect.fromLTRBR(-4.6, cy - 9.5, 4.8, cy + 5, const Radius.circular(2)), _pf(p.steel));
        c.drawRect(Rect.fromLTWH(1.4, cy - 9.5, 1.2, 14.5), _pf(p.steelDark));
        c.drawRect(Rect.fromLTWH(0.6, cy - 4.7, 4.2, 1.3), _pf(p.steelDark));
        final plume = Path()
          ..moveTo(-1, cy - 9.5)
          ..quadraticBezierTo(-9, cy - 18.5 + sw * 1.2, -13, cy - 7.5 + sw * 2)
          ..quadraticBezierTo(-7, cy - 11.5, -1, cy - 7.5)
          ..close();
        c.drawPath(plume, _pf(p.trim));
      } else {
        c.drawCircle(Offset(-0.5, cy), 5.4, _pf(p.steel));
        c.drawCircle(Offset(2.3, cy + 1), 3.0, skin);
        final helm = Path()
          ..moveTo(-5.6, cy)
          ..arcToPoint(Offset(5.8, cy), radius: const Radius.circular(5.7), clockwise: true)
          ..close();
        c.drawPath(helm, _pf(p.steel));
        c.drawRect(Rect.fromLTWH(4.2, cy - 1.5, 1.5, 6.5), _pf(p.steelDark));
      }
      break;
    case _Faction.viking:
      final hair = _pf(p.f(hairV, 0.2));
      c.drawCircle(Offset(-1.2, cy + 0.8), 5.8, hair);
      c.drawCircle(Offset(2.3, cy + 1), 3.0, skin);
      c.drawOval(Rect.fromCenter(center: Offset(2.8, cy + 4.6), width: 6.4, height: 5.6), hair);
      final cone = Path()
        ..moveTo(-5.6, cy)
        ..quadraticBezierTo(-4.2, cy - 8, 0.8, cy - 10.5)
        ..quadraticBezierTo(4.4, cy - 8, 5.8, cy)
        ..close();
      c.drawPath(cone, _pf(p.steel));
      c.drawRect(Rect.fromLTWH(-5.6, cy - 1.2, 11.4, 1.8), _pf(p.steelDark));
      c.drawRect(Rect.fromLTWH(4.2, cy - 1.2, 1.5, 6), _pf(p.steelDark));
      break;
    case _Faction.saracen:
      c.drawCircle(Offset(-1, cy + 1), 5.6, _pf(p.steel));
      c.drawCircle(Offset(2.3, cy + 1), 3.0, skin);
      final cone = Path()
        ..moveTo(-5.4, cy - 0.5)
        ..quadraticBezierTo(-3.8, cy - 8, 0.5, cy - 11)
        ..quadraticBezierTo(4.2, cy - 8, 5.6, cy - 0.5)
        ..close();
      c.drawPath(cone, _pf(p.steel));
      c.drawLine(Offset(0.5, cy - 11), Offset(0.5, cy - 14.5), _ps(p.steelDark, 1.2));
      final wrap = Rect.fromCenter(center: Offset(0.2, cy - 1.4), width: 12.6, height: 4.4);
      c.drawOval(wrap, _pf(p.cream));
      c.drawOval(wrap, _ps(p.trim, 0.9));
      break;
    case _Faction.mongol:
      c.drawOval(Rect.fromCenter(center: Offset(-3.5, cy + 2), width: 4.4, height: 7), _pf(p.fur));
      c.drawCircle(Offset(2.0, cy + 1), 3.2, skin);
      final cap = Path()
        ..moveTo(-5.4, cy - 1)
        ..quadraticBezierTo(-3.4, cy - 8, 1, cy - 9.5)
        ..quadraticBezierTo(4.6, cy - 8, 5.6, cy - 1)
        ..close();
      c.drawPath(cap, _pf(p.cloth));
      c.drawOval(Rect.fromCenter(center: Offset(0.2, cy - 1.2), width: 13.6, height: 4.6), _pf(p.fur));
      c.drawCircle(Offset(1, cy - 10.2), 1.2, _pf(p.trim));
      break;
  }
}

void _flag(Canvas c, _Pal p, double px, double top, double wave) {
  if (p.faction == _Faction.mongol) {
    c.drawCircle(Offset(px, top - 2), 2.2, _pf(p.trim));
    final tuft = _ps(p.fur, 2.4);
    c.drawLine(Offset(px, top), Offset(px - 6 + wave * 0.5, top + 12), tuft);
    c.drawLine(Offset(px, top), Offset(px - 2 + wave * 0.5, top + 15), tuft);
    c.drawLine(Offset(px, top), Offset(px - 9 + wave * 0.5, top + 9), tuft);
    return;
  }
  final flag = Path()
    ..moveTo(px, top)
    ..quadraticBezierTo(px - 13, top - 3 + wave, px - 27, top + 1 + wave * 1.4)
    ..lineTo(px - 22, top + 8 + wave * 1.4)
    ..lineTo(px - 27, top + 15 + wave * 1.4)
    ..quadraticBezierTo(px - 13, top + 11 + wave, px, top + 14)
    ..close();
  c.drawPath(flag, _pf(p.cloth));
  switch (p.faction) {
    case _Faction.crusader:
      c.drawRect(Rect.fromLTWH(px - 14, top + 1, 2.4, 12), _pf(p.trim));
      c.drawRect(Rect.fromLTWH(px - 19, top + 5.2, 11, 2.4), _pf(p.trim));
      break;
    case _Faction.viking:
      c.drawRect(Rect.fromLTWH(px - 26, top + 5.5, 24, 3), _pf(p.trim));
      break;
    case _Faction.saracen:
      c.drawArc(Rect.fromCircle(center: Offset(px - 12, top + 7), radius: 3.6), 0.6, 5.0, false, _ps(p.trim, 1.4));
      break;
    case _Faction.mongol:
      break;
  }
  c.drawCircle(Offset(px, top - 2), 1.7, _pf(p.steel));
}

void _weapon(Canvas c, _Pal p, _Wpn w, Offset hand, double a) {
  final d = Offset(math.cos(a), math.sin(a));
  final n = Offset(-d.dy, d.dx);
  switch (w) {
    case _Wpn.sword:
      c.drawLine(hand - d * 3, hand + d * 2, _ps(p.wood, 2.2));
      c.drawLine(hand + d * 2 - n * 3.6, hand + d * 2 + n * 3.6, _ps(p.steelDark, 1.8));
      c.drawLine(hand + d * 2, hand + d * 25, _ps(p.blade, 2.2));
      break;
    case _Wpn.saber:
      c.drawLine(hand - d * 3, hand + d * 2, _ps(p.wood, 2.2));
      c.drawLine(hand + d * 2 - n * 2.6, hand + d * 2 + n * 2.6, _ps(p.steelDark, 1.5));
      final o2 = hand + d * 2;
      final ctrl = hand + d * 14 + n * 1.2;
      final tip = hand + d * 25 + n * 4.5;
      final blade = Path()
        ..moveTo(o2.dx, o2.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
      c.drawPath(blade, _ps(p.blade, 2.2));
      break;
    case _Wpn.axe:
      c.drawLine(hand - d * 4, hand + d * 21, _ps(p.wood, 2.3));
      final b = hand + d * 17;
      final pa = b - d * 2.5;
      final pb = b + d * 4 + n * 8;
      final pc = b + d * 9;
      final pe = b + d * 4 - n * 2;
      final cp = b + d * 10 + n * 4;
      final head = Path()
        ..moveTo(pa.dx, pa.dy)
        ..lineTo(pb.dx, pb.dy)
        ..quadraticBezierTo(cp.dx, cp.dy, pc.dx, pc.dy)
        ..lineTo(pe.dx, pe.dy)
        ..close();
      c.drawPath(head, _pf(p.steel));
      c.drawPath(head, _ps(p.steelDark, 0.8));
      break;
    case _Wpn.spear:
      c.drawLine(hand - d * 14, hand + d * 52, _ps(p.wood, 1.9));
      final tip = hand + d * 63;
      final bse = hand + d * 51;
      final l1 = bse + n * 2.4;
      final l2 = bse - n * 2.4;
      final leaf = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(l1.dx, l1.dy)
        ..lineTo(l2.dx, l2.dy)
        ..close();
      c.drawPath(leaf, _pf(p.steel));
      break;
    case _Wpn.lance:
      c.drawLine(hand - d * 16, hand + d * 72, _ps(p.wood, 2.0));
      final tip = hand + d * 86;
      final bse = hand + d * 72;
      final l1 = bse + n * 2.2;
      final l2 = bse - n * 2.2;
      final leaf = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(l1.dx, l1.dy)
        ..lineTo(l2.dx, l2.dy)
        ..close();
      c.drawPath(leaf, _pf(p.steel));
      final a0 = hand + d * 58;
      final a1 = hand + d * 70;
      final a2 = hand + d * 64 + const Offset(-11, 5);
      final pen = Path()
        ..moveTo(a0.dx, a0.dy)
        ..lineTo(a1.dx, a1.dy)
        ..lineTo(a2.dx, a2.dy)
        ..close();
      c.drawPath(pen, _pf(p.cloth));
      break;
  }
}

void _drawFoot(Canvas c, _Pal p, _Soldier m, double ph, double raise, double ang, double t, double guard) {
  final sw = math.sin(ph);
  final bob = -math.cos(ph * 2).abs() * 1.1;
  final fy = -bob;
  c.save();
  c.translate(0, bob);

  c.drawLine(const Offset(0, -16), Offset(-sw * 7, fy), _ps(Color.lerp(p.hose, Colors.black, 0.18)!, 4.0));

  if (m.banner) {
    c.drawLine(const Offset(7, -6), const Offset(7, -86), _ps(p.wood, 2.0));
    _flag(c, p, 7, -84, math.sin(t * 3 + m.seed) * 2.2);
  }

  if (guard <= 0) _shield(c, p, 6, -37);

  c.drawLine(const Offset(0, -16), Offset(sw * 7, fy), _ps(p.hose, 4.2));

  _torso(c, p, -37, -14, -24);

  const sh = Offset(1.5, -35);
  final rest = Offset(4.5 - sw * 2.5, -24);
  final dir = Offset(math.cos(ang), math.sin(ang));
  final hand = Offset.lerp(rest, sh + dir * 15, raise)!;
  final wa = _lerpD(_restAngle(m.wpn) + sw * 0.08, ang, raise);
  c.drawLine(sh, hand, _ps(p.sleeve, 3.6));
  _weapon(c, p, m.wpn, hand, wa);
  c.drawCircle(hand, 2.1, _pf(p.skin));

  _head(c, p, -41.5, great: false, hairV: m.coat, sw: sw);

  if (guard > 0) _shield(c, p, _lerpD(6, 10, guard), _lerpD(-37, -52, guard));
  c.restore();
}

void _drawRider(Canvas c, _Pal p, _Soldier m, double ph, double raise, double ang, double t, double guard) {
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

  leg(const Offset(14, -27), ph + math.pi, coatFar);
  leg(const Offset(-15, -27), ph, coatFar);
  final tail = Path()
    ..moveTo(-25, -42)
    ..quadraticBezierTo(-37, -38 + sw * 2, -34 + sw * 2, -17);
  c.drawPath(tail, _ps(coatDark, 3.4));

  c.drawOval(Rect.fromCenter(center: const Offset(0, -36), width: 56, height: 25), _pf(coat));

  leg(const Offset(14, -27), ph, coat);
  leg(const Offset(-15, -27), ph + math.pi, coat);

  if (p.faction == _Faction.mongol) {
    c.drawRRect(RRect.fromLTRBR(-11, -49, 11, -40, const Radius.circular(3)), _pf(p.cloth));
    c.drawRect(Rect.fromLTWH(-11, -42, 22, 2), _pf(p.trim));
  } else {
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
    c.drawRect(Rect.fromLTWH(-25.5, -25, 47, 2.2), _pf(p.trim.withOpacity(0.85)));
    if (p.faction == _Faction.crusader) {
      final cr = _pf(p.trim.withOpacity(0.9));
      c.drawRect(Rect.fromLTWH(-2, -44, 3, 19), cr);
      c.drawRect(Rect.fromLTWH(-9, -37, 17, 3), cr);
    }
  }

  c.drawRRect(RRect.fromLTRBR(-6, -50, 6, -45, const Radius.circular(2)), _pf(p.wood));

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

  c.save();
  c.translate(-1, -49);

  if (m.banner) {
    c.drawLine(const Offset(9, 10), const Offset(9, -82), _ps(p.wood, 2.0));
    _flag(c, p, 9, -80, math.sin(t * 3 + m.seed) * 2.2);
  }

  final legP = Path()
    ..moveTo(0, -1)
    ..lineTo(7, 9)
    ..lineTo(3, 20);
  c.drawPath(legP, _ps(p.hose, 4.4));
  c.drawRect(Rect.fromCenter(center: const Offset(4, 21), width: 6, height: 2.6), _pf(p.steelDark));

  if (m.wpn == _Wpn.lance || m.wpn == _Wpn.spear) {
    c.drawLine(const Offset(-4, -5), const Offset(-15, 6), _ps(p.wood, 2.6));
  }

  if (guard <= 0) _shield(c, p, 8.5, -26);
  _torso(c, p, -24, 2, -7);

  const sh = Offset(1.2, -21);
  const rein = Offset(8.5, -8);
  final dir = Offset(math.cos(ang), math.sin(ang));
  final hand = Offset.lerp(rein, sh + dir * 16, raise)!;
  final wa = _lerpD(_restAngle(m.wpn), ang, raise);
  if (raise < 0.95) {
    c.drawLine(rein, const Offset(37, -9), _ps(p.wood.withOpacity(1 - raise), 0.9));
  }
  c.drawLine(sh, hand, _ps(p.sleeve, 3.8));
  _weapon(c, p, m.wpn, hand, wa);
  c.drawCircle(hand, 2.2, _pf(p.skin));

  _head(c, p, -29.5, great: p.faction == _Faction.crusader, hairV: 0xFF3E3028, sw: sw);

  if (guard > 0) _shield(c, p, _lerpD(8.5, 11, guard), _lerpD(-26, -40, guard));

  c.restore();
  c.restore();
}

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