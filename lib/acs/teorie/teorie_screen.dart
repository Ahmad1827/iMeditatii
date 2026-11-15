// =============================================================================
// THEORY PAGES: the list of lessons, and a lesson
//   /acs/<code>/teorie: the lessons as a road, part by part (with the seminar
//   test each part is for), what is read, where to go on.
//   /acs/<code>/teorie/<lesson>: what the lesson teaches first, then its
//   sections, each opening with its takeaway ("pe scurt"). Two ways to read:
//   esențial (the takeaways, definitions, theorems, algorithms and the
//   visualisations; the rest of a section behind "arată tot") and complet.
//   On a wide screen the contents stay on the left and follow the reading;
//   on a phone a bar with the section being read comes down once the title
//   is gone, and opens the contents. Sections come in as they are reached.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../acs_screen.dart' show acsSubject, acsTrail;
import '../../app_link.dart';
import '../../theme_manager.dart';
import '../acs_data.dart';
import '../acs_kit.dart';
import 'teorie_blocks.dart';
import 'teorie_data.dart';
import 'teorie_kit.dart';

export 'teorie_blocks.dart';

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
        final next = (_last != null && t.byId(_last!) != null && !_read.contains(_last))
            ? t.byId(_last!)!
            : t.lessons.firstWhere((l) => !_read.contains(l.id), orElse: () => t.lessons.first);
        var k = 0;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (ink.terminal)
            Text.rich(
                TextSpan(children: [
                  TextSpan(text: '~/acs/${widget.code}/', style: TextStyle(color: ink.accent)),
                  TextSpan(text: 'teorie', style: TextStyle(color: ink.strong)),
                ]),
                style: ink.mono(narrow ? 26 : 32, weight: FontWeight.w700, height: 1.1))
          else ...[
            Text('[${s?.short ?? widget.code}] teorie', style: ink.mono(15, weight: FontWeight.w700, color: ink.accent)),
            Text(t.title, style: ink.mono(narrow ? 26 : 34, weight: FontWeight.w700, color: ink.strong, height: 1.15)),
          ],
          const SizedBox(height: 8),
          AcsNav(ink: ink, trail: trail),
          const SizedBox(height: 16),
          _progress(ink, t, done),
          const SizedBox(height: 14),
          _continueCard(context, ink, narrow, t, next),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AppLink(to: '/acs/${widget.code}', child: AcsButton(ink, 'la problemele materiei', () => context.go('/acs/${widget.code}'), icon: Icons.edit_note)),
          ),
          for (final p in t.parts) ...[
            const SizedBox(height: 30),
            _partHead(ink, narrow, p, t),
            const SizedBox(height: 12),
            for (final (j, id) in p.lessons.indexed)
              if (t.byId(id) != null) Stagger(k++, child: _roadStop(context, ink, narrow, t, t.byId(id)!, last: j == p.lessons.length - 1)),
          ],
        ]);
      },
    );
  }

  Widget _progress(AcsInk ink, TeorieCourse t, int done) {
    final viz = t.lessons.fold(0, (a, l) => a + l.vizCount);
    final minutes = t.lessons.fold(0, (a, l) => a + l.minutes);
    final f = t.lessons.isEmpty ? 0.0 : done / t.lessons.length;
    return Row(children: [
      SizedBox(
        width: 54,
        height: 54,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: f),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(value: v, strokeWidth: 5, color: ink.good, backgroundColor: ink.line.withValues(alpha: 0.6)),
            Center(child: Text('${(v * 100).round()}%', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.strong))),
          ]),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$done din ${t.lessons.length} lecții citite', style: ink.mono(15, weight: FontWeight.w700, color: ink.strong)),
          const SizedBox(height: 2),
          Text('$viz vizualizări interactive · ${(minutes / 60).toStringAsFixed(1).replaceAll('.', ',')} ore de citit', style: ink.mono(13, color: ink.muted)),
        ]),
      ),
    ]);
  }

  Widget _continueCard(BuildContext context, AcsInk ink, bool narrow, TeorieCourse t, TeorieLesson l) {
    final n = t.indexOf(l) + 1;
    final read = _read.contains(l.id);
    final route = teorieRoute(widget.code, l.id);
    final label = read ? 'RECITEȘTE' : (_read.isEmpty ? 'ÎNCEPE AICI' : 'CONTINUĂ');
    final go = AcsButton(ink, read ? 'recitește' : (_read.isEmpty ? 'începe' : 'continuă'), () => context.go(route), primary: true, icon: Icons.play_arrow_rounded);
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ink.terminal ? '>> ${label.toLowerCase()}' : label, style: ink.mono(12.5, weight: FontWeight.w800, color: ink.accent).copyWith(letterSpacing: 1.1)),
      const SizedBox(height: 4),
      Text('$n. ${l.title}', style: ink.mono(narrow ? 18 : 21, weight: FontWeight.w700, color: ink.strong, height: 1.25)),
      const SizedBox(height: 4),
      Text(l.summary, style: ink.mono(13.5, color: ink.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]);
    return AppLink(
      to: route,
      child: AcsTap(
        label: '$label: ${l.title}',
        onTap: () => context.go(route),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: h ? ink.hover : ink.panel,
            border: Border.all(color: ink.accent, width: ink.terminal ? 1 : 1.5),
            borderRadius: ink.terminal ? null : BorderRadius.circular(12),
          ),
          child: narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [body, const SizedBox(height: 12), go])
              : Row(children: [Expanded(child: body), const SizedBox(width: 16), go]),
        ),
      ),
    );
  }

  Widget _partHead(AcsInk ink, bool narrow, TeoriePart p, TeorieCourse t) {
    final ls = [for (final id in p.lessons) if (t.byId(id) != null) t.byId(id)!];
    final done = ls.where((l) => _read.contains(l.id)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(ink.terminal ? '## ${p.title}' : p.title, style: ink.mono(narrow ? 18 : 20, weight: FontWeight.w700, color: ink.strong)),
        if (p.test.isNotEmpty) teorieTag(ink, 'pentru ${p.test}', ink.warn),
        Text('$done/${ls.length}', style: ink.mono(13, weight: FontWeight.w700, color: done == ls.length ? ink.good : ink.muted)),
      ]),
      if (p.about.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(p.about, style: ink.mono(13.5, color: ink.muted))),
    ]);
  }

  /// A lesson on the road: its number on the line, the card beside it.
  Widget _roadStop(BuildContext context, AcsInk ink, bool narrow, TeorieCourse t, TeorieLesson l, {required bool last}) {
    final n = t.indexOf(l) + 1;
    final read = _read.contains(l.id);
    final here = !read && _last == l.id;
    final route = teorieRoute(widget.code, l.id);
    final dot = narrow ? 30.0 : 34.0;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: narrow ? 36 : 46,
          child: Column(children: [
            Container(
              width: dot,
              height: dot,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: read ? ink.good : (here ? ink.accent : ink.bg),
                shape: ink.terminal ? BoxShape.rectangle : BoxShape.circle,
                border: Border.all(color: read || here ? Colors.transparent : ink.muted, width: 1.5),
              ),
              child: read ? Icon(Icons.check_rounded, size: 18, color: ink.bg) : Text('$n', style: ink.mono(13.5, weight: FontWeight.w800, color: here ? ink.bg : ink.strong)),
            ),
            if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: read ? ink.good.withValues(alpha: 0.7) : ink.line)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 12),
            child: AppLink(
              to: route,
              child: AcsTap(
                label: l.title,
                onTap: () => context.go(route),
                builder: (h) => AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  transform: Matrix4.translationValues(h ? 3 : 0, 0, 0),
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                  decoration: BoxDecoration(
                    color: h ? ink.hover : ink.panel,
                    border: Border.all(color: h ? ink.accent : ink.line),
                    borderRadius: ink.terminal ? null : BorderRadius.circular(10),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.title, style: ink.mono(15.5, weight: FontWeight.w700, color: ink.strong, height: 1.3)),
                    const SizedBox(height: 3),
                    Text(l.summary, style: ink.mono(13, color: ink.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 7),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (l.curs.isNotEmpty) teorieTag(ink, l.curs, ink.muted),
                      teorieTag(ink, '${l.minutes} min', ink.muted),
                      if (l.vizCount > 0) teorieTag(ink, plural(l.vizCount, 'vizualizare', 'vizualizări'), ink.accent),
                      if (l.practice.isNotEmpty) teorieTag(ink, plural(l.practice.length, 'problemă', 'probleme'), ink.accent),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
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
  bool _full = false; // complet; esențial otherwise
  final Map<String, GlobalKey> _keys = {};
  final GlobalKey _view = GlobalKey(), _head = GlobalKey(), _practiceKey = GlobalKey();
  final ScrollController _scroll = ScrollController();
  int _current = 0; // the section being read
  final Set<String> _seen = {}; // sections reached: they came in, and count as read
  final Set<String> _opened = {}; // in esențial, the sections shown whole
  bool _bar = false; // the phone's bar, once the title is gone

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_spy);
    () async {
      final t = await loadTeorie(widget.code);
      final p = await loadAcsCourse(widget.code);
      final s = await AcsProgress.solvedIds(widget.code);
      final r = await TeorieProgress.read(widget.code);
      final full = await TeorieProgress.full();
      TeorieProgress.setLast(widget.code, widget.lesson);
      if (!mounted) return;
      setState(() {
        _t = t;
        _problems = p;
        _solved = s;
        _read = r.contains(widget.lesson);
        _full = full;
        _loaded = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _spy());
    }();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  TeorieLesson? get _lesson => _t?.byId(widget.lesson);

  GlobalKey _keyOf(TeorieSection s) => _keys.putIfAbsent(s.id, () => GlobalKey());

  /// Where a widget's top is, from the top of the scrolling view.
  double? _top(GlobalKey k) {
    final view = _view.currentContext?.findRenderObject() as RenderBox?;
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || box == null || !box.attached || !view.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: view).dy;
  }

  void _spy() {
    final l = _lesson;
    if (l == null || !mounted) return;
    final view = (_view.currentContext?.findRenderObject() as RenderBox?)?.size.height ?? 800;
    var cur = 0;
    final seen = <String>{};
    for (final (i, s) in l.sections.indexed) {
      final y = _top(_keyOf(s));
      if (y == null) continue;
      if (y < 170) cur = i;
      if (y < view * 0.92) seen.add(s.id);
    }
    final headBox = _head.currentContext?.findRenderObject() as RenderBox?;
    final headTop = _top(_head);
    final bar = headBox != null && headTop != null && headTop + headBox.size.height < 0;
    if (cur != _current || bar != _bar || !_seen.containsAll(seen)) {
      setState(() {
        _current = cur;
        _bar = bar;
        _seen.addAll(seen);
      });
    }
  }

  void _goTo(GlobalKey k) {
    final y = _top(k);
    if (y == null || !_scroll.hasClients) return;
    final phone = MediaQuery.of(context).size.width < 1100;
    final target = (_scroll.offset + y - (phone ? 64 : 16)).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  void _later() => WidgetsBinding.instance.addPostFrameCallback((_) => _spy());

  void _toggleRead() {
    setState(() => _read = !_read);
    TeorieProgress.mark(widget.code, widget.lesson, _read);
  }

  void _setFull(bool v) {
    if (v == _full) return;
    setState(() => _full = v);
    TeorieProgress.setFull(v);
    _later();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.themeNotifier, ThemeManager.acsStyleNotifier]),
      builder: (context, _) {
        final ink = AcsInk.current;
        final width = MediaQuery.of(context).size.width;
        final narrow = width < 600;
        final wide = width >= 1100;
        final t = _t, l = _lesson;
        final ready = _loaded && t != null && l != null;
        final content = KeyedSubtree(
          key: _view,
          child: SingleChildScrollView(
            key: const ValueKey('lesson-scroll'),
            controller: _scroll,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(narrow ? 16 : 32, 18, narrow ? 16 : 32, 72),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Align(alignment: Alignment.centerRight, child: AcsSwitches(ink: ink)),
                    const SizedBox(height: 14),
                    if (!ready) _missing(ink) else ..._page(context, ink, narrow, wide, t, l),
                  ]),
                ),
              ),
            ),
          ),
        );
        return Scaffold(
          backgroundColor: ink.bg,
          body: DefaultTextStyle(
            style: ink.mono(15),
            child: SafeArea(
              child: !ready
                  ? content
                  : wide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          SizedBox(width: 290, child: _rail(context, ink, t, l)),
                          Expanded(child: content),
                        ])
                      : Stack(children: [
                          Positioned.fill(child: content),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              ignoring: !_bar,
                              child: AnimatedSlide(
                                offset: _bar ? Offset.zero : const Offset(0, -1.1),
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                child: _topBar(context, ink, t, l),
                              ),
                            ),
                          ),
                        ]),
            ),
          ),
        );
      },
    );
  }

  Widget _missing(AcsInk ink) {
    if (!_loaded) return Text('se încarcă...', style: ink.mono(14, color: ink.muted));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AcsNav(ink: ink, trail: [...acsTrail(widget.code), ('teorie', teorieRoute(widget.code))]),
      const SizedBox(height: 20),
      Text('Lecția nu există.', style: ink.mono(15, color: ink.bad)),
    ]);
  }

  // ------------------------------------------------------------ the page
  List<Widget> _page(BuildContext context, AcsInk ink, bool narrow, bool wide, TeorieCourse t, TeorieLesson l) {
    final i = t.indexOf(l);
    final prev = i > 0 ? t.lessons[i - 1] : null, next = i + 1 < t.lessons.length ? t.lessons[i + 1] : null;
    final part = t.partOf(l);
    return [
      KeyedSubtree(
        key: _head,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AcsNav(ink: ink, trail: [...acsTrail(widget.code), ('teorie', teorieRoute(widget.code)), ('${i + 1}', teorieRoute(widget.code, l.id))]),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('LECȚIA ${i + 1}${l.curs.isEmpty ? '' : ' · ${l.curs.toUpperCase()}'}',
                style: ink.mono(12.5, weight: FontWeight.w700, color: ink.accent).copyWith(letterSpacing: 1.2)),
            if (part != null && part.test.isNotEmpty) teorieTag(ink, 'pentru ${part.test}', ink.warn),
          ]),
          const SizedBox(height: 2),
          Text(l.title, style: ink.mono(narrow ? 25 : 32, weight: FontWeight.w700, color: ink.strong, height: 1.2)),
          const SizedBox(height: 6),
          Text(l.summary, style: ink.mono(15, color: ink.muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 14, runSpacing: 6, children: [
            _fact(ink, Icons.schedule, '${l.minutes} min'),
            _fact(ink, Icons.segment, plural(l.sections.length, 'secțiune', 'secțiuni')),
            if (l.vizCount > 0) _fact(ink, Icons.play_circle_outline, plural(l.vizCount, 'vizualizare', 'vizualizări')),
            if (l.practice.isNotEmpty) _fact(ink, Icons.edit_note, plural(l.practice.length, 'problemă', 'probleme')),
          ]),
          if (l.goals.isNotEmpty) ...[const SizedBox(height: 16), _goals(ink, l)],
          const SizedBox(height: 16),
          _modeSwitch(ink, narrow),
          if (!wide) ...[const SizedBox(height: 14), _contents(ink, l, i)],
        ]),
      ),
      for (final (k, s) in l.sections.indexed) _section(ink, narrow, i, k, s),
      if (l.practice.isNotEmpty)
        KeyedSubtree(
          key: _practiceKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 34),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(ink.terminal ? '## exersează' : 'Exersează', style: ink.mono(21, weight: FontWeight.w700, color: ink.strong)),
              const SizedBox(height: 4),
              Text('Probleme verificate automat pe care se aplică lecția.', style: ink.mono(13.5, color: ink.muted)),
              const SizedBox(height: 10),
              _practice(context, ink, l.practice),
            ]),
          ),
        ),
      const SizedBox(height: 28),
      Align(alignment: Alignment.centerLeft, child: AcsButton(ink, _read ? 'citită ✓' : 'am citit lecția', _toggleRead, primary: !_read, icon: _read ? null : Icons.check)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final p = prev == null ? null : _navCard(context, ink, 'lecția anterioară', prev, i, back: true);
        final n = next == null
            ? null
            : _navCard(context, ink, 'lecția următoare', next, i + 2, onGo: () {
                if (!_read) TeorieProgress.mark(widget.code, widget.lesson, true);
              });
        if (c.maxWidth < 600) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (p != null) p, if (p != null && n != null) const SizedBox(height: 8), if (n != null) n]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: p ?? const SizedBox.shrink()),
          const SizedBox(width: 12),
          Expanded(child: n ?? const SizedBox.shrink()),
        ]);
      }),
    ];
  }

  Widget _fact(AcsInk ink, IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        if (!ink.terminal) ...[Icon(icon, size: 16, color: ink.muted), const SizedBox(width: 5)],
        Text(ink.terminal ? '[$text]' : text, style: ink.mono(13.5, color: ink.muted, weight: FontWeight.w600)),
      ]);

  Widget _goals(AcsInk ink, TeorieLesson l) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: ink.good.withValues(alpha: ink.dark ? 0.08 : 0.06),
          border: Border.all(color: ink.good.withValues(alpha: 0.5)),
          borderRadius: ink.terminal ? null : BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(ink.terminal ? '# după lecție știi să' : 'DUPĂ LECȚIE ȘTII SĂ', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.good).copyWith(letterSpacing: 1)),
          const SizedBox(height: 4),
          for (final g in l.goals)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: ink.terminal ? Text('[ ]', style: ink.mono(13, color: ink.good)) : Icon(Icons.check_circle_outline, size: 17, color: ink.good),
                ),
                Expanded(child: AcsText(g, ink, size: 14.5)),
              ]),
            ),
        ]),
      );

  Widget _modeSwitch(AcsInk ink, bool narrow) {
    Widget seg(String label, bool on, VoidCallback tap) => AcsTap(
          label: 'mod $label',
          onTap: tap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: on ? ink.accent : (h ? ink.hover : Colors.transparent),
              borderRadius: ink.terminal ? null : BorderRadius.circular(20),
            ),
            child: Text(label, style: ink.mono(13.5, weight: FontWeight.w700, color: on ? ink.bg : ink.muted)),
          ),
        );
    final segs = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(22)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('esențial', !_full, () => _setFull(false)), seg('complet', _full, () => _setFull(true))]),
    );
    final say = Text(
      _full ? 'Toată lecția: explicații, exemple, probleme de examen, întrebări.' : 'Ideile, definițiile, teoremele și vizualizările. Restul, la „arată tot”.',
      style: ink.mono(13, color: ink.muted),
    );
    return narrow
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [segs, const SizedBox(height: 6), say])
        : Row(children: [segs, const SizedBox(width: 12), Expanded(child: say)]);
  }

  /// Under the title, where there is no rail: the sections as a list.
  Widget _contents(AcsInk ink, TeorieLesson l, int i) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(color: ink.panel, border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(ink.terminal ? '# cuprins' : 'CUPRINS', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.muted).copyWith(letterSpacing: 1)),
          const SizedBox(height: 4),
          for (final (k, s) in l.sections.indexed) _outlineRow(ink, '${i + 1}.${k + 1}', s.title, () => _goTo(_keyOf(s))),
          if (l.practice.isNotEmpty) _outlineRow(ink, '→', 'la exerciții (${l.practice.length})', () => _goTo(_practiceKey)),
        ]),
      );

  Widget _outlineRow(AcsInk ink, String n, String title, VoidCallback onTap) => AcsTap(
        label: title,
        onTap: onTap,
        builder: (h) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 40, child: Text(n, style: ink.mono(13.5, weight: FontWeight.w700, color: ink.accent))),
            Expanded(child: Text(title, style: ink.mono(13.5, weight: FontWeight.w600, color: h ? ink.strong : ink.fg))),
          ]),
        ),
      );

  // ------------------------------------------------------------ a section
  Widget _section(AcsInk ink, bool narrow, int i, int k, TeorieSection s) {
    final whole = _full || _opened.contains(s.id);
    final hidden = [for (final b in s.blocks) if (!essentialBlock(b)) b];
    final shown = whole ? s.blocks : [for (final b in s.blocks) if (essentialBlock(b)) b];
    final here = k == _current;
    return Padding(
      key: _keyOf(s),
      padding: const EdgeInsets.only(top: 36),
      child: _Appear(
        shown: _seen.contains(s.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: here ? ink.accent : ink.accent.withValues(alpha: 0.12),
                borderRadius: ink.terminal ? null : BorderRadius.circular(6),
              ),
              child: Text('${i + 1}.${k + 1}', style: ink.mono(narrow ? 14 : 15, weight: FontWeight.w800, color: here ? ink.bg : ink.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(ink.terminal ? '## ${s.title}' : s.title, style: ink.mono(narrow ? 18.5 : 21, weight: FontWeight.w700, color: ink.strong, height: 1.25))),
          ]),
          if (s.key.isNotEmpty) ...[const SizedBox(height: 12), _keyBox(ink, s.key)],
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final b in shown)
                  Padding(
                    key: ObjectKey(b),
                    padding: const EdgeInsets.only(top: 14),
                    child: TeorieBlock(ink, b, code: widget.code, problems: _problems, solved: _solved),
                  ),
              ],
            ),
          ),
          if (!_full && hidden.isNotEmpty) ...[const SizedBox(height: 12), _moreBar(ink, s, hidden, whole)],
        ]),
      ),
    );
  }

  Widget _keyBox(AcsInk ink, List<String> key) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: ink.accent.withValues(alpha: ink.dark ? 0.10 : 0.07),
          borderRadius: ink.terminal ? null : BorderRadius.circular(10),
          border: ink.terminal ? Border(left: BorderSide(color: ink.accent, width: 3)) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            if (!ink.terminal) ...[Icon(Icons.bolt_rounded, size: 17, color: ink.accent), const SizedBox(width: 4)],
            Text(ink.terminal ? '> pe scurt' : 'PE SCURT', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.accent).copyWith(letterSpacing: 1)),
          ]),
          const SizedBox(height: 2),
          for (final k in key)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 18, child: Text('▸', style: ink.mono(15, weight: FontWeight.w800, color: ink.accent, height: 1.6))),
                Expanded(child: AcsText(k, ink, size: 15, color: ink.strong)),
              ]),
            ),
        ]),
      );

  Widget _moreBar(AcsInk ink, TeorieSection s, List<Map<String, dynamic>> hidden, bool open) => AcsTap(
        label: open ? 'doar esențialul' : 'arată tot',
        onTap: () {
          setState(() => open ? _opened.remove(s.id) : _opened.add(s.id));
          _later();
        },
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: h ? ink.hover : Colors.transparent,
            border: Border.all(color: h ? ink.accent : ink.line),
            borderRadius: ink.terminal ? null : BorderRadius.circular(8),
          ),
          child: Row(children: [
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.expand_more_rounded, size: 20, color: ink.accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: open ? 'doar esențialul' : 'arată tot', style: TextStyle(color: ink.accent, fontWeight: FontWeight.w800)),
                  if (!open) TextSpan(text: '  ·  ${countBlocks(hidden)}', style: TextStyle(color: ink.muted)),
                ]),
                style: ink.mono(13.5),
              ),
            ),
          ]),
        ),
      );

  // ------------------------------------------------------------ the rail (wide)
  Widget _rail(BuildContext context, AcsInk ink, TeorieCourse t, TeorieLesson l) {
    final i = t.indexOf(l);
    final f = l.sections.isEmpty ? 0.0 : l.sections.where((s) => _seen.contains(s.id)).length / l.sections.length;
    return Container(
      decoration: BoxDecoration(color: ink.panel, border: Border(right: BorderSide(color: ink.line))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppLink(
            to: teorieRoute(widget.code),
            child: AcsTap(
              label: 'toate lecțiile',
              onTap: () => context.go(teorieRoute(widget.code)),
              builder: (h) => Text('← toate lecțiile', style: ink.mono(13, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)),
            ),
          ),
          const SizedBox(height: 14),
          Text('LECȚIA ${i + 1} DIN ${t.lessons.length}', style: ink.mono(11.5, weight: FontWeight.w800, color: ink.muted).copyWith(letterSpacing: 1.1)),
          const SizedBox(height: 3),
          Text(l.title, style: ink.mono(15, weight: FontWeight.w800, color: ink.strong, height: 1.3)),
          const SizedBox(height: 10),
          GrowBar(value: f, color: ink.good, track: ink.line.withValues(alpha: 0.6), height: 5),
          const SizedBox(height: 4),
          Text('${(f * 100).round()}% parcurs', style: ink.mono(12, color: ink.muted)),
          const SizedBox(height: 16),
          for (final (k, s) in l.sections.indexed) _railRow(ink, i, k, s),
          if (l.practice.isNotEmpty)
            AcsTap(
              label: 'la exerciții',
              onTap: () => _goTo(_practiceKey),
              builder: (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                child: Row(children: [
                  SizedBox(width: 34, child: Icon(Icons.edit_note, size: 18, color: ink.accent)),
                  Text('la exerciții (${l.practice.length})', style: ink.mono(13.5, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)),
                ]),
              ),
            ),
          const SizedBox(height: 18),
          Text('CUM CITEȘTI', style: ink.mono(11.5, weight: FontWeight.w800, color: ink.muted).copyWith(letterSpacing: 1.1)),
          const SizedBox(height: 6),
          _railMode(ink),
          const SizedBox(height: 18),
          if (i > 0) _railLesson(context, ink, '← $i. ${t.lessons[i - 1].title}', t.lessons[i - 1]),
          if (i + 1 < t.lessons.length) _railLesson(context, ink, '${i + 2}. ${t.lessons[i + 1].title} →', t.lessons[i + 1]),
        ]),
      ),
    );
  }

  Widget _railRow(AcsInk ink, int i, int k, TeorieSection s) {
    final here = k == _current;
    final seen = _seen.contains(s.id);
    return AcsTap(
      label: s.title,
      onTap: () => _goTo(_keyOf(s)),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: here ? ink.accent.withValues(alpha: 0.13) : (h ? ink.hover : Colors.transparent),
          border: Border(left: BorderSide(color: here ? ink.accent : Colors.transparent, width: 3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 34,
            child: seen && !here
                ? Padding(padding: const EdgeInsets.only(top: 1), child: Icon(Icons.check_rounded, size: 16, color: ink.good))
                : Text('${i + 1}.${k + 1}', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.accent)),
          ),
          Expanded(
            child: Text(s.title, style: ink.mono(13.5, weight: here ? FontWeight.w800 : FontWeight.w600, color: here || h ? ink.strong : ink.fg, height: 1.3)),
          ),
        ]),
      ),
    );
  }

  Widget _railMode(AcsInk ink) {
    Widget opt(String title, String say, bool on, VoidCallback tap) => AcsTap(
          label: 'mod $title',
          onTap: tap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: on ? ink.accent.withValues(alpha: 0.12) : (h ? ink.hover : Colors.transparent),
              border: Border.all(color: on ? ink.accent : ink.line),
              borderRadius: ink.terminal ? null : BorderRadius.circular(8),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: on ? ink.accent : ink.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: ink.mono(13.5, weight: FontWeight.w800, color: ink.strong)),
                  Text(say, style: ink.mono(12, color: ink.muted)),
                ]),
              ),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      opt('Esențial', 'ideile și ce trebuie știut', !_full, () => _setFull(false)),
      opt('Complet', 'cu explicații, exemple, examene', _full, () => _setFull(true)),
    ]);
  }

  Widget _railLesson(BuildContext context, AcsInk ink, String label, TeorieLesson l) => AppLink(
        to: teorieRoute(widget.code, l.id),
        child: AcsTap(
          label: l.title,
          onTap: () => context.go(teorieRoute(widget.code, l.id)),
          builder: (h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(label, style: ink.mono(12.5, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)),
          ),
        ),
      );

  // ------------------------------------------------------------ the bar (phone)
  Widget _topBar(BuildContext context, AcsInk ink, TeorieCourse t, TeorieLesson l) {
    final i = t.indexOf(l);
    final s = l.sections.isEmpty ? null : l.sections[_current.clamp(0, l.sections.length - 1)];
    final f = l.sections.isEmpty ? 0.0 : (_current + 1) / l.sections.length;
    return Material(
      color: ink.bg,
      elevation: 3,
      shadowColor: Colors.black26,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LECȚIA ${i + 1} · ${l.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ink.mono(11, weight: FontWeight.w700, color: ink.muted)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(s == null ? '' : '${i + 1}.${_current + 1}  ${s.title}',
                      key: ValueKey(_current), maxLines: 1, overflow: TextOverflow.ellipsis, style: ink.mono(14, weight: FontWeight.w800, color: ink.strong)),
                ),
              ]),
            ),
            AcsButton(ink, 'cuprins', () => _sheet(context, ink, t, l), icon: Icons.toc_rounded),
          ]),
        ),
        GrowBar(value: f, color: ink.accent, track: ink.line.withValues(alpha: 0.4), height: 3),
      ]),
    );
  }

  void _sheet(BuildContext context, AcsInk ink, TeorieCourse t, TeorieLesson l) {
    final i = t.indexOf(l);
    void go(BuildContext sheet, GlobalKey k) {
      Navigator.of(sheet).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(k));
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ink.bg,
      isScrollControlled: true,
      shape: ink.terminal ? const RoundedRectangleBorder() : const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.8),
          child: StatefulBuilder(
            builder: (sheet, set) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('LECȚIA ${i + 1}', style: ink.mono(12, weight: FontWeight.w800, color: ink.muted).copyWith(letterSpacing: 1)),
                Text(l.title, style: ink.mono(16, weight: FontWeight.w800, color: ink.strong)),
                const SizedBox(height: 10),
                for (final (k, s) in l.sections.indexed) _outlineRow(ink, _seen.contains(s.id) && k != _current ? '✓' : '${i + 1}.${k + 1}', s.title, () => go(sheet, _keyOf(s))),
                if (l.practice.isNotEmpty) _outlineRow(ink, '→', 'la exerciții (${l.practice.length})', () => go(sheet, _practiceKey)),
                const SizedBox(height: 14),
                _modeSwitch(ink, true),
              ]),
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ------------------------------------------------------------ the end
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
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
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

/// A section coming in the first time it is reached.
class _Appear extends StatelessWidget {
  final bool shown;
  final Widget child;
  const _Appear({required this.shown, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: shown ? 1 : 0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, t, c) => Opacity(opacity: 0.15 + 0.85 * t, child: Transform.translate(offset: Offset(0, 22 * (1 - t)), child: c)),
        child: child,
      );
}
