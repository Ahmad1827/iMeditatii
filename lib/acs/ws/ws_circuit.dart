// =============================================================================
// ELTH: THE CIRCUIT ON THE PAGE
//   The schematic is drawn from the task (resistors as boxes, sources,
//   capacitors, coils, ground); the asked currents carry an arrow that fixes
//   their direction. "solve": the student computes the asked values and the
//   page checks them against the solver; then "simulează" writes every
//   current and potential on the drawing. "design": the student picks a
//   component's value so the circuit meets a goal, and measures it.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/circuit.dart';
import '../engine/math_task.dart';
import 'ws_common.dart';

class CircuitWorkspace extends AcsWorkspace {
  const CircuitWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<CircuitWorkspace> createState() => _CircuitWorkspaceState();
}

class _CircuitWorkspaceState extends State<CircuitWorkspace> {
  Map get spec => widget.problem.spec;
  late final Circuit _base = Circuit.fromSpec(spec);
  late final List<Map> _ask = [for (final a in spec['ask'] as List? ?? const []) a as Map];
  late final Map? _design = spec['design'] as Map?;
  final Map<String, TextEditingController> _in = {};
  List<Check>? _checks;
  Solution? _shown; // the simulation on the drawing
  String? _reading;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    for (final a in _ask) {
      _in[a['q'] as String] = TextEditingController();
    }
    for (final v in (_design?['vars'] as List? ?? const [])) {
      _in[(v as Map)['name'] as String] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _in.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String t) {
    try {
      return MathTask.number(t);
    } catch (_) {
      return null;
    }
  }

  Circuit? _designed() {
    final vals = <String, double>{};
    for (final v in (_design?['vars'] as List? ?? const [])) {
      final name = (v as Map)['name'] as String;
      final x = _num(_in[name]!.text);
      if (x == null || x <= 0) return null;
      vals[name] = x;
    }
    return _base.withValues(vals);
  }

  void _verify() {
    final out = <Check>[];
    try {
      if (_design == null) {
        final s = _base.solve();
        for (final a in _ask) {
          final want = Circuit.quantity(s, a['q'] as String);
          final got = _num(_in[a['q']]!.text);
          final tol = (a['tol'] as num?)?.toDouble() ?? 0.01;
          final isPhase = (a['q'] as String).startsWith('ph');
          final ok = got != null && (isPhase ? ((got - want + 540) % 360 - 180).abs() <= 1.0 : (got - want).abs() <= tol * math.max(want.abs(), 1e-9) + 1e-9);
          out.add(Check('${a['label']}', ok, got == null ? 'scrie un număr' : (ok ? '' : _sign(got, want))));
        }
      } else {
        final c = _designed();
        final t = _design['target'] as Map;
        if (c == null) {
          out.add(const Check('valorile alese sunt numere pozitive', false));
        } else {
          final got = Circuit.quantity(c.solve(), t['q'] as String);
          final want = (t['value'] as num).toDouble();
          final tol = (t['tol'] as num?)?.toDouble() ?? 0.01;
          final abstol = (t['abstol'] as num?)?.toDouble();
          final ok = abstol != null ? (got - want).abs() <= abstol : (got - want).abs() <= tol * want.abs();
          out.add(Check('${t['label']}', ok, 'cu valorile tale: ${_f(got)} ${t['unit'] ?? ''}'));
        }
      }
    } on CircuitError catch (e) {
      out.add(Check('circuitul se poate rezolva', false, e.message));
    }
    final ok = out.every((c) => c.ok);
    setState(() {
      _checks = out;
      if (ok) _solved = true;
    });
    widget.onVerdict(ok);
  }

  String _sign(double got, double want) {
    if ((got + want).abs() <= 0.01 * want.abs() && want.abs() > 1e-9) return 'ai semnul schimbat: sensul e cel al săgeții de pe schemă';
    return 'nu e ${_f(got)}';
  }

  static String _f(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1000 || a < 0.01) return v.toStringAsExponential(3);
    return v.toStringAsFixed(a >= 100 ? 1 : a >= 10 ? 2 : 3);
  }

  void _simulate() {
    try {
      final c = _design == null ? _base : _designed();
      if (c == null) {
        setState(() => _reading = 'alege întâi valorile (numere pozitive)');
        return;
      }
      final s = c.solve();
      setState(() {
        _shown = s;
        if (_design != null) {
          final t = _design['target'] as Map;
          _reading = '${t['meter'] ?? t['label']}: ${_f(Circuit.quantity(s, t['q'] as String))} ${t['unit'] ?? ''}';
        }
      });
    } on CircuitError catch (e) {
      setState(() => _reading = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final ac = _base.omega > 0;
    final canSimulate = _design != null || _solved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          color: ink.bg,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (ac) Text('regim sinusoidal · ω = ${_f(_base.omega)} rad/s · valori efective', style: ink.mono(12.5, color: ink.muted)),
            LayoutBuilder(builder: (context, c) {
              final g = (spec['grid'] as List).cast<num>();
              final unit = math.min(c.maxWidth / (g[0] + 1), 64.0);
              return SizedBox(
                width: c.maxWidth,
                height: unit * (g[1] + 1),
                child: CustomPaint(painter: _SchemPainter(ink, _base, unit, {for (final a in _ask) (a['q'] as String).split('.').last: (a['q'] as String).split('.').first}, _shown, ac)),
              );
            }),
            const SizedBox(height: 10),
            if (_design == null)
              for (final a in _ask)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(width: 150, child: Text('${a['label']} =', style: ink.mono(14.5, weight: FontWeight.w700, color: ink.strong))),
                    AcsField(ink, _in[a['q']]!, width: 140, hint: 'de ex. 1.25', onSubmitted: (_) => _verify()),
                    if (a['unit'] != null) Text('  ${a['unit']}', style: ink.mono(14, color: ink.muted)),
                  ]),
                )
            else
              for (final v in (_design['vars'] as List).cast<Map>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(width: 150, child: Text('${v['label']} =', style: ink.mono(14.5, weight: FontWeight.w700, color: ink.strong))),
                    AcsField(ink, _in[v['name']]!, width: 140, onSubmitted: (_) => _simulate()),
                    if (v['unit'] != null) Text('  ${v['unit']}', style: ink.mono(14, color: ink.muted)),
                  ]),
                ),
            if (_reading != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('» $_reading', style: ink.mono(14, color: ink.accent, weight: FontWeight.w700))),
            if (!canSimulate) Text('După ce rezolvi, „simulează” scrie toate curenții pe schemă.', style: ink.mono(12, color: ink.dim)),
          ]),
        ),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check),
          AcsButton(ink, _design == null ? 'simulează' : 'măsoară', canSimulate ? _simulate : null, icon: Icons.bolt),
        ]),
        if (_checks != null) ...[const SizedBox(height: 12), ChecksView(ink, _checks!)],
      ],
    );
  }
}

class _SchemPainter extends CustomPainter {
  final AcsInk ink;
  final Circuit c;
  final double u;
  final Map<String, String> asked; // element -> I / U / P...
  final Solution? s;
  final bool ac;
  _SchemPainter(this.ink, this.c, this.u, this.asked, this.s, this.ac);

  Offset _p((int, int) g) => Offset((g.$1 + 0.5) * u, (g.$2 + 0.5) * u);

  void _text(Canvas cv, String t, Offset at, {Color? color, double size = 12, bool bold = false, bool center = true}) {
    final tp = TextPainter(text: TextSpan(text: t, style: ink.mono(size, color: color ?? ink.strong, weight: bold ? FontWeight.w700 : FontWeight.w400, height: 1)), textDirection: TextDirection.ltr)..layout();
    tp.paint(cv, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  static String _v(double v, String unit) {
    final a = v.abs();
    String n;
    if (a >= 1e6) {
      n = '${(v / 1e6).toStringAsFixed(a >= 1e7 ? 0 : 1)} M';
    } else if (a >= 1e3) {
      n = '${(v / 1e3).toStringAsFixed(a >= 1e4 ? 0 : 1)} k';
    } else if (a >= 1 || a == 0) {
      n = '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)} ';
    } else if (a >= 1e-3) {
      n = '${(v * 1e3).toStringAsFixed(a >= 1e-2 ? 0 : 1)} m';
    } else {
      n = '${(v * 1e6).toStringAsFixed(a >= 1e-5 ? 0 : 1)} µ';
    }
    return '$n$unit';
  }

  @override
  void paint(Canvas cv, Size size) {
    final wire = Paint()
      ..color = ink.strong
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final degree = <(int, int), int>{};
    for (final e in c.elems.where((e) => e.type != 'G')) {
      degree[e.a] = (degree[e.a] ?? 0) + 1;
      degree[e.b] = (degree[e.b] ?? 0) + 1;
    }
    for (final e in c.elems) {
      final a = _p(e.a), b = _p(e.b);
      if (e.type == 'G') {
        cv.drawLine(a, a + Offset(0, u * 0.3), wire);
        for (var k = 0; k < 3; k++) {
          final w = u * (0.3 - k * 0.09);
          final y = a.dy + u * (0.3 + k * 0.08);
          cv.drawLine(Offset(a.dx - w, y), Offset(a.dx + w, y), wire);
        }
        continue;
      }
      if (e.type == 'W') {
        cv.drawLine(a, b, wire);
        continue;
      }
      final mid = (a + b) / 2;
      final len = (b - a).distance;
      final dir = (b - a) / len;
      final nrm = Offset(-dir.dy, dir.dx);
      final half = math.min(u * 0.42, len * 0.3);
      cv.drawLine(a, mid - dir * half, wire);
      cv.drawLine(mid + dir * half, b, wire);
      final body = Paint()
        ..color = ink.strong
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      switch (e.type) {
        case 'R':
          final r = Rect.fromCenter(center: mid, width: dir.dx.abs() > 0.5 ? half * 2 : u * 0.32, height: dir.dx.abs() > 0.5 ? u * 0.32 : half * 2);
          cv.drawRect(r, Paint()..color = ink.bg);
          cv.drawRect(r, body);
        case 'V':
        case 'I':
          cv.drawCircle(mid, half * 0.85, Paint()..color = ink.bg);
          cv.drawCircle(mid, half * 0.85, body);
          if (e.type == 'V') {
            if (ac) {
              final path = Path();
              for (var k = 0; k <= 20; k++) {
                final t = k / 20;
                final p = mid + nrm * (half * 0.5 * (t * 2 - 1)) + dir * (half * 0.35 * math.sin(t * 2 * math.pi));
                k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
              }
              cv.drawPath(path, body);
            }
            _text(cv, '+', mid - dir * half * 0.45 + nrm * (ac ? half * 0.6 : 0), size: 13, bold: true);
            _text(cv, '-', mid + dir * half * 0.45 + nrm * (ac ? half * 0.6 : 0), size: 13, bold: true);
          } else {
            cv.drawLine(mid - dir * half * 0.5, mid + dir * half * 0.5, body);
            final tip = mid + dir * half * 0.55;
            cv.drawLine(tip, tip - dir * 6 + nrm * 5, body);
            cv.drawLine(tip, tip - dir * 6 - nrm * 5, body);
          }
        case 'C':
          cv.drawLine(mid - dir * 4 + nrm * half * 0.6, mid - dir * 4 - nrm * half * 0.6, body..strokeWidth = 3);
          cv.drawLine(mid + dir * 4 + nrm * half * 0.6, mid + dir * 4 - nrm * half * 0.6, body);
          cv.drawLine(a, mid - dir * 4, wire);
          cv.drawLine(mid + dir * 4, b, wire);
        case 'L':
          cv.drawRect(Rect.fromCenter(center: mid, width: half * 2 + 4, height: half * 2 + 4), Paint()..color = ink.bg);
          for (var k = 0; k < 4; k++) {
            final cc = mid - dir * half + dir * (half / 2) * (k + 0.5);
            cv.drawArc(Rect.fromCircle(center: cc, radius: half / 4), math.atan2(nrm.dy, nrm.dx) - math.pi, math.pi, false, body);
          }
          cv.drawLine(a, mid - dir * half, wire);
          cv.drawLine(mid + dir * half, b, wire);
      }
      final unit = switch (e.type) { 'R' => 'Ω', 'V' => 'V', 'I' => 'A', 'C' => 'F', 'L' => 'H', _ => '' };
      final label = '${e.name}${e.value == 0 && e.type == 'R' ? '' : ' ${_v(e.value, unit)}'}${(e.type == 'V' || e.type == 'I') && ac && e.phase != 0 ? ' ∠${e.phase.toStringAsFixed(0)}°' : ''}';
      if (dir.dx.abs() > 0.5) {
        _text(cv, label, mid - Offset(0, half + 14), size: 11.5, bold: true, color: ink.accent);
      } else {
        // beside a vertical element, to its right, read from its edge
        _text(cv, label, mid + Offset(half + 8, -6), size: 11.5, bold: true, color: ink.accent, center: false);
      }
      // the asked current's direction
      final ask = asked[e.name];
      final cur = s?.current[e.name];
      if (ask != null || cur != null) {
        final p0 = mid - dir * (half + 16);
        final arrow = Paint()
          ..color = ink.bad
          ..strokeWidth = 2;
        final start = p0 - dir * 10;
        cv.drawLine(start, p0, arrow);
        cv.drawLine(p0, p0 - dir * 6 + nrm * 4, arrow);
        cv.drawLine(p0, p0 - dir * 6 - nrm * 4, arrow);
        if (ask != null && s == null) _text(cv, ask == 'U' ? 'U' : 'I', start - nrm * 10, size: 11, color: ink.bad, bold: true);
        if (cur != null) {
          final value = ac ? '${_v(cur.abs, 'A')} ∠${cur.deg.toStringAsFixed(0)}°' : _v(cur.re, 'A');
          _text(cv, value, start - nrm * 12 - dir * 6, size: 10.5, color: ink.bad, bold: true);
        }
      }
    }
    for (final kv in degree.entries) {
      if (kv.value > 2) cv.drawCircle(_p(kv.key), 4, Paint()..color = ink.strong);
    }
    // potentials of the nodes, after a simulation (DC)
    if (s != null && !ac) {
      final seen = <String>{};
      for (final kv in degree.entries) {
        if (kv.value <= 2) continue;
        final v = s!.potential[kv.key];
        if (v == null) continue;
        final t = 'φ=${_v(v.re, 'V')}';
        if (!seen.add('${kv.key}')) continue;
        _text(cv, t, _p(kv.key) + const Offset(6, -16), size: 10, color: ink.muted, center: false);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SchemPainter o) => true;
}
