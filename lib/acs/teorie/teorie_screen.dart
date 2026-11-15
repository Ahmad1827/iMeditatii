// =============================================================================
// THEORY PAGES: the list of lessons, and a lesson
//   /acs/<code>/teorie: the lessons by part, what is read, where to go on.
//   /acs/<code>/teorie/<lesson>: its sections (a contents box on top jumps to
//   them), definitions, theorems with their proofs, examples, notes, tables,
//   questions to check oneself, exam problems solved, and visualisations
//   that run the algorithms; at the end the problems to practise on and the
//   way to the next lesson.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../acs_screen.dart' show acsSubject, acsTrail;
import '../../app_link.dart';
import '../acs_data.dart';
import '../acs_kit.dart';
import 'teorie_data.dart';
import 'teorie_kit.dart';
import 'viz_cfg.dart';
import 'viz_machines.dart';
import 'viz_regular.dart';

String teorieRoute(String code, [String? lesson]) => lesson == null ? '/acs/$code/teorie' : '/acs/$code/teorie/$lesson';

// ---------------------------------------------------------------- the list
class AcsTeorieScreen extends StatefulWidget {
  final String code;
  const AcsTeorieScreen({super.key, required this.code});

  @override
  State<AcsTeorieScreen> createState() => _AcsTeorieScreenState();
}

class _AcsTeorieScreenState extends State<AcsTeorieScreen> {
  TeorieCourse? _t;
  bool _loaded = false;
  Set<String> _read = const {};
  String? _last;

  @override
  void initState() {
    super.initState();
    () async {
      final t = await loadTeorie(widget.code);
      final r = await TeorieProgress.read(widget.code);
      final l = await TeorieProgress.last(widget.code);
      if (!mounted) return;
      setState(() {
        _t = t;
        _read = r;
        _last = l;
        _loaded = true;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return AcsPage(
      maxWidth: 1000,
      builder: (context, ink, narrow) {
        final trail = [...acsTrail(widget.code), ('teorie', teorieRoute(widget.code))];
        if (!_loaded) return Text('se încarcă...', style: ink.mono(14, color: ink.muted));
        final t = _t;
        if (t == null) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AcsNav(ink: ink, trail: trail),
            const SizedBox(height: 20),
            Text('Materia nu are încă lecții de teorie.', style: ink.mono(15, color: ink.bad)),
          ]);
        }
        final s = acsSubject(widget.code);
        final done = t.lessons.where((l) => _read.contains(l.id)).length;
        final next = (_last != null && t.byId(_last!) != null && !_read.contains(_last)) ? t.byId(_last!)! : t.lessons.firstWhere((l) => !_read.contains(l.id), orElse: () => t.lessons.first);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (ink.terminal) ...[
            Text.rich(
                TextSpan(children: [
                  TextSpan(text: '~/acs/${widget.code}/', style: TextStyle(color: ink.accent)),
                  TextSpan(text: 'teorie', style: TextStyle(color: ink.strong)),
                ]),
                style: ink.mono(narrow ? 26 : 32, weight: FontWeight.w700, height: 1.1)),
          ] else ...[
            Text('[${s?.short ?? widget.code}] teorie', style: ink.mono(15, weight: FontWeight.w700, color: ink.accent)),
            Text(t.title, style: ink.mono(narrow ? 26 : 34, weight: FontWeight.w700, color: ink.strong, height: 1.15)),
          ],
          const SizedBox(height: 8),
          AcsNav(ink: ink, trail: trail),
          const SizedBox(height: 12),
          AcsText(t.intro, ink, size: 15, color: ink.fg),
          const SizedBox(height: 12),
          Text('$done din ${t.lessons.length} lecții citite · ${t.lessons.fold(0, (a, l) => a + l.vizCount)} vizualizări interactive · ${t.lessons.fold(0, (a, l) => a + l.minutes)} minute de citit',
              style: ink.mono(13, color: ink.muted)),
          const SizedBox(height: 14),
          _lessonCard(context, ink, narrow, t, next, highlight: true),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AppLink(
                to: '/acs/${widget.code}',
                child: AcsButton(ink, 'la problemele materiei', () => context.go('/acs/${widget.code}'), icon: Icons.edit_note)),
          ),
          for (final p in t.parts) ...[
            const SizedBox(height: 22),
            Text(ink.terminal ? '## ${p.title}' : p.title, style: ink.mono(19, weight: FontWeight.w700, color: ink.strong)),
            if (p.about.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(p.about, style: ink.mono(13.5, color: ink.muted))),
            const SizedBox(height: 8),
            for (final id in p.lessons)
              if (t.byId(id) != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: _lessonCard(context, ink, narrow, t, t.byId(id)!)),
          ],
        ]);
      },
    );
  }

  Widget _lessonCard(BuildContext context, AcsInk ink, bool narrow, TeorieCourse t, TeorieLesson l, {bool highlight = false}) {
    final n = t.indexOf(l) + 1;
    final read = _read.contains(l.id);
    final route = teorieRoute(widget.code, l.id);
    return AppLink(
      to: route,
      child: AcsTap(
        label: l.title,
        onTap: () => context.go(route),
        builder: (h) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: h ? ink.hover : ink.panel,
            border: Border.all(color: highlight ? ink.accent : ink.line, width: highlight ? 1.5 : 1),
            borderRadius: ink.terminal ? null : BorderRadius.circular(10),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 38, child: Text(n.toString().padLeft(2, '0'), style: ink.mono(18, weight: FontWeight.w700, color: read ? ink.good : ink.accent))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (highlight)
                  Text(read ? 'RECITEȘTE' : (_read.isEmpty ? 'ÎNCEPE AICI' : 'CONTINUĂ'), style: ink.mono(12, weight: FontWeight.w700, color: ink.accent).copyWith(letterSpacing: 1.1)),
                Text(l.title, style: ink.mono(16, weight: FontWeight.w700, color: ink.strong, height: 1.3)),
                const SizedBox(height: 2),
                Text(l.summary, style: ink.mono(13.5, color: ink.muted), maxLines: highlight ? 3 : 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (l.curs.isNotEmpty) teorieTag(ink, l.curs, ink.muted),
                  teorieTag(ink, '${l.minutes} min', ink.muted),
                  teorieTag(ink, '${l.sections.length} secțiuni', ink.muted),
                  if (l.vizCount > 0) teorieTag(ink, '${l.vizCount} vizualizări', ink.accent),
                  if (l.practice.isNotEmpty) teorieTag(ink, '${l.practice.length} probleme', ink.accent),
                ]),
              ]),
            ),
            if (read) Icon(Icons.check_circle, size: 18, color: ink.good),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- a lesson
class AcsLessonScreen extends StatefulWidget {
  final String code, lesson;
  const AcsLessonScreen({super.key, required this.code, required this.lesson});

  @override
  State<AcsLessonScreen> createState() => _AcsLessonScreenState();
}

class _AcsLessonScreenState extends State<AcsLessonScreen> {
  TeorieCourse? _t;
  AcsCourseData? _problems;
  Set<String> _solved = const {};
  bool _loaded = false;
  bool _read = false;
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    () async {
      final t = await loadTeorie(widget.code);
      final p = await loadAcsCourse(widget.code);
      final s = await AcsProgress.solvedIds(widget.code);
      final r = await TeorieProgress.read(widget.code);
      TeorieProgress.setLast(widget.code, widget.lesson);
      if (!mounted) return;
      setState(() {
        _t = t;
        _problems = p;
        _solved = s;
        _read = r.contains(widget.lesson);
        _loaded = true;
      });
    }();
  }

  void _toggleRead() {
    setState(() => _read = !_read);
    TeorieProgress.mark(widget.code, widget.lesson, _read);
  }

  @override
  Widget build(BuildContext context) {
    return AcsPage(
      maxWidth: 940,
      builder: (context, ink, narrow) {
        final base = [...acsTrail(widget.code), ('teorie', teorieRoute(widget.code))];
        if (!_loaded) return Text('se încarcă...', style: ink.mono(14, color: ink.muted));
        final t = _t;
        final l = t?.byId(widget.lesson);
        if (t == null || l == null) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AcsNav(ink: ink, trail: base),
            const SizedBox(height: 20),
            Text('Lecția nu există.', style: ink.mono(15, color: ink.bad)),
          ]);
        }
        final i = t.indexOf(l);
        final prev = i > 0 ? t.lessons[i - 1] : null, next = i + 1 < t.lessons.length ? t.lessons[i + 1] : null;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AcsNav(ink: ink, trail: [...base, ('${i + 1}', teorieRoute(widget.code, l.id))]),
          const SizedBox(height: 14),
          Text('LECȚIA ${i + 1}${l.curs.isEmpty ? '' : ' · ${l.curs.toUpperCase()}'}', style: ink.mono(12.5, weight: FontWeight.w700, color: ink.accent).copyWith(letterSpacing: 1.2)),
          Text(l.title, style: ink.mono(narrow ? 25 : 32, weight: FontWeight.w700, color: ink.strong, height: 1.2)),
          const SizedBox(height: 6),
          Text(l.summary, style: ink.mono(15, color: ink.muted)),
          const SizedBox(height: 14),
          _contents(ink, l),
          for (final (k, s) in l.sections.indexed) ...[
            const SizedBox(height: 26),
            Container(
              key: _keys.putIfAbsent(s.id, () => GlobalKey()),
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
              child: Text(ink.terminal ? '## ${i + 1}.${k + 1} ${s.title}' : '${i + 1}.${k + 1}  ${s.title}', style: ink.mono(narrow ? 18 : 21, weight: FontWeight.w700, color: ink.strong)),
            ),
            for (final b in s.blocks) Padding(padding: const EdgeInsets.only(top: 12), child: TeorieBlock(ink, b, code: widget.code, problems: _problems, solved: _solved)),
          ],
          if (l.practice.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(ink.terminal ? '## exersează' : 'Exersează', style: ink.mono(21, weight: FontWeight.w700, color: ink.strong)),
            const SizedBox(height: 6),
            Text('Probleme verificate automat pe care se aplică lecția.', style: ink.mono(13.5, color: ink.muted)),
            const SizedBox(height: 8),
            _practice(context, ink, l.practice),
          ],
          const SizedBox(height: 26),
          Align(alignment: Alignment.centerLeft, child: AcsButton(ink, _read ? 'citită ✓' : 'am citit lecția', _toggleRead, primary: !_read, icon: _read ? null : Icons.check)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final p = prev == null ? null : _navCard(context, ink, 'lecția anterioară', prev, i, back: true);
            final n = next == null
                ? null
                : _navCard(context, ink, 'lecția următoare', next, i + 2, onGo: () {
                    if (!_read) TeorieProgress.mark(widget.code, widget.lesson, true);
                  });
            if (c.maxWidth < 600) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (p != null) p, if (p != null && n != null) const SizedBox(height: 8), if (n != null) n]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: p ?? const SizedBox.shrink()),
              const SizedBox(width: 12),
              Expanded(child: n ?? const SizedBox.shrink()),
            ]);
          }),
        ]);
      },
    );
  }

  Widget _navCard(BuildContext context, AcsInk ink, String label, TeorieLesson l, int n, {bool back = false, VoidCallback? onGo}) {
    final route = teorieRoute(widget.code, l.id);
    return AppLink(
      to: route,
      child: AcsTap(
        label: '$label: ${l.title}',
        onTap: () {
          onGo?.call();
          context.go(route);
        },
        builder: (h) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: h ? ink.hover : ink.panel,
            border: Border.all(color: back ? ink.line : ink.accent),
            borderRadius: ink.terminal ? null : BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: back ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
            Text(back ? '← $label' : '$label →', style: ink.mono(12.5, weight: FontWeight.w700, color: ink.accent)),
            const SizedBox(height: 2),
            Text('$n. ${l.title}', textAlign: back ? TextAlign.left : TextAlign.right, style: ink.mono(14, weight: FontWeight.w700, color: ink.strong)),
          ]),
        ),
      ),
    );
  }

  Widget _contents(AcsInk ink, TeorieLesson l) => AcsBox(ink,
      title: ink.terminal ? 'cuprins' : 'În această lecție',
      color: ink.panel,
      child: Wrap(spacing: 14, runSpacing: 4, children: [
        for (final (k, s) in l.sections.indexed)
          AcsTap(
            label: s.title,
            onTap: () {
              final c = _keys[s.id]?.currentContext;
              if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: 0.02);
            },
            builder: (h) => Text('${k + 1}. ${s.title}', style: ink.mono(13.5, color: h ? ink.strong : ink.accent, weight: FontWeight.w600)),
          ),
      ]));

  Widget _practice(BuildContext context, AcsInk ink, List<String> ids) {
    final d = _problems;
    if (d == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final id in ids)
        if (d.byId(id) != null)
          () {
            final p = d.byId(id)!;
            final ok = _solved.contains(p.id);
            return AppLink(
              to: p.route,
              child: AcsTap(
                label: p.title,
                onTap: () => context.go(p.route),
                builder: (h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(color: h ? ink.hover : ink.panel, borderRadius: ink.terminal ? null : BorderRadius.circular(6)),
                  child: Row(children: [
                    Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: ok ? ink.good : ink.dim),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.title, style: ink.mono(14, weight: FontWeight.w600, color: ink.strong))),
                    teorieTag(ink, p.kindLabel, ink.accent),
                    const SizedBox(width: 6),
                    teorieTag(ink, p.difficulty, ink.muted),
                  ]),
                ),
              ),
            );
          }(),
    ]);
  }
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

  Widget _framed(String label, Color c, Widget child, {String? title}) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: ink.dark ? 0.09 : 0.06),
          border: Border(left: BorderSide(color: c, width: 3)),
          borderRadius: ink.terminal ? null : const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text.rich(
              TextSpan(children: [
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
        return _framed('DEFINIȚIE', ink.accent, AcsText(_s('text'), ink, size: 15), title: _s('title'));
      case 'thm':
        return _framed(_s('label').isEmpty ? 'TEOREMĂ' : _s('label').toUpperCase(), ink.warn,
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AcsText(_s('text'), ink, size: 15),
              if (_s('proof').isNotEmpty) ...[const SizedBox(height: 6), Reveal(ink, 'demonstrația', AcsText(_s('proof'), ink, size: 14.5, color: ink.fg))],
            ]),
            title: _s('title'));
      case 'ex':
        return _framed('EXEMPLU', ink.good,
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AcsText(_s('text'), ink, size: 15),
              if (_s('solution').isNotEmpty) ...[const SizedBox(height: 6), Reveal(ink, b['open'] == true ? 'rezolvarea' : 'vezi rezolvarea', AcsText(_s('solution'), ink, size: 14.5), open: b['open'] == true)],
            ]),
            title: _s('title'));
      case 'note':
        final tone = _s('tone');
        final (label, c) = switch (tone) { 'warn' => ('ATENȚIE', ink.bad), 'tip' => ('SFAT', ink.good), 'exam' => ('LA EXAMEN', ink.warn), _ => ('DE REȚINUT', ink.accent) };
        return _framed(label, c, AcsText(_s('text'), ink, size: 14.5), title: _s('title'));
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
            title: _s('title'));
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
