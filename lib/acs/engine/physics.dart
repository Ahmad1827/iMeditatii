// =============================================================================
// MECHANICS, SIMULATED (Fizică)
//   Each kind of experiment knows its true answers and where everything is at
//   time t — with the true values, or with the student's (a ball thrown with
//   their speed, a ghost cart moving with their velocity). Pure Dart.
// =============================================================================

import 'dart:math' as math;

class PhysTask {
  final String sim; // projectile incline collision spring pendulum atwood
  final Map<String, double> p; // the experiment's data
  final List<Map> fields; // what the student gives: name, label, unit
  final double tol;
  PhysTask(this.sim, this.p, this.fields, this.tol);

  factory PhysTask.fromSpec(Map s) => PhysTask(
        s['sim'] as String,
        {for (final e in (s['params'] as Map).entries) '${e.key}': (e.value as num).toDouble()},
        [for (final f in s['fields'] as List) f as Map],
        (s['tol'] as num?)?.toDouble() ?? 0.01,
      );

  double get g => p['g'] ?? 9.81;
  static double rad(double deg) => deg * math.pi / 180;

  /// The right value of each field.
  Map<String, double> answers() {
    switch (sim) {
      case 'projectile':
        final a = rad(p['angle'] ?? 0), h0 = p['h0'] ?? 0, d = p['d']!, ht = p['ht'] ?? 0;
        // y(d) = h0 + d tan a - g d² / (2 v² cos² a) = ht
        final v0 = math.sqrt(g * d * d / (2 * math.cos(a) * math.cos(a) * (h0 + d * math.tan(a) - ht)));
        final t = d / (v0 * math.cos(a));
        return {'v0': v0, 't': t};
      case 'range':
        final v = p['v0']!;
        return {'alpha': 45, 'R': v * v / g};
      case 'incline':
        final th = rad(p['angle']!), mu = p['mu'] ?? 0, len = p['L']!;
        final acc = g * (math.sin(th) - mu * math.cos(th));
        return {'a': acc, 't': math.sqrt(2 * len / acc), 'v': math.sqrt(2 * acc * len)};
      case 'friction':
        return {'mu': math.tan(rad(p['angle']!))};
      case 'collision':
        final m1 = p['m1']!, m2 = p['m2']!, v1 = p['v1']!, v2 = p['v2']!;
        if ((p['elastic'] ?? 0) == 0) {
          final v = (m1 * v1 + m2 * v2) / (m1 + m2);
          final lost = 0.5 * m1 * v1 * v1 + 0.5 * m2 * v2 * v2 - 0.5 * (m1 + m2) * v * v;
          return {'v': v, 'Q': lost};
        }
        return {'v1p': ((m1 - m2) * v1 + 2 * m2 * v2) / (m1 + m2), 'v2p': ((m2 - m1) * v2 + 2 * m1 * v1) / (m1 + m2)};
      case 'spring':
        final w = math.sqrt(p['k']! / p['m']!);
        return {'T': 2 * math.pi / w, 'vmax': w * p['A']!};
      case 'pendulum':
        return {'T': 2 * math.pi * math.sqrt(p['L']! / g)};
      case 'atwood':
        final m1 = p['m1']!, m2 = p['m2']!;
        return {'a': (m1 - m2) * g / (m1 + m2), 'T': 2 * m1 * m2 * g / (m1 + m2)};
    }
    throw ArgumentError('simulare necunoscută $sim');
  }

  bool close(double got, double want) => (got - want).abs() <= tol * math.max(want.abs(), 1e-6) + 1e-9;

  /// How long the animation runs (seconds of simulated time).
  double duration(Map<String, double> mine) {
    final a = answers();
    switch (sim) {
      case 'projectile':
        final v0 = mine['v0'] ?? a['v0']!;
        final ang = rad(p['angle'] ?? 0), h0 = p['h0'] ?? 0;
        final vy = v0 * math.sin(ang);
        // until it lands (y = 0), or passes the target a little
        final land = (vy + math.sqrt(vy * vy + 2 * g * h0)) / g;
        return math.min(land, 6);
      case 'range':
        final v0 = p['v0']!, ang = rad(mine['alpha'] ?? 45);
        return math.max(0.2, 2 * v0 * math.sin(ang) / g);
      case 'incline':
        return math.max(a['t']!, mine['t'] ?? 0) + 0.6;
      case 'friction':
        return 3;
      case 'collision':
        return 4;
      case 'spring':
      case 'pendulum':
        return 3 * a['T']!;
      case 'atwood':
        return math.sqrt(2 * 1.2 / a['a']!.abs());
    }
    return 3;
  }

  /// A projectile's position at t with launch speed [v0] (or angle in degrees for 'range').
  (double, double) ball(double t, {double? v0, double? angleDeg}) {
    final speed = v0 ?? p['v0'] ?? answers()['v0']!;
    final ang = rad(angleDeg ?? p['angle'] ?? 0);
    return (speed * math.cos(ang) * t, (p['h0'] ?? 0) + speed * math.sin(ang) * t - g * t * t / 2);
  }

  /// Does the ball thrown at [v0] go through the target (a hoop of radius 0.25 m)?
  bool hits(double v0) {
    final ang = rad(p['angle'] ?? 0), d = p['d']!, ht = p['ht'] ?? 0;
    final t = d / (v0 * math.cos(ang));
    final y = (p['h0'] ?? 0) + v0 * math.sin(ang) * t - g * t * t / 2;
    return (y - ht).abs() <= (p['hoop'] ?? 0.12);
  }

  /// Distance slid along the incline at t (stops at the bottom); with a static friction [mu] for 'friction'.
  double slid(double t, {double? mu}) {
    final th = rad(p['angle']!);
    if (sim == 'friction') {
      final m = mu ?? 0;
      if (m >= math.tan(th)) return 0;
      final acc = g * (math.sin(th) - m * math.cos(th));
      return math.min(p['L'] ?? 3, acc * t * t / 2);
    }
    final acc = answers()['a']!;
    return math.min(p['L']!, acc * t * t / 2);
  }

  /// The carts' positions at t (they meet at t = 1.5); after, with velocities [after] (v or v1p, v2p).
  (double, double) carts(double t, Map<String, double> after) {
    final v1 = p['v1']!, v2 = p['v2']!;
    const tc = 1.5;
    // they start so that they meet at x = 0 at t = tc
    final x1c = -0.3, x2c = 0.3;
    if (t <= tc) return (x1c + v1 * (t - tc), x2c + v2 * (t - tc));
    final dt = t - tc;
    if ((p['elastic'] ?? 0) == 0) {
      final v = after['v'] ?? 0;
      return (x1c + v * dt, x2c + v * dt);
    }
    return (x1c + (after['v1p'] ?? 0) * dt, x2c + (after['v2p'] ?? 0) * dt);
  }

  /// An oscillation's displacement (spring: metres; pendulum: degrees of swing) with period [period].
  double swing(double t, double period) => math.cos(2 * math.pi * t / period);

  /// How far the heavier mass of the Atwood machine has gone down at t, with acceleration [acc].
  double atwood(double t, double acc) => math.min(1.2, acc * t * t / 2);
}
