// =============================================================================
// CIRCUITS, SOLVED (ELTH)
//   A schematic on a grid: resistors, sources of voltage and current,
//   capacitors, coils, wires and a ground. Modified nodal analysis gives
//   every node's potential and every element's current, in direct current
//   or in sinusoidal steady state (complex amplitudes at ω, values rms).
//   An element's current is counted from its end a to its end b; a voltage
//   source has + at a.
// =============================================================================

import 'dart:math' as math;

class Cx {
  final double re, im;
  const Cx(this.re, [this.im = 0]);
  static const zero = Cx(0), one = Cx(1);
  factory Cx.polar(double r, double deg) => Cx(r * math.cos(deg * math.pi / 180), r * math.sin(deg * math.pi / 180));
  Cx operator +(Cx o) => Cx(re + o.re, im + o.im);
  Cx operator -(Cx o) => Cx(re - o.re, im - o.im);
  Cx operator -() => Cx(-re, -im);
  Cx operator *(Cx o) => Cx(re * o.re - im * o.im, re * o.im + im * o.re);
  Cx operator /(Cx o) {
    final d = o.re * o.re + o.im * o.im;
    return Cx((re * o.re + im * o.im) / d, (im * o.re - re * o.im) / d);
  }

  double get abs => math.sqrt(re * re + im * im);
  double get deg => math.atan2(im, re) * 180 / math.pi;
}

class CircuitError implements Exception {
  final String message;
  CircuitError(this.message);
  @override
  String toString() => message;
}

class Elem {
  final String type; // R V I C L W G
  final String name;
  final (int, int) a, b;
  final double value; // ohm, V (rms in AC), A, F, H
  final double phase; // sources, degrees
  Elem(this.type, this.name, this.a, this.b, this.value, this.phase);

  factory Elem.fromJson(Map j) {
    final a = (j['a'] as List).cast<num>();
    final b = (j['b'] as List? ?? j['a'] as List).cast<num>();
    return Elem(j['t'] as String, j['n'] as String? ?? '', (a[0].toInt(), a[1].toInt()), (b[0].toInt(), b[1].toInt()), (j['v'] as num?)?.toDouble() ?? 0,
        (j['ph'] as num?)?.toDouble() ?? 0);
  }

  Elem withValue(double v) => Elem(type, name, a, b, v, phase);
}

class Solution {
  final Map<(int, int), Cx> potential; // every grid point that is a node
  final Map<String, Cx> current; // a -> b, through each element
  final Map<String, Cx> voltage; // V(a) - V(b)
  Solution(this.potential, this.current, this.voltage);

  double power(String n) => (voltage[n]! * Cx(current[n]!.re, -current[n]!.im)).re; // absorbed, P = Re(U I*)
}

class Circuit {
  final List<Elem> elems;
  final double omega; // 0: direct current
  Circuit(this.elems, this.omega);

  factory Circuit.fromSpec(Map s) => Circuit([for (final e in s['elems'] as List) Elem.fromJson(e as Map)], (s['omega'] as num?)?.toDouble() ?? 0);

  Circuit withValues(Map<String, double> v) => Circuit([for (final e in elems) v.containsKey(e.name) ? e.withValue(v[e.name]!) : e], omega);

  Elem byName(String n) => elems.firstWhere((e) => e.name == n, orElse: () => throw CircuitError('nu există elementul $n'));

  Solution solve() {
    // nodes: grid points joined by wires are one node
    final parent = <(int, int), (int, int)>{};
    (int, int) find((int, int) p) {
      parent.putIfAbsent(p, () => p);
      var r = p;
      while (parent[r] != r) {
        r = parent[r]!;
      }
      parent[p] = r;
      return r;
    }

    for (final e in elems) {
      find(e.a);
      find(e.b);
      if (e.type == 'W') parent[find(e.a)] = find(e.b);
    }
    final ground = elems.where((e) => e.type == 'G').map((e) => find(e.a)).toSet();
    final roots = {for (final p in parent.keys) find(p)}.toList();
    final gnd = ground.isNotEmpty ? ground.first : roots.first;
    final idx = <(int, int), int>{};
    for (final r in roots) {
      if (r != gnd) idx[r] = idx.length;
    }
    final n = idx.length;
    // DC: a coil is a 0 V source, a capacitor is open
    final vsrc = [
      for (final e in elems)
        if (e.type == 'V' || (e.type == 'L' && omega == 0)) e,
    ];
    final size = n + vsrc.length;
    final a = List.generate(size, (_) => List.filled(size, Cx.zero));
    final rhs = List.filled(size, Cx.zero);
    int? node((int, int) p) => idx[find(p)];
    void stamp(int? i, int? j, Cx y) {
      if (i != null) a[i][i] = a[i][i] + y;
      if (j != null) a[j][j] = a[j][j] + y;
      if (i != null && j != null) {
        a[i][j] = a[i][j] - y;
        a[j][i] = a[j][i] - y;
      }
    }

    Cx adm(Elem e) => switch (e.type) {
          'R' => Cx(1 / e.value),
          'C' => Cx(0, omega * e.value),
          'L' => Cx.one / Cx(0, omega * e.value),
          _ => Cx.zero,
        };
    for (final e in elems) {
      final i = node(e.a), j = node(e.b);
      switch (e.type) {
        case 'R':
          if (e.value <= 0) throw CircuitError('${e.name}: rezistența trebuie să fie pozitivă');
          stamp(i, j, adm(e));
        case 'C':
          if (omega > 0) stamp(i, j, adm(e));
        case 'L':
          if (omega > 0) stamp(i, j, adm(e));
        case 'I':
          final cur = Cx.polar(e.value, e.phase);
          if (i != null) rhs[i] = rhs[i] - cur;
          if (j != null) rhs[j] = rhs[j] + cur;
      }
    }
    for (var k = 0; k < vsrc.length; k++) {
      final e = vsrc[k];
      final i = node(e.a), j = node(e.b), r = n + k;
      if (i != null) {
        a[i][r] = a[i][r] + Cx.one;
        a[r][i] = a[r][i] + Cx.one;
      }
      if (j != null) {
        a[j][r] = a[j][r] - Cx.one;
        a[r][j] = a[r][j] - Cx.one;
      }
      rhs[r] = e.type == 'V' ? Cx.polar(e.value, e.phase) : Cx.zero;
    }
    final x = _gauss(a, rhs);
    Cx pot((int, int) p) {
      final i = node(p);
      return i == null ? Cx.zero : x[i];
    }

    final potential = {for (final p in parent.keys) p: pot(p)};
    final current = <String, Cx>{}, voltage = <String, Cx>{};
    for (final e in elems) {
      if (e.type == 'G' || e.name.isEmpty) continue;
      final u = pot(e.a) - pot(e.b);
      voltage[e.name] = u;
      final k = vsrc.indexOf(e);
      current[e.name] = switch (e.type) {
        'I' => Cx.polar(e.value, e.phase),
        _ when k >= 0 => x[n + k],
        'C' when omega == 0 => Cx.zero,
        'W' => Cx.zero,
        _ => u * adm(e),
      };
    }
    return Solution(potential, current, voltage);
  }

  static List<Cx> _gauss(List<List<Cx>> a, List<Cx> b) {
    final n = b.length;
    for (var k = 0; k < n; k++) {
      var p = k;
      for (var i = k + 1; i < n; i++) {
        if (a[i][k].abs > a[p][k].abs) p = i;
      }
      if (a[p][k].abs < 1e-12) throw CircuitError('circuitul nu are o soluție unică (o buclă de surse sau un nod izolat)');
      final t = a[p];
      a[p] = a[k];
      a[k] = t;
      final tb = b[p];
      b[p] = b[k];
      b[k] = tb;
      for (var i = k + 1; i < n; i++) {
        final f = a[i][k] / a[k][k];
        if (f.abs == 0) continue;
        for (var j = k; j < n; j++) {
          a[i][j] = a[i][j] - f * a[k][j];
        }
        b[i] = b[i] - f * b[k];
      }
    }
    final x = List.filled(n, Cx.zero);
    for (var i = n - 1; i >= 0; i--) {
      var s = b[i];
      for (var j = i + 1; j < n; j++) {
        s = s - a[i][j] * x[j];
      }
      x[i] = s / a[i][i];
    }
    return x;
  }

  /// A quantity asked by a task: I.R2, U.R1, P.R3, |I|.L1, phi.I1 (degrees), Re.U.C1...
  static double quantity(Solution s, String q) {
    final parts = q.split('.');
    final kind = parts[0];
    final name = parts.last;
    Cx v(String k) => (k == 'I' ? s.current : s.voltage)[name] ?? (throw CircuitError('nu există $name'));
    return switch (kind) {
      'I' => v('I').re,
      'U' => v('U').re,
      'absI' => v('I').abs,
      'absU' => v('U').abs,
      'phI' => v('I').deg,
      'phU' => v('U').deg,
      'P' => s.power(name),
      'Q' => (s.voltage[name]! * Cx(s.current[name]!.re, -s.current[name]!.im)).im,
      _ => throw CircuitError('mărime necunoscută $kind'),
    };
  }
}
