// =============================================================================
// THEORY PAGES: one block of a lesson
//   Prose, a definition, a theorem (its proof opens on a tap), an example, a
//   note, an algorithm's steps, a table, a question, an exam problem solved,
//   or a visualisation. [essentialBlock] says which ones the "esențial" mode
//   keeps: what is to be known (definitions, theorems, steps, tables, the
//   visualisations, the warnings); the explanations, examples, exam problems
//   and questions wait behind "arată tot".
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import 'teorie_kit.dart';
import 'viz_cfg.dart';
import 'viz_machines.dart';
import 'viz_regular.dart';

bool essentialBlock(Map<String, dynamic> b) => switch (b['t']) {
      'def' || 'thm' || 'steps' || 'table' || 'viz' => true,
      'note' => b['tone'] == 'warn' || b['tone'] == 'exam',
      _ => false,
    };

/// What a block is, said in the plural for "arată tot (2 exemple)".
(String, String) blockNoun(Map<String, dynamic> b) => switch (b['t']) {
      'p' => ('explicație', 'explicații'),
      'ex' => ('exemplu', 'exemple'),
      'exam' => ('problemă de examen', 'probleme de examen'),
      'quiz' => ('întrebare', 'întrebări'),
      'note' => ('notă', 'note'),
      'def' => ('definiție', 'definiții'),
      'thm' => ('teoremă', 'teoreme'),
      'viz' => ('vizualizare', 'vizualizări'),
      'table' => ('tabel', 'tabele'),
      'steps' => ('algoritm', 'algoritmi'),
      _ => ('bloc', 'blocuri'),
    };

/// "2 explicații · 1 exemplu", in the order they first come.
String countBlocks(Iterable<Map<String, dynamic>> blocks) {
  final n = <String, int>{};
  final nouns = <String, (String, String)>{};
  for (final b in blocks) {
    final k = '${b['t']}';
    n[k] = (n[k] ?? 0) + 1;
    nouns[k] = blockNoun(b);
  }
  return [for (final e in n.entries) '${e.value} ${e.value == 1 ? nouns[e.key]!.$1 : nouns[e.key]!.$2}'].join(' · ');
}

// ---------------------------------------------------------------- one block
class TeorieBlock extends StatelessWidget {
  final AcsInk ink;
  final Map<String, dynamic> b;
  final String code;
  final AcsCourseData? problems;
  final Set<String> solved;
  const TeorieBlock(this.ink, this.b, {super.key, required this.code, this.problems, this.solved = const {}});

  String _s(String k) => '${b[k] ?? ''}';

  Widget _framed(String label, Color c, Widget child, {String? title, IconData? icon}) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: ink.dark ? 0.09 : 0.06),
          border: Border(left: BorderSide(color: c, width: 3)),
          borderRadius: ink.terminal ? null : const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text.rich(
              TextSpan(children: [
                if (icon != null && !ink.terminal)
                  WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.only(right: 6), child: Icon(icon, size: 16, color: c))),
                TextSpan(text: label, style: TextStyle(color: c, fontWeight: FontWeight.w800, letterSpacing: 1)),
                if (title != null && title.isNotEmpty) TextSpan(text: '  $title', style: TextStyle(color: ink.strong, fontWeight: FontWeight.w700)),
              ]),
              style: ink.mono(13)),
          const SizedBox(height: 6),
          child,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    switch (b['t']) {
      case 'p':
        return AcsText(_s('text'), ink, size: 15);
      case 'def':
        return _framed('DEFINIȚIE', ink.accent, AcsText(_s('text'), ink, size: 15), title: _s('title'), icon: Icons.menu_book_outlined);
      case 'thm':
        return _framed(_s('label').isEmpty ? 'TEOREMĂ' : _s('label').toUpperCase(), ink.warn,
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AcsText(_s('text'), ink, size: 15),
              if (_s('proof').isNotEmpty) ...[const SizedBox(height: 6), Reveal(ink, 'demonstrația', AcsText(_s('proof'), ink, size: 14.5, color: ink.fg))],
            ]),
            title: _s('title'),
            icon: Icons.verified_outlined);
      case 'ex':
        return _framed('EXEMPLU', ink.good,
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AcsText(_s('text'), ink, size: 15),
              if (_s('solution').isNotEmpty) ...[const SizedBox(height: 6), Reveal(ink, b['open'] == true ? 'rezolvarea' : 'vezi rezolvarea', AcsText(_s('solution'), ink, size: 14.5), open: b['open'] == true)],
            ]),
            title: _s('title'),
            icon: Icons.lightbulb_outline);
      case 'note':
        final tone = _s('tone');
        final (label, c, icon) = switch (tone) {
          'warn' => ('ATENȚIE', ink.bad, Icons.warning_amber_rounded),
          'tip' => ('SFAT', ink.good, Icons.tips_and_updates_outlined),
          'exam' => ('LA EXAMEN', ink.warn, Icons.school_outlined),
          _ => ('DE REȚINUT', ink.accent, Icons.push_pin_outlined),
        };
        return _framed(label, c, AcsText(_s('text'), ink, size: 14.5), title: _s('title'), icon: icon);
      case 'steps':
        final items = [for (final x in b['items'] as List) '$x'];
        return AcsBox(ink,
            title: _s('title').isEmpty ? null : _s('title'),
            color: ink.panel,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (i, it) in items.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 30, child: Text('${i + 1}.', style: ink.mono(15, weight: FontWeight.w800, color: ink.accent))),
                    Expanded(child: AcsText(it, ink, size: 14.5)),
                  ]),
                ),
            ]));
      case 'table':
        final head = [for (final x in b['head'] as List) '$x'];
        final rows = [for (final r in b['rows'] as List) [for (final x in r as List) '$x']];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_s('title').isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(_s('title'), style: ink.mono(14, weight: FontWeight.w700, color: ink.strong))),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: ink.line, width: 0.8),
              children: [
                TableRow(decoration: BoxDecoration(color: ink.panel), children: [
                  for (final h in head) Padding(padding: const EdgeInsets.all(8), child: Text(h, style: ink.mono(13.5, weight: FontWeight.w700, color: ink.strong))),
                ]),
                for (final r in rows)
                  TableRow(children: [
                    for (final c in r) Padding(padding: const EdgeInsets.all(8), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340), child: AcsText(c, ink, size: 13.5))),
                  ]),
              ],
            ),
          ),
        ]);
      case 'quiz':
        return _Quiz(ink, b);
      case 'exam':
        return _framed('PROBLEMĂ DE EXAMEN', ink.warn,
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_s('source').isNotEmpty) Text(_s('source'), style: ink.mono(12.5, color: ink.muted)),
              AcsText(_s('text'), ink, size: 15),
              const SizedBox(height: 6),
              Reveal(ink, 'rezolvarea', AcsText(_s('solution'), ink, size: 14.5)),
            ]),
            title: _s('title'),
            icon: Icons.assignment_outlined);
      case 'viz':
        return AcsBox(ink,
            title: ink.terminal ? '>> ${_s('title')}' : '▶ ${_s('title')}',
            color: ink.bg,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_s('text').isNotEmpty) ...[AcsText(_s('text'), ink, size: 14, color: ink.muted), const SizedBox(height: 10)],
              _viz(),
            ]));
      default:
        return AcsText(_s('text'), ink);
    }
  }

  Widget _viz() {
    final spec = b;
    return switch (b['kind']) {
      'automaton' => AutomatonViz(ink, spec),
      'subset' => SubsetViz(ink, spec),
      'elim' => ElimViz(ink, spec),
      'thompson' => ThompsonViz(ink, spec),
      'regexlab' => RegexLabViz(ink, spec),
      'minimize' => MinimizeViz(ink, spec),
      'product' => ProductViz(ink, spec),
      'pump' => PumpViz(ink, spec),
      'derive' => DeriveViz(ink, spec),
      'cnf' => CnfViz(ink, spec),
      'cyk' => CykViz(ink, spec),
      'hierarchy' => HierarchyViz(ink),
      'pda' => PdaViz(ink, spec),
      'tm' => TmViz(ink, spec),
      _ => Text('vizualizare necunoscută: ${b['kind']}', style: ink.mono(13, color: ink.bad)),
    };
  }
}

class _Quiz extends StatefulWidget {
  final AcsInk ink;
  final Map<String, dynamic> b;
  const _Quiz(this.ink, this.b);

  @override
  State<_Quiz> createState() => _QuizState();
}

class _QuizState extends State<_Quiz> {
  int? _pick;

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final options = [for (final o in widget.b['options'] as List) '$o'];
    final right = (widget.b['answer'] as num).toInt();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(ink.terminal ? '? VERIFICĂ-TE' : 'VERIFICĂ-TE', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.accent).copyWith(letterSpacing: 1)),
        const SizedBox(height: 6),
        AcsText('${widget.b['q']}', ink, size: 15),
        const SizedBox(height: 8),
        for (final (i, o) in options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AcsTap(
              label: o,
              onTap: () => setState(() => _pick = i),
              builder: (h) {
                final shown = _pick != null;
                final c = !shown ? (h ? ink.strong : ink.line) : (i == right ? ink.good : (i == _pick ? ink.bad : ink.line));
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: shown && i == right ? ink.good.withValues(alpha: 0.1) : (shown && i == _pick ? ink.bad.withValues(alpha: 0.08) : ink.panel),
                    border: Border.all(color: c),
                    borderRadius: ink.terminal ? null : BorderRadius.circular(6),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 26, child: Text('${String.fromCharCode(97 + i)})', style: ink.mono(14, weight: FontWeight.w700, color: ink.accent))),
                    Expanded(child: AcsText(o, ink, size: 14)),
                  ]),
                );
              },
            ),
          ),
        if (_pick != null) ...[
          Text(_pick == right ? 'Corect.' : 'Nu: răspunsul e ${String.fromCharCode(97 + right)}).', style: ink.mono(14, weight: FontWeight.w700, color: _pick == right ? ink.good : ink.bad)),
          if ('${widget.b['why'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: AcsText('${widget.b['why']}', ink, size: 14, color: ink.fg)),
        ],
      ]),
    );
  }
}
