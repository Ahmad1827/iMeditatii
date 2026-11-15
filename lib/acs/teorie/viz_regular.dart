// =============================================================================
// REGULAR LANGUAGES, SEEN WORKING
//   An automaton reading a word (the configurations written as the course
//   writes them), the subset construction row by row, state elimination with
//   the state to remove chosen by a tap, Thompson's construction growing
//   arrow by arrow, an expression taken all the way to its minimal DFA,
//   minimisation by marking pairs, and the product of two automata.
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/lfa.dart';
import '../engine/lfa_algo.dart';
import 'diagram_view.dart';
import '../ws/ws_common.dart' show AcsField;
import 'teorie_kit.dart';

Widget _caption(AcsInk ink, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: ink.mono(13, color: ink.muted)),
    );

Widget _err(AcsInk ink, String text) => Text(text, style: ink.mono(13.5, color: ink.bad));

/// A complete DFA from a deterministic table; a missing move goes to a new
/// trap state (named g).
(Dfa, List<String>) dfaOfTable(Nfa a, List<String> alphabet, List<String> names) {
  final sink = a.states;
  var needSink = false;
  final next = <List<int>>[];
  for (var s = 0; s < a.states; s++) {
    next.add([
      for (final c in alphabet)
        () {
          final t = a.targets(s, c);
          if (t.isEmpty) {
            needSink = true;
            return sink;
          }
          return t.first;
        }(),
    ]);
  }
  if (needSink) next.add([for (final _ in alphabet) sink]);
  return (Dfa(alphabet, next, [for (var s = 0; s < next.length; s++) a.accepting.contains(s)]), [...names, if (needSink) 'g']);
}

Nfa nfaOfDfa(Dfa d) => Nfa(d.states, {for (var s = 0; s < d.states; s++) if (d.accepting[s]) s}, {
      for (var s = 0; s < d.states; s++) s: {for (var k = 0; k < d.alphabet.length; k++) d.alphabet[k]: {d.next[s][k]}},
    });

// ---------------------------------------------------------------- a word, read
class AutomatonViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const AutomatonViz(this.ink, this.spec, {super.key});

  @override
  State<AutomatonViz> createState() => _AutomatonVizState();
}

class _AutomatonVizState extends State<AutomatonViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final Nfa a = nfaOf(widget.spec['a']);
  late final List<String> names = namesOf(widget.spec['names']) ?? [for (var i = 0; i < a.states; i++) 'q$i'];
  late final Diagram d = Diagram.ofNfa(a, [...sigma, lfaEps], names: names, pos: placesOf(widget.spec['pos']));
  late final List<String> words = [for (final w in widget.spec['words'] as List? ?? const []) '$w'];
  late final TextEditingController _word = TextEditingController(text: words.isEmpty ? '' : words.first);
  int _k = 0;

  @override
  void initState() {
    super.initState();
    _word.addListener(() => setState(() => _k = 0));
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  bool get _det => a.isDeterministic(sigma);

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final w = _word.text;
    final ok = w.split('').every(sigma.contains);
    final run = ok ? a.run(w) : const <Set<int>>[];
    final k = run.isEmpty ? 0 : _k.clamp(0, run.length - 1);
    final cur = run.isEmpty ? const <int>{} : run[k];
    final hot = <int>{};
    if (k > 0) {
      final prev = run[k - 1], c = w[k - 1];
      for (final (i, (f, t, label)) in d.edges.indexed) {
        final syms = label.split(',');
        if (prev.contains(f) && syms.contains(c) && a.targets(f, c).contains(t)) hot.add(i);
        if (syms.contains(lfaEps) && cur.contains(f) && cur.contains(t)) hot.add(i);
      }
    }
    String conf(int i) {
      final rest = w.substring(i);
      final st = run[i];
      final s = _det ? names[st.single] : (st.isEmpty ? '∅' : '{${(st.toList()..sort()).map((x) => names[x]).join(', ')}}');
      return '($s, ${wordShown(rest)})';
    }

    final end = run.isNotEmpty && k == run.length - 1;
    final accepted = run.isNotEmpty && run.last.any(a.accepting.contains);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DiagramView(ink, d, active: cur, hot: hot),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('cuvântul:', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _word, width: 160, hint: 'gol = ε'),
        for (final x in words) AcsButton(ink, wordShown(x), () => _word.text = x),
      ]),
      const SizedBox(height: 8),
      if (!ok)
        _err(ink, 'Cuvântul are simboluri din afara alfabetului {${sigma.join(', ')}}.')
      else ...[
        StepBar(ink, step: k, count: run.length, onChanged: (v) => setState(() => _k = v), label: (s) => s == 0 ? 'înainte de primul simbol' : 'după ${w.substring(0, s)}'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text.rich(
              TextSpan(children: [
                for (var i = 0; i <= k; i++) ...[
                  if (i > 0) TextSpan(text: '  ⊢  ', style: TextStyle(color: ink.muted)),
                  TextSpan(text: conf(i), style: TextStyle(color: i == k ? ink.accent : ink.fg, fontWeight: i == k ? FontWeight.w700 : null)),
                ],
              ]),
              style: ink.mono(14)),
        ),
        if (end)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                accepted
                    ? 'acceptat: ${_det ? 'starea la care s-a ajuns e finală' : 'printre stările în care poate fi automatul e una finală'}'
                    : (cur.isEmpty ? 'respins: automatul s-a blocat (nicio tranziție)' : 'respins: ${_det ? 'starea la care s-a ajuns nu e finală' : 'nicio stare din mulțime nu e finală'}'),
                style: ink.mono(14, weight: FontWeight.w700, color: accepted ? ink.good : ink.bad)),
          ),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- subsets
class SubsetViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const SubsetViz(this.ink, this.spec, {super.key});

  @override
  State<SubsetViz> createState() => _SubsetVizState();
}

class _SubsetVizState extends State<SubsetViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final Nfa a = nfaOf(widget.spec['a']);
  late final List<String> names = namesOf(widget.spec['names']) ?? [for (var i = 0; i < a.states; i++) 'q$i'];
  late final Diagram nd = Diagram.ofNfa(a, [...sigma, lfaEps], names: names, pos: placesOf(widget.spec['pos']));
  late final List<SubsetRow> rows = subsetRows(a, sigma);
  late final bool eps = a.moves.values.any((m) => (m[lfaEps] ?? const {}).isNotEmpty);
  int _k = 0;

  String _set(Set<int> s) => s.isEmpty ? '∅' : '{${(s.toList()..sort()).map((x) => names[x]).join(',')}}';

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final shown = rows.sublist(0, _k + 1);
    int idx(Set<int> s) => rows.indexWhere((r) => r.set.length == s.length && r.set.containsAll(s));
    // the DFA so far: the rows written, and the states they point to
    final known = <int>{for (var i = 0; i <= _k; i++) i};
    for (final r in shown) {
      for (final t in r.moves.values) {
        known.add(idx(t));
      }
    }
    final order = known.toList()..sort();
    final moves = <int, Map<String, Set<int>>>{};
    for (var i = 0; i <= _k; i++) {
      moves[order.indexOf(i)] = {for (final c in sigma) c: {order.indexOf(idx(rows[i].moves[c]!))}};
    }
    final dfa = Nfa(order.length, {for (final (j, i) in order.indexed) if (rows[i].accepting) j}, moves);
    final dd = Diagram.ofNfa(dfa, sigma, names: [for (final i in order) _set(rows[i].set)]);
    final head = ink.mono(13, weight: FontWeight.w700, color: ink.muted);
    final cur = rows[_k];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _caption(ink, 'Automatul nedeterminist (aprinse: stările din rândul de acum, ${_set(cur.set)})'),
      DiagramView(ink, nd, active: cur.set, maxHeight: 300),
      const SizedBox(height: 10),
      StepBar(ink, step: _k, count: rows.length, onChanged: (v) => setState(() => _k = v), label: (s) => 'rândul ${s + 1} din ${rows.length}'),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(horizontalInside: BorderSide(color: ink.line)),
          children: [
            TableRow(children: [
              Padding(padding: const EdgeInsets.fromLTRB(0, 4, 18, 4), child: Text('stare a AFD', style: head)),
              for (final c in sigma) Padding(padding: const EdgeInsets.fromLTRB(0, 4, 18, 4), child: Text(eps ? 'cu $c, apoi E(·)' : 'cu $c', style: head)),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('finală?', style: head)),
            ]),
            for (final (i, r) in shown.indexed)
              TableRow(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 18, 4),
                    child: Text('${i == 0 ? '→ ' : ''}${_set(r.set)}', style: ink.mono(14, weight: FontWeight.w700, color: i == _k ? ink.accent : ink.strong))),
                for (final c in sigma)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 18, 4),
                    child: Text(eps && r.raw[c]!.length != r.moves[c]!.length ? '${_set(r.raw[c]!)} → ${_set(r.moves[c]!)}' : _set(r.moves[c]!),
                        style: ink.mono(14, color: idx(r.moves[c]!) > _k ? ink.warn : ink.fg)),
                  ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(r.accepting ? 'da' : '—', style: ink.mono(14, color: r.accepting ? ink.good : ink.dim))),
              ]),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Text(
          _k < rows.length - 1
              ? 'Mulțimile scrise cu galben au apărut acum și primesc și ele un rând.'
              : 'Gata: nicio mulțime nouă. AFD-ul are ${rows.length} ${rows.length == 1 ? 'stare' : 'stări'}${rows.any((r) => r.set.isEmpty) ? ' (∅ este groapa)' : ''}.',
          style: ink.mono(13, color: ink.muted)),
      const SizedBox(height: 10),
      _caption(ink, 'AFD-ul construit până acum'),
      DiagramView(ink, dd, active: {order.indexOf(_k)}, maxHeight: 320),
    ]);
  }
}

// ---------------------------------------------------------------- state elimination
class ElimViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const ElimViz(this.ink, this.spec, {super.key});

  @override
  State<ElimViz> createState() => _ElimVizState();
}

class _ElimVizState extends State<ElimViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final Nfa a = nfaOf(widget.spec['a']);
  late final List<String> names = namesOf(widget.spec['names']) ?? [for (var i = 0; i < a.states; i++) 'q$i'];
  late final List<(double, double)> pos = () {
    final p = placesOf(widget.spec['pos']) ?? Diagram.ofNfa(a, [...sigma, lfaEps]).pos;
    var x0 = 0.0, x1 = 0.0, y = 0.0;
    for (final (i, (px, _)) in p.indexed) {
      if (i == 0 || px < x0) x0 = px;
      if (i == 0 || px > x1) x1 = px;
    }
    y = p[0].$2;
    final fy = a.accepting.isEmpty ? y : a.accepting.map((f) => p[f].$2).reduce((s, t) => s + t) / a.accepting.length;
    return [...p, (x0 - 1.4, y), (x1 + 1.4, fy)];
  }();
  late final List<Gnfa> _hist = [Gnfa.of(a, sigma, names: names)];
  final List<int> _removed = [];
  late final List<int>? _order = (widget.spec['order'] as List?)?.map((x) => (x as num).toInt()).toList();

  Gnfa get _g => _hist.last;

  void _remove(int q) {
    if (!_g.inner.contains(q)) return;
    setState(() {
      _hist.add(_g.eliminate(q));
      _removed.add(q);
    });
  }

  String _show(Re r) => r.show(sigma: sigma);

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final g = _g;
    final alive = g.alive.toList()..sort();
    final edges = <(int, int, String)>[
      for (final e in g.edges.entries) (alive.indexOf(e.key.$1), alive.indexOf(e.key.$2), _show(e.value)),
    ];
    final d = Diagram([for (final s in alive) g.names[s]], [for (final s in alive) pos[s]], {alive.indexOf(g.accept)}, alive.indexOf(g.start), edges);
    final last = _removed.isEmpty ? null : _removed.last;
    final before = _hist.length >= 2 ? _hist[_hist.length - 2] : null;
    final pairs = last == null ? const <ElimPair>[] : before!.pairs(last);
    final suggestion = g.inner.isEmpty ? null : (_order != null && _removed.length < _order.length && g.inner.contains(_order[_removed.length]) ? _order[_removed.length] : g.cheapest);
    final head = ink.mono(13, weight: FontWeight.w700, color: ink.muted);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _caption(
          ink,
          g.inner.isEmpty
              ? 'Au rămas doar qs și qf: expresia e pe singura săgeată.'
              : 'Atinge o stare ca s-o elimini (oricare merge; ordinea schimbă doar forma expresiei).'),
      DiagramView(ink, d, maxHeight: 340, marked: {if (suggestion != null) alive.indexOf(suggestion)}, onTapState: (i) => _remove(alive[i])),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (suggestion != null) AcsButton(ink, 'elimină ${g.names[suggestion]}', () => _remove(suggestion), primary: true),
        for (final q in g.inner)
          if (q != suggestion) AcsButton(ink, g.names[q], () => _remove(q)),
        AcsButton(ink, 'înapoi', _hist.length > 1 ? () => setState(() {
              _hist.removeLast();
              _removed.removeLast();
            }) : null),
        AcsButton(ink, 'de la capăt', _hist.length > 1 ? () => setState(() {
              _hist.removeRange(1, _hist.length);
              _removed.clear();
            }) : null),
      ]),
      const SizedBox(height: 10),
      if (last == null)
        Text('Pasul 1 e făcut: o stare de start nouă qs, cu ε spre ${names[0]}, și o stare finală nouă qf, cu ε din fiecare stare finală veche.', style: ink.mono(13.5, color: ink.fg))
      else ...[
        Text('Am eliminat ${g.names[last]}${before!.edges.containsKey((last, last)) ? ' (are buclă: ${_show(before.edges[(last, last)]!)}, deci intră o stea)' : ''}. Săgețile noi: R_in ${before.edges.containsKey((last, last)) ? '(R_buclă)* ' : ''}R_out, reunite cu ce era deja.',
            style: ink.mono(13.5, color: ink.fg)),
        const SizedBox(height: 6),
        if (pairs.isEmpty)
          Text('Nicio pereche (intrare, ieșire): starea nu era pe niciun drum de la qs la qf.', style: ink.mono(13.5, color: ink.muted))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder(horizontalInside: BorderSide(color: ink.line)),
              children: [
                TableRow(children: [
                  for (final h in ['din', 'în', 'R_in', 'R_buclă', 'R_out', 'era', 'eticheta nouă'])
                    Padding(padding: const EdgeInsets.fromLTRB(0, 4, 16, 4), child: Text(h, style: head)),
                ]),
                for (final p in pairs)
                  TableRow(children: [
                    for (final (i, t) in [
                      g.names[p.from],
                      g.names[p.to],
                      _show(p.rin),
                      p.loop == null ? '—' : _show(p.loop!),
                      _show(p.rout),
                      p.before == null ? '—' : _show(p.before!),
                      _show(p.merged),
                    ].indexed)
                      Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 16, 4),
                          child: Text(t, style: ink.mono(13.5, color: i == 6 ? ink.accent : ink.fg, weight: i == 6 ? FontWeight.w700 : null))),
                  ]),
              ],
            ),
          ),
      ],
      if (g.inner.isEmpty) ...[
        const SizedBox(height: 10),
        AcsBox(ink,
            color: ink.panel,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('expresia regulată (ordinea ${_removed.map((q) => g.names[q]).join(', ')}):', style: ink.mono(13, color: ink.muted)),
              const SizedBox(height: 4),
              SelectableText(_show(g.result), style: ink.mono(16, weight: FontWeight.w700, color: ink.strong)),
            ])),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- Thompson
class ThompsonViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const ThompsonViz(this.ink, this.spec, {super.key});

  @override
  State<ThompsonViz> createState() => _ThompsonVizState();
}

class _ThompsonVizState extends State<ThompsonViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final TextEditingController _re = TextEditingController(text: '${widget.spec['regex'] ?? '(a∪b)*ab'}');
  int _k = 1 << 20;

  @override
  void initState() {
    super.initState();
    _re.addListener(() => setState(() => _k = 1 << 20));
  }

  @override
  void dispose() {
    _re.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    ThompsonResult? t;
    String? error;
    try {
      t = thompson(Re.parse(_re.text, sigma));
    } on LfaError catch (e) {
      error = e.message;
    }
    final field = Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('expresia:', style: ink.mono(13.5, color: ink.muted)),
      AcsField(ink, _re, width: 220),
      for (final s in const ['∪', '*', 'ε', '(', ')'])
        AcsButton(ink, s, () {
          final v = _re.value;
          final at = v.selection.isValid ? v.selection.end : v.text.length;
          _re.value = TextEditingValue(text: v.text.replaceRange(at, at, s), selection: TextSelection.collapsed(offset: at + s.length));
        }),
    ]);
    if (t == null) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [field, const SizedBox(height: 8), _err(ink, error ?? '')]);
    final pieces = t.pieces;
    final k = _k.clamp(0, pieces.length - 1);
    // what exists once piece k is built: the states made so far
    final (_, ps, pe) = pieces[k];
    final upto = <int>{};
    for (var i = 0; i <= k; i++) {
      upto.add(pieces[i].$2);
      upto.add(pieces[i].$3);
    }
    final made = <int>{...upto};
    final edgesNow = <(int, String, int)>[];
    for (final m in t.moves) {
      if (made.contains(m.$1) && made.contains(m.$3)) edgesNow.add(m);
    }
    // keep the states that some arrow so far touches, and the ends of the pieces
    final keep = <int>{...upto, for (final (f, _, to) in edgesNow) ...[f, to]};
    final list = keep.toList()..sort();
    final by = <(int, int), List<String>>{};
    for (final (f, c, to) in edgesNow) {
      (by[(list.indexOf(f), list.indexOf(to))] ??= []).add(c);
    }
    final whole = k == pieces.length - 1;
    final arrows = [for (final e in by.entries) (e.key.$1, e.key.$2, e.value.join(','))];
    final d = Diagram([for (final s in list) '$s'], [for (final s in list) t.pos[s]], whole ? t.nfa.accepting.map(list.indexOf).toSet() : {}, whole ? list.indexOf(0) : -1, arrows,
        bends: [for (final (f, to, _) in arrows) t.bends[(list[f], list[to])]]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      field,
      const SizedBox(height: 8),
      DiagramView(ink, d, active: {list.indexOf(ps), list.indexOf(pe)}, maxHeight: 340),
      const SizedBox(height: 8),
      StepBar(ink, step: k, count: pieces.length, onChanged: (v) => setState(() => _k = v), label: (s) => 'bucata ${s + 1} din ${pieces.length}'),
      const SizedBox(height: 6),
      Text.rich(
          TextSpan(children: [
            TextSpan(text: 'construită acum: ', style: TextStyle(color: ink.muted)),
            TextSpan(text: pieces[k].$1, style: TextStyle(color: ink.accent, fontWeight: FontWeight.w700)),
            TextSpan(text: '   (start ${pieces[k].$2}, final ${pieces[k].$3}, aprinse)', style: TextStyle(color: ink.muted)),
          ]),
          style: ink.mono(14)),
      if (whole)
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${t.nfa.states} stări, ${t.moves.length} tranziții, dintre care ${t.moves.where((m) => m.$2 == lfaEps).length} pe ε.', style: ink.mono(13, color: ink.muted))),
    ]);
  }
}

// ---------------------------------------------------------------- the whole way: ER -> AFN -> AFD -> AFD minim
class RegexLabViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const RegexLabViz(this.ink, this.spec, {super.key});

  @override
  State<RegexLabViz> createState() => _RegexLabVizState();
}

class _RegexLabVizState extends State<RegexLabViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final TextEditingController _re = TextEditingController(text: '${widget.spec['regex'] ?? '(a∪b)*abb'}');
  final TextEditingController _w = TextEditingController();

  @override
  void initState() {
    super.initState();
    _re.addListener(() => setState(() {}));
    _w.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _re.dispose();
    _w.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    Nfa? n;
    String? error;
    try {
      n = Regex.parse(_re.text, sigma);
    } on LfaError catch (e) {
      error = e.message;
    }
    final field = Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('expresia:', style: ink.mono(13.5, color: ink.muted)),
      AcsField(ink, _re, width: 220),
      Text('peste {${sigma.join(', ')}}', style: ink.mono(13, color: ink.dim)),
    ]);
    if (n == null) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [field, const SizedBox(height: 8), _err(ink, error ?? '')]);
    final dfa = n.toDfa(sigma);
    final m = minimise(dfa);
    final (min, minNames) = minimalOf(dfa, m);
    final w = _w.text;
    final okWord = w.split('').every(sigma.contains);
    Widget part(String title, String note, Widget body) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: ink.mono(14.5, weight: FontWeight.w700, color: ink.strong)),
            Text(note, style: ink.mono(12.5, color: ink.muted)),
            const SizedBox(height: 4),
            body,
          ]),
        );
    final big = dfa.states > 14;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      field,
      part('1. AFD prin construcția submulțimilor', '${dfa.states} stări (fiecare e o mulțime de stări ale automatului Thompson, cu ε-închiderea făcută)',
          big ? Text('prea multe stări ca să le desenez frumos', style: ink.mono(13, color: ink.dim)) : DiagramView(ink, Diagram.ofNfa(nfaOfDfa(dfa), sigma, names: [for (var i = 0; i < dfa.states; i++) 'D$i']), maxHeight: 300)),
      part('2. AFD minim', '${min.states} stări; ${m.classes.where((c) => c.length > 1).isEmpty ? 'nicio stare nu s-a putut uni' : 'unite: ${m.classes.where((c) => c.length > 1).map((c) => '{${c.map((s) => 'D$s').join(', ')}}').join(' ')}'}',
          DiagramView(ink, Diagram.ofNfa(min, sigma, names: [for (var i = 0; i < min.states; i++) 'm$i']), maxHeight: 300)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('încearcă un cuvânt:', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _w, width: 160, hint: 'gol = ε'),
        if (!okWord)
          _err(ink, 'simboluri din afara alfabetului')
        else
          Text(dfa.accepts(w) ? '${wordShown(w)} ∈ L' : '${wordShown(w)} ∉ L', style: ink.mono(14, weight: FontWeight.w700, color: dfa.accepts(w) ? ink.good : ink.bad)),
      ]),
      const SizedBox(height: 4),
      Text('Cele mai scurte cuvinte din limbaj: ${_firstWords(dfa).map(wordShown).join('  ')}', style: ink.mono(13, color: ink.muted)),
      if (minNames.isNotEmpty) const SizedBox.shrink(),
    ]);
  }

  List<String> _firstWords(Dfa d) {
    final out = <String>[];
    for (final w in allWords(sigma, 6)) {
      if (d.accepts(w)) out.add(w);
      if (out.length >= 10) break;
    }
    return out.isEmpty ? ['(niciunul de cel mult 6 simboluri)'] : out;
  }
}

// ---------------------------------------------------------------- minimisation
class MinimizeViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const MinimizeViz(this.ink, this.spec, {super.key});

  @override
  State<MinimizeViz> createState() => _MinimizeVizState();
}

class _MinimizeVizState extends State<MinimizeViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final Nfa a = nfaOf(widget.spec['a']);
  late final (Dfa, List<String>) _dn = dfaOfTable(a, sigma, namesOf(widget.spec['names']) ?? [for (var i = 0; i < a.states; i++) 'q$i']);
  late final Dfa dfa = _dn.$1;
  late final List<String> names = _dn.$2;
  late final MinResult m = minimise(dfa);
  late final Diagram d = Diagram.ofNfa(nfaOfDfa(dfa), sigma, names: names, pos: dfa.states == a.states ? placesOf(widget.spec['pos']) : null);
  int _k = 0; // the round shown; one more for the merged automaton

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final steps = m.rounds + 2;
    final k = _k.clamp(0, steps - 1);
    final merged = k == steps - 1;
    final r = m.reach;
    final unreachable = [for (var s = 0; s < dfa.states; s++) if (!r.contains(s)) names[s]];
    final cell = ink.mono(12.5, weight: FontWeight.w700);
    Widget box(String t, Color c, Color bg) => Container(
          width: 52,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, border: Border.all(color: ink.line, width: 0.6)),
          child: Text(t, style: cell.copyWith(color: c)),
        );
    final sorted = [...r]..sort();
    final (min, minNames) = minimalOf(dfa, m);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DiagramView(ink, d, maxHeight: 300, faded: {for (var s = 0; s < dfa.states; s++) if (!r.contains(s)) s}),
      if (unreachable.isNotEmpty) Text('Întâi scoatem ce nu se poate atinge din start: ${unreachable.join(', ')}.', style: ink.mono(13, color: ink.muted)),
      if (dfa.states > a.states) Text('Tabela nu era completă: am adăugat groapa g, unde duc tranzițiile care lipseau.', style: ink.mono(13, color: ink.muted)),
      const SizedBox(height: 8),
      StepBar(ink, step: k, count: steps, onChanged: (v) => setState(() => _k = v), label: (s) => s == steps - 1 ? 'automatul minim' : 'runda $s'),
      const SizedBox(height: 8),
      Text(
          merged
              ? 'Nicio pereche nouă de marcat: perechile rămase nemarcate sunt stări echivalente și se unesc.'
              : (k == 0
                  ? 'Runda 0: marcăm perechile cu o stare finală și una nefinală (cuvântul ε le deosebește).'
                  : 'Runda $k: marcăm (p, q) dacă un simbol le duce într-o pereche deja marcată. Simbolul e scris în căsuță.'),
          style: ink.mono(13.5, color: ink.fg)),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 1; i < sorted.length; i++)
            Row(children: [
              SizedBox(width: 44, child: Text(names[sorted[i]], style: cell.copyWith(color: ink.strong))),
              for (var j = 0; j < i; j++)
                () {
                  final mk = m.mark(sorted[i], sorted[j]);
                  final visible = mk != null && (merged || mk.$1 <= k);
                  final fresh = visible && !merged && mk.$1 == k;
                  return box(visible ? (mk.$2.isEmpty ? '×' : '×${mk.$2}') : (merged ? '≡' : ''), visible ? (fresh ? ink.accent : ink.bad) : ink.good,
                      fresh ? ink.accent.withValues(alpha: 0.14) : (merged && !visible ? ink.good.withValues(alpha: 0.12) : ink.panel));
                }(),
            ]),
          Row(children: [
            const SizedBox(width: 44),
            for (var j = 0; j < sorted.length - 1; j++) SizedBox(width: 52, child: Center(child: Text(names[sorted[j]], style: cell.copyWith(color: ink.strong)))),
          ]),
        ]),
      ),
      if (merged) ...[
        const SizedBox(height: 10),
        Text('Clasele: ${m.classes.map((c) => '{${c.map((s) => names[s]).join(', ')}}').join('  ')}  →  ${min.states} stări', style: ink.mono(13.5, weight: FontWeight.w700, color: ink.strong)),
        const SizedBox(height: 6),
        DiagramView(ink, Diagram.ofNfa(min, sigma, names: [for (final c in m.classes) c.map((s) => names[s]).join('')]), maxHeight: 280),
        if (minNames.isEmpty) const SizedBox.shrink(),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- product
class ProductViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const ProductViz(this.ink, this.spec, {super.key});

  @override
  State<ProductViz> createState() => _ProductVizState();
}

class _ProductVizState extends State<ProductViz> {
  late final List<String> sigma = alphabetOf(widget.spec);
  late final Nfa a = nfaOf(widget.spec['a']), b = nfaOf(widget.spec['b']);
  late final Dfa da = dfaOfTable(a, sigma, [for (var i = 0; i < a.states; i++) 'p$i']).$1;
  late final Dfa db = dfaOfTable(b, sigma, [for (var i = 0; i < b.states; i++) 'r$i']).$1;
  late ProductOp _op = ProductOp.values.firstWhere((o) => productOpName(o) == '${widget.spec['op'] ?? '∩'}', orElse: () => ProductOp.inter);

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final (p, pn) = product(da, db, _op);
    final la = '${widget.spec['la'] ?? 'L(A)'}', lb = '${widget.spec['lb'] ?? 'L(B)'}';
    final small = LayoutBuilder(builder: (context, c) {
      final two = c.maxWidth > 560;
      final pa = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _caption(ink, 'A: $la'),
        DiagramView(ink, Diagram.ofNfa(nfaOfDfa(da), sigma, names: [for (var i = 0; i < da.states; i++) 'p$i'], pos: da.states == a.states ? placesOf(widget.spec['posA']) : null), maxHeight: 200),
      ]);
      final pb = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _caption(ink, 'B: $lb'),
        DiagramView(ink, Diagram.ofNfa(nfaOfDfa(db), sigma, names: [for (var i = 0; i < db.states; i++) 'r$i'], pos: db.states == b.states ? placesOf(widget.spec['posB']) : null), maxHeight: 200),
      ]);
      return two ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: pa), const SizedBox(width: 12), Expanded(child: pb)]) : Column(children: [pa, pb]);
    });
    final rule = switch (_op) {
      ProductOp.inter => 'finală dacă ambele sunt finale',
      ProductOp.union => 'finală dacă măcar una e finală',
      ProductOp.minus => 'finală dacă prima e finală și a doua nu',
      ProductOp.xor => 'finală dacă exact una dintre ele e finală',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      small,
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('operația:', style: ink.mono(13.5, color: ink.muted)),
        for (final o in ProductOp.values) AcsButton(ink, productOpName(o), () => setState(() => _op = o), primary: o == _op),
      ]),
      const SizedBox(height: 6),
      Text('O stare (p, r) ține minte unde e fiecare automat; din (p, r) cu x se merge în (δA(p, x), δB(r, x)). Pentru $la ${productOpName(_op)} $lb, o pereche e $rule.',
          style: ink.mono(13.5, color: ink.fg)),
      const SizedBox(height: 6),
      DiagramView(ink, Diagram.ofNfa(p, sigma, names: [for (final x in pn) '(p${x.split(',')[0]},r${x.split(',')[1]})']), maxHeight: 340),
      Text('${p.states} perechi atinse din (p0, r0), ${p.accepting.length} finale.', style: ink.mono(13, color: ink.muted)),
    ]);
  }
}
