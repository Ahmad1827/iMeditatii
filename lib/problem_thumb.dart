// =============================================================================
// A PROBLEM'S THUMBNAIL in the problem list
//   One small drawing per kind of chapter (a row of cells for arrays, a graph
//   for graphs, a curve for functions...), in the chapter's colour. Drawn here,
//   so a new problem gets its picture from its chapter with no work of its own.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// What a chapter is drawn as.
enum ThumbKind {
  sequence, branch, digits, divisors, array, frequency, sort, prefix, repeat, pseudo, olympiad, bug,
  matrix, lee, text, stack, subprogram, recursion, divide, greedy, record, bignum, backtracking, tree,
  graph, dp, linked, combinatorics, file, sets, progression, induction, function, parabola, vectors,
  trig, analytic, complex, exponential, composition, integral, probability, system,
  // ACS: the faculty's courses
  shell, logic, circuit, cpu, mechanics, other,
}

/// The kind of drawing for a chapter, from its name ("5. Tablouri unidimensionale" -> array).
ThumbKind thumbKindOf(String chapter) {
  final c = chapter.toLowerCase();
  bool has(String s) => c.contains(s);
  if (has('acadnet')) return ThumbKind.bug;
  // ACS chapters, before the school words they contain ("Circuite secvențiale", "Dinamică")
  if (has('linia de comandă') || has('shell') || has('utilizatori și procese')) return ThumbKind.shell;
  if (has('booleană') || has('circuite combina') || has('circuite secvențiale')) return ThumbKind.logic;
  if (has('curent') || has('tranzitoriu')) return ThumbKind.circuit;
  if (has('registre') || has('compilare') || has('stiva și apelul')) return ThumbKind.cpu;
  if (has('cinematic') || has('legile lui newton') || has('lucru mecanic') || has('rotație și oscila')) return ThumbKind.mechanics;
  if (has('numerație') || has('biți')) return ThumbKind.digits;
  if (has('stive')) return ThumbKind.stack;
  if (has('heap')) return ThumbKind.tree;
  if (has('rețelistic')) return ThumbKind.graph;
  if (has('grilă')) return ThumbKind.pseudo;
  if (has('valori proprii')) return ThumbKind.matrix;
  if (has('serii')) return ThumbKind.progression;
  if (has('câmpului')) return ThumbKind.vectors;
  if (has('laplace')) return ThumbKind.integral;
  if (has('statistic')) return ThumbKind.probability;
  if (has('diferențiale') || has('interpol') || has('neliniare')) return ThumbKind.function;
  if (has('olimpiad')) return ThumbKind.olympiad;
  if (has('fișier')) return ThumbKind.file;
  if (has('subprogram')) return ThumbKind.subprogram;
  if (has('șiruri și matrice')) return ThumbKind.matrix;
  if (has('pseudocod') || has('subiectul') || has('recapitulare') || has('suplimentare') || has('eficien')) return ThumbKind.pseudo;
  if (has('secvențial')) return ThumbKind.sequence;
  if (has('alternativ')) return ThumbKind.branch;
  if (has('repetitiv')) return ThumbKind.repeat;
  if (has('cifr')) return ThumbKind.digits;
  if (has('numere mari')) return ThumbKind.bignum;
  if (has('divizib') || has('prime') || has('modular')) return ThumbKind.divisors;
  if (has('frecvenț')) return ThumbKind.frequency;
  if (has('sortare') || has('căutare')) return ThumbKind.sort;
  if (has('sume parțiale') || has('doi indici')) return ThumbKind.prefix;
  if (has('lee')) return ThumbKind.lee;
  if (has('determinanț')) return ThumbKind.matrix;
  if (has('sisteme')) return ThumbKind.system;
  if (has('bidimensional') || has('matrice')) return ThumbKind.matrix;
  if (has('unidimensional') || has('tablouri') || has('vectori de')) return ThumbKind.array;
  if (has('caractere')) return ThumbKind.text;
  if (has('stivă') || has('stl')) return ThumbKind.stack;
  if (has('recursiv')) return ThumbKind.recursion;
  if (has('divide')) return ThumbKind.divide;
  if (has('greedy')) return ThumbKind.greedy;
  if (has('struct')) return ThumbKind.record;
  if (has('backtracking')) return ThumbKind.backtracking;
  if (has('arbor')) return ThumbKind.tree;
  if (has('graf')) return ThumbKind.graph;
  if (has('dinamic')) return ThumbKind.dp;
  if (has('liste')) return ThumbKind.linked;
  if (has('binom') || has('combinatoric')) return ThumbKind.combinatorics;
  if (has('mulțimi')) return ThumbKind.sets;
  if (has('progresii') || has('șiruri')) return ThumbKind.progression;
  if (has('inducție')) return ThumbKind.induction;
  if (has('gradul ii') || has('polinoame')) return ThumbKind.parabola;
  if (has('vectori') || has('produs scalar')) return ThumbKind.vectors;
  if (has('trigonometr')) return ThumbKind.trig;
  if (has('geometrie')) return ThumbKind.analytic;
  if (has('complex')) return ThumbKind.complex;
  if (has('puteri') || has('logaritm') || has('exponențial')) return ThumbKind.exponential;
  if (has('compoziție') || has('grupuri') || has('inele')) return ThumbKind.composition;
  if (has('primitive') || has('integral')) return ThumbKind.integral;
  if (has('probabilit') || has('financiar')) return ThumbKind.probability;
  if (has('funcți') || has('limite') || has('derivat') || has('continuitate')) return ThumbKind.function;
  return ThumbKind.other;
}

/// The thumbnail: a tinted tile with the chapter's drawing.
class ProblemThumb extends StatelessWidget {
  final String chapter;
  final Color color;
  final double width;
  final double? height; // 0.6 of the width unless given (a square for a chapter's header)
  final bool dark;
  const ProblemThumb({super.key, required this.chapter, required this.color, this.width = 72, this.height, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final kind = thumbKindOf(chapter);
    final number = RegExp(r'^\d+').stringMatch(chapter.trim()) ?? '';
    return Container(
      width: width,
      height: height ?? width * 0.6,
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(width >= 80 ? 14 : 10),
      ),
      child: CustomPaint(painter: _ThumbPainter(kind, color, number)),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  final ThumbKind kind;
  final Color c;
  final String number;
  _ThumbPainter(this.kind, this.c, this.number);

  @override
  bool shouldRepaint(_ThumbPainter o) => o.kind != kind || o.c != c || o.number != number;

  @override
  void paint(Canvas canvas, Size size) {
    // drawn in a 100 x 60 box, scaled evenly into the middle of the tile
    final k = math.min(size.width / 100, size.height / 60) * 0.92;
    canvas.save();
    canvas.translate((size.width - 100 * k) / 2, (size.height - 60 * k) / 2);
    canvas.scale(k);
    _draw(canvas);
    canvas.restore();
  }

  Paint get _line => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Paint _fill([double o = 1]) => Paint()..color = c.withOpacity(o);

  void _box(Canvas k, double x, double y, double w, double h, {double fill = 0}) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(2.5));
    if (fill > 0) k.drawRRect(r, _fill(fill));
    k.drawRRect(r, _line..strokeWidth = 2.8);
  }

  void _arrow(Canvas k, Offset a, Offset b) {
    k.drawLine(a, b, _line);
    final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
    for (final s in [-1, 1]) {
      k.drawLine(b, b - Offset.fromDirection(ang + s * 0.5, 6), _line);
    }
  }

  void _text(Canvas k, String t, Offset center, double size) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(k, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _axes(Canvas k) {
    final p = Paint()
      ..color = c.withOpacity(0.45)
      ..strokeWidth = 1.4;
    k.drawLine(const Offset(14, 50), const Offset(88, 50), p);
    k.drawLine(const Offset(20, 8), const Offset(20, 54), p);
  }

  void _curve(Canvas k, double Function(double) f, {double from = 20, double to = 86}) {
    final path = Path();
    for (var x = from; x <= to; x += 1) {
      final y = f(x);
      x == from ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    k.drawPath(path, _line);
  }

  void _dots(Canvas k, List<Offset> at, {double r = 4, double o = 1}) {
    for (final p in at) {
      k.drawCircle(p, r, _fill(o));
    }
  }

  void _draw(Canvas k) {
    switch (kind) {
      case ThumbKind.sequence:
        _box(k, 12, 20, 22, 20, fill: 0.3);
        _arrow(k, const Offset(39, 30), const Offset(60, 30));
        _box(k, 66, 20, 22, 20);
      case ThumbKind.branch:
        k.drawLine(const Offset(14, 30), const Offset(40, 30), _line);
        _arrow(k, const Offset(40, 30), const Offset(72, 13));
        _arrow(k, const Offset(40, 30), const Offset(72, 47));
        _dots(k, const [Offset(40, 30)], r: 4.5);
        _dots(k, const [Offset(80, 11), Offset(80, 49)], r: 5, o: 0.45);
      case ThumbKind.digits:
        for (var i = 0; i < 3; i++) {
          _box(k, 19 + i * 22.0, 17, 18, 26, fill: i == 2 ? 0.3 : 0);
          _text(k, '${[4, 0, 7][i]}', Offset(28 + i * 22.0, 30), 14);
        }
      case ThumbKind.bignum:
        for (var i = 0; i < 7; i++) {
          _box(k, 10 + i * 11.6, 22, 10, 16, fill: i.isEven ? 0.3 : 0);
        }
      case ThumbKind.divisors:
        for (var r = 0; r < 3; r++) {
          for (var col = 0; col < 4; col++) {
            k.drawCircle(Offset(29 + col * 14.0, 16 + r * 14.0), 4.5, _fill(col == 3 ? 0.35 : 1));
          }
        }
      case ThumbKind.array:
        for (var i = 0; i < 5; i++) {
          _box(k, 13 + i * 15.0, 22, 13, 16, fill: i == 2 ? 0.45 : 0);
        }
      case ThumbKind.frequency:
        const h = <double>[14, 30, 8, 22, 36];
        for (var i = 0; i < 5; i++) {
          k.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18 + i * 13.0, 50 - h[i], 9, h[i]), const Radius.circular(2)), _fill(0.85));
        }
      case ThumbKind.sort:
        for (var i = 0; i < 5; i++) {
          final hh = 8.0 + i * 8;
          k.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18 + i * 13.0, 50 - hh, 9, hh), const Radius.circular(2)), _fill(0.35 + i * 0.15));
        }
      case ThumbKind.prefix:
        for (var i = 0; i < 5; i++) {
          _box(k, 13 + i * 15.0, 16, 13, 16, fill: i >= 1 && i <= 3 ? 0.4 : 0);
        }
        final p = Path()
          ..moveTo(28, 38)
          ..quadraticBezierTo(28, 44, 34, 44)
          ..lineTo(66, 44)
          ..quadraticBezierTo(72, 44, 72, 38);
        k.drawPath(p, _line);
        k.drawLine(const Offset(50, 44), const Offset(50, 50), _line);
      case ThumbKind.repeat:
        k.drawArc(const Rect.fromLTWH(32, 12, 36, 36), -0.6, 5.2, false, _line);
        final end = Offset(50 + 18 * math.cos(4.6), 30 + 18 * math.sin(4.6));
        _arrow(k, end + const Offset(-6, -1), end);
      case ThumbKind.pseudo:
        const w = <double>[48, 36, 40, 28];
        const ind = <double>[0, 10, 10, 0];
        for (var i = 0; i < 4; i++) {
          k.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(22 + ind[i], 13 + i * 10.0, w[i], 4.5), const Radius.circular(2)), _fill(i == 1 ? 1 : 0.5));
        }
      case ThumbKind.bug:
        const w = <double>[46, 36, 50, 30];
        for (var i = 0; i < 4; i++) {
          k.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 13 + i * 10.0, w[i], 4.5), const Radius.circular(2)), _fill(i == 2 ? 1 : 0.4));
        }
        k.drawLine(const Offset(76, 31), const Offset(84, 39), _line);
        k.drawLine(const Offset(84, 31), const Offset(76, 39), _line);
      case ThumbKind.olympiad:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 19.0 : 8.0;
          final a = -math.pi / 2 + i * math.pi / 5;
          final p = Offset(50 + r * math.cos(a), 31 + r * math.sin(a));
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        k.drawPath(star, _fill(0.35));
        k.drawPath(star, _line..strokeWidth = 2.8);
      case ThumbKind.matrix:
      case ThumbKind.dp:
      case ThumbKind.lee:
        for (var r = 0; r < 3; r++) {
          for (var col = 0; col < 3; col++) {
            double f = 0;
            if (kind == ThumbKind.matrix && r == col) f = 1;
            if (kind == ThumbKind.dp) f = 0.15 + (r + col) * 0.2;
            if (kind == ThumbKind.lee && (r == 0 || col == 2)) f = 0.75;
            _box(k, 30 + col * 14.0, 9 + r * 14.0, 11, 11, fill: f);
          }
        }
      case ThumbKind.text:
        _text(k, 'abc', const Offset(46, 28), 20);
        k.drawLine(const Offset(70, 18), const Offset(70, 40), _line);
      case ThumbKind.stack:
        for (var i = 0; i < 3; i++) {
          _box(k, 32, 22 + i * 11.0, 36, 8, fill: i == 0 ? 0.45 : 0.15);
        }
        _arrow(k, const Offset(50, 4), const Offset(50, 16));
      case ThumbKind.subprogram:
        _text(k, 'f(x)', const Offset(50, 30), 20);
      case ThumbKind.recursion:
        for (var i = 0; i < 3; i++) {
          final d = i * 7.0;
          _box(k, 24 + d, 10 + d * 0.6, 52 - 2 * d, 40 - 1.2 * d, fill: i == 2 ? 0.4 : 0);
        }
      case ThumbKind.divide:
        _box(k, 18, 9, 64, 10, fill: 0.4);
        _box(k, 18, 25, 30, 10, fill: 0.25);
        _box(k, 52, 25, 30, 10, fill: 0.25);
        for (var i = 0; i < 4; i++) {
          _box(k, 18 + i * 17.0, 41, 13, 10);
        }
      case ThumbKind.greedy:
        _dots(k, const [Offset(30, 32)], r: 13, o: 0.9);
        _dots(k, const [Offset(56, 35)], r: 9, o: 0.6);
        _dots(k, const [Offset(75, 38)], r: 6, o: 0.4);
      case ThumbKind.record:
        _box(k, 28, 8, 44, 44);
        k.drawRect(const Rect.fromLTWH(28, 8, 44, 11), _fill(0.45));
        for (var i = 0; i < 3; i++) {
          k.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(34, 25 + i * 8.0, 32 - i * 6.0, 4), const Radius.circular(2)), _fill(0.6));
        }
      case ThumbKind.tree:
      case ThumbKind.backtracking:
        const n = [Offset(50, 11), Offset(32, 30), Offset(68, 30), Offset(22, 49), Offset(42, 49), Offset(60, 49), Offset(78, 49)];
        for (final e in const [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6]]) {
          k.drawLine(n[e[0]], n[e[1]], _line..strokeWidth = 2.8);
        }
        _dots(k, n, r: 4.5);
        if (kind == ThumbKind.backtracking) {
          _dots(k, [n[6]], r: 6.5, o: 0.35);
          k.drawLine(const Offset(71, 54), const Offset(85, 44), _line..strokeWidth = 2.8);
        }
      case ThumbKind.graph:
        const n = [Offset(22, 18), Offset(52, 10), Offset(80, 26), Offset(34, 48), Offset(66, 50)];
        for (final e in const [[0, 1], [1, 2], [0, 3], [3, 4], [1, 4], [2, 4]]) {
          k.drawLine(n[e[0]], n[e[1]], _line..strokeWidth = 2.8);
        }
        _dots(k, n, r: 5);
      case ThumbKind.linked:
        for (var i = 0; i < 3; i++) {
          _box(k, 10 + i * 30.0, 22, 18, 16, fill: 0.3);
          if (i < 2) _arrow(k, Offset(30 + i * 30.0, 30), Offset(38 + i * 30.0, 30));
        }
      case ThumbKind.combinatorics:
        final pts = <Offset>[];
        for (var r = 0; r < 4; r++) {
          for (var i = 0; i <= r; i++) {
            pts.add(Offset(50 - r * 7 + i * 14.0, 12 + r * 12.0));
          }
        }
        _dots(k, pts, r: 3.8);
      case ThumbKind.file:
        final p = Path()
          ..moveTo(34, 6)
          ..lineTo(58, 6)
          ..lineTo(68, 16)
          ..lineTo(68, 54)
          ..lineTo(34, 54)
          ..close();
        k.drawPath(p, _line..strokeWidth = 2.8);
        for (var i = 0; i < 3; i++) {
          k.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(40, 24 + i * 9.0, 22 - i * 5.0, 4), const Radius.circular(2)), _fill(0.6));
        }
      case ThumbKind.sets:
        k.drawCircle(const Offset(40, 30), 17, _fill(0.25));
        k.drawCircle(const Offset(60, 30), 17, _fill(0.25));
        k.drawCircle(const Offset(40, 30), 17, _line..strokeWidth = 2.8);
        k.drawCircle(const Offset(60, 30), 17, _line..strokeWidth = 2.8);
      case ThumbKind.progression:
        _dots(k, [for (var i = 0; i < 6; i++) Offset(18 + i * 13.0, 48 - i * 7.0)], r: 4);
      case ThumbKind.induction:
        for (var i = 0; i < 5; i++) {
          k.save();
          k.translate(22 + i * 13.0, 50);
          k.rotate(i < 2 ? 0.55 - i * 0.2 : 0);
          k.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -30, 6, 30), const Radius.circular(1.5)), _fill(i < 2 ? 0.45 : 0.9));
          k.restore();
        }
      case ThumbKind.function:
        _axes(k);
        _curve(k, (x) => 30 - 16 * math.sin((x - 20) / 10));
      case ThumbKind.parabola:
        _axes(k);
        _curve(k, (x) => 10 + math.pow((x - 54) / 6, 2).toDouble(), from: 32, to: 76);
      case ThumbKind.exponential:
        _axes(k);
        _curve(k, (x) => 48 - math.exp((x - 20) / 18) * 1.6, from: 20, to: 80);
      case ThumbKind.integral:
        _axes(k);
        final area = Path()..moveTo(36, 50);
        for (var x = 36.0; x <= 72; x++) {
          area.lineTo(x, 34 - 10 * math.sin((x - 20) / 12));
        }
        area
          ..lineTo(72, 50)
          ..close();
        k.drawPath(area, _fill(0.3));
        _curve(k, (x) => 34 - 10 * math.sin((x - 20) / 12));
      case ThumbKind.vectors:
        _arrow(k, const Offset(24, 48), const Offset(74, 40));
        _arrow(k, const Offset(24, 48), const Offset(44, 12));
      case ThumbKind.trig:
        k.drawCircle(const Offset(50, 30), 21, _line..strokeWidth = 2.8);
        final p = Offset(50 + 21 * math.cos(-0.8), 30 + 21 * math.sin(-0.8));
        k.drawLine(const Offset(50, 30), p, _line);
        k.drawLine(const Offset(50, 30), const Offset(71, 30), _line..strokeWidth = 2.2);
        k.drawArc(const Rect.fromLTWH(41, 21, 18, 18), -0.8, 0.8, true, _fill(0.4));
      case ThumbKind.analytic:
        _axes(k);
        k.drawLine(const Offset(26, 48), const Offset(82, 12), _line);
        _dots(k, const [Offset(54, 30)], r: 4.5);
      case ThumbKind.complex:
        _axes(k);
        k.drawLine(const Offset(20, 50), const Offset(64, 18), _line..strokeWidth = 2.4);
        _dots(k, const [Offset(64, 18)], r: 5);
        k.drawLine(const Offset(64, 18), const Offset(64, 50), _line..strokeWidth = 1);
      case ThumbKind.composition:
        _text(k, 'x∘y', const Offset(50, 30), 20);
      case ThumbKind.probability:
        k.drawCircle(const Offset(50, 30), 20, _fill(0.3));
        k.drawArc(const Rect.fromLTWH(30, 10, 40, 40), -math.pi / 2, 2.2, true, _fill(0.9));
      case ThumbKind.system:
        _text(k, '{', const Offset(28, 29), 34);
        k.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, 18, 40, 5), const Radius.circular(2)), _fill(0.8));
        k.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, 36, 32, 5), const Radius.circular(2)), _fill(0.8));
      case ThumbKind.shell: // a terminal: the prompt and a cursor
        _box(k, 14, 10, 72, 40);
        _text(k, '\$_', const Offset(36, 30), 17);
        k.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(50, 27, 24, 4.5), const Radius.circular(2)), _fill(0.45));
      case ThumbKind.logic: // an AND gate, two inputs and an output
        final gate = Path()
          ..moveTo(38, 14)
          ..lineTo(52, 14)
          ..arcToPoint(const Offset(52, 46), radius: const Radius.circular(16))
          ..lineTo(38, 46)
          ..close();
        k.drawPath(gate, _fill(0.3));
        k.drawPath(gate, _line);
        k.drawLine(const Offset(18, 22), const Offset(38, 22), _line);
        k.drawLine(const Offset(18, 38), const Offset(38, 38), _line);
        k.drawLine(const Offset(68, 30), const Offset(84, 30), _line);
      case ThumbKind.circuit: // a loop with a resistor and a source
        final wire = Path()
          ..moveTo(30, 14)
          ..lineTo(16, 14)
          ..lineTo(16, 46)
          ..lineTo(84, 46)
          ..lineTo(84, 14)
          ..lineTo(70, 14);
        k.drawPath(wire, _line);
        final zig = Path()..moveTo(30, 14);
        for (var i = 0; i < 6; i++) {
          zig.lineTo(33.3 + i * 6.7, i.isEven ? 8 : 20);
        }
        zig.lineTo(70, 14);
        k.drawPath(zig, _line);
        k.drawCircle(const Offset(50, 46), 7, _fill(1));
      case ThumbKind.cpu: // a chip with its pins
        _box(k, 32, 12, 36, 36, fill: 0.3);
        for (var i = 0; i < 3; i++) {
          final d = 20.0 + i * 10;
          k.drawLine(Offset(24, d), Offset(32, d), _line);
          k.drawLine(Offset(68, d), Offset(76, d), _line);
        }
        _text(k, 'x86', const Offset(50, 30), 10);
      case ThumbKind.mechanics: // a thrown body's arc and its velocity
        _axes(k);
        _curve(k, (x) => 50 - (x - 20) * (86 - x) / 26);
        _dots(k, const [Offset(36, 27)], r: 5);
        _arrow(k, const Offset(36, 27), const Offset(50, 17));
      case ThumbKind.other:
        _text(k, number.isEmpty ? '?' : number, const Offset(50, 30), 22);
    }
  }
}
