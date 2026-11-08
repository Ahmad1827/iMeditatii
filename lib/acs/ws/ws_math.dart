// =============================================================================
// AM / MS / ALGAED: ANSWERS WRITTEN AS MATHS, SEEN ON A GRAPH
//   Formulas, numbers, matrices and points, checked by their properties
//   (engine/math_task.dart). A formula in one variable is drawn as it is
//   typed, beside the curve it should match (a Taylor polynomial against its
//   function, a Fourier sum against the signal...); points of a function of
//   two variables sit on its heat map.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/math_task.dart';
import '../engine/octave.dart';
import 'ws_common.dart';

class MathWorkspace extends AcsWorkspace {
  const MathWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<MathWorkspace> createState() => _MathWorkspaceState();
}

class _MathWorkspaceState extends State<MathWorkspace> {
  late final MathTask _task = MathTask.fromSpec(widget.problem.spec);
  final Map<String, TextEditingController> _text = {};
  final Map<String, List<List<TextEditingController>>> _cells = {};
  final Map<String, List<(TextEditingController, TextEditingController, String)>> _points = {};
  List<Check>? _checks;

  Map get spec => widget.problem.spec;

  @override
  void initState() {
    super.initState();
    for (final f in _task.fields) {
      switch (f.type) {
        case 'matrix':
          _cells[f.name] = [for (var i = 0; i < f.rows; i++) [for (var j = 0; j < f.cols; j++) _ctl()]];
        case 'points':
          _points[f.name] = [(_ctl(), _ctl(), '')];
        default:
          _text[f.name] = _ctl();
      }
    }
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      final parts = d.split('\u0001');
      var k = 0;
      for (final f in _task.fields) {
        if (_text.containsKey(f.name) && k < parts.length) _text[f.name]!.text = parts[k];
        k++;
      }
    });
  }

  TextEditingController _ctl() => TextEditingController()
    ..addListener(() {
      if (mounted) setState(() {});
      _save();
    });

  void _save() {
    AcsProgress.saveDraft(widget.problem, [for (final f in _task.fields) _text[f.name]?.text ?? ''].join('\u0001'));
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final m in _cells.values) {
      for (final r in m) {
        for (final c in r) {
          c.dispose();
        }
      }
    }
    for (final l in _points.values) {
      for (final (a, b, _) in l) {
        a.dispose();
        b.dispose();
      }
    }
    super.dispose();
  }

  Map<String, MathAnswer> _answers() => {
        for (final f in _task.fields)
          f.name: switch (f.type) {
            'matrix' => MathAnswer(cells: [for (final r in _cells[f.name]!) [for (final c in r) c.text]]),
            'points' => MathAnswer(points: [for (final (a, b, k) in _points[f.name]!) (a.text, b.text, k)]),
            _ => MathAnswer(text: _text[f.name]!.text),
          },
      };

  void _verify() {
    final r = _task.verify(_answers());
    setState(() => _checks = [for (final c in r) Check(c.label, c.ok, c.detail)]);
    widget.onVerdict(r.isNotEmpty && r.every((c) => c.ok));
  }

  String? _liveError(MathField f) {
    final t = _text[f.name]?.text ?? '';
    if (t.trim().isEmpty) return null;
    try {
      if (f.type == 'number') {
        MathTask.number(t, _task.constants);
      } else {
        Octave().evalExpr('@(${f.vars.join(', ')}) ${toOctave(t, f.vars, constants: _task.constants)}');
      }
      return null;
    } on MathError catch (e) {
      return e.message;
    } on OctError catch (e) {
      return e.message;
    }
  }

  Widget _field(AcsInk ink, MathField f) {
    final label = Text(f.label, style: ink.mono(14.5, weight: FontWeight.w700, color: ink.strong));
    switch (f.type) {
      case 'matrix':
        final cells = _cells[f.name]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label,
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: cells.length * 44.0, decoration: BoxDecoration(border: Border(left: BorderSide(color: ink.strong, width: 2), top: BorderSide(color: ink.strong, width: 2), bottom: BorderSide(color: ink.strong, width: 2)))),
            Column(children: [
              for (final row in cells)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final c in row) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: AcsField(ink, c, width: widget.narrow ? 58 : 76, align: TextAlign.center)),
                  ]),
                ),
            ]),
            Container(width: 6, height: cells.length * 44.0, decoration: BoxDecoration(border: Border(right: BorderSide(color: ink.strong, width: 2), top: BorderSide(color: ink.strong, width: 2), bottom: BorderSide(color: ink.strong, width: 2)))),
          ]),
          if (f.hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(f.hint, style: ink.mono(12, color: ink.muted))),
        ]);
      case 'points':
        final pts = _points[f.name]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label,
          const SizedBox(height: 6),
          for (var k = 0; k < pts.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('P${k + 1} = (', style: ink.mono(14)),
                AcsField(ink, pts[k].$1, width: 72, align: TextAlign.center, hint: 'x'),
                Text(',', style: ink.mono(14)),
                AcsField(ink, pts[k].$2, width: 72, align: TextAlign.center, hint: 'y'),
                Text(')', style: ink.mono(14)),
                if (f.kinds)
                  for (final kind in ['min', 'max', 'șa'])
                    AcsTap(
                      label: kind,
                      onTap: () => setState(() => pts[k] = (pts[k].$1, pts[k].$2, pts[k].$3 == kind ? '' : kind)),
                      builder: (h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: pts[k].$3 == kind ? ink.accent : (h ? ink.hover : ink.bg), border: Border.all(color: ink.line)),
                        child: Text(kind, style: ink.mono(12.5, weight: FontWeight.w700, color: pts[k].$3 == kind ? ink.bg : ink.fg)),
                      ),
                    ),
              ]),
            ),
          ToolRow([
            AcsButton(ink, '+ punct', pts.length >= 8 ? null : () => setState(() => pts.add((_ctl(), _ctl(), '')))),
            AcsButton(ink, '− ultimul', pts.length <= 1
                ? null
                : () => setState(() {
                      final (a, b, _) = pts.removeLast();
                      a.dispose();
                      b.dispose();
                    })),
          ]),
        ]);
      default:
        final err = _liveError(f);
        final number = f.type == 'number';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Flexible(flex: 0, child: label),
            const SizedBox(width: 8),
            if (number) AcsField(ink, _text[f.name]!, width: 200, hint: 'de ex. 3/4, sqrt(2), e^2', onSubmitted: (_) => _verify(), ok: err == null ? null : false)
            else Expanded(child: AcsField(ink, _text[f.name]!, width: double.infinity, hint: 'de ex. x^2*e^x + sin(2x)', onSubmitted: (_) => _verify(), ok: err == null ? null : false)),
          ]),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(err, style: ink.mono(12, color: ink.bad))),
          if (f.hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(f.hint, style: ink.mono(12, color: ink.muted))),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final plot = spec['plot'] as Map?;
    final heat = spec['heat'] as Map?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          color: ink.bg,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Scrie ca pe hârtie: 2x, x^2, e^x, sin x, ln(1+x), sqrt(x), pi. Nu contează forma: se verifică ce e expresia, nu cum arată.', style: ink.mono(12.5, color: ink.muted)),
            const SizedBox(height: 12),
            for (final f in _task.fields) ...[_field(ink, f), const SizedBox(height: 14)],
            if (plot != null)
              _Plot(
                  ink: ink,
                  spec: plot,
                  text: _text[plot['field']]?.text ?? '',
                  a0Text: plot['a0'] == null ? null : _text[plot['a0']]?.text,
                  vars: _task.fields.firstWhere((f) => f.name == plot['field']).vars,
                  constants: _task.constants),
            if (heat != null) _Heat(ink: ink, spec: heat, points: [for (final (a, b, k) in _points[heat['field']] ?? const <(TextEditingController, TextEditingController, String)>[]) (a.text, b.text, k)], constants: _task.constants),
          ]),
        ),
        const SizedBox(height: 10),
        ToolRow([AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check)]),
        if (_checks != null) ...[const SizedBox(height: 12), ChecksView(ink, _checks!)],
      ],
    );
  }
}

/// The student's curve against the reference one.
class _Plot extends StatelessWidget {
  final AcsInk ink;
  final Map spec;
  final String text;
  final String? a0Text;
  final List<String> vars;
  final Map<String, String> constants;
  const _Plot({required this.ink, required this.spec, required this.text, required this.vars, required this.constants, this.a0Text});

  @override
  Widget build(BuildContext context) {
    final r = (spec['range'] as List).cast<num>();
    final a = r[0].toDouble(), b = r[1].toDouble();
    const n = 240;
    final xs = [for (var k = 0; k <= n; k++) a + (b - a) * k / n];
    List<double>? ref;
    try {
      final o = Octave();
      final f = o.evalExpr(spec['ref'] as String) as OFunc;
      final v = o.call('feval', [f, Mat(1, xs.length, xs)], 1).first as Mat;
      ref = v.n == 1 ? List.filled(xs.length, v.d[0]) : v.d;
    } catch (_) {
      ref = null;
    }
    List<double>? mine;
    final fourier = spec['fourier'] as String?;
    if (text.trim().isEmpty) {
      mine = null;
    } else if (fourier != null) {
      // the partial Fourier sum built from the student's coefficient
      final nTerms = (spec['N'] as num?)?.toInt() ?? 15;
      final coef = MathTask.sample(text, vars, [for (var k = 1; k <= nTerms; k++) k.toDouble()], constants);
      double a0 = 0;
      final a0Field = spec['a0'] as String?;
      if (a0Field != null) {
        try {
          a0 = MathTask.number(a0Text ?? '', constants);
        } catch (_) {}
      }
      mine = coef == null
          ? null
          : [
              for (final x in xs)
                a0 / 2 + [for (var k = 1; k <= nTerms; k++) coef[k - 1] * (fourier == 'sin' ? math.sin(k * x) : math.cos(k * x))].fold(0.0, (s, v) => s + v),
            ];
    } else {
      mine = MathTask.sample(text, vars, xs, constants);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(TextSpan(children: [
        TextSpan(text: '━ ${spec['refLabel'] ?? 'ținta'}', style: TextStyle(color: ink.muted)),
        const TextSpan(text: '    '),
        TextSpan(text: '━ ${spec['label'] ?? 'expresia ta'}', style: TextStyle(color: ink.accent, fontWeight: FontWeight.w700)),
      ]), style: ink.mono(12.5)),
      const SizedBox(height: 4),
      SizedBox(height: 230, width: double.infinity, child: CustomPaint(painter: _PlotPainter(ink, xs, ref, mine, spec['yrange'] as List?))),
    ]);
  }
}

class _PlotPainter extends CustomPainter {
  final AcsInk ink;
  final List<double> xs;
  final List<double>? ref, mine;
  final List? yrange;
  _PlotPainter(this.ink, this.xs, this.ref, this.mine, this.yrange);

  @override
  void paint(Canvas c, Size size) {
    double lo, hi;
    if (yrange != null) {
      lo = (yrange![0] as num).toDouble();
      hi = (yrange![1] as num).toDouble();
    } else {
      final vals = [...?ref].where((v) => v.isFinite).toList()..sort();
      if (vals.isEmpty) {
        lo = -1;
        hi = 1;
      } else {
        lo = vals[(vals.length * 0.02).floor()];
        hi = vals[(vals.length * 0.98).floor().clamp(0, vals.length - 1)];
      }
      final pad = math.max(0.5, (hi - lo) * 0.25);
      lo -= pad;
      hi += pad;
    }
    final a = xs.first, b = xs.last;
    Offset at(double x, double y) => Offset((x - a) / (b - a) * size.width, size.height - (y - lo) / (hi - lo) * size.height);
    c.drawRect(Offset.zero & size, Paint()..color = ink.panel);
    final axis = Paint()
      ..color = ink.line
      ..strokeWidth = 1;
    if (lo < 0 && hi > 0) c.drawLine(at(a, 0), at(b, 0), axis);
    if (a < 0 && b > 0) c.drawLine(at(0, lo), at(0, hi), axis);
    void tick(String t, Offset o) {
      final tp = TextPainter(text: TextSpan(text: t, style: ink.mono(10, color: ink.dim)), textDirection: TextDirection.ltr)..layout();
      tp.paint(c, o);
    }

    String f(double v) => v.abs() >= 100 || v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    tick(f(a), Offset(2, size.height - 13));
    tick(f(b), Offset(size.width - 26, size.height - 13));
    tick(f(hi), const Offset(2, 2));
    tick(f(lo), Offset(2, size.height - 26));
    void curve(List<double>? ys, Color color, double w) {
      if (ys == null) return;
      final p = Paint()
        ..color = color
        ..strokeWidth = w
        ..style = PaintingStyle.stroke;
      Path? path;
      for (var k = 0; k < xs.length && k < ys.length; k++) {
        final y = ys[k];
        if (!y.isFinite || y < lo - (hi - lo) * 3 || y > hi + (hi - lo) * 3) {
          if (path != null) c.drawPath(path, p);
          path = null;
          continue;
        }
        final o = at(xs[k], y);
        if (path == null) {
          path = Path()..moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      if (path != null) c.drawPath(path, p);
    }

    c.save();
    c.clipRect(Offset.zero & size);
    curve(ref, ink.muted, 2.4);
    curve(mine, ink.accent, 2);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _PlotPainter old) => true;
}

/// A function of two variables as colours, with the student's points on it.
class _Heat extends StatelessWidget {
  final AcsInk ink;
  final Map spec;
  final List<(String, String, String)> points;
  final Map<String, String> constants;
  const _Heat({required this.ink, required this.spec, required this.points, required this.constants});

  @override
  Widget build(BuildContext context) {
    final xr = (spec['xr'] as List).cast<num>(), yr = (spec['yr'] as List).cast<num>();
    const n = 64;
    final xs = [for (var k = 0; k < n; k++) xr[0] + (xr[1] - xr[0]) * (k + 0.5) / n].map((v) => v.toDouble()).toList();
    final ys = [for (var k = 0; k < n; k++) yr[0] + (yr[1] - yr[0]) * (k + 0.5) / n].map((v) => v.toDouble()).toList();
    final g = MathTask.grid(spec['fn'] as String, xs, ys);
    final pts = <(double, double, String)>[];
    for (final (a, b, k) in points) {
      try {
        pts.add((MathTask.number(a, constants), MathTask.number(b, constants), k));
      } catch (_) {
        // not a number yet
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${spec['label'] ?? 'f(x, y)'}: albastru = mic, roșu = mare; liniile sunt curbe de nivel. Punctele tale sunt cercurile.', style: ink.mono(12, color: ink.muted)),
      const SizedBox(height: 4),
      AspectRatio(
        aspectRatio: 1.4,
        child: CustomPaint(painter: _HeatPainter(ink, g, n, xr[0].toDouble(), xr[1].toDouble(), yr[0].toDouble(), yr[1].toDouble(), pts)),
      ),
    ]);
  }
}

class _HeatPainter extends CustomPainter {
  final AcsInk ink;
  final List<double>? g;
  final int n;
  final double x0, x1, y0, y1;
  final List<(double, double, String)> pts;
  _HeatPainter(this.ink, this.g, this.n, this.x0, this.x1, this.y0, this.y1, this.pts);

  @override
  void paint(Canvas c, Size size) {
    if (g == null) return;
    final vals = g!.where((v) => v.isFinite).toList()..sort();
    if (vals.isEmpty) return;
    final lo = vals[(vals.length * 0.03).floor()], hi = vals[(vals.length * 0.97).floor().clamp(0, vals.length - 1)];
    final cw = size.width / n, ch = size.height / n;
    const cold = Color(0xFF3B6FB6), mid = Color(0xFFF4F1E8), hot = Color(0xFFC0452E);
    for (var j = 0; j < n; j++) {
      for (var i = 0; i < n; i++) {
        final v = g![j * n + i];
        if (!v.isFinite) continue;
        final t = ((v - lo) / (hi - lo)).clamp(0.0, 1.0);
        final col = t < 0.5 ? Color.lerp(cold, mid, t * 2)! : Color.lerp(mid, hot, (t - 0.5) * 2)!;
        // contour lines: where the value crosses a level
        final band = (t * 10).floor();
        final right = i + 1 < n ? (((g![j * n + i + 1] - lo) / (hi - lo)).clamp(0.0, 1.0) * 10).floor() : band;
        final up = j + 1 < n ? (((g![(j + 1) * n + i] - lo) / (hi - lo)).clamp(0.0, 1.0) * 10).floor() : band;
        c.drawRect(Rect.fromLTWH(i * cw, size.height - (j + 1) * ch, cw + 0.5, ch + 0.5), Paint()..color = (band != right || band != up) ? Color.lerp(col, Colors.black, 0.25)! : col);
      }
    }
    Offset at(double x, double y) => Offset((x - x0) / (x1 - x0) * size.width, size.height - (y - y0) / (y1 - y0) * size.height);
    final axis = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    if (y0 < 0 && y1 > 0) c.drawLine(at(x0, 0), at(x1, 0), axis);
    if (x0 < 0 && x1 > 0) c.drawLine(at(0, y0), at(0, y1), axis);
    for (final (x, y, k) in pts) {
      final o = at(x, y);
      c.drawCircle(o, 8, Paint()..color = Colors.white);
      c.drawCircle(o, 8, Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      if (k.isNotEmpty) {
        final tp = TextPainter(text: TextSpan(text: k, style: ink.mono(11, color: Colors.black, weight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
        tp.paint(c, o + const Offset(10, -16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatPainter old) => true;
}
