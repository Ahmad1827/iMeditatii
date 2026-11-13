// =============================================================================
// AN ACS COURSE: its problems, organised so the next one is easy to pick
//   On top, where to go on: the problem tried and left, or the first one not
//   solved. Then the chapters as tiles (problems, solved, how hard, how many
//   are exercises and how many multiple-choice), each a tab of the list; then
//   filters (status, difficulty, exercises / grile, only from exams) and a
//   search. In the list a chapter's exercises come before its grile, the easy
//   ones first, each with the start of its statement.
//   Terminal: the tiles are boxes with a bar of blocks, the filters are flags.
//   Notebook: rounded tiles, pills.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum _Status { all, todo, tried, solved }

enum _Type { all, exercises, grile }

const _diffs = ['ușoară', 'medie', 'grea'];
int _diffRank(String d) => _diffs.contains(d) ? _diffs.indexOf(d) : 1;

class _AcsCourseScreenState extends State<AcsCourseScreen> {
  AcsCourseData? _data;
  bool _loaded = false;
  Set<String> _solved = const {};
  Set<String> _tried = const {};

  // the tab: a chapter, or null for every chapter
  String? _chapter;
  _Status _status = _Status.all;
  String? _diff;
  _Type _type = _Type.all;
  bool _examOnly = false;
  String _query = '';
  final TextEditingController _search = TextEditingController();

  String get _prefKey => 'acs-capitol:${widget.code}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await loadAcsCourse(widget.code);
    final s = await AcsProgress.solvedIds(widget.code);
    final t = await AcsProgress.triedIds(widget.code);
    String? saved;
    var chosen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefKey)) {
        chosen = true;
        final v = prefs.getString(_prefKey) ?? '';
        saved = v.isEmpty ? null : v;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _data = d;
      _solved = s;
      _tried = t;
      _loaded = true;
      if (d != null) {
        if (chosen && (saved == null || d.chapters.contains(saved))) {
          _chapter = saved;
        } else {
          _chapter = _next(d)?.chapter;
        }
      }
    });
  }

  void _pickChapter(String? ch) {
    setState(() {
      _chapter = ch;
    });
    SharedPreferences.getInstance().then((p) => p.setString(_prefKey, ch ?? '')).catchError((_) => false);
  }

  bool _isGrila(AcsProblem p) => p.kind == 'grila';

  /// From an exam or a test of the course, not from a seminar, a lab or the course's slides.
  static bool _fromExam(AcsProblem p) => RegExp(r'examen|test|colocviu|evaluare|parțial|partial|subiect', caseSensitive: false).hasMatch(p.source);

  /// Where to go on: a problem tried and not solved, else the first not solved.
  AcsProblem? _next(AcsCourseData d) {
    for (final p in d.problems) {
      if (_tried.contains(p.id) && !_solved.contains(p.id)) return p;
    }
    for (final p in d.problems) {
      if (!_solved.contains(p.id)) return p;
    }
    return null;
  }

  bool get _filtering => _status != _Status.all || _diff != null || _type != _Type.all || _examOnly || _query.trim().isNotEmpty;

  bool _passes(AcsProblem p) {
    final solved = _solved.contains(p.id), tried = _tried.contains(p.id);
    switch (_status) {
      case _Status.todo:
        if (solved) return false;
      case _Status.tried:
        if (!tried || solved) return false;
      case _Status.solved:
        if (!solved) return false;
      case _Status.all:
    }
    if (_diff != null && p.difficulty != _diff) return false;
    if (_type == _Type.grile && !_isGrila(p)) return false;
    if (_type == _Type.exercises && _isGrila(p)) return false;
    if (_examOnly && !_fromExam(p)) return false;
    final q = _fold(_query.trim());
    if (q.isNotEmpty && !_fold('${p.title} ${p.statement} ${p.source} ${p.kindLabel}').contains(q)) return false;
    return true;
  }

  /// A chapter's problems in the order shown: exercises before grile, easy first.
  List<AcsProblem> _ordered(Iterable<AcsProblem> ps) {
    final list = ps.toList();
    final at = {for (final (i, p) in list.indexed) p.id: i};
    list.sort((a, b) {
      final g = (_isGrila(a) ? 1 : 0) - (_isGrila(b) ? 1 : 0);
      if (g != 0) return g;
      final d = _diffRank(a.difficulty) - _diffRank(b.difficulty);
      return d != 0 ? d : at[a.id]! - at[b.id]!;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final subject = acsSubject(widget.code);
    return AcsPage(
      maxWidth: 1040,
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
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(ink, narrow, subject, data),
          const SizedBox(height: 18),
          _continueCard(context, ink, narrow, data),
          const SizedBox(height: 22),
          _sectionTitle(ink, 'capitole', 'Capitole'),
          const SizedBox(height: 8),
          _chapterTiles(ink, narrow, data),
          const SizedBox(height: 18),
          _filterBar(ink, narrow, data),
          const SizedBox(height: 14),
          ..._list(context, ink, narrow, data),
        ]);
      },
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header(AcsInk ink, bool narrow, AcsSubject s, AcsCourseData data) {
    final done = data.problems.where((p) => _solved.contains(p.id)).length;
    final total = data.problems.length;
    final grile = data.problems.where(_isGrila).length;
    final exam = data.problems.where(_fromExam).length;
    final facts = '$total probleme · ${total - grile} exerciții · $grile grile${exam > 0 ? ' · $exam din examene și teste' : ''}';
    if (ink.terminal) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        const SizedBox(height: 16),
        AcsPrompt(ink, 'cat progres', dir: '~/acs/${s.code}'),
        const SizedBox(height: 4),
        Wrap(spacing: 14, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _blocks(ink, done, total, 24, 14),
          Text('$done/$total rezolvate', style: ink.mono(14, color: ink.muted)),
        ]),
        Text(facts, style: ink.mono(13, color: ink.dim)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('[${s.short}]', style: ink.mono(15, weight: FontWeight.w700, color: ink.accent)),
      Text(s.name, style: ink.mono(narrow ? 28 : 36, weight: FontWeight.w700, color: ink.strong, height: 1.15)),
      const SizedBox(height: 4),
      Text(s.about, style: ink.mono(narrow ? 15 : 17, color: ink.muted)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line, width: 2))),
        child: AcsNav(ink: ink, trail: acsTrail(s.code), size: narrow ? 15 : 17),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _bar(ink, total == 0 ? 0 : done / total, 8)),
        const SizedBox(width: 12),
        Text('$done / $total rezolvate', style: ink.mono(14, weight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      Text(facts, style: ink.mono(13, color: ink.muted)),
    ]);
  }

  Widget _sectionTitle(AcsInk ink, String cmd, String title) => ink.terminal
      ? AcsPrompt(ink, 'ls $cmd/', dir: '~/acs/${widget.code}')
      : Text(title, style: ink.mono(19, weight: FontWeight.w700, color: ink.strong));

  /// `████░░░░` for the terminal.
  Widget _blocks(AcsInk ink, int done, int total, int width, double size) {
    final n = total == 0 ? 0 : (done * width / total).round();
    return Text.rich(
        TextSpan(children: [
          TextSpan(text: '█' * n, style: TextStyle(color: ink.accent)),
          TextSpan(text: '█' * (width - n), style: TextStyle(color: ink.line)),
        ]),
        style: ink.mono(size, height: 1.2));
  }

  /// A rounded bar for the notebook.
  Widget _bar(AcsInk ink, double f, double h) => ClipRRect(
        borderRadius: BorderRadius.circular(h),
        child: SizedBox(
          height: h,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: ink.line.withValues(alpha: 0.5)),
            FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: f.clamp(0, 1).toDouble(), child: ColoredBox(color: ink.good)),
          ]),
        ),
      );

  // ---------------------------------------------------------- continue card

  Widget _continueCard(BuildContext context, AcsInk ink, bool narrow, AcsCourseData data) {
    final p = _next(data);
    if (p == null) {
      return AcsBox(ink,
          color: ink.panel,
          child: Text(ink.terminal ? '# toate problemele sunt rezolvate. bravo!' : 'Ai rezolvat toate problemele materiei. Bravo!',
              style: ink.mono(15, weight: FontWeight.w700, color: ink.good)));
    }
    final resumed = _tried.contains(p.id);
    final label = resumed ? 'continuă' : (_solved.isEmpty ? 'începe aici' : 'următoarea');
    final open = AcsButton(ink, resumed ? 'continuă' : 'deschide', () => context.go(p.route), primary: true, icon: Icons.play_arrow_rounded);
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ink.terminal ? '>> $label' : label.toUpperCase(),
          style: ink.mono(12.5, weight: FontWeight.w700, color: resumed ? ink.warn : ink.accent).copyWith(letterSpacing: ink.terminal ? 0 : 1.2)),
      const SizedBox(height: 4),
      Text(p.title, style: ink.mono(narrow ? 18 : 21, weight: FontWeight.w700, color: ink.strong, height: 1.25)),
      const SizedBox(height: 4),
      Text(_excerpt(p.statement, 180), style: ink.mono(13.5, color: ink.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        _tag(ink, _chapterName(p.chapter), ink.muted),
        _tag(ink, p.kindLabel, ink.accent),
        _tag(ink, p.difficulty, _diffColor(ink, p.difficulty)),
        if (p.source.isNotEmpty) _tag(ink, p.source, ink.muted),
      ]),
    ]);
    return AppLink(
      to: p.route,
      child: AcsTap(
        label: '$label: ${p.title}',
        onTap: () => context.go(p.route),
        builder: (h) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: h ? ink.hover : ink.panel,
            border: Border.all(color: resumed ? ink.warn : ink.accent, width: ink.terminal ? 1 : 1.5),
            borderRadius: ink.terminal ? null : BorderRadius.circular(10),
          ),
          child: narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [body, const SizedBox(height: 12), open])
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: body), const SizedBox(width: 16), open]),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- chapter tiles

  Widget _chapterTiles(AcsInk ink, bool narrow, AcsCourseData data) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 760 ? 3 : (c.maxWidth >= 330 ? 2 : 1);
      const gap = 10.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final (i, ch) in data.chapters.indexed) SizedBox(width: w, child: _tile(ink, narrow, data, ch, i + 1)),
      ]);
    });
  }

  Widget _tile(AcsInk ink, bool narrow, AcsCourseData data, String ch, int n) {
    final ps = data.problems.where((p) => p.chapter == ch).toList();
    final done = ps.where((p) => _solved.contains(p.id)).length;
    final grile = ps.where(_isGrila).length;
    final byDiff = [for (final d in _diffs) ps.where((p) => p.difficulty == d).length];
    final sel = _chapter == ch;
    final complete = ps.isNotEmpty && done == ps.length;
    return AcsTap(
      label: 'capitolul ${_chapterName(ch)}',
      onTap: () => _pickChapter(sel ? null : ch),
      builder: (h) => Container(
        padding: EdgeInsets.all(narrow ? 10 : 12),
        decoration: BoxDecoration(
          color: sel ? ink.hover : (h ? ink.hover : ink.panel),
          border: Border.all(color: sel ? ink.accent : ink.line, width: sel ? 2 : 1),
          borderRadius: ink.terminal ? null : BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ink.terminal ? '${n.toString().padLeft(2, '0')} ' : '$n  ', style: ink.mono(14, weight: FontWeight.w700, color: ink.accent)),
            Expanded(
              child: Text(_chapterName(ch),
                  style: ink.mono(14, weight: FontWeight.w700, color: ink.strong, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (complete) Icon(Icons.check_circle, size: 16, color: ink.good),
          ]),
          const SizedBox(height: 8),
          ink.terminal
              ? Row(children: [Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _blocks(ink, done, ps.length, 16, 12))), const SizedBox(width: 8), Text('$done/${ps.length}', style: ink.mono(12.5, color: ink.muted))])
              : Row(children: [Expanded(child: _bar(ink, ps.isEmpty ? 0 : done / ps.length, 5)), const SizedBox(width: 8), Text('$done/${ps.length}', style: ink.mono(12.5, color: ink.muted))]),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              if (ps.length > grile) TextSpan(text: '${ps.length - grile} ex.'),
              if (grile > 0) TextSpan(text: '${ps.length > grile ? ' · ' : ''}$grile grile'),
              const TextSpan(text: '   '),
              for (final (k, d) in _diffs.indexed)
                if (byDiff[k] > 0) TextSpan(text: '●${byDiff[k]} ', style: TextStyle(color: _diffColor(ink, d))),
            ]),
            style: ink.mono(12, color: ink.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }

  // -------------------------------------------------------------- filters

  Widget _filterBar(AcsInk ink, bool narrow, AcsCourseData data) {
    Widget group(String label, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(width: narrow ? null : 92, child: Text(ink.terminal ? '--$label' : label, style: ink.mono(12.5, color: ink.muted))),
            ...chips,
          ]),
        );
    final ps = data.problems;
    int count(bool Function(AcsProblem) f) => ps.where(f).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _searchField(ink),
      const SizedBox(height: 10),
      group('capitol', [
        _chip(ink, 'toate capitolele', _chapter == null, () => _pickChapter(null)),
        if (_chapter != null) _chip(ink, _chapterName(_chapter!), true, () => _pickChapter(null), closable: true),
      ]),
      group('stare', [
        _chip(ink, 'toate', _status == _Status.all, () => setState(() => _status = _Status.all)),
        _chip(ink, 'de rezolvat', _status == _Status.todo, () => setState(() => _status = _Status.todo)),
        _chip(ink, 'începute ${count((p) => _tried.contains(p.id) && !_solved.contains(p.id))}', _status == _Status.tried,
            () => setState(() => _status = _Status.tried)),
        _chip(ink, 'rezolvate ${_solved.length}', _status == _Status.solved, () => setState(() => _status = _Status.solved)),
      ]),
      group('dificultate', [
        _chip(ink, 'oricare', _diff == null, () => setState(() => _diff = null)),
        for (final d in _diffs)
          _chip(ink, '$d ${count((p) => p.difficulty == d)}', _diff == d, () => setState(() => _diff = _diff == d ? null : d), dot: _diffColor(ink, d)),
      ]),
      group('tip', [
        _chip(ink, 'toate', _type == _Type.all, () => setState(() => _type = _Type.all)),
        _chip(ink, 'exerciții ${count((p) => !_isGrila(p))}', _type == _Type.exercises, () => setState(() => _type = _Type.exercises)),
        _chip(ink, 'grile ${count(_isGrila)}', _type == _Type.grile, () => setState(() => _type = _Type.grile)),
        _chip(ink, 'din examene ${count(_fromExam)}', _examOnly, () => setState(() => _examOnly = !_examOnly)),
      ]),
    ]);
  }

  Widget _searchField(AcsInk ink) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ink.panel,
          border: Border.all(color: ink.line),
          borderRadius: ink.terminal ? null : BorderRadius.circular(8),
        ),
        child: Row(children: [
          ink.terminal ? Text('grep -i ', style: ink.mono(14, color: ink.accent)) : Icon(Icons.search, size: 18, color: ink.muted),
          if (!ink.terminal) const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: ink.accent,
              style: ink.mono(14, color: ink.strong),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                hintText: 'caută în titluri și enunțuri (ex.: subrețea, semafor, Bresenham)',
                hintStyle: ink.mono(13.5, color: ink.dim),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            AcsTap(
              label: 'șterge căutarea',
              onTap: () => setState(() {
                _search.clear();
                _query = '';
              }),
              builder: (h) => Icon(Icons.close, size: 18, color: h ? ink.strong : ink.muted),
            ),
        ]),
      );

  Widget _chip(AcsInk ink, String label, bool on, VoidCallback onTap, {Color? dot, bool closable = false}) => AcsTap(
        label: label,
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: on ? ink.accent : (h ? ink.hover : Colors.transparent),
            border: Border.all(color: on ? ink.accent : ink.line),
            borderRadius: ink.terminal ? null : BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (dot != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: on ? ink.bg : dot, shape: ink.terminal ? BoxShape.rectangle : BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label, style: ink.mono(12.5, weight: on ? FontWeight.w700 : null, color: on ? ink.bg : ink.fg)),
            if (closable) ...[const SizedBox(width: 4), Icon(Icons.close, size: 13, color: on ? ink.bg : ink.muted)],
          ]),
        ),
      );

  // ------------------------------------------------------------------ list

  List<Widget> _list(BuildContext context, AcsInk ink, bool narrow, AcsCourseData data) {
    final chapters = _chapter == null ? data.chapters : [_chapter!];
    final out = <Widget>[];
    var shown = 0;
    for (final ch in chapters) {
      final all = data.problems.where((p) => p.chapter == ch).toList();
      final ps = _ordered(all.where(_passes));
      if (ps.isEmpty) continue;
      shown += ps.length;
      final done = all.where((p) => _solved.contains(p.id)).length;
      out.add(Padding(
        padding: EdgeInsets.only(top: out.isEmpty ? 6 : 22, bottom: 6),
        child: ink.terminal
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AcsPrompt(ink, 'ls ${_slug(ch)}/', dir: '~/acs/${widget.code}'),
                Text('# $ch  ($done/${all.length})', style: ink.mono(13.5, color: ink.muted)),
              ])
            : Container(
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text(ch, style: ink.mono(narrow ? 18 : 20, weight: FontWeight.w700, color: ink.strong))),
                  Text('$done/${all.length}', style: ink.mono(13, color: ink.muted)),
                ]),
              ),
      ));
      final ex = ps.where((p) => !_isGrila(p)).toList();
      final gr = ps.where(_isGrila).toList();
      if (ex.isNotEmpty && gr.isNotEmpty) out.add(_subhead(ink, 'exerciții', ex.length));
      for (final p in ex) {
        out.add(_row(context, ink, narrow, p));
      }
      if (gr.isNotEmpty && ex.isNotEmpty) out.add(_subhead(ink, 'grile', gr.length));
      for (final p in gr) {
        out.add(_row(context, ink, narrow, p));
      }
    }
    if (shown == 0) {
      out.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ink.terminal ? '# nicio problemă nu se potrivește' : 'Nicio problemă nu se potrivește filtrelor.', style: ink.mono(14.5, color: ink.muted)),
          const SizedBox(height: 10),
          AcsButton(ink, 'arată tot', () => setState(() {
                _status = _Status.all;
                _diff = null;
                _type = _Type.all;
                _examOnly = false;
                _search.clear();
                _query = '';
                _chapter = null;
              })),
        ]),
      ));
    } else if (_filtering || _chapter != null) {
      out.insert(
          0,
          Text(ink.terminal ? '# $shown ${shown == 1 ? 'problemă' : 'probleme'}' : '$shown ${shown == 1 ? 'problemă' : 'probleme'}',
              style: ink.mono(13, color: ink.muted)));
    }
    if (ink.terminal) {
      out.add(const SizedBox(height: 22));
      out.add(Row(children: [Flexible(child: AcsPrompt(ink, '', dir: '~/acs/${widget.code}')), AcsCursor(color: ink.accent)]));
    }
    return out;
  }

  Widget _subhead(AcsInk ink, String label, int n) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(ink.terminal ? '## $label ($n)' : '${label.toUpperCase()} · $n',
            style: ink.mono(12, weight: FontWeight.w700, color: ink.dim).copyWith(letterSpacing: ink.terminal ? 0 : 1.1)),
      );

  String _status1(AcsProblem p) => _solved.contains(p.id) ? 'x' : _tried.contains(p.id) ? '~' : ' ';

  Widget _row(BuildContext context, AcsInk ink, bool narrow, AcsProblem p) {
    final st = _status1(p);
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis);
          final excerpt = _excerpt(p.statement, 160);
          final meta = Wrap(spacing: 6, runSpacing: 4, children: [
            _tag(ink, p.kindLabel, ink.accent),
            _tag(ink, p.difficulty, _diffColor(ink, p.difficulty)),
            if (p.source.isNotEmpty) _tag(ink, p.source, ink.muted),
          ]);
          final status = ink.terminal
              ? Text.rich(TextSpan(children: [
                  TextSpan(text: '[', style: TextStyle(color: ink.dim)),
                  TextSpan(text: st, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                  TextSpan(text: '] ', style: TextStyle(color: ink.dim)),
                ]), style: cells)
              : Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Icon(st == 'x' ? Icons.check_circle : st == '~' ? Icons.timelapse_rounded : Icons.radio_button_unchecked, size: 18, color: statusColor),
                );
          return Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: h ? ink.hover : Colors.transparent,
              borderRadius: ink.terminal ? null : BorderRadius.circular(6),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              status,
              if (ink.terminal) SizedBox(width: 30, child: Text(p.id.padLeft(2, '0'), style: cells.copyWith(color: ink.accent))),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  title,
                  if (excerpt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(excerpt, style: ink.mono(12.5, color: ink.muted, height: 1.35), maxLines: narrow ? 2 : 1, overflow: TextOverflow.ellipsis),
                    ),
                  if (narrow) Padding(padding: const EdgeInsets.only(top: 5), child: meta),
                ]),
              ),
              if (!narrow) ...[
                const SizedBox(width: 12),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: Align(alignment: Alignment.topRight, widthFactor: 1, child: meta)),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _tag(AcsInk ink, String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.55)),
          borderRadius: ink.terminal ? null : BorderRadius.circular(4),
        ),
        child: Text(text, style: ink.mono(11.5, color: c), maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  static Color _diffColor(AcsInk ink, String d) => d == 'grea' ? ink.bad : d == 'medie' ? ink.warn : ink.good;

  /// "3. Rasterizare" -> "Rasterizare".
  static String _chapterName(String ch) => ch.replaceFirst(RegExp(r'^\d+\.\s*'), '');

  /// The statement's first words, without the marks of its markdown and TeX.
  static String _excerpt(String s, int max) {
    var t = s
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' … ')
        .replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), ' … ')
        .replaceAll(RegExp(r'[`*_#>|]'), '')
        .replaceAll(RegExp(r'\$([^$]*)\$'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (t.length > max) t = '${t.substring(0, max).trimRight()}…';
    return t;
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[ăâ]'), 'a')
      .replaceAll('î', 'i')
      .replaceAll(RegExp('[șş]'), 's')
      .replaceAll(RegExp('[țţ]'), 't');

  static String _slug(String ch) => _fold(ch)
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
