// =============================================================================
// AN ACS PROBLEM: the statement beside the course's own tool
//   The statement (where it comes from, the task, a closed hint) on the left,
//   the workspace on the right (below it on a phone): a shell for USO, an x86
//   emulator for IOCLA, a C editor with tests, a circuit, a simulation...
//   Solved, it says so, shows how it's done and links to the next problem.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../acs_screen.dart' show acsSubject, acsTrail;
import '../app_link.dart';
import 'acs_data.dart';
import 'acs_kit.dart';
import 'ws/workspaces.dart';

class AcsProblemScreen extends StatefulWidget {
  final String course;
  final String id;
  const AcsProblemScreen({super.key, required this.course, required this.id});

  @override
  State<AcsProblemScreen> createState() => _AcsProblemScreenState();
}

class _AcsProblemScreenState extends State<AcsProblemScreen> {
  AcsCourseData? _data;
  AcsProblem? _p;
  bool _loaded = false;
  bool _solved = false;
  bool _justSolved = false;
  int _fails = 0;
  bool _hint = false;
  bool _solution = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await loadAcsCourse(widget.course);
    final p = d?.byId(widget.id);
    final s = p == null ? false : await AcsProgress.solved(p);
    if (!mounted) return;
    setState(() {
      _data = d;
      _p = p;
      _solved = s;
      _loaded = true;
    });
  }

  void _verdict(bool ok) {
    final p = _p!;
    if (ok) {
      AcsProgress.markSolved(p);
      setState(() {
        _justSolved = !_solved || _justSolved;
        _solved = true;
      });
    } else {
      AcsProgress.markTried(p);
      setState(() => _fails++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AcsPage(
      maxWidth: 1360,
      builder: (context, ink, narrow) {
        if (!_loaded) return Text('se încarcă...', style: ink.mono(14, color: ink.muted));
        final p = _p;
        final subject = acsSubject(widget.course);
        if (p == null || subject == null) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AcsNav(ink: ink, trail: [...acsTrail(widget.course), (widget.id, '/acs/${widget.course}/${widget.id}')]),
            const SizedBox(height: 24),
            Text(ink.terminal ? 'cat: ${widget.id}: No such file or directory' : 'Problema nu există.', style: ink.mono(15, color: ink.bad)),
          ]);
        }
        final wide = MediaQuery.of(context).size.width >= 1100;
        final statement = _statement(context, ink, narrow, p);
        final workspace = KeyedSubtree(
          key: ValueKey(p.key),
          child: buildWorkspace(p, ink, narrow, _verdict),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, ink, narrow, p, subject.code),
            const SizedBox(height: 18),
            if (_justSolved) ...[_solvedBar(context, ink, p), const SizedBox(height: 16)],
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: statement),
                  const SizedBox(width: 28),
                  Expanded(flex: 6, child: workspace),
                ],
              )
            else ...[
              statement,
              const SizedBox(height: 22),
              workspace,
            ],
            const SizedBox(height: 28),
            _footer(context, ink, p),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, AcsInk ink, bool narrow, AcsProblem p, String code) {
    final meta = [p.difficulty, p.kindLabel, if (p.source.isNotEmpty) p.source].join(' · ');
    final solvedTag = _solved
        ? Text(ink.terminal ? '  [✓ rezolvată]' : '  ✓ rezolvată', style: ink.mono(14, weight: FontWeight.w700, color: ink.good))
        : const SizedBox.shrink();
    if (ink.terminal) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AcsNav(ink: ink, trail: [...acsTrail(code), (p.id, p.route)]),
        const SizedBox(height: 14),
        AcsPrompt(ink, 'cat ${p.id.padLeft(2, '0')}.md', dir: '~/acs/$code'),
        const SizedBox(height: 6),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('# ${p.title}', style: ink.mono(narrow ? 22 : 27, weight: FontWeight.w700, color: ink.strong, height: 1.2)),
          solvedTag,
        ]),
        const SizedBox(height: 4),
        Text('> ${p.chapter} · $meta', style: ink.mono(13.5, color: ink.muted)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line, width: 2))),
        child: AcsNav(ink: ink, trail: [...acsTrail(code), (p.id, p.route)], size: narrow ? 15 : 16),
      ),
      const SizedBox(height: 16),
      Text(p.chapter, style: ink.mono(14, color: ink.accent, weight: FontWeight.w700)),
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('${p.id}. ${p.title}', style: ink.mono(narrow ? 24 : 30, weight: FontWeight.w700, color: ink.strong, height: 1.2)),
        solvedTag,
      ]),
      const SizedBox(height: 4),
      Text(meta, style: ink.mono(13.5, color: ink.muted)),
    ]);
  }

  Widget _statement(BuildContext context, AcsInk ink, bool narrow, AcsProblem p) {
    Widget toggle(String label, bool open, VoidCallback onTap) => AcsTap(
          label: label,
          onTap: onTap,
          builder: (h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${open ? '[−]' : '[+]'} $label',
                style: ink.mono(14, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)),
          ),
        );
    final canSee = _solved || _fails >= 2;
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AcsText(p.statement, ink, size: narrow ? 14.5 : 15.5),
          if (p.hint.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectionContainer.disabled(child: toggle('indiciu', _hint, () => setState(() => _hint = !_hint))),
            if (_hint) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: AcsText(p.hint, ink, size: 14.5, color: ink.muted)),
          ],
          if (p.solution.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (canSee)
              SelectionContainer.disabled(child: toggle('cum se rezolvă', _solution, () => setState(() => _solution = !_solution)))
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('[·] rezolvarea apare după ce rezolvi problema (sau după două încercări)', style: ink.mono(13, color: ink.dim)),
              ),
            if (canSee && _solution) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: AcsText(p.solution, ink, size: 14.5)),
          ],
        ],
      ),
    );
  }

  Widget _solvedBar(BuildContext context, AcsInk ink, AcsProblem p) {
    final next = _data?.after(p);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ink.good.withValues(alpha: 0.12),
        border: Border.all(color: ink.good),
        borderRadius: ink.terminal ? null : BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(
          child: Text(ink.terminal ? '[✓] exit 0 — problema e rezolvată.' : 'Corect! Problema e rezolvată.',
              style: ink.mono(15, weight: FontWeight.w700, color: ink.good)),
        ),
        if (next != null) AppLink(to: next.route, child: AcsButton(ink, 'următoarea →', () => context.go(next.route), primary: true)),
      ]),
    );
  }

  Widget _footer(BuildContext context, AcsInk ink, AcsProblem p) {
    final list = _data?.problems ?? const <AcsProblem>[];
    final i = list.indexWhere((q) => q.id == p.id);
    final prev = i > 0 ? list[i - 1] : null;
    final next = i >= 0 && i + 1 < list.length ? list[i + 1] : null;
    Widget link(AcsProblem q, String label) => AppLink(
          to: q.route,
          child: AcsTap(
            label: q.title,
            onTap: () => context.go(q.route),
            builder: (h) => Text(label,
                style: ink.mono(14, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)
                    .copyWith(decoration: h ? TextDecoration.underline : null, decorationColor: ink.strong)),
          ),
        );
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: ink.line))),
      child: Row(children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: prev == null ? const SizedBox.shrink() : link(prev, '← ${prev.title}'))),
        const SizedBox(width: 16),
        Expanded(child: Align(alignment: Alignment.centerRight, child: next == null ? const SizedBox.shrink() : link(next, '${next.title} →'))),
      ]),
    );
  }
}
