// =============================================================================
// THE PUMPING LEMMAS AS A GAME, AND MACHINES WITH MEMORY, RUNNING
//   Pumping: the student picks a word of the language at least p long; every
//   way the lemma allows to cut it is listed, and for each the student picks
//   an i that throws the word out of the language. A cut that no i breaks
//   means the word chosen proves nothing. The regular lemma cuts xyz with
//   |xy| ≤ p, |y| ≥ 1; the context-free one cuts uvxyz with |vxy| ≤ p,
//   |vy| ≥ 1.
//   A pushdown automaton's accepting run, the stack drawn; a Turing
//   machine's tape and head, step by step.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/lfa.dart';
import '../engine/lfa_algo.dart';
import '../engine/lfa_machines.dart';
import '../ws/ws_common.dart' show AcsField;
import 'diagram_view.dart';
import 'teorie_kit.dart';

// ---------------------------------------------------------------- languages for the game
class PumpLang {
  final String name; // as written in the lesson
  final String alphabet;
  final bool Function(String) has;
  final String Function(int p) sample; // a good word to start from
  const PumpLang(this.name, this.alphabet, this.has, this.sample);
}

bool _isPrime(int n) {
  if (n < 2) return false;
  for (var d = 2; d * d <= n; d++) {
    if (n % d == 0) return false;
  }
  return true;
}

int _count(String w, String c) => w.split('').where((x) => x == c).length;

final Map<String, PumpLang> pumpLangs = {
  'anbn': PumpLang('L = {aⁿbⁿ | n ≥ 0}', 'ab', (w) {
    final n = w.length ~/ 2;
    return w.length.isEven && w == 'a' * n + 'b' * n;
  }, (p) => 'a' * p + 'b' * p),
  'eqab': PumpLang('L = {w ∈ {a, b}* | #a(w) = #b(w)}', 'ab', (w) => _count(w, 'a') == _count(w, 'b'), (p) => 'a' * p + 'b' * p),
  'pal': PumpLang('L = {w ∈ {a, b}* | w = wᴿ}', 'ab', (w) => w == w.split('').reversed.join(), (p) => '${'a' * p}b${'a' * p}'),
  'ww': PumpLang('L = {ww | w ∈ {a, b}*}', 'ab', (w) => w.length.isEven && w.substring(0, w.length ~/ 2) == w.substring(w.length ~/ 2), (p) => '${'a' * p}b${'a' * p}b'),
  'asq': PumpLang('L = {a^(n²) | n ≥ 0}', 'a', (w) {
    final r = math.sqrt(w.length).round();
    return r * r == w.length && !w.contains('b');
  }, (p) => 'a' * (p * p)),
  'aprime': PumpLang('L = {aᵖ | p prim}', 'a', (w) => _isPrime(w.length), (p) {
    var q = p + 2;
    while (!_isPrime(q)) {
      q++;
    }
    return 'a' * q;
  }),
  'anbmlt': PumpLang('L = {aⁿbᵐ | n < m}', 'ab', (w) {
    final m = RegExp(r'^(a*)(b*)$').firstMatch(w);
    return m != null && m[1]!.length < m[2]!.length;
  }, (p) => '${'a' * p}${'b' * (p + 1)}'),
  'anbncn': PumpLang('L = {aⁿbⁿcⁿ | n ≥ 0}', 'abc', (w) {
    final n = w.length ~/ 3;
    return w.length % 3 == 0 && w == 'a' * n + 'b' * n + 'c' * n;
  }, (p) => 'a' * p + 'b' * p + 'c' * p),
  '0n1n0n': PumpLang('L = {0ⁿ1ⁿ0ⁿ | n ≥ 0}', '01', (w) {
    final n = w.length ~/ 3;
    return w.length % 3 == 0 && w == '0' * n + '1' * n + '0' * n;
  }, (p) => '0' * p + '1' * p + '0' * p),
  'astar': PumpLang('L = a*b* (regulat)', 'ab', (w) => RegExp(r'^a*b*$').hasMatch(w), (p) => 'a' * p + 'b' * p),
};

class PumpViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const PumpViz(this.ink, this.spec, {super.key});

  @override
  State<PumpViz> createState() => _PumpVizState();
}

class _PumpVizState extends State<PumpViz> {
  late String _lang = '${widget.spec['lang'] ?? 'anbn'}';
  late final List<String> _choices = [for (final x in widget.spec['langs'] as List? ?? [widget.spec['lang'] ?? 'anbn']) '$x'];
  late final bool cfl = widget.spec['mode'] == 'cfl';
  late int _p = (widget.spec['p'] as num?)?.toInt() ?? (cfl ? 2 : 3);
  late final TextEditingController _w = TextEditingController(text: pumpLangs[_lang]!.sample(_p));
  final Map<int, int> _picked = {}; // split index -> i chosen
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _w.addListener(() => setState(() {
          _picked.clear();
          _page = 0;
        }));
  }

  @override
  void dispose() {
    _w.dispose();
    super.dispose();
  }

  /// Every cut the lemma allows: regular (x, y, z), or context-free (u, v, x, y, z).
  List<List<String>> _splits(String w) {
    final out = <List<String>>[];
    if (!cfl) {
      for (var i = 0; i <= math.min(_p, w.length); i++) {
        for (var j = i + 1; j <= math.min(_p, w.length); j++) {
          out.add([w.substring(0, i), w.substring(i, j), w.substring(j)]);
        }
      }
      return out;
    }
    for (var s = 0; s < w.length; s++) {
      for (var lv = 0; lv <= _p; lv++) {
        for (var lx = 0; lv + lx <= _p; lx++) {
          for (var ly = 0; lv + lx + ly <= _p; ly++) {
            if (lv + ly == 0 || s + lv + lx + ly > w.length) continue;
            out.add([w.substring(0, s), w.substring(s, s + lv), w.substring(s + lv, s + lv + lx), w.substring(s + lv + lx, s + lv + lx + ly), w.substring(s + lv + lx + ly)]);
          }
        }
      }
    }
    return out;
  }

  String _pump(List<String> c, int i) => cfl ? c[0] + c[1] * i + c[2] + c[3] * i + c[4] : c[0] + c[1] * i + c[2];

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final lang = pumpLangs[_lang]!;
    final w = _w.text;
    final inL = w.split('').every(lang.alphabet.split('').contains) && lang.has(w);
    final long = w.length >= _p;
    final splits = inL && long ? _splits(w) : const <List<String>>[];
    final safe = <int>{for (final (k, c) in splits.indexed) if ([0, 2, 3].every((i) => lang.has(_pump(c, i)))) k};
    final beaten = _picked.entries.where((e) => !lang.has(_pump(splits[e.key], e.value))).length;
    final colors = [ink.fg, ink.accent, ink.fg, ink.warn, ink.fg];
    const per = 12;
    final pages = (splits.length / per).ceil();
    final int page = _page.clamp(0, math.max(0, pages - 1)).toInt();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final id in _choices)
          AcsButton(ink, pumpLangs[id]!.name, () => setState(() {
                _lang = id;
                _w.text = pumpLangs[id]!.sample(_p);
              }), primary: id == _lang),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('1. Adversarul alege p =', style: ink.mono(13.5, color: ink.muted)),
        for (final v in cfl ? const [1, 2, 3] : const [2, 3, 4, 5])
          AcsButton(ink, '$v', () => setState(() {
                _p = v;
                _w.text = lang.sample(v);
              }), primary: v == _p),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('2. Tu alegi w ∈ L cu |w| ≥ p:', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _w, width: 220),
        AcsButton(ink, 'cuvântul sugerat', () => _w.text = lang.sample(_p)),
      ]),
      const SizedBox(height: 6),
      if (!inL)
        Text('${wordShown(w)} nu e în L: alege un cuvânt din limbaj.', style: ink.mono(13.5, color: ink.bad))
      else if (!long)
        Text('|w| = ${w.length} < p = $_p: cuvântul trebuie să aibă cel puțin p simboluri.', style: ink.mono(13.5, color: ink.bad))
      else ...[
        Text(
            cfl
                ? '3. Adversarul poate tăia w = uvxyz în ${splits.length} feluri (|vxy| ≤ $_p, |vy| ≥ 1). Pentru fiecare, alege i astfel încât uvⁱxyⁱz ∉ L.'
                : '3. Adversarul poate tăia w = xyz în ${splits.length} feluri (|xy| ≤ $_p, |y| ≥ 1). Pentru fiecare, alege i astfel încât xyⁱz ∉ L.',
            style: ink.mono(13.5, color: ink.fg)),
        const SizedBox(height: 4),
        if (safe.isNotEmpty)
          Text('Atenție: ${safe.length} ${safe.length == 1 ? 'tăietură rămâne' : 'tăieturi rămân'} în L pentru i = 0, 2, 3. Cu acest cuvânt (sau acest p) nu se poate demonstra nimic; încearcă alt cuvânt.',
              style: ink.mono(13.5, weight: FontWeight.w700, color: ink.warn))
        else
          Text(beaten == splits.length ? 'Ai câștigat: orice tăietură ar alege adversarul, ai un i care scoate cuvântul din L. Deci L nu respectă lema.' : 'Învinse: $beaten din ${splits.length}.',
              style: ink.mono(13.5, weight: FontWeight.w700, color: beaten == splits.length ? ink.good : ink.muted)),
        const SizedBox(height: 8),
        for (final (k, c) in splits.indexed.skip(page * per).take(per))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text.rich(
                  TextSpan(children: [
                    for (final (j, part) in c.indexed) ...[
                      if (j > 0) TextSpan(text: '|', style: TextStyle(color: ink.dim)),
                      TextSpan(text: part.isEmpty ? lfaEps : part, style: TextStyle(color: part.isEmpty ? ink.dim : (cfl ? colors[j] : (j == 1 ? ink.accent : ink.fg)), fontWeight: (cfl ? j == 1 || j == 3 : j == 1) ? FontWeight.w700 : null)),
                    ],
                  ]),
                  style: ink.mono(14.5)),
              for (final i in const [0, 2, 3])
                AcsButton(ink, 'i=$i', () => setState(() => _picked[k] = i), primary: _picked[k] == i),
              if (_picked[k] != null)
                () {
                  final out = _pump(c, _picked[k]!);
                  final still = lang.has(out);
                  return Text('${out.length > 28 ? '${out.substring(0, 28)}…' : wordShown(out)} ${still ? '∈ L' : '∉ L ✓'}', style: ink.mono(13.5, weight: FontWeight.w700, color: still ? ink.bad : ink.good));
                }(),
              if (safe.contains(k)) Text('(nu se poate scoate din L)', style: ink.mono(12.5, color: ink.warn)),
            ]),
          ),
        if (pages > 1)
          Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            AcsButton(ink, '◀', page > 0 ? () => setState(() => _page = page - 1) : null),
            Text('pagina ${page + 1} din $pages', style: ink.mono(13, color: ink.muted)),
            AcsButton(ink, '▶', page < pages - 1 ? () => setState(() => _page = page + 1) : null),
            AcsButton(ink, 'alege automat câte un i', () => setState(() {
                  for (final (k, c) in splits.indexed) {
                    for (final i in const [0, 2, 3]) {
                      if (!lang.has(_pump(c, i))) {
                        _picked[k] = i;
                        break;
                      }
                    }
                  }
                })),
          ])
        else
          AcsButton(ink, 'alege automat câte un i', () => setState(() {
                for (final (k, c) in splits.indexed) {
                  for (final i in const [0, 2, 3]) {
                    if (!lang.has(_pump(c, i))) {
                      _picked[k] = i;
                      break;
                    }
                  }
                }
              })),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- pushdown
class PdaViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const PdaViz(this.ink, this.spec, {super.key});

  @override
  State<PdaViz> createState() => _PdaVizState();
}

class _PdaVizState extends State<PdaViz> {
  late final Pda pda = Pda.parse('${widget.spec['pda']}');
  late final List<String> words = [for (final w in widget.spec['words'] as List? ?? const []) '$w'];
  late final TextEditingController _w = TextEditingController(text: words.isEmpty ? '' : words.first);
  int _k = 0;

  @override
  void initState() {
    super.initState();
    _w.addListener(() => setState(() => _k = 0));
  }

  @override
  void dispose() {
    _w.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final w = _w.text;
    final run = pda.run(w);
    final k = _k.clamp(0, run.path.length - 1);
    final c = run.path[k];
    final mv = run.moves[k];
    final arrows = pda.arrows();
    final si = pda.states.indexOf(pda.start);
    // the start drawn first: reorder so it is state 0 for the diagram
    final order = [si, for (var i = 0; i < pda.states.length; i++) if (i != si) i];
    final d = Diagram([for (final i in order) pda.states[i]], placesOf(widget.spec['pos']) ?? const [], {for (final (j, i) in order.indexed) if (pda.finals.contains(pda.states[i])) j}, 0,
        [for (final (f, t, l) in arrows) (order.indexOf(f), order.indexOf(t), l)]);
    final dd = d.pos.length == d.n ? d : d.layered();
    final hot = <int>{};
    if (mv != null) {
      final f = order.indexOf(pda.states.indexOf(mv.from)), t = order.indexOf(pda.states.indexOf(mv.to));
      for (final (i, (a, b, _)) in dd.edges.indexed) {
        if (a == f && b == t) hot.add(i);
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DiagramView(ink, dd, active: {order.indexOf(pda.states.indexOf(c.state))}, hot: hot, maxHeight: 300),
      const SizedBox(height: 6),
      Text('Eticheta a,β/γ: citește a, scoate β din vârful stivei, pune γ. Acceptă: tot cuvântul citit, o stare finală, stiva goală.', style: ink.mono(12.5, color: ink.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('cuvântul:', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _w, width: 160, hint: 'gol = ε'),
        for (final x in words) AcsButton(ink, wordShown(x), () => _w.text = x),
      ]),
      const SizedBox(height: 8),
      StepBar(ink, step: k, count: run.path.length, onChanged: (v) => setState(() => _k = v), every: const Duration(milliseconds: 750)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'configurația: ', style: TextStyle(color: ink.muted)),
                  TextSpan(text: '(${c.state}, ${wordShown(w.substring(c.pos))}, ${wordShown(c.stack)})', style: TextStyle(color: ink.accent, fontWeight: FontWeight.w700)),
                ]),
                style: ink.mono(14)),
            const SizedBox(height: 4),
            Text(mv == null ? 'starea inițială, stiva goală' : 'tranziția: ${mv.show()}', style: ink.mono(13.5, color: ink.fg)),
            const SizedBox(height: 4),
            Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'citit: ', style: TextStyle(color: ink.muted)),
                  TextSpan(text: w.substring(0, c.pos), style: TextStyle(color: ink.accent, fontWeight: FontWeight.w700)),
                  TextSpan(text: w.substring(c.pos), style: TextStyle(color: ink.dim)),
                ]),
                style: ink.mono(14)),
            if (k == run.path.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    run.accepted
                        ? 'acceptat: am găsit un drum până la o stare finală cu tot cuvântul citit și stiva goală'
                        : 'respins: niciun drum nu se termină într-o stare finală cu stiva goală${run.cut ? ' (căutarea s-a oprit la limită)' : ''}; arăt drumul care a citit cel mai mult',
                    style: ink.mono(13.5, weight: FontWeight.w700, color: run.accepted ? ink.good : ink.bad)),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Column(children: [
          Text('stiva', style: ink.mono(12, color: ink.muted)),
          const SizedBox(height: 4),
          Container(
            width: 46,
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: ink.strong), right: BorderSide(color: ink.strong), bottom: BorderSide(color: ink.strong, width: 2))),
            child: Column(children: [
              for (final (i, s) in c.stack.split('').take(10).indexed)
                Container(
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  color: i == 0 ? ink.accent.withValues(alpha: 0.25) : ink.panel,
                  child: Text(s, style: ink.mono(13, weight: FontWeight.w700, color: ink.strong)),
                ),
              if (c.stack.length > 10) Text('…', style: ink.mono(12, color: ink.dim)),
            ]),
          ),
        ]),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------- Turing
class TmViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const TmViz(this.ink, this.spec, {super.key});

  @override
  State<TmViz> createState() => _TmVizState();
}

class _TmVizState extends State<TmViz> {
  late final Tm tm = Tm.parse('${widget.spec['tm']}');
  late final List<String> words = [for (final w in widget.spec['words'] as List? ?? const []) '$w'];
  late final TextEditingController _w = TextEditingController(text: words.isEmpty ? '' : words.first);
  int _k = 0;

  @override
  void initState() {
    super.initState();
    _w.addListener(() => setState(() => _k = 0));
  }

  @override
  void dispose() {
    _w.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final w = _w.text;
    final run = tm.run(w, limit: 400, atEnd: widget.spec['head'] == 'last');
    final k = _k.clamp(0, run.steps.length - 1);
    final st = run.steps[k];
    final si = tm.states.indexOf(tm.start);
    final order = [si, for (var i = 0; i < tm.states.length; i++) if (i != si) i];
    final arrows = tm.arrows();
    final d0 = Diagram([for (final i in order) tm.states[i]], placesOf(widget.spec['pos']) ?? const [], {for (final (j, i) in order.indexed) if (Tm.accepting.contains(tm.states[i])) j}, 0,
        [for (final (f, t, l) in arrows) (order.indexOf(f), order.indexOf(t), l)]);
    final d = d0.pos.length == d0.n ? d0 : d0.layered();
    final (tape, head) = st.window(pad: 2);
    final end = k == run.steps.length - 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DiagramView(ink, d, active: {order.indexOf(tm.states.indexOf(st.state))}, maxHeight: 300),
      const SizedBox(height: 4),
      Text('Eticheta a/b,D: citește a, scrie b, mută capul D (L stânga, R dreapta, S pe loc). # e blancul.', style: ink.mono(12.5, color: ink.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('intrarea:', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _w, width: 160, hint: 'gol = ε'),
        for (final x in words) AcsButton(ink, wordShown(x), () => _w.text = x),
      ]),
      const SizedBox(height: 8),
      StepBar(ink, step: k, count: run.steps.length, onChanged: (v) => setState(() => _k = v), every: const Duration(milliseconds: 350)),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            for (var i = 0; i < tape.length; i++)
              Container(
                width: 32,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == head ? ink.accent.withValues(alpha: 0.22) : ink.panel,
                  border: Border.all(color: i == head ? ink.accent : ink.line, width: i == head ? 2 : 0.8),
                ),
                child: Text(tape[i], style: ink.mono(15, weight: FontWeight.w700, color: tape[i] == tmBlank ? ink.dim : ink.strong)),
              ),
          ]),
          Row(children: [
            for (var i = 0; i < tape.length; i++) SizedBox(width: 32, child: Center(child: Text(i == head ? '▲' : '', style: ink.mono(13, color: ink.accent)))),
          ]),
          Row(children: [
            SizedBox(width: 32.0 * head - 20 < 0 ? 0 : 32.0 * head - 20),
            Text(st.state, style: ink.mono(13, weight: FontWeight.w700, color: ink.accent)),
          ]),
        ]),
      ),
      if (end)
        Text(
            switch (run.end) {
              TmEnd.accept => 'oprită în ${st.state}: acceptă${st.output.isEmpty ? '' : '; pe bandă: ${st.output}'}',
              TmEnd.reject => 'oprită în ${st.state}: respinge',
              TmEnd.stuck => 'nicio tranziție pentru (${st.state}, ${(st.tape[st.head] ?? tmBlank)}): se blochează, deci respinge',
              TmEnd.running => 'după 400 de pași încă nu s-a oprit',
            },
            style: ink.mono(13.5, weight: FontWeight.w700, color: run.end == TmEnd.accept ? ink.good : ink.bad)),
    ]);
  }
}
