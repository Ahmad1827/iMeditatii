// =============================================================================
// SD: THE STRUCTURE ON THE PAGE, BUILT ONE MOVE AT A TIME
//   A binary search tree with its empty places, a heap as a tree and as an
//   array, a hash table's cells, a graph: the student clicks, each move is
//   checked against the algorithm (engine/ds.dart), a wrong one is explained.
//   Too many mistakes and it starts again.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/ds.dart';
import 'ws_common.dart';

class DsWorkspace extends AcsWorkspace {
  const DsWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<DsWorkspace> createState() => _DsWorkspaceState();
}

class _Hit {
  final DsTarget t;
  final Offset at;
  final double r;
  const _Hit(this.t, this.at, this.r);
}

class _DsWorkspaceState extends State<DsWorkspace> {
  late DsTask _task;
  DsFeedback? _last;
  int? _selected; // heap: the first cell of a swap
  bool _reported = false;
  final List<_Hit> _hits = [];
  final List<(int, Offset, Offset)> _edgeHits = []; // edge index, ends

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _task = DsTask.fromSpec(widget.problem.spec);
    _last = null;
    _selected = null;
    _reported = false;
  }

  void _play(DsTarget t) {
    if (_task.done || _task.failed) return;
    final f = _task.play(t);
    setState(() => _last = f);
    if (_task.done && !_reported) {
      _reported = true;
      widget.onVerdict(true);
    } else if (_task.failed && !_reported) {
      _reported = true;
      widget.onVerdict(false);
    }
  }

  void _tap(Offset p) {
    if (_task is GraphTask && (_task as GraphTask).edgeMode) {
      for (final (i, a, b) in _edgeHits) {
        if (_distToSegment(p, a, b) < 12) {
          _play(DsTarget('edge', i));
          return;
        }
      }
      return;
    }
    for (final h in _hits) {
      if ((h.at - p).distance <= h.r + 6) {
        if (_task is HeapTask) {
          final i = h.t.a;
          if (_selected == null) {
            setState(() => _selected = i);
          } else if (_selected == i) {
            setState(() => _selected = null);
          } else {
            final a = _selected!;
            _selected = null;
            _play(DsTarget('swap', math.min(a, i), math.max(a, i)));
          }
          return;
        }
        _play(h.t);
        return;
      }
    }
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final t = _task;
    final status = t.failed
        ? 'Prea multe greșeli (${t.mistakes}). Reia de la început.'
        : t.done
            ? 'Gata${t.mistakes == 0 ? ', fără nicio greșeală' : ', cu ${t.mistakes} ${t.mistakes == 1 ? 'greșeală' : 'greșeli'}'}.'
            : 'greșeli: ${t.mistakes} din ${t.maxMistakes} permise';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          color: ink.bg,
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.prompt, style: ink.mono(14, color: ink.strong, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth;
              final h = _height(w);
              return GestureDetector(
                onTapUp: (d) => _tap(d.localPosition),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: CustomPaint(size: Size(w, h), painter: _DsPainter(this, ink, w, h)),
                ),
              );
            }),
            const SizedBox(height: 8),
            if (_last != null)
              Text(_last!.ok ? '✓ ${_last!.message}' : '✗ ${_last!.message}', style: ink.mono(13.5, color: _last!.ok ? ink.good : ink.bad)),
            const SizedBox(height: 4),
            Text(status, style: ink.mono(13, color: t.failed ? ink.bad : t.done ? ink.good : ink.muted)),
            if (t.log.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('pași: ${t.log.join(' ')}', style: ink.mono(12.5, color: ink.dim)),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'reia de la început', () => setState(_reset), primary: t.failed),
        ]),
      ],
    );
  }

  double _height(double w) {
    final t = _task;
    if (t is HashTask) return ((t.m + 9) ~/ 10) * 62.0 + 10;
    if (t is HeapTask) return math.max(200, 70.0 * (math.log(math.max(t.a.length, 1)) / math.ln2 + 1)) + 80;
    if (t is BstTask) return 64.0 * (_depth((t).root) + 1) + 40;
    return math.min(420, w * 0.62);
  }

  static int _depth(BstNode? n) => n == null ? 0 : 1 + math.max(_depth(n.left), _depth(n.right));
}

class _DsPainter extends CustomPainter {
  final _DsWorkspaceState s;
  final AcsInk ink;
  final double w, h;
  _DsPainter(this.s, this.ink, this.w, this.h);

  void _label(Canvas c, String text, Offset at, {double size = 14, Color? color, FontWeight weight = FontWeight.w700, bool center = true}) {
    final tp = TextPainter(text: TextSpan(text: text, style: ink.mono(size, color: color ?? ink.strong, weight: weight, height: 1)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  void _node(Canvas c, Offset at, String text, {double r = 18, Color? fill, Color? stroke, bool dashed = false, Color? textColor}) {
    final paint = Paint()..color = fill ?? ink.panel;
    c.drawCircle(at, r, paint);
    final border = Paint()
      ..color = stroke ?? ink.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (dashed) {
      const n = 12;
      for (var k = 0; k < n; k += 2) {
        c.drawArc(Rect.fromCircle(center: at, radius: r), k * 2 * math.pi / n, 2 * math.pi / n, false, border);
      }
    } else {
      c.drawCircle(at, r, border);
    }
    _label(c, text, at, color: textColor, size: text.length > 3 ? 11.5 : 14);
  }

  @override
  void paint(Canvas c, Size size) {
    s._hits.clear();
    s._edgeHits.clear();
    final t = s._task;
    final line = Paint()
      ..color = ink.dim
      ..strokeWidth = 1.6;
    if (t is BstTask) {
      // in-order positions for nodes and empty places alike
      final items = <(BstNode?, int, int, BstNode?, int)>[]; // node, depth, x, parent, side
      var x = 0;
      void walk(BstNode? n, int d, BstNode? parent, int side) {
        if (n == null) {
          items.add((null, d, x++, parent, side));
          return;
        }
        walk(n.left, d + 1, n, 0);
        items.add((n, d, x++, parent, side));
        walk(n.right, d + 1, n, 1);
      }

      walk(t.root, 0, null, 0);
      final cols = math.max(1, x);
      Offset pos(int xi, int d) => Offset((xi + 0.5) * w / cols, 26 + d * 64.0);
      final at = <BstNode, Offset>{};
      for (final (n, d, xi, _, _) in items) {
        if (n != null) at[n] = pos(xi, d);
      }
      for (final (n, d, xi, parent, _) in items) {
        if (parent != null) c.drawLine(at[parent]!, pos(xi, d), n == null ? (Paint()..color = ink.line..strokeWidth = 1) : line);
      }
      final done = t.done || t.failed;
      for (final (n, d, xi, parent, side) in items) {
        final p = pos(xi, d);
        if (n != null) {
          _node(c, p, '${n.key}', stroke: ink.accent);
        } else if (!done) {
          _node(c, p, '+', r: 12, dashed: true, textColor: ink.muted, fill: ink.bg);
          s._hits.add(_Hit(DsTarget('slot', parent?.key ?? -1, side), p, 12));
        }
      }
      return;
    }
    if (t is HeapTask) {
      final n = t.a.length;
      final levels = n == 0 ? 1 : (math.log(n) / math.ln2).floor() + 1;
      Offset pos(int i) {
        final d = (math.log(i + 1) / math.ln2).floor();
        final first = (1 << d) - 1;
        final k = i - first;
        final count = 1 << d;
        return Offset((k + 0.5) * w / count, 26 + d * 66.0);
      }

      for (var i = 1; i < n; i++) {
        c.drawLine(pos((i - 1) ~/ 2), pos(i), line);
      }
      for (var i = 0; i < n; i++) {
        final sel = s._selected == i;
        _node(c, pos(i), '${t.a[i]}', fill: sel ? ink.accent : ink.panel, stroke: sel ? ink.accent : ink.line, textColor: sel ? ink.bg : null);
        s._hits.add(_Hit(DsTarget('node', i), pos(i), 18));
      }
      // the array below
      final top = 26 + levels * 66.0;
      final cw = math.min(48.0, (w - 10) / math.max(n, 1));
      for (var i = 0; i < n; i++) {
        final r = Rect.fromLTWH(5 + i * cw, top, cw - 3, 30);
        final sel = s._selected == i;
        c.drawRect(r, Paint()..color = sel ? ink.accent : ink.panel);
        c.drawRect(r, Paint()
          ..color = ink.line
          ..style = PaintingStyle.stroke);
        _label(c, '${t.a[i]}', r.center, size: 13, color: sel ? ink.bg : ink.strong);
        _label(c, '$i', Offset(r.center.dx, r.bottom + 9), size: 10.5, color: ink.dim, weight: FontWeight.w400);
        s._hits.add(_Hit(DsTarget('node', i), r.center, cw / 2 - 2));
      }
      if (t.extracted.isNotEmpty) _label(c, 'scoase: ${t.extracted.join(', ')}', Offset(5, top + 48), size: 12, color: ink.muted, center: false, weight: FontWeight.w400);
      return;
    }
    if (t is HashTask) {
      final cw = (w - 10) / 10;
      for (var i = 0; i < t.m; i++) {
        final r = Rect.fromLTWH(5 + (i % 10) * cw, 6 + (i ~/ 10) * 62.0, cw - 4, 36);
        final v = t.table[i];
        c.drawRect(r, Paint()..color = v == null ? ink.bg : ink.panel);
        c.drawRect(r, Paint()
          ..color = v == null ? ink.line : ink.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
        if (v != null) _label(c, '$v', r.center, size: 13.5);
        _label(c, '$i', Offset(r.center.dx, r.bottom + 9), size: 10.5, color: ink.dim, weight: FontWeight.w400);
        s._hits.add(_Hit(DsTarget('cell', i), r.center, cw / 2 - 2));
      }
      return;
    }
    if (t is GraphTask) {
      const pad = 34.0;
      Offset pos(GNode n) => Offset(pad + n.x * (w - 2 * pad), pad + n.y * (h - 2 * pad));
      for (final (i, e) in t.edges.indexed) {
        final a = pos(t.nodes[e.u]), b = pos(t.nodes[e.v]);
        final chosen = t.picked.contains(i);
        final p = Paint()
          ..color = chosen ? ink.accent : ink.dim
          ..strokeWidth = chosen ? 3.5 : 1.6;
        c.drawLine(a, b, p);
        if (t.directed) {
          final dir = (b - a) / (b - a).distance;
          final tip = b - dir * 20;
          final side = Offset(-dir.dy, dir.dx);
          final path = Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo((tip - dir * 10 + side * 5).dx, (tip - dir * 10 + side * 5).dy)
            ..lineTo((tip - dir * 10 - side * 5).dx, (tip - dir * 10 - side * 5).dy)
            ..close();
          c.drawPath(path, Paint()..color = p.color);
        }
        if (t.weighted) {
          final mid = (a + b) / 2;
          c.drawRect(Rect.fromCenter(center: mid, width: 26, height: 18), Paint()..color = ink.bg);
          _label(c, '${e.w}', mid, size: 12.5, color: chosen ? ink.accent : ink.muted);
        }
        s._edgeHits.add((i, a, b));
      }
      for (final (i, n) in t.nodes.indexed) {
        final k = t.order.indexOf(i);
        final visited = k >= 0;
        _node(c, pos(n), n.name, fill: visited ? ink.accent : ink.panel, stroke: i == t.start && !visited ? ink.accent : ink.line, textColor: visited ? ink.bg : null, r: 19);
        if (visited && !t.edgeMode) _label(c, '${k + 1}', pos(n) + const Offset(18, -18), size: 11, color: ink.accent);
        if (t.algo == 'dijkstra') {
          final d = t.dist[i];
          _label(c, d >= 1 << 40 ? '∞' : '$d', pos(n) + const Offset(0, 30), size: 12, color: visited ? ink.good : ink.warn);
        }
        s._hits.add(_Hit(DsTarget('node', i), pos(n), 19));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
