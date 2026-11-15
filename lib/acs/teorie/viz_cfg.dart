// =============================================================================
// GRAMMARS, SEEN WORKING
//   A word derived step by step (the leftmost derivation beside its tree,
//   the tree growing with it, and a second tree when the grammar is
//   ambiguous), the Chomsky normal form step by step, the CYK table filled
//   cell by cell, and the Chomsky hierarchy with what each class has.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/lfa.dart';
import '../engine/lfa_cfg.dart';
import '../ws/ws_common.dart' show AcsField;
import 'teorie_kit.dart';

// ---------------------------------------------------------------- a tree
class _TreeLayout {
  final List<(ParseTree, Offset, int)> nodes = []; // node, place (units), parent index
  double width = 1, depth = 1;
}

_TreeLayout _layoutTree(ParseTree root) {
  final l = _TreeLayout();
  var leaf = 0.0;
  double walk(ParseTree t, int d, int parent) {
    final me = l.nodes.length;
    l.nodes.add((t, Offset.zero, parent));
    double x;
    if (t.leaf) {
      x = leaf;
      leaf += 1;
    } else {
      final xs = [for (final k in t.kids) walk(k, d + 1, me)];
      x = (xs.first + xs.last) / 2;
    }
    l.nodes[me] = (t, Offset(x, d.toDouble()), parent);
    l.depth = math.max(l.depth, d + 1.0);
    return x;
  }

  walk(root, 0, -1);
  l.width = math.max(1, leaf);
  return l;
}

class TreeView extends StatelessWidget {
  final AcsInk ink;
  final ParseTree tree;
  final int expanded; // how many nonterminals (in leftmost order) are expanded
  const TreeView(this.ink, this.tree, {super.key, this.expanded = 1 << 20});

  @override
  Widget build(BuildContext context) {
    final l = _layoutTree(tree);
    return LayoutBuilder(builder: (context, c) {
      final h = (l.depth * 54 + 20).clamp(120.0, 520.0);
      return CustomPaint(size: Size(c.maxWidth, h), painter: _TreePainter(ink, l, expanded));
    });
  }
}

class _TreePainter extends CustomPainter {
  final AcsInk ink;
  final _TreeLayout l;
  final int expanded;
  _TreePainter(this.ink, this.l, this.expanded);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = math.min(56.0, (size.width - 40) / math.max(1, l.width - 1 + 0.001));
    final ox = (size.width - (l.width - 1) * sx) / 2;
    final sy = (size.height - 34) / math.max(1, l.depth - 1 + 0.001);
    Offset at(Offset u) => Offset(ox + u.dx * sx, 17 + u.dy * math.min(sy, 58));
    // which nodes are visible: the root, and the children of the first [expanded] interior nodes in preorder
    final order = [for (final (i, (t, _, _)) in l.nodes.indexed) if (!t.leaf) i];
    final open = order.take(expanded).toSet();
    final visible = <int>{0};
    for (final (i, (_, _, p)) in l.nodes.indexed) {
      if (p >= 0 && open.contains(p) && visible.contains(p)) visible.add(i);
    }
    final nextOpen = order.length > expanded ? order[expanded] : -1;
    final line = Paint()
      ..color = ink.muted
      ..strokeWidth = 1.2;
    for (final (i, (_, u, p)) in l.nodes.indexed) {
      if (p >= 0 && visible.contains(i)) canvas.drawLine(at(l.nodes[p].$2), at(u), line);
    }
    for (final (i, (t, u, _)) in l.nodes.indexed) {
      if (!visible.contains(i)) continue;
      final nt = !t.leaf;
      final c = i == nextOpen ? ink.accent : (nt ? ink.strong : (t.sym == lfaEps ? ink.dim : ink.good));
      final tp = TextPainter(text: TextSpan(text: t.sym, style: ink.mono(14, color: c, weight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
      final r = Rect.fromCenter(center: at(u), width: math.max(22, tp.width + 10), height: 22);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(11)), Paint()..color = nt ? ink.panel : ink.bg);
      if (nt) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(11)),
            Paint()
              ..color = c
              ..style = PaintingStyle.stroke
              ..strokeWidth = i == nextOpen ? 2 : 1);
      }
      tp.paint(canvas, at(u) - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) => true;
}

// ---------------------------------------------------------------- derivations
class DeriveViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const DeriveViz(this.ink, this.spec, {super.key});

  @override
  State<DeriveViz> createState() => _DeriveVizState();
}

class _DeriveVizState extends State<DeriveViz> {
  late final Cfg g = Cfg.parse('${widget.spec['grammar']}');
  late final List<String> words = [for (final w in widget.spec['words'] as List? ?? const []) '$w'];
  late final TextEditingController _w = TextEditingController(text: words.isEmpty ? '' : words.first);
  int _tree = 0;
  int _k = 1 << 20;

  @override
  void initState() {
    super.initState();
    _w.addListener(() => setState(() {
          _tree = 0;
          _k = 1 << 20;
        }));
  }

  @override
  void dispose() {
    _w.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final w = _w.text.replaceAll(lfaEps, '');
    final trees = w.length > 14 ? const <ParseTree>[] : parseTrees(g, w);
    final controls = Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('cuvântul:', style: ink.mono(13.5, color: ink.muted)),
      AcsField(ink, _w, width: 160, hint: 'gol = ε'),
      for (final x in words) AcsButton(ink, wordShown(x), () => _w.text = x),
    ]);
    final grammar = AcsBox(ink, color: ink.panel, child: Text(g.show(), style: ink.mono(14, color: ink.strong)));
    if (trees.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        grammar,
        const SizedBox(height: 8),
        controls,
        const SizedBox(height: 8),
        Text(w.length > 14 ? 'Cuvântul e prea lung pentru căutare (cel mult 14 simboluri).' : '${wordShown(w)} nu se poate deriva din ${g.start}: nu e în L(G).', style: ink.mono(14, color: ink.bad)),
      ]);
    }
    final t = trees[_tree.clamp(0, trees.length - 1)];
    final steps = t.leftmost();
    final rules = t.rulesUsed();
    final k = _k.clamp(0, steps.length - 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      grammar,
      const SizedBox(height: 8),
      controls,
      const SizedBox(height: 8),
      if (trees.length > 1)
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Două arbori diferiți: gramatica e ambiguă.', style: ink.mono(13.5, weight: FontWeight.w700, color: ink.warn)),
          for (var i = 0; i < trees.length; i++)
            AcsButton(ink, 'arborele ${i + 1}', () => setState(() {
                  _tree = i;
                  _k = 1 << 20;
                }), primary: i == _tree),
        ])
      else
        Text('Un singur arbore de derivare pentru acest cuvânt.', style: ink.mono(13.5, color: ink.muted)),
      const SizedBox(height: 8),
      StepBar(ink, step: k, count: steps.length, onChanged: (v) => setState(() => _k = v), label: (s) => s == 0 ? 'simbolul de start' : 'pasul $s: ${rules[s - 1]}'),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text.rich(
            TextSpan(children: [
              for (var i = 0; i <= k; i++) ...[
                if (i > 0) TextSpan(text: ' ⇒ ', style: TextStyle(color: ink.muted)),
                TextSpan(text: steps[i], style: TextStyle(color: i == k ? ink.accent : ink.fg, fontWeight: i == k ? FontWeight.w700 : null)),
              ],
            ]),
            style: ink.mono(14.5)),
      ),
      const SizedBox(height: 8),
      TreeView(ink, t, expanded: k),
    ]);
  }
}

// ---------------------------------------------------------------- CNF
class CnfViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const CnfViz(this.ink, this.spec, {super.key});

  @override
  State<CnfViz> createState() => _CnfVizState();
}

class _CnfVizState extends State<CnfViz> {
  late final TextEditingController _g = TextEditingController(text: '${widget.spec['grammar']}');
  int _k = 0;

  @override
  void initState() {
    super.initState();
    _g.addListener(() => setState(() => _k = 0));
  }

  @override
  void dispose() {
    _g.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    List<CnfStep>? steps;
    String? error;
    try {
      steps = toChomsky(Cfg.parse(_g.text));
    } on LfaError catch (e) {
      error = e.message;
    }
    final editor = TextField(
      controller: _g,
      maxLines: null,
      style: ink.mono(14, color: ink.strong),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: ink.panel,
        border: OutlineInputBorder(borderSide: BorderSide(color: ink.line)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.line)),
        helperText: 'o regulă pe linie; schimb-o ca să vezi alt exemplu',
        helperStyle: ink.mono(12, color: ink.dim),
      ),
    );
    if (steps == null) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [editor, const SizedBox(height: 6), Text(error ?? '', style: ink.mono(13.5, color: ink.bad))]);
    final k = _k.clamp(0, steps.length - 1);
    final s = steps[k];
    final before = k > 0 ? steps[k - 1].grammar.show().split('\n').toSet() : const <String>{};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      editor,
      const SizedBox(height: 8),
      StepBar(ink, step: k, count: steps.length, onChanged: (v) => setState(() => _k = v), label: (i) => steps![i].title),
      const SizedBox(height: 8),
      Text(s.title, style: ink.mono(15, weight: FontWeight.w700, color: ink.strong)),
      Text(s.what, style: ink.mono(13.5, color: ink.fg)),
      const SizedBox(height: 6),
      AcsBox(ink,
          color: ink.panel,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final line in s.grammar.show().split('\n'))
              Text(line, style: ink.mono(14, color: k > 0 && !before.contains(line) ? ink.accent : ink.strong, weight: k > 0 && !before.contains(line) ? FontWeight.w700 : null)),
          ])),
      const SizedBox(height: 4),
      Text('${s.grammar.ruleCount} reguli${k == steps.length - 1 ? (s.grammar.isChomsky ? ' · în forma normală Chomsky' : '') : ''} · rândurile schimbate sunt colorate', style: ink.mono(12.5, color: ink.muted)),
    ]);
  }
}

// ---------------------------------------------------------------- CYK
class CykViz extends StatefulWidget {
  final AcsInk ink;
  final Map spec;
  const CykViz(this.ink, this.spec, {super.key});

  @override
  State<CykViz> createState() => _CykVizState();
}

class _CykVizState extends State<CykViz> {
  late final Cfg g = Cfg.parse('${widget.spec['grammar']}');
  late final TextEditingController _w = TextEditingController(text: '${widget.spec['word'] ?? ''}');
  int _k = 1 << 20;

  @override
  void initState() {
    super.initState();
    _w.addListener(() => setState(() => _k = 1 << 20));
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
    final n = w.length;
    final r = n == 0 || n > 10 ? null : cyk(g, w);
    final cells = <(int, int)>[for (var l = 1; l <= n; l++) for (var i = 0; i + l <= n; i++) (l, i)];
    final int k = _k.clamp(0, math.max(0, cells.length - 1)).toInt();
    final (cl, ci) = cells.isEmpty ? (0, 0) : cells[k];
    final filled = cells.take(k + 1).toSet();
    // the splits that fed the cell being filled
    final feed = <(int, int)>{};
    if (cl > 1) {
      for (var s = 1; s < cl; s++) {
        feed.add((s, ci));
        feed.add((cl - s, ci + s));
      }
    }
    const cw = 64.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AcsBox(ink, color: ink.panel, child: Text(g.show(), style: ink.mono(14, color: ink.strong))),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('cuvântul:', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _w, width: 160),
        Text('(1–10 simboluri)', style: ink.mono(12.5, color: ink.dim)),
      ]),
      const SizedBox(height: 8),
      if (r == null)
        Text(n == 0 ? 'Scrie un cuvânt.' : 'Cel mult 10 simboluri.', style: ink.mono(13.5, color: ink.muted))
      else ...[
        StepBar(ink, step: k, count: cells.length, onChanged: (v) => setState(() => _k = v), every: const Duration(milliseconds: 600), label: (s) {
          final (l, i) = cells[s];
          return 'X[${i + 1},${i + l}] = ce generează „${w.substring(i, i + l)}”';
        }),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var l = n; l >= 1; l--)
              Row(children: [
                SizedBox(width: 34, child: Text('$l', style: ink.mono(12, color: ink.dim))),
                for (var i = 0; i + l <= n; i++)
                  Container(
                    width: cw,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (l, i) == (cl, ci)
                          ? ink.accent.withValues(alpha: 0.2)
                          : (feed.contains((l, i)) ? ink.warn.withValues(alpha: 0.14) : ink.panel),
                      border: Border.all(color: ink.line, width: 0.6),
                    ),
                    child: Text(
                        filled.contains((l, i)) ? (r.table[l - 1][i].isEmpty ? '∅' : (r.table[l - 1][i].toList()..sort()).join(',')) : '',
                        style: ink.mono(12.5, weight: FontWeight.w700, color: l == n && r.table[l - 1][i].contains(g.start) && filled.contains((l, i)) ? ink.good : ink.strong)),
                  ),
              ]),
            Row(children: [
              const SizedBox(width: 34),
              for (var i = 0; i < n; i++) SizedBox(width: cw, child: Center(child: Text(w[i], style: ink.mono(15, weight: FontWeight.w700, color: ink.accent)))),
            ]),
          ]),
        ),
        const SizedBox(height: 6),
        Text(
            cl == 1
                ? 'Pe rândul de jos: neterminalele A cu o regulă A → ${w[ci]}.'
                : 'O căsuță de lungime $cl: pentru fiecare tăietură în două, A intră dacă are o regulă A → BC cu B în partea stângă și C în cea dreaptă (căsuțele galbene).',
            style: ink.mono(13, color: ink.fg)),
        if (k == cells.length - 1)
          Text(r.accepted ? '${g.start} e în căsuța de sus: ${wordShown(w)} ∈ L(G).' : '${g.start} nu e în căsuța de sus: ${wordShown(w)} ∉ L(G).',
              style: ink.mono(14, weight: FontWeight.w700, color: r.accepted ? ink.good : ink.bad)),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- the hierarchy
class HierarchyViz extends StatefulWidget {
  final AcsInk ink;
  const HierarchyViz(this.ink, {super.key});

  @override
  State<HierarchyViz> createState() => _HierarchyVizState();
}

class _HierarchyVizState extends State<HierarchyViz> {
  int _at = 1;

  static const levels = [
    ('Finite', 'orice limbaj finit', 'o listă de cuvinte; o ER fără stea', '{ε, ab, aab}', 'reuniune, intersecție, concatenare, diferență; NU complement, NU stea'),
    ('Regulate (LR) · tip 3', 'AFD, AFN, ε-AFN; expresii regulate; gramatici regulate (A → aB | a | ε)', 'automat finit: memorie finită', 'a*b*, #a par, numere în baza 2 divizibile cu 3',
        'reuniune, intersecție, complement, diferență, concatenare, stea, oglindire, morfisme'),
    ('Independente de context (LIC) · tip 2', 'gramatici independente de context (A → α); automate cu stivă (APD)', 'automat cu o stivă', 'aⁿbⁿ, palindroame, paranteze bine închise, #a = #b',
        'reuniune, concatenare, stea, oglindire, ∩ cu un LR; NU intersecție, NU complement'),
    ('Dependente de context · tip 1', 'gramatici monotone (|α| ≤ |β|)', 'mașină Turing cu bandă liniar mărginită', 'aⁿbⁿcⁿ, ww, a^(n²)', 'reuniune, intersecție, complement, concatenare, stea'),
    ('Decidabile (recursive, TD)', 'mașini Turing care se opresc pe orice intrare', 'mașină Turing care decide', 'aⁿbⁿcⁿ, {ρ(M) | M are 5 stări}, numerele prime', 'reuniune, intersecție, complement, concatenare, stea'),
    ('Turing acceptate (r.e., TA) · tip 0', 'gramatici fără restricții; mașini Turing care acceptă', 'mașină Turing (poate să nu se oprească)', 'H = {ρ(M)ρ(w) | M se oprește pe w}', 'reuniune, intersecție, concatenare, stea; NU complement (L și ∁L în TA ⇒ L decidabil)'),
    ('Toate limbajele', 'nenumărabil de multe: majoritatea nu au nicio descriere finită', '—', '∁H = {ρ(M)ρ(w) | M nu se oprește pe w}', '—'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    Widget nest(int i) {
      final (name, _, _, _, _) = levels[levels.length - 1 - i];
      final idx = levels.length - 1 - i;
      final on = idx == _at;
      return AcsTap(
        label: name,
        onTap: () => setState(() => _at = idx),
        builder: (h) => Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: on ? ink.accent.withValues(alpha: 0.14) : (h ? ink.hover : ink.bg.withValues(alpha: 0)),
            border: Border.all(color: on ? ink.accent : ink.line, width: on ? 2 : 1),
            borderRadius: ink.terminal ? null : BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(name, style: ink.mono(13, weight: FontWeight.w700, color: on ? ink.accent : ink.strong)),
            if (i < levels.length - 1) ...[const SizedBox(height: 6), nest(i + 1)],
          ]),
        ),
      );
    }

    final (name, gen, acc, ex, clos) = levels[_at];
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$k: ', style: TextStyle(color: ink.muted, fontWeight: FontWeight.w700)),
            TextSpan(text: v),
          ]), style: ink.mono(13.5)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      nest(0),
      const SizedBox(height: 10),
      AcsBox(ink,
          color: ink.panel,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(name, style: ink.mono(15, weight: FontWeight.w700, color: ink.strong)),
            row('cum se descriu', gen),
            row('cine le recunoaște', acc),
            row('exemple', ex),
            row('închise la', clos),
          ])),
      Text('Atinge o clasă. Fiecare e cuprinsă strict în cea din jur.', style: ink.mono(12.5, color: ink.muted)),
    ]);
  }
}
