// =============================================================================
// AN ACS COURSE: its problems, chapter by chapter, in the section's look
//   Terminal: an `ls -l` of the course's folder, one line per problem, its
//   status ([x] solved, [~] tried), the tool that solves it and how hard.
//   Notebook: the chapters as headings, the problems as a numbered list.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../acs_screen.dart' show acsSubject, acsTrail, AcsSubject;
import '../app_link.dart';
import 'acs_data.dart';
import 'acs_kit.dart';

class AcsCourseScreen extends StatefulWidget {
  final String code;
  const AcsCourseScreen({super.key, required this.code});

  @override
  State<AcsCourseScreen> createState() => _AcsCourseScreenState();
}

class _AcsCourseScreenState extends State<AcsCourseScreen> {
  AcsCourseData? _data;
  bool _loaded = false;
  Set<String> _solved = const {};
  Set<String> _tried = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await loadAcsCourse(widget.code);
    final s = await AcsProgress.solvedIds(widget.code);
    final t = await AcsProgress.triedIds(widget.code);
    if (!mounted) return;
    setState(() {
      _data = d;
      _solved = s;
      _tried = t;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subject = acsSubject(widget.code);
    return AcsPage(
      maxWidth: 960,
      builder: (context, ink, narrow) {
        if (!_loaded) return Padding(padding: const EdgeInsets.only(top: 40), child: Text('se încarcă...', style: ink.mono(14, color: ink.muted)));
        final data = _data;
        if (subject == null || data == null) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AcsNav(ink: ink, trail: acsTrail(widget.code)),
            const SizedBox(height: 24),
            Text(ink.terminal ? 'ls: cannot access \'${widget.code}/\': No such file or directory' : 'Materia nu are încă probleme.', style: ink.mono(15, color: ink.bad)),
          ]);
        }
        return ink.terminal
            ? _terminal(context, ink, narrow, subject, data)
            : _notebook(context, ink, narrow, subject, data);
      },
    );
  }

  String _status(AcsProblem p) => _solved.contains(p.id) ? 'x' : _tried.contains(p.id) ? '~' : ' ';

  Widget _row(BuildContext context, AcsInk ink, bool narrow, AcsProblem p, int n) {
    final st = _status(p);
    final statusColor = st == 'x' ? ink.good : st == '~' ? ink.warn : ink.dim;
    final cells = ink.mono(narrow ? 13.5 : 14.5);
    return AppLink(
      to: p.route,
      child: AcsTap(
        label: p.title,
        onTap: () => context.go(p.route),
        builder: (h) {
          final title = Text(p.title,
              style: cells.copyWith(
                  color: st == 'x' ? ink.muted : ink.strong,
                  fontWeight: FontWeight.w700,
                  decoration: h ? TextDecoration.underline : null,
                  decorationColor: ink.strong),
              overflow: TextOverflow.ellipsis);
          if (ink.terminal) {
            return Container(
              color: h ? ink.hover : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('[', style: cells.copyWith(color: ink.dim)),
                  Text(st, style: cells.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
                  Text('] ', style: cells.copyWith(color: ink.dim)),
                  SizedBox(width: 30, child: Text(p.id.padLeft(2, '0'), style: cells.copyWith(color: ink.accent))),
                  Expanded(child: title),
                  if (!narrow) SizedBox(width: 92, child: Text(p.kindLabel, style: cells.copyWith(color: ink.muted))),
                  SizedBox(width: narrow ? 62 : 74, child: Text(p.difficulty, textAlign: TextAlign.right, style: cells.copyWith(color: _diffColor(ink, p.difficulty)))),
                ],
              ),
            );
          }
          return Container(
            color: h ? ink.hover : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Icon(st == 'x' ? Icons.check_box : st == '~' ? Icons.indeterminate_check_box_outlined : Icons.check_box_outline_blank,
                      size: 18, color: statusColor),
                ),
                SizedBox(width: 28, child: Text('$n.', style: cells.copyWith(color: ink.muted))),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    title,
                    Text('${p.kindLabel} · ${p.difficulty}${p.source.isEmpty ? '' : ' · ${p.source}'}',
                        style: ink.mono(12.5, color: ink.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Color _diffColor(AcsInk ink, String d) => d == 'grea' ? ink.bad : d == 'medie' ? ink.warn : ink.good;

  Widget _terminal(BuildContext context, AcsInk ink, bool narrow, AcsSubject s, AcsCourseData data) {
    final done = data.problems.where((p) => _solved.contains(p.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
                TextSpan(children: [
                  TextSpan(text: '~/acs/', style: TextStyle(color: ink.accent)),
                  TextSpan(text: s.code, style: TextStyle(color: ink.strong)),
                ]),
                style: ink.mono(narrow ? 28 : 34, weight: FontWeight.w700, height: 1.1)),
            const SizedBox(height: 4),
            Text('${s.name} · ${s.about}', style: ink.mono(14, color: ink.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        AcsNav(ink: ink, trail: acsTrail(s.code)),
        const SizedBox(height: 18),
        AcsPrompt(ink, 'cat progres', dir: '~/acs/${s.code}'),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: '█' * (data.problems.isEmpty ? 0 : (done * 20 / data.problems.length).round()), style: TextStyle(color: ink.accent)),
          TextSpan(text: '█' * (20 - (data.problems.isEmpty ? 0 : (done * 20 / data.problems.length).round())), style: TextStyle(color: ink.line)),
          TextSpan(text: '  $done/${data.problems.length} rezolvate', style: TextStyle(color: ink.muted)),
        ]), style: ink.mono(14)),
        for (final ch in data.chapters) ...[
          const SizedBox(height: 20),
          AcsPrompt(ink, 'ls ${_slug(ch)}/', dir: '~/acs/${s.code}'),
          Padding(padding: const EdgeInsets.only(top: 2, bottom: 4), child: Text('# $ch', style: ink.mono(13.5, color: ink.muted))),
          for (final (i, p) in data.problems.where((p) => p.chapter == ch).indexed) _row(context, ink, narrow, p, i + 1),
        ],
        const SizedBox(height: 22),
        Row(children: [Flexible(child: AcsPrompt(ink, '', dir: '~/acs/${s.code}')), AcsCursor(color: ink.accent)]),
      ],
    );
  }

  Widget _notebook(BuildContext context, AcsInk ink, bool narrow, AcsSubject s, AcsCourseData data) {
    final done = data.problems.where((p) => _solved.contains(p.id)).length;
    var n = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('[${s.short}]', style: ink.mono(15, weight: FontWeight.w700, color: ink.accent)),
        Text(s.name, style: ink.mono(narrow ? 28 : 36, weight: FontWeight.w700, color: ink.strong, height: 1.15)),
        const SizedBox(height: 4),
        Text(s.about, style: ink.mono(narrow ? 15 : 17, color: ink.muted)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line, width: 2))),
          child: AcsNav(ink: ink, trail: acsTrail(s.code), size: narrow ? 15 : 17),
        ),
        const SizedBox(height: 12),
        Text.rich(TextSpan(children: [
          TextSpan(text: '${data.problems.length} probleme', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: ' • $done rezolvate', style: TextStyle(color: ink.muted)),
        ]), style: ink.mono(14)),
        for (final ch in data.chapters) ...[
          const SizedBox(height: 26),
          Text(ch, style: ink.mono(narrow ? 18 : 21, weight: FontWeight.w700, color: ink.strong)),
          const SizedBox(height: 8),
          for (final p in data.problems.where((p) => p.chapter == ch)) _row(context, ink, narrow, p, ++n),
        ],
      ],
    );
  }

  static String _slug(String ch) => ch
      .toLowerCase()
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp('[ăâ]'), 'a')
      .replaceAll('î', 'i')
      .replaceAll(RegExp('[șş]'), 's')
      .replaceAll(RegExp('[țţ]'), 't')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
