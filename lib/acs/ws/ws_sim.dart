// =============================================================================
// FIZICĂ: THE EXPERIMENT, RUN WITH THE STUDENT'S NUMBERS
//   The student computes the asked values; "lansează" plays the experiment:
//   the ball thrown with their speed goes in the hoop or misses, the block
//   slides while their predicted time is marked, a ghost cart moves with the
//   velocity they predicted beside the real one, a ghost mass swings with
//   their period. Verifică compares the values (1%).
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/math_task.dart';
import '../engine/physics.dart';
import 'ws_common.dart';

class SimWorkspace extends AcsWorkspace {
  const SimWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<SimWorkspace> createState() => _SimWorkspaceState();
}

class _SimWorkspaceState extends State<SimWorkspace> with SingleTickerProviderStateMixin {
  late final PhysTask _t = PhysTask.fromSpec(widget.problem.spec);
  final Map<String, TextEditingController> _in = {};
  late final AnimationController _anim = AnimationController(vsync: this);
  Map<String, double> _mine = const {};
  double _duration = 3;
  List<Check>? _checks;
  bool _ran = false;

  @override
  void initState() {
    super.initState();
    for (final f in _t.fields) {
      _in[f['name'] as String] = TextEditingController();
    }
    _anim.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in _in.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> _values() {
    final out = <String, double>{};
    for (final e in _in.entries) {
      try {
        out[e.key] = MathTask.number(e.value.text);
      } catch (_) {
        // empty or not a number
      }
    }
    return out;
  }

  void _run() {
    final mine = _values();
    final d = _t.duration(mine);
    setState(() {
      _mine = mine;
      _duration = d;
      _ran = true;
    });
    final reduce = MediaQuery.of(context).disableAnimations;
    _anim.duration = Duration(milliseconds: (math.max(d, 0.5) * 1000 * (_t.sim == 'collision' ? 1 : 1)).round().clamp(600, 9000));
    if (reduce) {
      _anim.value = 1;
    } else {
      _anim.forward(from: 0);
    }
  }

  void _verify() {
    final mine = _values();
    final want = _t.answers();
    final out = <Check>[];
    for (final f in _t.fields) {
      final n = f['name'] as String;
      final got = mine[n];
      final ok = got != null && _t.close(got, want[n]!);
      out.add(Check('${f['label']}', ok, got == null ? 'scrie un număr' : (ok ? '' : 'nu e ${_fmt(got)}')));
    }
    setState(() => _checks = out);
    widget.onVerdict(out.every((c) => c.ok));
  }

  static String _fmt(double v) => v.abs() >= 100 ? v.toStringAsFixed(1) : v.toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final simT = _anim.value * _duration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          color: ink.bg,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: widget.narrow ? 1.3 : 1.8,
              child: CustomPaint(painter: _SimPainter(ink, _t, simT, _ran ? _mine : const {}, _ran)),
            ),
            const SizedBox(height: 6),
            Text(_ran ? 't = ${simT.toStringAsFixed(2)} s${_status(simT)}' : 'Calculează, apoi apasă „lansează” ca să vezi experimentul cu valorile tale.', style: ink.mono(13, color: ink.muted)),
            const SizedBox(height: 10),
            for (final f in _t.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(width: 150, child: Text('${f['label']} =', style: ink.mono(14.5, weight: FontWeight.w700, color: ink.strong))),
                  AcsField(ink, _in[f['name']]!, width: 140, hint: 'de ex. 2.5', onSubmitted: (_) => _run()),
                  if (f['unit'] != null) Text('  ${f['unit']}', style: ink.mono(14, color: ink.muted)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'lansează', _run, icon: Icons.play_arrow),
          AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check),
        ]),
        if (_checks != null) ...[const SizedBox(height: 12), ChecksView(ink, _checks!)],
      ],
    );
  }

  String _status(double t) {
    final done = _anim.value >= 1;
    switch (_t.sim) {
      case 'projectile':
        final v0 = _mine['v0'];
        if (v0 == null || !done) return '';
        return _t.hits(v0) ? '  ·  coș! mingea trece prin cerc' : '  ·  ratat: mingea nu trece prin cerc';
      case 'friction':
        final mu = _mine['mu'];
        if (mu == null) return '';
        return _t.slid(_duration, mu: mu) == 0 ? '  ·  corpul stă pe loc' : '  ·  corpul alunecă';
      case 'incline':
        return '  ·  ajunge jos la ${_t.answers()['t']!.toStringAsFixed(2)} s';
      default:
        return '';
    }
  }
}

class _SimPainter extends CustomPainter {
  final AcsInk ink;
  final PhysTask t;
  final double time;
  final Map<String, double> mine;
  final bool ran;
  _SimPainter(this.ink, this.t, this.time, this.mine, this.ran);

  void _text(Canvas c, String s, Offset at, {Color? color, double size = 11.5}) {
    final tp = TextPainter(text: TextSpan(text: s, style: ink.mono(size, color: color ?? ink.muted, height: 1)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, at);
  }

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = ink.panel);
    final real = Paint()..color = ink.accent;
    final ghost = Paint()
      ..color = ink.warn
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final line = Paint()
      ..color = ink.strong
      ..strokeWidth = 2;
    switch (t.sim) {
      case 'projectile':
      case 'range':
        final isRange = t.sim == 'range';
        final a = t.answers();
        final xMax = isRange ? a['R']! * 1.15 : t.p['d']! * 1.25;
        final yMax = isRange ? a['R']! * 0.45 : math.max(t.p['h0'] ?? 0, t.p['ht'] ?? 0) * 1.8 + 1;
        final sc = math.min(size.width / xMax, (size.height - 20) / yMax);
        Offset at(double x, double y) => Offset(10 + x * sc, size.height - 14 - y * sc);
        c.drawLine(at(0, 0), at(xMax, 0), line);
        if (!isRange) {
          final h0 = t.p['h0'] ?? 0;
          if (h0 > 0) c.drawLine(at(0, 0), at(0, h0), line..strokeWidth = 4);
          final d = t.p['d']!, ht = t.p['ht'] ?? 0;
          if (ht > 0) c.drawLine(at(d + 0.3, 0), at(d + 0.3, ht + 0.4), Paint()..color = ink.muted..strokeWidth = 3);
          c.drawOval(Rect.fromCenter(center: at(d, ht), width: 0.45 * sc, height: 0.12 * sc), Paint()..color = ink.bad..style = PaintingStyle.stroke..strokeWidth = 3);
          _text(c, 'ținta: ${d.toStringAsFixed(1)} m, ${ht.toStringAsFixed(2)} m', at(d - 1.2, ht + 0.7));
        } else {
          _text(c, 'v₀ = ${t.p['v0']!.toStringAsFixed(0)} m/s', at(0.2, yMax * 0.85));
        }
        if (ran) {
          final v0 = isRange ? null : mine['v0'];
          final ang = isRange ? (mine['alpha'] ?? 45) : null;
          if (isRange || v0 != null) {
            final path = Path();
            const n = 80;
            for (var k = 0; k <= n; k++) {
              final tt = time * k / n;
              final (x, y) = t.ball(tt, v0: v0, angleDeg: ang);
              final o = at(x, math.max(y, 0));
              k == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
            }
            c.drawPath(path, ghost);
            final (x, y) = t.ball(time, v0: v0, angleDeg: ang);
            c.drawCircle(at(x, math.max(y, 0)), 7, real);
            if (isRange) _text(c, 'bătaia: ${x.toStringAsFixed(1)} m', at(x - 1, 1.5), color: ink.accent);
          }
        }
      case 'incline':
      case 'friction':
        final th = PhysTask.rad(t.p['angle']!);
        final len = t.p['L'] ?? 3;
        final w = size.width * 0.8, h = w * math.tan(th);
        final sc = math.min(1.0, (size.height - 30) / h);
        final base = Offset(size.width * 0.1, size.height - 14);
        final top = base + Offset(0, -h * sc);
        final bottom = base + Offset(w * sc, 0);
        c.drawPath(Path()..moveTo(top.dx, top.dy)..lineTo(bottom.dx, bottom.dy)..lineTo(base.dx, base.dy)..close(), Paint()..color = ink.hover);
        c.drawLine(top, bottom, line);
        final dir = (bottom - top) / (bottom - top).distance;
        final slope = (bottom - top).distance;
        final s = ran ? (t.sim == 'friction' ? t.slid(time, mu: mine['mu']) : t.slid(time)) : 0.0;
        final pos = top + dir * (12 + (slope - 40) * s / len);
        c.save();
        c.translate(pos.dx, pos.dy);
        c.rotate(th);
        c.drawRect(const Rect.fromLTWH(-14, -26, 28, 26), real);
        c.restore();
        _text(c, '${t.p['angle']!.toStringAsFixed(0)}°', base + const Offset(8, -18));
        if (t.sim == 'incline' && ran && mine['t'] != null) {
          final mark = time >= mine['t']! ? 'predicția ta (${mine['t']!.toStringAsFixed(2)} s): a trecut' : 'predicția ta: ${mine['t']!.toStringAsFixed(2)} s';
          _text(c, mark, Offset(size.width * 0.45, 10), color: ink.warn);
        }
      case 'collision':
        final after = ran ? mine : const <String, double>{};
        final truth = t.answers();
        final (r1, r2) = t.carts(time, truth);
        final sc = size.width / 6;
        final y = size.height * 0.62;
        Offset at(double x) => Offset(size.width / 2 + x * sc, y);
        c.drawLine(Offset(0, y + 14), Offset(size.width, y + 14), line);
        void cart(double x, Color col, String label, bool isGhost) {
          final r = Rect.fromCenter(center: at(x), width: 56, height: 26);
          if (isGhost) {
            c.drawRect(r.shift(const Offset(0, -40)), ghost);
            _text(c, label, r.shift(const Offset(0, -40)).topLeft + const Offset(4, 6), color: ink.warn, size: 11);
          } else {
            c.drawRect(r, Paint()..color = col);
            _text(c, label, r.topLeft + const Offset(4, 6), color: ink.bg, size: 11);
          }
        }

        cart(r1 - 0.25, ink.accent, 'm₁=${t.p['m1']!.toStringAsFixed(0)}', false);
        cart(r2 + 0.25, ink.strong, 'm₂=${t.p['m2']!.toStringAsFixed(0)}', false);
        if (ran && time > 1.5 && after.isNotEmpty) {
          final (g1, g2) = t.carts(time, after);
          cart(g1 - 0.25, ink.warn, 'tu', true);
          cart(g2 + 0.25, ink.warn, 'tu', true);
        }
        _text(c, 'sus, punctat: căruțele mișcate cu vitezele tale după ciocnire', const Offset(8, 8), color: ink.warn);
      case 'spring':
      case 'pendulum':
        final a = t.answers();
        final period = a['T']!;
        final myPeriod = mine['T'];
        void draw(double phase, Color col, bool isGhost, double cx) {
          if (t.sim == 'spring') {
            final x = cx + phase * size.width * 0.12;
            final y = size.height / 2;
            final path = Path()..moveTo(cx - size.width * 0.3, y);
            const coils = 12;
            for (var k = 1; k <= coils * 2; k++) {
              final px = cx - size.width * 0.3 + (x - 20 - (cx - size.width * 0.3)) * k / (coils * 2);
              path.lineTo(px, y + (k.isOdd ? -10 : 10));
            }
            path.lineTo(x - 20, y);
            c.drawPath(path, Paint()..color = isGhost ? ink.warn : ink.muted..style = PaintingStyle.stroke..strokeWidth = 1.6);
            final r = Rect.fromCenter(center: Offset(x, y), width: 40, height: 40);
            isGhost ? c.drawRect(r.shift(const Offset(0, 56)), ghost) : c.drawRect(r, Paint()..color = col);
          } else {
            final pivot = Offset(cx, 16);
            final ang = phase * 0.35;
            final l = size.height * 0.7;
            final bob = pivot + Offset(math.sin(ang) * l, math.cos(ang) * l);
            c.drawLine(pivot, bob, Paint()..color = isGhost ? ink.warn : ink.muted..strokeWidth = 1.6);
            isGhost ? c.drawCircle(bob, 13, ghost) : c.drawCircle(bob, 13, Paint()..color = col);
          }
        }

        final cx = t.sim == 'spring' ? size.width * 0.55 : size.width * 0.35;
        c.drawLine(Offset(t.sim == 'spring' ? size.width * 0.25 : cx - 40, t.sim == 'spring' ? size.height / 2 - 30 : 16),
            Offset(t.sim == 'spring' ? size.width * 0.25 : cx + 40, t.sim == 'spring' ? size.height / 2 + 30 : 16), line..strokeWidth = 4);
        draw(t.swing(ran ? time : 0, period), ink.accent, false, cx);
        if (ran && myPeriod != null && myPeriod > 0) {
          draw(t.swing(time, myPeriod), ink.warn, true, t.sim == 'spring' ? cx : size.width * 0.68);
          _text(c, 'punctat: cu perioada ta (${myPeriod.toStringAsFixed(3)} s)', const Offset(8, 8), color: ink.warn);
        }
      case 'atwood':
        final acc = t.answers()['a']!;
        final pulley = Offset(size.width / 2, 30);
        c.drawCircle(pulley, 22, Paint()..color = ink.muted..style = PaintingStyle.stroke..strokeWidth = 3);
        final scale = (size.height - 120) / 1.4;
        void masses(double drop, bool isGhost) {
          final yl = 70 + 0.6 * scale + drop * scale, yr = 70 + 0.6 * scale - drop * scale;
          final xl = pulley.dx - 22 + (isGhost ? -70 : 0), xr = pulley.dx + 22 + (isGhost ? 70 : 0);
          final rope = Paint()..color = isGhost ? ink.warn : ink.strong..strokeWidth = 1.5;
          if (!isGhost) {
            c.drawLine(Offset(xl, pulley.dy), Offset(xl, yl), rope);
            c.drawLine(Offset(xr, pulley.dy), Offset(xr, yr), rope);
          }
          final rl = Rect.fromCenter(center: Offset(xl, yl + 18), width: 34, height: 36), rr = Rect.fromCenter(center: Offset(xr, yr + 14), width: 28, height: 28);
          if (isGhost) {
            c.drawRect(rl, ghost);
            c.drawRect(rr, ghost);
          } else {
            c.drawRect(rl, Paint()..color = ink.accent);
            c.drawRect(rr, Paint()..color = ink.strong);
            _text(c, 'm₁', rl.topLeft + const Offset(8, 10), color: ink.bg);
            _text(c, 'm₂', rr.topLeft + const Offset(4, 8), color: ink.bg);
          }
        }

        masses(ran ? t.atwood(time, acc) : 0, false);
        if (ran && mine['a'] != null) {
          masses(t.atwood(time, mine['a']!), true);
          _text(c, 'punctat: cu accelerația ta', const Offset(8, 8), color: ink.warn);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _SimPainter o) => true;
}
