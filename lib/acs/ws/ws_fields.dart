// =============================================================================
// THE ANSWER FIELDS OF A TASK, AND THE TWO WORKSPACES BUILT ON THEM
//   RL: an address written out bit by bit, the prefix moved by hand, so the
//       network and host parts are seen, not computed for the student.
//   EG: demand and supply drawn from the task's own curves, with a trial
//       price that shows what is asked for and what is offered at it.
// =============================================================================

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/fields.dart';
import 'ws_common.dart';

/// The fields, their check, and the draft kept on the device. [above] is the
/// subject's own tool.
mixin _Fields<T extends AcsWorkspace> on State<T> {
  late final FieldsTask task = FieldsTask.fromSpec(widget.problem.spec);
  late final Map<String, TextEditingController> typed = {for (final f in task.fields) f.id: TextEditingController()..addListener(_save)};
  Map<String, bool> marks = const {};

  @override
  void initState() {
    super.initState();
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        final j = json.decode(d) as Map;
        for (final e in j.entries) {
          typed['${e.key}']?.text = '${e.value}';
        }
      } catch (_) {
        // an old draft we can't read: start clean
      }
    });
  }

  @override
  void dispose() {
    for (final c in typed.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!mounted) return;
    if (marks.isNotEmpty) setState(() => marks = const {});
    AcsProgress.saveDraft(widget.problem, json.encode({for (final e in typed.entries) e.key: e.value.text}));
  }

  void verify() {
    final r = task.check({for (final e in typed.entries) e.key: e.value.text});
    setState(() => marks = r);
    widget.onVerdict(r.values.every((ok) => ok));
  }

  Widget fieldsView() {
    final ink = widget.ink;
    final wrong = marks.values.where((ok) => !ok).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in task.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: widget.narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.label, style: ink.mono(14, color: ink.fg)),
                    const SizedBox(height: 4),
                    AcsField(ink, typed[f.id]!, width: 220, hint: f.hint, ok: marks[f.id], onSubmitted: (_) => verify()),
                  ])
                : Row(children: [
                    Expanded(child: Text(f.label, style: ink.mono(14, color: ink.fg))),
                    const SizedBox(width: 12),
                    AcsField(ink, typed[f.id]!, width: 220, hint: f.hint, ok: marks[f.id], onSubmitted: (_) => verify()),
                  ]),
          ),
        const SizedBox(height: 4),
        ToolRow([
          AcsButton(ink, 'verifică', verify, primary: true, icon: Icons.check),
          if (marks.isNotEmpty)
            Text(wrong == 0 ? 'toate răspunsurile sunt corecte' : (wrong == 1 ? 'un răspuns e greșit sau lipsește' : '$wrong răspunsuri sunt greșite sau lipsesc'),
                style: ink.mono(14, weight: FontWeight.w700, color: wrong == 0 ? ink.good : ink.bad)),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- RL
class NetWorkspace extends AcsWorkspace {
  const NetWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<NetWorkspace> createState() => _NetWorkspaceState();
}

class _NetWorkspaceState extends State<NetWorkspace> with _Fields<NetWorkspace> {
  late final TextEditingController _ip = TextEditingController(text: widget.problem.spec['ip'] as String? ?? '');
  late int _prefix = (widget.problem.spec['prefix'] as num?)?.toInt() ?? 24;

  @override
  void initState() {
    super.initState();
    _ip.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final v = parseIp(_ip.text);
    final bits = v == null ? null : bitsOf(v);
    final size = widget.narrow ? 12.0 : 14.5;
    Widget row(String label, List<int>? b, {bool mask = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(width: widget.narrow ? 54 : 78, child: Text(label, style: ink.mono(12.5, color: ink.muted))),
            if (b == null)
              Text('scrie o adresă a.b.c.d', style: ink.mono(13, color: ink.dim))
            else
              Text.rich(
                TextSpan(children: [
                  for (var i = 0; i < 32; i++) ...[
                    if (i > 0 && i % 8 == 0) TextSpan(text: '.', style: TextStyle(color: ink.dim)),
                    TextSpan(
                        text: '${b[i]}',
                        style: TextStyle(color: i < _prefix ? ink.accent : (mask ? ink.dim : ink.strong), fontWeight: i < _prefix ? FontWeight.w700 : null)),
                    if (i == _prefix - 1 && _prefix < 32) TextSpan(text: '|', style: TextStyle(color: ink.warn, fontWeight: FontWeight.w700)),
                  ],
                ]),
                style: ink.mono(size),
              ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          title: ink.terminal ? 'adresa pe biți: rețea | stație' : 'Adresa pe biți: rețea | stație',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToolRow([
                AcsField(ink, _ip, width: 170, hint: 'a.b.c.d', ok: _ip.text.isEmpty || v != null ? null : false),
                AcsButton(ink, '−', _prefix > 0 ? () => setState(() => _prefix--) : null),
                Text('/$_prefix', style: ink.mono(16, weight: FontWeight.w700, color: ink.accent)),
                AcsButton(ink, '+', _prefix < 32 ? () => setState(() => _prefix++) : null),
                Text('${32 - _prefix} biți de stație', style: ink.mono(13, color: ink.muted)),
              ]),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  row('adresa', bits),
                  const SizedBox(height: 2),
                  row('masca', bitsOf(maskOf(_prefix)), mask: true),
                ]),
              ),
              const SizedBox(height: 8),
              Text(
                  'Adresa de rețea are toți biții de stație 0, cea de difuzare îi are pe toți 1. Un octet: 128 64 32 16 8 4 2 1.',
                  style: ink.mono(12.5, color: ink.muted)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        fieldsView(),
      ],
    );
  }
}

// ---------------------------------------------------------------- EG
class MarketWorkspace extends AcsWorkspace {
  const MarketWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<MarketWorkspace> createState() => _MarketWorkspaceState();
}

class _MarketWorkspaceState extends State<MarketWorkspace> with _Fields<MarketWorkspace> {
  // Qd = a - b·P, Qs = c + d·P; null when the task has no curves
  late final List<double>? _curves = (widget.problem.spec['curves'] as List?)?.map((v) => (v as num).toDouble()).toList();
  late double _price = (widget.problem.spec['price'] as num?)?.toDouble() ?? 0;

  double get _pMax => _curves![0] / _curves[1]; // where nothing is asked for any more

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final c = _curves;
    String n(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c != null) ...[
          AcsBox(
            ink,
            title: ink.terminal ? 'cererea (coboară) și oferta (urcă): mută prețul de probă' : 'Cererea (coboară) și oferta (urcă): mută prețul de probă',
            color: ink.bg,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: widget.narrow ? 1.2 : 2.2, child: CustomPaint(painter: _MarketPainter(c, _price, _pMax, ink))),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: ink.accent, inactiveTrackColor: ink.line, thumbColor: ink.accent, overlayColor: ink.accent.withValues(alpha: 0.12)),
                  child: Slider(value: _price.clamp(0, _pMax), min: 0, max: _pMax, divisions: 200, onChanged: (v) => setState(() => _price = v)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Builder(builder: (context) {
                    final qd = math.max(0.0, c[0] - c[1] * _price), qs = math.max(0.0, c[2] + c[3] * _price);
                    final gap = qd - qs;
                    return Text(
                        'la prețul ${n(_price)}: se cer ${n(qd)}, se oferă ${n(qs)} · ${gap.abs() < 0.005 ? 'piața e în echilibru' : (gap > 0 ? 'penurie de ${n(gap)}' : 'surplus de ${n(-gap)}')}',
                        style: ink.mono(13.5, color: gap.abs() < 0.005 ? ink.good : ink.fg));
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        fieldsView(),
      ],
    );
  }
}

class _MarketPainter extends CustomPainter {
  final List<double> c;
  final double price, pMax;
  final AcsInk ink;
  _MarketPainter(this.c, this.price, this.pMax, this.ink);

  @override
  void paint(Canvas canvas, Size size) {
    const l = 44.0, b = 24.0, t = 8.0, r = 12.0;
    final qMax = math.max(c[0], c[2] + c[3] * pMax) * 1.05;
    Offset at(double q, double p) => Offset(l + q / qMax * (size.width - l - r), size.height - b - p / pMax * (size.height - b - t));
    final axis = Paint()
      ..color = ink.muted
      ..strokeWidth = 1.4;
    canvas.drawLine(at(0, 0), at(qMax, 0), axis);
    canvas.drawLine(at(0, 0), at(0, pMax), axis);
    void label(String s, Offset p, Color col, {bool right = false}) {
      final tp = TextPainter(text: TextSpan(text: s, style: ink.mono(11.5, color: col)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, right ? p - Offset(tp.width + 4, tp.height / 2) : p);
    }

    for (var i = 1; i <= 4; i++) {
      final p = pMax * i / 4, q = qMax * i / 4;
      label(p.toStringAsFixed(p >= 20 ? 0 : 1), at(0, p), ink.muted, right: true);
      label(q.toStringAsFixed(0), at(q, 0) + const Offset(-8, 5), ink.muted);
      canvas.drawLine(at(0, p), at(qMax, p), Paint()..color = ink.line);
    }
    label('P', at(0, pMax) + const Offset(4, -4), ink.muted);
    label('Q', at(qMax, 0) + const Offset(-12, -16), ink.muted);
    final demand = Paint()
      ..color = ink.accent
      ..strokeWidth = 2.2;
    final supply = Paint()
      ..color = ink.warn
      ..strokeWidth = 2.2;
    canvas.drawLine(at(c[0], 0), at(0, pMax), demand);
    final p0 = c[2] < 0 ? -c[2] / c[3] : 0.0; // the supply starts where it turns positive
    canvas.drawLine(at(math.max(0, c[2] + c[3] * p0), p0), at(c[2] + c[3] * pMax, pMax), supply);
    label('C', at(c[0] * 0.9, pMax * 0.1) + const Offset(4, -16), ink.accent);
    label('O', at(c[2] + c[3] * pMax * 0.95, pMax * 0.95) + const Offset(6, -4), ink.warn);
    // the trial price, with what is asked and offered at it
    final qd = math.max(0.0, c[0] - c[1] * price), qs = math.max(0.0, c[2] + c[3] * price);
    final trial = Paint()
      ..color = ink.strong
      ..strokeWidth = 1.2;
    canvas.drawLine(at(0, price), at(math.max(qd, qs), price), trial);
    canvas.drawCircle(at(qd, price), 4.5, Paint()..color = ink.accent);
    canvas.drawCircle(at(qs, price), 4.5, Paint()..color = ink.warn);
  }

  @override
  bool shouldRepaint(_MarketPainter old) => true;
}
