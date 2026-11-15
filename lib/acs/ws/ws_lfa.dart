// =============================================================================
// LFA: AN AUTOMATON, A REGULAR EXPRESSION OR A GRAMMAR FOR A LANGUAGE
//   The automaton is written in its transition table and drawn as it is
//   written; a word can be walked through it symbol by symbol. The check
//   compares languages, not drawings: a wrong answer gets the shortest word
//   that gives it away.
// =============================================================================

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/lfa.dart';
import '../engine/lfa_algo.dart' show Diagram;
import '../engine/lfa_machines.dart';
import '../teorie/diagram_view.dart';
import 'ws_common.dart';

class LfaWorkspace extends AcsWorkspace {
  const LfaWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<LfaWorkspace> createState() => _LfaWorkspaceState();
}

class _LfaWorkspaceState extends State<LfaWorkspace> {
  late final LfaTask _task = LfaTask.fromSpec(widget.problem.spec);
  bool get _auto => _task.mode == 'dfa' || _task.mode == 'nfa';
  List<String> get _cols => [..._task.alphabet, if (_task.mode == 'nfa') lfaEps];

  // the automaton's table
  int _n = 2;
  final Set<int> _final = {};
  final Map<String, TextEditingController> _cells = {};
  // a regular expression, or a grammar
  late final TextEditingController _text = _task.mode == 'cfg'
      ? acsCodeController('', const {}, comment: '#')
      : (_task.machine ? acsCodeController('', const {'start', 'final'}, comment: '//') : TextEditingController());
  final TextEditingController _word = TextEditingController();
  int _at = 0; // how much of the word has been read
  List<Check> _checks = const [];

  TextEditingController _cell(int s, String a) => _cells.putIfAbsent('$s $a', () => TextEditingController()..addListener(_changed));

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    _word.addListener(() => setState(() => _at = 0));
    final start = widget.problem.spec['starter'];
    if (start is String) _text.text = start;
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        final j = json.decode(d) as Map;
        setState(() {
          if (_auto && j['a'] != null) _load(Nfa.fromJson(j['a'] as Map));
          if (!_auto && j['text'] is String) _text.text = j['text'] as String;
        });
      } catch (_) {
        // an old draft we can't read: start clean
      }
    });
  }

  @override
  void dispose() {
    for (final c in _cells.values) {
      c.dispose();
    }
    _text.dispose();
    _word.dispose();
    super.dispose();
  }

  void _load(Nfa a) {
    _n = a.states.clamp(1, 12);
    _final
      ..clear()
      ..addAll(a.accepting);
    for (var s = 0; s < _n; s++) {
      for (final c in _cols) {
        _cell(s, c).text = [for (final t in a.targets(s, c).toList()..sort()) 'q$t'].join(', ');
      }
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() => _checks = const []);
    AcsProgress.saveDraft(widget.problem, json.encode(_auto ? {'a': _automaton().toJson()} : {'text': _text.text}));
  }

  /// The states a cell names: "q1, q2", "1 2"; what is not a state is left out.
  Set<int> _targets(String text) => {
        for (final m in RegExp(r'\d+').allMatches(text))
          if (int.parse(m[0]!) < _n) int.parse(m[0]!),
      };

  bool _cellOk(String text) => RegExp(r'^[\sq,;\-\d]*$').hasMatch(text) && RegExp(r'\d+').allMatches(text).every((m) => int.parse(m[0]!) < _n);

  Nfa _automaton() => Nfa(_n, {..._final.where((f) => f < _n)}, {
        for (var s = 0; s < _n; s++) s: {for (final c in _cols) c: _targets(_cell(s, c).text)},
      });

  /// The automaton as the student filled it in, one state a line.
  String _tableText() => [
        'stări: ${[for (var s = 0; s < _n; s++) 'q$s'].join(', ')}; inițială q0; finale: ${[for (final f in _final.where((f) => f < _n).toList()..sort()) 'q$f'].join(', ')}',
        for (var s = 0; s < _n; s++)
          for (final c in _cols) 'δ(q$s, $c) = ${_cell(s, c).text.trim().isEmpty ? (_task.mode == 'nfa' ? '∅' : '(gol)') : _cell(s, c).text.trim()}',
      ].join('\n');

  void _verify() {
    final r = _auto
        ? _task.checkAutomaton(_automaton())
        : switch (_task.mode) {
            'regex' => _task.checkRegex(_text.text),
            'pda' => _task.checkPda(_text.text),
            'tm' || 'tmf' => _task.checkTm(_text.text),
            _ => _task.checkGrammar(_text.text),
          };
    setState(() => _checks = [for (final (l, ok, d) in r) Check(l, ok, d)]);
    widget.onVerdict(r.every((c) => c.$2), Attempt(_auto ? _tableText() : _text.text, reportOfTriples(r)));
  }

  void _resize(int d) {
    setState(() {
      _n = (_n + d).clamp(1, 12);
      _final.removeWhere((f) => f >= _n);
    });
    _changed();
  }

  /// Does the student's answer accept [w]? null when it can't be read.
  bool? _mine(String w) {
    try {
      if (_auto) return _automaton().accepts(w);
      if (_task.mode == 'regex') return Regex.parse(_text.text, _task.alphabet).accepts(w);
      if (_task.mode == 'pda') return Pda.parse(_text.text).accepts(w);
      if (_task.mode == 'tm') return Tm.parse(_text.text).accepts(w);
      return w.length <= _task.upTo ? Grammar.parse(_text.text).words(_task.upTo).contains(w) : null;
    } on LfaError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_auto) ..._automatonParts(ink) else if (_task.machine) ..._machineParts(ink) else ..._textParts(ink),
        const SizedBox(height: 12),
        _tester(ink),
        const SizedBox(height: 12),
        ToolRow([AcsButton(ink, 'verifică limbajul', _verify, primary: true, icon: Icons.check)]),
        if (_checks.isNotEmpty) ...[const SizedBox(height: 12), ChecksView(ink, _checks)],
      ],
    );
  }

  // ---------------------------------------------------------------- automaton
  List<Widget> _automatonParts(AcsInk ink) {
    final a = _automaton();
    final w = _word.text;
    final sets = w.split('').every(_task.alphabet.contains) ? a.run(w) : null;
    final active = sets == null ? const <int>{} : sets[_at.clamp(0, sets.length - 1)];
    final head = ink.mono(13.5, weight: FontWeight.w700, color: ink.muted);
    final cellW = widget.narrow ? 74.0 : 96.0;
    return [
      Text(
          ink.terminal
              ? '# tabela de tranziții: în fiecare căsuță, starea în care ajungi (q0 e starea inițială)'
              : 'Tabela de tranziții: în fiecare căsuță, starea în care ajungi (q0 e starea inițială).${_task.mode == 'nfa' ? ' Mai multe stări se despart prin virgulă.' : ''}',
          style: ink.mono(13.5, color: ink.muted)),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SizedBox(width: 92, child: Text('stare', style: head)),
              for (final c in _cols) SizedBox(width: cellW + 8, child: Text(c, style: head)),
              Text('finală', style: head),
            ]),
            for (var s = 0; s < _n; s++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  SizedBox(
                    width: 92,
                    child: Text('${s == 0 ? '→ ' : '  '}q$s', style: ink.mono(15, weight: FontWeight.w700, color: active.contains(s) ? ink.accent : ink.strong)),
                  ),
                  for (final c in _cols)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AcsField(ink, _cell(s, c), width: cellW, hint: 'q?', ok: _cellOk(_cell(s, c).text) ? null : false),
                    ),
                  AcsTap(
                    label: 'q$s finală',
                    onTap: () {
                      setState(() => _final.contains(s) ? _final.remove(s) : _final.add(s));
                      _changed();
                    },
                    builder: (h) => Text(ink.terminal ? (_final.contains(s) ? '[x]' : '[ ]') : (_final.contains(s) ? '☑' : '☐'),
                        style: ink.mono(16, weight: FontWeight.w700, color: _final.contains(s) ? ink.good : (h ? ink.strong : ink.dim))),
                  ),
                ]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ToolRow([
        AcsButton(ink, '+ stare', _n < 12 ? () => _resize(1) : null),
        AcsButton(ink, '− stare', _n > 1 ? () => _resize(-1) : null),
        Text('$_n ${_n == 1 ? 'stare' : 'stări'}${_task.maxStates == null ? '' : ' · cel mult ${_task.maxStates}'}', style: ink.mono(13, color: ink.muted)),
      ]),
      const SizedBox(height: 12),
      AcsBox(
        ink,
        title: ink.terminal ? 'automatul tău, desenat din tabelă' : 'Automatul tău, desenat din tabelă',
        color: ink.bg,
        child: AspectRatio(
          aspectRatio: widget.narrow ? 1.15 : 2.1,
          child: CustomPaint(painter: _DiagramPainter(a, _cols, ink, active)),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------- text
  List<Widget> _textParts(AcsInk ink) {
    if (_task.mode == 'regex') {
      return [
        Text(
            ink.terminal
                ? '# expresia: alăturare, ∪ sau | pentru reuniune, * + ?, ε cuvântul vid, ∅ limbajul vid'
                : 'Expresia: alăturare, ∪ sau | pentru reuniune, * + ?, ε pentru cuvântul vid, ∅ pentru limbajul vid.',
            style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) => AcsField(ink, _text, width: c.maxWidth, hint: 'de exemplu (a∪b)*abb', onSubmitted: (_) => _verify())),
        const SizedBox(height: 8),
        ToolRow([
          for (final sym in const ['∪', '*', 'ε', '∅', '(', ')'])
            AcsButton(ink, sym, () {
              final v = _text.value;
              final at = v.selection.isValid ? v.selection.end : v.text.length;
              _text.value = TextEditingValue(text: v.text.replaceRange(at, at, sym), selection: TextSelection.collapsed(offset: at + sym.length));
            }),
        ]),
      ];
    }
    List<String> sample = const [];
    String? error;
    try {
      final all = Grammar.parse(_text.text).words(_task.upTo).toList()..sort((x, y) => x.length != y.length ? x.length - y.length : x.compareTo(y));
      sample = all.take(14).toList();
    } on LfaError catch (e) {
      error = _text.text.trim().isEmpty ? null : e.message;
    }
    return [
      Text(
          ink.terminal
              ? '# o regulă pe linie: S -> aSb | ε   (literele mari sunt neterminale, prima regulă e a simbolului de start)'
              : 'O regulă pe linie: S -> aSb | ε. Literele mari sunt neterminale; prima regulă e a simbolului de start.',
          style: ink.mono(13.5, color: ink.muted)),
      const SizedBox(height: 8),
      AcsCodeEditor(ink, _text, minHeight: 150, comment: '#', onRun: _verify),
      const SizedBox(height: 8),
      AcsBox(
        ink,
        title: ink.terminal ? 'ce generează gramatica ta (cele mai scurte cuvinte)' : 'Ce generează gramatica ta (cele mai scurte cuvinte)',
        color: ink.bg,
        child: Text(error ?? (sample.isEmpty ? (_text.text.trim().isEmpty ? 'scrie o regulă' : 'niciun cuvânt de cel mult ${_task.upTo} simboluri') : sample.map((w) => w.isEmpty ? lfaEps : w).join('   ')),
            style: ink.mono(14, color: error == null ? ink.strong : ink.bad)),
      ),
    ];
  }

  // ---------------------------------------------------------------- a machine
  List<Widget> _machineParts(AcsInk ink) {
    final pda = _task.mode == 'pda';
    String? error;
    Diagram? d;
    try {
      if (pda) {
        final p = Pda.parse(_text.text);
        final si = p.states.indexOf(p.start);
        final order = [si, for (var i = 0; i < p.states.length; i++) if (i != si) i];
        d = Diagram([for (final i in order) p.states[i]], const [], {for (final (j, i) in order.indexed) if (p.finals.contains(p.states[i])) j}, 0,
            [for (final (f, t, l) in p.arrows()) (order.indexOf(f), order.indexOf(t), l)]).layered();
      } else {
        final m = Tm.parse(_text.text);
        final si = m.states.indexOf(m.start);
        final order = [si, for (var i = 0; i < m.states.length; i++) if (i != si) i];
        d = Diagram([for (final i in order) m.states[i]], const [], {for (final (j, i) in order.indexed) if (Tm.accepting.contains(m.states[i])) j}, 0,
            [for (final (f, t, l) in m.arrows()) (order.indexOf(f), order.indexOf(t), l)]).layered();
      }
    } on LfaError catch (e) {
      error = _text.text.trim().isEmpty ? null : e.message;
    }
    final help = pda
        ? 'O tranziție pe linie: p, a, β -> q, γ (citește a, scoate β din vârf, pune γ; ε sau e = nimic). Liniile „start q0” și „final q1 q2” numesc stările. Acceptă: tot cuvântul citit, stare finală, stivă goală.'
        : 'O tranziție pe linie: q, a -> p, b, R (citește a, scrie b, mută L, R sau S). # e blancul; capul pornește pe primul simbol al intrării. Starea h (sau y) acceptă și oprește, n respinge; o tranziție care lipsește respinge.';
    return [
      Text(ink.terminal ? '# $help' : help, style: ink.mono(13.5, color: ink.muted)),
      const SizedBox(height: 8),
      AcsCodeEditor(ink, _text, minHeight: 170, comment: '//', onRun: _verify),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(error, style: ink.mono(13.5, color: ink.bad))),
      if (d != null) ...[
        const SizedBox(height: 10),
        AcsBox(ink, title: ink.terminal ? 'desenat din tranziții' : 'Desenat din tranziții', color: ink.bg, child: DiagramView(ink, d, maxHeight: 320)),
      ],
    ];
  }

  Widget _functionTester(AcsInk ink, String w, bool valid) {
    String? got;
    String? err;
    if (valid) {
      try {
        got = Tm.parse(_text.text).compute(w);
      } on LfaError catch (e) {
        err = e.message;
      }
    }
    final want = valid ? _task.wantsOutput(w) : null;
    String show(String? x) => x == null ? 'nu se oprește' : (x.isEmpty ? lfaEps : x);
    return AcsBox(
      ink,
      title: ink.terminal ? 'încearcă o intrare peste {${_task.alphabet.join(', ')}}' : 'Încearcă o intrare peste {${_task.alphabet.join(', ')}}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AcsField(ink, _word, width: 200, hint: 'gol = ε'),
        const SizedBox(height: 8),
        if (!valid)
          Text('Intrarea are simboluri din afara alfabetului.', style: ink.mono(13.5, color: ink.bad))
        else
          Text.rich(TextSpan(children: [
            TextSpan(text: 'mașina ta lasă pe bandă: ', style: TextStyle(color: ink.muted)),
            TextSpan(text: err != null ? '?' : show(got), style: TextStyle(color: err == null && got == want ? ink.good : ink.bad, fontWeight: FontWeight.w700)),
            TextSpan(text: '   ·   trebuie: ', style: TextStyle(color: ink.muted)),
            TextSpan(text: show(want), style: TextStyle(color: ink.strong, fontWeight: FontWeight.w700)),
          ]), style: ink.mono(14)),
      ]),
    );
  }

  // ---------------------------------------------------------------- a word
  Widget _tester(AcsInk ink) {
    final w = _word.text;
    final valid = w.split('').every(_task.alphabet.contains);
    if (_task.mode == 'tmf') return _functionTester(ink, w, valid);
    final mine = valid ? _mine(w) : null;
    final should = valid && (_task.exact || _task.machine || w.length <= _task.upTo) ? _task.wants(w) : null;
    String yn(bool? b) => b == null ? '?' : (b ? 'da' : 'nu');
    return AcsBox(
      ink,
      title: ink.terminal ? 'încearcă un cuvânt peste {${_task.alphabet.join(', ')}}' : 'Încearcă un cuvânt peste {${_task.alphabet.join(', ')}}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToolRow([
            AcsField(ink, _word, width: 200, hint: 'gol = ε'),
            if (_auto && valid && w.isNotEmpty) ...[
              AcsButton(ink, '← pas', _at > 0 ? () => setState(() => _at--) : null),
              AcsButton(ink, 'pas →', _at < w.length ? () => setState(() => _at++) : null),
            ],
          ]),
          const SizedBox(height: 8),
          if (!valid)
            Text('Cuvântul are simboluri din afara alfabetului.', style: ink.mono(13.5, color: ink.bad))
          else ...[
            if (_auto && w.isNotEmpty)
              Text.rich(TextSpan(children: [
                TextSpan(text: 'citit: ', style: TextStyle(color: ink.muted)),
                TextSpan(text: w.substring(0, _at.clamp(0, w.length)), style: TextStyle(color: ink.accent, fontWeight: FontWeight.w700)),
                TextSpan(text: w.substring(_at.clamp(0, w.length)), style: TextStyle(color: ink.dim)),
                TextSpan(text: '   stările aprinse în desen sunt cele în care e automatul', style: TextStyle(color: ink.muted)),
              ]), style: ink.mono(14)),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'răspunsul tău îl acceptă: ', style: TextStyle(color: ink.muted)),
              TextSpan(text: yn(mine), style: TextStyle(color: mine == should ? ink.good : ink.bad, fontWeight: FontWeight.w700)),
              TextSpan(text: '   ·   e în limbajul cerut: ', style: TextStyle(color: ink.muted)),
              TextSpan(text: yn(should), style: TextStyle(color: ink.strong, fontWeight: FontWeight.w700)),
            ]), style: ink.mono(14)),
          ],
        ],
      ),
    );
  }
}

/// The automaton on a circle: accepting states doubled, the start marked by
/// an arrow, the moves between two states gathered on one arrow.
class _DiagramPainter extends CustomPainter {
  final Nfa a;
  final List<String> cols;
  final AcsInk ink;
  final Set<int> active;
  _DiagramPainter(this.a, this.cols, this.ink, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final n = a.states;
    const r = 19.0;
    final center = size.center(Offset.zero);
    final rx = math.max(0.0, size.width / 2 - 62), ry = math.max(0.0, size.height / 2 - 46);
    Offset pos(int i) {
      if (n == 1) return center;
      final t = math.pi + 2 * math.pi * i / n; // q0 on the left
      return center + Offset(rx * math.cos(t), ry * math.sin(t));
    }

    final line = Paint()
      ..color = ink.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    void label(String t, Offset at, Color c, {double sz = 12.5, bool bold = false}) {
      final tp = TextPainter(text: TextSpan(text: t, style: ink.mono(sz, color: c, weight: bold ? FontWeight.w700 : null)), textDirection: TextDirection.ltr)..layout();
      canvas.drawRect(Rect.fromCenter(center: at, width: tp.width + 4, height: tp.height), Paint()..color = ink.bg);
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }

    void arrow(Offset tip, Offset dir) {
      final d = dir / dir.distance;
      final nrm = Offset(-d.dy, d.dx);
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - d.dx * 9 + nrm.dx * 4, tip.dy - d.dy * 9 + nrm.dy * 4)
            ..lineTo(tip.dx - d.dx * 9 - nrm.dx * 4, tip.dy - d.dy * 9 - nrm.dy * 4)
            ..close(),
          Paint()..color = ink.muted);
    }

    // the moves, gathered by where they go
    final edges = <(int, int), List<String>>{};
    for (var s = 0; s < n; s++) {
      for (final c in cols) {
        for (final t in a.targets(s, c)) {
          (edges[(s, t)] ??= []).add(c);
        }
      }
    }
    for (final e in edges.entries) {
      final (s, t) = e.key;
      final text = e.value.join(',');
      final p = pos(s);
      if (s == t) {
        // a loop, on the outside of the circle
        final out = n == 1 ? const Offset(0, -1) : (p - center) / math.max(1.0, (p - center).distance);
        final c = p + out * (r + 11);
        canvas.drawCircle(c, 12, line);
        label(text, c + out * 19, ink.fg);
        continue;
      }
      final q = pos(t);
      final d = (q - p) / (q - p).distance;
      final nrm = Offset(-d.dy, d.dx);
      // bent to one side, so the way back has its own arrow
      final both = edges.containsKey((t, s));
      final bend = both ? 16.0 : 0.0;
      final from = p + d * r + nrm * (both ? 5 : 0), to = q - d * r + nrm * (both ? 5 : 0);
      final mid = (from + to) / 2 + nrm * bend;
      canvas.drawPath(Path()..moveTo(from.dx, from.dy)..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy), line);
      arrow(to, to - mid);
      label(text, (from + to) / 2 + nrm * (bend / 2 + (both ? 8 : 0)), ink.fg);
    }
    for (var s = 0; s < n; s++) {
      final p = pos(s);
      final on = active.contains(s);
      canvas.drawCircle(p, r, Paint()..color = on ? ink.accent.withValues(alpha: 0.22) : ink.panel);
      final edge = Paint()
        ..color = on ? ink.accent : ink.strong
        ..style = PaintingStyle.stroke
        ..strokeWidth = on ? 2.2 : 1.5;
      canvas.drawCircle(p, r, edge);
      if (a.accepting.contains(s)) canvas.drawCircle(p, r - 4, edge);
      final tp = TextPainter(text: TextSpan(text: 'q$s', style: ink.mono(13, color: on ? ink.accent : ink.strong, weight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      if (s == 0) {
        final tip = p - const Offset(r, 0);
        canvas.drawLine(tip - const Offset(26, 0), tip, line);
        arrow(tip, const Offset(1, 0));
      }
    }
  }

  @override
  bool shouldRepaint(_DiagramPainter old) => true;
}
