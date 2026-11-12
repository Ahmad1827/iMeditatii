// =============================================================================
// EGC: 2D TRANSFORMATIONS IN HOMOGENEOUS COORDINATES
//   Points are column vectors (x, y, 1), as in the course, so a sequence of
//   transformations applied one after another is the product of their
//   matrices written right to left: first T1, then T2 is M = T2 · T1.
// =============================================================================

import 'dart:math' as math;

/// A 3x3 matrix, row by row.
class Mat3 {
  final List<double> m;
  const Mat3(this.m);

  static const identity = Mat3([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  factory Mat3.translate(double tx, double ty) => Mat3([1, 0, tx, 0, 1, ty, 0, 0, 1]);
  factory Mat3.scale(double sx, double sy) => Mat3([sx, 0, 0, 0, sy, 0, 0, 0, 1]);
  factory Mat3.shear(double fx, double fy) => Mat3([1, fx, 0, fy, 1, 0, 0, 0, 1]);

  /// Counter-clockwise, in degrees, about the origin.
  factory Mat3.rotate(double deg) {
    final r = deg * math.pi / 180;
    final c = math.cos(r), s = math.sin(r);
    return Mat3([c, -s, 0, s, c, 0, 0, 0, 1]);
  }

  /// this · other: [other] is applied first.
  Mat3 operator *(Mat3 o) => Mat3([
        for (var i = 0; i < 3; i++)
          for (var j = 0; j < 3; j++) m[i * 3] * o.m[j] + m[i * 3 + 1] * o.m[3 + j] + m[i * 3 + 2] * o.m[6 + j],
      ]);

  (double, double) apply(double x, double y) => (m[0] * x + m[1] * y + m[2], m[3] * x + m[4] * y + m[5]);

  bool closeTo(Mat3 o, [double eps = 1e-6]) {
    for (var i = 0; i < 9; i++) {
      if ((m[i] - o.m[i]).abs() > eps * math.max(1.0, o.m[i].abs())) return false;
    }
    return true;
  }
}

/// One step of the student's list: T(a, b), R(a), S(a, b) or F(a, b).
class Op {
  final String kind;
  final double a, b;
  const Op(this.kind, this.a, [this.b = 0]);

  Mat3 get matrix => switch (kind) {
        'T' => Mat3.translate(a, b),
        'R' => Mat3.rotate(a),
        'S' => Mat3.scale(a, b),
        _ => Mat3.shear(a, b),
      };

  static String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String get text => kind == 'R' ? 'R(${_n(a)}°)' : '$kind(${_n(a)}, ${_n(b)})';

  static const names = {'T': 'translație', 'R': 'rotație', 'S': 'scalare', 'F': 'forfecare'};

  Map<String, dynamic> toJson() => {'op': kind, 'a': a, 'b': b};
  factory Op.fromJson(Map j) => Op('${j['op']}', (j['a'] as num).toDouble(), (j['b'] as num? ?? 0).toDouble());
}

/// The matrix of [ops] applied in order (the first one first).
Mat3 compose(List<Op> ops) => ops.fold(Mat3.identity, (m, op) => op.matrix * m);

/// "M = T(2, 1) · R(90°) · T(-2, -1)": the product, as the course writes it.
String productText(List<Op> ops) => ops.isEmpty ? 'M = I' : 'M = ${ops.reversed.map((o) => o.text).join(' · ')}';

class TransformTask {
  final List<(double, double)> shape;
  final Mat3 target;
  final List<Op> reference;
  final int? maxOps;
  final Set<String> allowed;
  const TransformTask(this.shape, this.target, this.reference, this.maxOps, this.allowed);

  factory TransformTask.fromSpec(Map<String, dynamic> spec) => TransformTask(
        [for (final p in spec['shape'] as List) ((p[0] as num).toDouble(), (p[1] as num).toDouble())],
        Mat3([for (final v in spec['target'] as List) (v as num).toDouble()]),
        [for (final o in spec['reference'] as List) Op.fromJson(o as Map)],
        (spec['maxOps'] as num?)?.toInt(),
        {for (final a in spec['allowed'] as List? ?? const ['T', 'R', 'S', 'F']) '$a'},
      );

  List<(String, bool, String)> check(List<Op> ops) {
    final used = {for (final o in ops) o.kind}.difference(allowed);
    return [
      if (allowed.length < 4)
        ('folosește doar ${allowed.map((a) => Op.names[a]).join(', ')}', used.isEmpty, 'ai folosit și ${used.map((a) => Op.names[a]).join(', ')}'),
      if (maxOps != null) ('are cel mult $maxOps transformări', ops.length <= maxOps!, 'are ${ops.length}'),
      ('matricea compusă este cea cerută: forma ajunge exact peste țintă', compose(ops).closeTo(target, 1e-4), 'forma ta nu se suprapune cu ținta'),
    ];
  }
}

/// A raster task: the pixels to light, on a grid.
class RasterTask {
  final int width, height;
  final Set<(int, int)> pixels;
  final Set<(int, int)> given; // lit from the start (the ends)
  const RasterTask(this.width, this.height, this.pixels, this.given);

  factory RasterTask.fromSpec(Map<String, dynamic> spec) {
    Set<(int, int)> pts(Object? l) => {for (final p in l as List? ?? const []) ((p[0] as num).toInt(), (p[1] as num).toInt())};
    return RasterTask((spec['w'] as num).toInt(), (spec['h'] as num).toInt(), pts(spec['pixels']), pts(spec['given']));
  }

  List<(String, bool, String)> check(Set<(int, int)> lit) {
    final extra = lit.difference(pixels).length, missing = pixels.difference(lit).length;
    return [
      ('niciun pixel aprins în plus', extra == 0, extra == 1 ? 'un pixel nu face parte din desen' : '$extra pixeli nu fac parte din desen'),
      ('niciun pixel lipsă', missing == 0, missing == 1 ? 'mai lipsește un pixel' : 'mai lipsesc $missing pixeli'),
    ];
  }
}
