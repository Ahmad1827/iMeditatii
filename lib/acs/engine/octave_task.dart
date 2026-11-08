// =============================================================================
// AN MN TASK: an Octave function, called on tests
//   spec.function / nout: what is called; spec.tests: [{args: ["[4 1; 2 5]",
//   ...], expect: ["[0.1; 0.3]", ...], check: ["norm(o1*o1' - a1) < 1e-8"],
//   tol}]; spec.forbid: built-ins that may not be used (inv, \, lu, chol...).
//   The arguments and the expected values are Octave expressions.
// =============================================================================

import 'dart:math' as math;

import 'octave.dart';

class OctCase {
  final List<String> args;
  final List<String> expect;
  final List<String> checks;
  final double tol;
  OctCase(this.args, this.expect, this.checks, this.tol);

  factory OctCase.fromJson(Map j) => OctCase(
        [for (final a in j['args'] as List) '$a'],
        [for (final a in j['expect'] as List? ?? const []) '$a'],
        [for (final a in j['check'] as List? ?? const []) '$a'],
        (j['tol'] as num?)?.toDouble() ?? 1e-6,
      );
}

class OctResult {
  final OctCase c;
  final bool ok;
  final String message;
  final String printed;
  OctResult(this.c, this.ok, this.message, [this.printed = '']);
}

class OctaveTask {
  final String function;
  final int nout;
  final List<OctCase> cases;
  final Set<String> forbid;
  OctaveTask(this.function, this.nout, this.cases, this.forbid);

  factory OctaveTask.fromSpec(Map s) => OctaveTask(
        s['function'] as String,
        (s['nout'] as num?)?.toInt() ?? 1,
        [for (final c in s['tests'] as List) OctCase.fromJson(c as Map)],
        {for (final f in s['forbid'] as List? ?? const []) '$f'},
      );

  String describe(OctCase c) {
    String short(String a) => a.length > 40 ? '${a.substring(0, 37)}...' : a;
    final outs = nout == 1 ? '' : '[${[for (var k = 1; k <= nout; k++) 'o$k'].join(', ')}] = ';
    return '$outs$function(${c.args.map(short).join(', ')})';
  }

  /// Runs every test on a fresh interpreter with the student's file.
  List<OctResult> run(String code) => [for (final c in cases) runOne(code, c)];

  OctResult runOne(String code, OctCase c) {
    final o = Octave()..maxSteps = 3000000;
    try {
      o.load(code);
    } on OctError catch (e) {
      return OctResult(c, false, e.toString());
    }
    if (!o.functions.containsKey(function)) return OctResult(c, false, "nu ai definit funcția $function (function ... = $function(...))");
    try {
      final args = [for (final a in c.args) Octave().evalExpr(a)];
      o.called.clear();
      o.usedOps.clear();
      final outs = o.call(function, args, nout);
      final bad = {...o.called, ...o.usedOps}.intersection(forbid);
      if (bad.isNotEmpty) return OctResult(c, false, 'nu ai voie să folosești ${bad.map((b) => b == '\\' ? 'operatorul \\' : b).join(', ')}', o.out.toString());
      if (outs.length < nout) return OctResult(c, false, 'funcția a întors ${outs.length} valori, se așteptau $nout');
      for (var k = 0; k < c.expect.length; k++) {
        final want = Octave().evalExpr(c.expect[k]);
        final why = compare(outs[k], want, c.tol);
        if (why != null) return OctResult(c, false, 'o${k + 1}: $why', o.out.toString());
      }
      if (c.checks.isNotEmpty) {
        final env = <String, OVal>{
          for (var k = 0; k < outs.length; k++) 'o${k + 1}': outs[k],
          for (var k = 0; k < args.length; k++) 'a${k + 1}': args[k],
        };
        final checker = Octave();
        for (final ch in c.checks) {
          final v = checker.evalExpr(ch, env);
          if (!Octave.truthy(v)) return OctResult(c, false, 'nu e adevărat că $ch', o.out.toString());
        }
      }
      return OctResult(c, true, 'corect', o.out.toString());
    } on OctError catch (e) {
      return OctResult(c, false, e.toString(), o.out.toString());
    }
  }

  /// Why [got] isn't [want] (relative tolerance), or null if it is.
  static String? compare(OVal got, OVal want, double tol) {
    if (want is OStr) return got is OStr && got.s == want.s ? null : 'se aștepta „${want.s}”';
    if (got is! Mat) return 'se aștepta o matrice';
    final w = want as Mat;
    if (got.r != w.r || got.c != w.c) {
      // a row vector where a column was asked is still a mistake, but say it plainly
      return 'are dimensiunea ${got.r}×${got.c}, se aștepta ${w.r}×${w.c}';
    }
    for (var k = 0; k < w.n; k++) {
      final a = got.d[k], b = w.d[k];
      if (a.isNaN || (a - b).abs() > tol * math.max(1, b.abs())) {
        final i = k % w.r + 1, j = k ~/ w.r + 1;
        return 'elementul ($i, $j) e ${_f(a)}, se aștepta ${_f(b)}';
      }
    }
    return null;
  }

  static String _f(double x) => x == x.roundToDouble() && x.abs() < 1e12 ? '${x.toInt()}' : x.toStringAsPrecision(8);
}
