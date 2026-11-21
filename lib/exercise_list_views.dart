part of 'exercise_list_screen.dart';

// =============================================================================
// THE LIST'S SUBCATEGORIES AND ITS FIVE VIEWS (clean look)
//   Above the problems: the year, the kind of paper, the classes of a contest
//   (each row only where the grade's problems differ in it), the difficulty,
//   how far the student got; then how they are shown and in what order.
//   The views: Listă (the table, chapter by chapter), Carduri (a grid),
//   Compact (a line each), Tablă (to solve / tried / solved, side by side),
//   Pe ani (a timeline of the years; by level where no problem has a year).
// =============================================================================

extension _Views on _ExerciseListScreenState {
  static const Color _cGreen = _ExerciseListScreenState._cGreen;
  static const Color _cAmber = _ExerciseListScreenState._cAmber;
  static const Color _cRose = _ExerciseListScreenState._cRose;
  static const Color _cBlue = _ExerciseListScreenState._cBlue;
  static const Map<String, String> _sortNames = {
    'implicit': 'Ordinea capitolelor',
    'nou': 'Cele mai noi',
    'vechi': 'Cele mai vechi',
    'usor': 'Ușoare întâi',
    'greu': 'Grele întâi',
    'titlu': 'Titlu (A–Z)',
  };

  String _statusOf(Map<String, dynamic> e) {
    if (_isSolved(e)) return 'rezolvate';
    if (_isTried(e)) return 'incercate';
    return 'nerezolvate';
  }

  /// Whether the problem is let through by the filters, [skip] left out (to
  /// count what choosing it would give).
  bool _passes(Map<String, dynamic> e, {String skip = ''}) {
    if (skip != 'diff' && _cDiff != 'toate' && _diffKey('${e['difficulty']}') != _cDiff) return false;
    if (skip != 'status' && _cStatus != 'toate' && _statusOf(e) != _cStatus) return false;
    if (skip != 'year' && _fYear != null && e['year'] != _fYear) return false;
    if (skip != 'type' && _fType != null && e['type'] != _fType) return false;
    if (skip != 'classes' && _fClasses != null && e['classes'] != _fClasses) return false;
    return true;
  }

  int get _activeFilters => [_cDiff != 'toate', _cStatus != 'toate', _fYear != null, _fType != null, _fClasses != null].where((b) => b).length;

  void _clearFilters() {
    _set(() {
      _cDiff = 'toate';
      _cStatus = 'toate';
      _fYear = null;
      _fType = null;
      _fClasses = null;
      _cLimit = 25;
    });
  }

  void _resetAll() {
    _cSearch.clear();
    searchQuery = '';
    _clearFilters();
    _set(() => selectedCategory = 'Toate');
    _updateCategoriesAndFilter();
  }

  /// Chapter by chapter as they come, unless a search (best first) or an order was asked for.
  bool get _grouped => _sort == 'implicit' && _search.isEmpty;

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> rows) {
    if (_grouped) return rows;
    final at = {for (final (i, e) in rows.indexed) e: i};
    int keep(Map<String, dynamic> a, Map<String, dynamic> b) => at[a]!.compareTo(at[b]!);
    int year(Map<String, dynamic> e, int none) => e['year'] as int? ?? none;
    int diff(Map<String, dynamic> e) => ExFacets.diffRank('${e['difficulty']}');
    final int Function(Map<String, dynamic>, Map<String, dynamic>) by = switch (_sort) {
      'nou' => (a, b) => year(b, -1).compareTo(year(a, -1)),
      'vechi' => (a, b) => year(a, 99999).compareTo(year(b, 99999)),
      'usor' => (a, b) => diff(a).compareTo(diff(b)),
      'greu' => (a, b) => const [2, 1, 0, 3][diff(a)].compareTo(const [2, 1, 0, 3][diff(b)]),
      'titlu' => (a, b) => ExFacets.fold('${a['title']}').compareTo(ExFacets.fold('${b['title']}')),
      _ => (a, b) => (_scores[b['id']] ?? 0).compareTo(_scores[a['id']] ?? 0),
    };
    return List.of(rows)..sort((a, b) {
      final c = by(a, b);
      return c != 0 ? c : keep(a, b);
    });
  }

  /// The text with the words searched marked.
  List<InlineSpan> _hlSpans(String text) {
    final marks = _search.marks(text);
    if (marks.isEmpty) return [TextSpan(text: text)];
    final hl = TextStyle(backgroundColor: _cAmber.withOpacity(AppColors.isDark ? 0.32 : 0.26), fontWeight: FontWeight.w700, color: Pb.text);
    final out = <InlineSpan>[];
    var i = 0;
    for (final (a, b) in marks) {
      if (a > i) out.add(TextSpan(text: text.substring(i, a)));
      out.add(TextSpan(text: text.substring(a, b), style: hl));
      i = b;
    }
    if (i < text.length) out.add(TextSpan(text: text.substring(i)));
    return out;
  }

  // ---------------------------------------------------------------- the bar on top
  Widget _fChip(String label, int? count, bool sel, VoidCallback onTap, {Color? color, IconData? icon}) {
    final accent = color ?? Pb.link;
    final empty = count == 0 && !sel;
    return _LHover(
      onTap: onTap,
      builder:
          (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? accent.withOpacity(0.12) : (h ? Pb.hoverBg : Colors.transparent),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: sel ? accent.withOpacity(0.7) : Pb.border, width: sel ? 1.4 : 1),
            ),
            child: Opacity(
              opacity: empty ? 0.45 : 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (color != null && icon == null) ...[
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  if (icon != null) ...[Icon(icon, size: 14, color: sel ? accent : (color ?? Pb.muted)), const SizedBox(width: 5)],
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : Pb.text)),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text('$count', style: TextStyle(fontSize: 12, color: sel ? accent : Pb.muted, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _cFacetBar(bool isMobile) {
    final base = displayedExercises;
    Map<K, int> count<K>(K? Function(Map<String, dynamic>) key, String skip) {
      final m = <K, int>{};
      for (final e in base) {
        final k = key(e);
        if (k != null && _passes(e, skip: skip)) m[k] = (m[k] ?? 0) + 1;
      }
      return m;
    }

    // a row is shown only where the grade's problems differ in it
    final inGrade = allExercises.where((e) => e['grade'] == selectedGrade);
    final allYears = inGrade.map((e) => e['year'] as int?).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
    final allTypes = inGrade.map((e) => '${e['type']}').toSet().toList()..sort((a, b) => ExFacets.typeRank(a).compareTo(ExFacets.typeRank(b)));
    final allClasses = inGrade.map((e) => e['classes'] as String?).whereType<String>().toSet().toList()..sort();
    final years = count<int>((e) => e['year'] as int?, 'year');
    final types = count<String>((e) => '${e['type']}', 'type');
    final classes = count<String>((e) => e['classes'] as String?, 'classes');
    final diffs = count<String>((e) => _diffKey('${e['difficulty']}'), 'diff');
    final states = count<String>(_statusOf, 'status');
    int sum(Map<Object, int> m) => m.values.fold(0, (a, b) => a + b);

    void pick(VoidCallback f) => _set(() {
      f();
      _cLimit = 25;
    });

    Widget line(String label, IconData icon, List<Widget> chips) {
      final head = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Pb.muted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.muted)),
        ],
      );
      final spaced = [for (final c in chips) Padding(padding: const EdgeInsets.only(right: 6, bottom: 6), child: c)];
      if (isMobile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [head, const SizedBox(height: 6), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: spaced))],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SizedBox(width: 118, child: Padding(padding: const EdgeInsets.only(top: 6), child: head)), Expanded(child: Wrap(children: spaced))],
        ),
      );
    }

    final typeIcon = {
      'Model': Icons.description_outlined,
      'Simulare': Icons.science_outlined,
      'Sesiunea specială': Icons.star_outline,
      'Iunie–iulie': Icons.wb_sunny_outlined,
      'Rezervă': Icons.inventory_2_outlined,
      'August': Icons.beach_access_outlined,
      'Test de antrenament': Icons.fitness_center,
      'Antrenament': Icons.fitness_center,
      'Olimpiadă': Icons.emoji_events_outlined,
      'Problemă clasică': Icons.menu_book_outlined,
      'Exercițiu': Icons.edit_note,
    };

    final lines = <Widget>[
      if (allYears.length > 1)
        line('An', Icons.event_outlined, [
          _fChip('Toți anii', null, _fYear == null, () => pick(() => _fYear = null)),
          for (final y in allYears) _fChip('$y', years[y] ?? 0, _fYear == y, () => pick(() => _fYear = _fYear == y ? null : y), color: _cBlue),
        ]),
      if (allTypes.length > 1)
        line('Tip', Icons.category_outlined, [
          _fChip('Toate', null, _fType == null, () => pick(() => _fType = null)),
          for (final t in allTypes)
            _fChip(
              t,
              types[t] ?? 0,
              _fType == t,
              () => pick(() => _fType = _fType == t ? null : t),
              color: Pb.primary,
              icon: typeIcon[t] ?? Icons.label_outline,
            ),
        ]),
      if (allClasses.length > 1)
        line('Clase', Icons.groups_outlined, [
          _fChip('Toate', null, _fClasses == null, () => pick(() => _fClasses = null)),
          for (final c in allClasses)
            _fChip(c, classes[c] ?? 0, _fClasses == c, () => pick(() => _fClasses = _fClasses == c ? null : c), color: const Color(0xFF8B5CF6)),
        ]),
      line('Dificultate', Icons.signal_cellular_alt, [
        _fChip('Oricare', sum(diffs), _cDiff == 'toate', () => pick(() => _cDiff = 'toate')),
        _fChip('Ușoară', diffs['usoara'] ?? 0, _cDiff == 'usoara', () => pick(() => _cDiff = _cDiff == 'usoara' ? 'toate' : 'usoara'), color: _cGreen),
        _fChip('Medie', diffs['medie'] ?? 0, _cDiff == 'medie', () => pick(() => _cDiff = _cDiff == 'medie' ? 'toate' : 'medie'), color: _cAmber),
        _fChip('Grea', diffs['grea'] ?? 0, _cDiff == 'grea', () => pick(() => _cDiff = _cDiff == 'grea' ? 'toate' : 'grea'), color: _cRose),
      ]),
      line('Progres', Icons.flag_outlined, [
        _fChip('Toate', sum(states), _cStatus == 'toate', () => pick(() => _cStatus = 'toate')),
        _fChip(
          'De rezolvat',
          states['nerezolvate'] ?? 0,
          _cStatus == 'nerezolvate',
          () => pick(() => _cStatus = _cStatus == 'nerezolvate' ? 'toate' : 'nerezolvate'),
          icon: Icons.radio_button_unchecked,
          color: Pb.muted,
        ),
        _fChip(
          'Încercate',
          states['incercate'] ?? 0,
          _cStatus == 'incercate',
          () => pick(() => _cStatus = _cStatus == 'incercate' ? 'toate' : 'incercate'),
          icon: Icons.adjust,
          color: _cAmber,
        ),
        _fChip(
          'Rezolvate',
          states['rezolvate'] ?? 0,
          _cStatus == 'rezolvate',
          () => pick(() => _cStatus = _cStatus == 'rezolvate' ? 'toate' : 'rezolvate'),
          icon: Icons.check_circle,
          color: _cGreen,
        ),
      ]),
    ];

    final open = _fOpen ?? !isMobile;
    final hasYears = allYears.isNotEmpty;
    final views = [
      (ExView.lista, Icons.view_list_rounded, 'Listă'),
      (ExView.carduri, Icons.grid_view_rounded, 'Carduri'),
      (ExView.compact, Icons.density_small, 'Compact'),
      (ExView.tabla, Icons.view_kanban_outlined, 'Tablă'),
      (ExView.ani, Icons.timeline, hasYears ? 'Pe ani' : 'Pe niveluri'),
    ];
    final switcher = PbLineTabs(children: [
      for (final (v, icon, name) in views)
        PbLineTab(
          label: name,
          icon: icon,
          showLabel: !isMobile || _view == v,
          selected: _view == v,
          color: _subjectColor,
          onTap: () {
            _set(() => _view = v);
            SharedPreferences.getInstance().then((p) => p.setString(_ExerciseListScreenState._viewKey, v.name));
          },
        ),
    ]);

    final sortLabel = _sort == 'implicit' && !_search.isEmpty ? 'Relevanță' : _sortNames[_sort]!;
    final sort = PopupMenuButton<String>(
      tooltip: 'Ordonează',
      initialValue: _sort,
      color: Pb.surface,
      onSelected: (v) => _set(() => _sort = v),
      itemBuilder:
          (_) => [
            for (final e in _sortNames.entries)
              if (hasYears || (e.key != 'nou' && e.key != 'vechi'))
                PopupMenuItem(
                  value: e.key,
                  child: Text(
                    e.key == 'implicit' && !_search.isEmpty ? 'Relevanță' : e.value,
                    style: TextStyle(fontSize: 14, color: Pb.text, fontWeight: _sort == e.key ? FontWeight.w700 : FontWeight.w400),
                  ),
                ),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 16, color: Pb.muted),
            const SizedBox(width: 6),
            Text(sortLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
            Icon(Icons.arrow_drop_down, size: 18, color: Pb.muted),
          ],
        ),
      ),
    );

    final clear =
        _activeFilters == 0
            ? null
            : _LHover(
              onTap: _clearFilters,
              builder:
                  (h) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_off_outlined, size: 15, color: h ? _cRose : Pb.muted),
                      const SizedBox(width: 4),
                      Text(
                        'Șterge filtrele ($_activeFilters)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: h ? _cRose : Pb.muted,
                          decoration: h ? TextDecoration.underline : null,
                        ),
                      ),
                    ],
                  ),
            );

    return GlassBox(
      radius: 14,
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 18, 14, isMobile ? 14 : 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LHover(
            onTap: isMobile ? () => _set(() => _fOpen = !open) : null,
            builder: (h) => Row(
              children: [
                Icon(Icons.tune, size: 18, color: _subjectColor),
                const SizedBox(width: 8),
                Text('Subcategorii', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text)),
                if (!open && _activeFilters > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: _subjectColor, borderRadius: BorderRadius.circular(99)),
                    child: Text('$_activeFilters', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
                const Spacer(),
                if (clear != null && open) clear,
                if (isMobile) ...[
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 22, color: Pb.muted),
                  ),
                ],
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            // folded, the first row (the years, where there are) stays in sight
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const SizedBox(height: 12), ...(open ? lines : lines.take(1))],
            ),
          ),
          Container(height: 1, color: Pb.border, margin: const EdgeInsets.only(top: 4, bottom: 12)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [SingleChildScrollView(scrollDirection: Axis.horizontal, child: switcher), sort],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- the results
  Widget _cResults(List<Map<String, dynamic>> rows, bool isMobile) {
    final limit = _cLimit;
    final shown = rows.length < limit ? rows.length : limit;
    final title =
        !_search.isEmpty
            ? 'Rezultate pentru „${_search.raw.trim()}”'
            : (selectedCategory == 'Toate' ? 'Toate problemele' : AppStyle.sentence(selectedCategory));

    final head = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ),
              const SizedBox(width: 8),
              Text('${rows.length} probleme', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
          if (!_search.isEmpty && selectedCategory != 'Toate' && _otherChapters > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: PbLink(
                text: '+ încă $_otherChapters în celelalte capitole: caută peste tot',
                fontSize: 13.5,
                onTap: () {
                  _set(() => selectedCategory = 'Toate');
                  _updateCategoriesAndFilter();
                },
              ),
            ),
          ],
        ],
      ),
    );

    final Widget content;
    if (rows.isEmpty) {
      content = _empty();
    } else {
      content = switch (_view) {
        ExView.lista => _vList(rows, shown, isMobile),
        ExView.carduri => _vCards(rows, shown, isMobile),
        ExView.compact => _vCompact(rows, shown, isMobile),
        ExView.tabla => _vBoard(rows, isMobile),
        ExView.ani => _vYears(rows, shown, isMobile),
      };
    }

    final board = _view == ExView.tabla;
    final more = board ? ['nerezolvate', 'incercate', 'rezolvate'].any((s) => rows.where((e) => _statusOf(e) == s).length > limit) : rows.length > shown;
    final foot =
        rows.isEmpty
            ? const SizedBox.shrink()
            : Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(board ? 'Cel mult $limit pe coloană' : 'Afișate $shown din ${rows.length}', style: TextStyle(fontSize: 13, color: Pb.muted)),
                  ),
                  if (more) PbButton(text: 'Arată mai multe', variant: PbVariant.outlinePrimary, size: PbSize.sm, onPressed: () => _set(() => _cLimit += 25)),
                ],
              ),
            );

    return GlassBox(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
            layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
            child: KeyedSubtree(key: ValueKey(_view), child: content),
          ),
          foot,
        ],
      ),
    );
  }

  Widget _empty() {
    final others = _otherGrades.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 30, color: Pb.muted),
          const SizedBox(height: 8),
          Text('Nicio problemă nu se potrivește.', style: TextStyle(fontSize: 14, color: Pb.muted)),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Dar se găsesc în:', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final o in others.take(6))
                  _fChip(
                    isSchoolGrade(o.key) ? 'Clasa ${_gradeLabel(o.key)}' : o.key,
                    o.value,
                    false,
                    () => _selectGrade(o.key),
                    icon: Icons.arrow_forward,
                    color: _subjectColor,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          PbButton(text: 'Resetează căutarea și filtrele', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _resetAll),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- shared pieces
  Widget _statusIcon(Map<String, dynamic> e, double size) {
    final review = _isSolved(e) ? null : _review(e);
    if (review != null) {
      return Icon(review.rejected ? Icons.cancel : Icons.hourglass_top_rounded, size: size, color: review.rejected ? Pb.danger : const Color(0xFFB45309));
    }
    return switch (_statusOf(e)) {
      'rezolvate' => Icon(Icons.check_circle, size: size, color: _cGreen),
      'incercate' => Icon(Icons.adjust, size: size, color: _cAmber),
      _ => Icon(Icons.radio_button_unchecked, size: size, color: Pb.inputBorder),
    };
  }

  Widget _diffPill(String diff, {bool small = false}) {
    if (diff.isEmpty) return Text('–', style: TextStyle(fontSize: 13, color: Pb.muted));
    final dc = _diffColor(diff);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(color: dc.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(AppStyle.sentence(diff), style: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w700, color: dc)),
    );
  }

  /// "Model 2026", "Olimpiadă 2024": what kind of paper, when it says.
  String _paperTag(Map<String, dynamic> e) {
    final t = '${e['type']}';
    final y = e['year'];
    final parts = [if (t != 'Exercițiu') t, if (y != null) '$y'];
    return parts.join(' ');
  }

  Widget _tag(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withOpacity(0.28))),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
  );

  Widget _open(Map<String, dynamic> e, Widget Function(bool h) builder) => AppLink(
    to: '/exercitiu/${e['id']}?materie=${Uri.encodeComponent(widget.subject)}&clasa=${Uri.encodeComponent(selectedGrade)}',
    child: _LHover(onTap: () => _openExercise(e), builder: builder),
  );

  TextStyle get _mono => const TextStyle(fontFamily: 'Iosevka', fontFamilyFallback: ['monospace']);

  String _statementOf(Map<String, dynamic> e) => '${(e['about'] as Map?)?['s'] ?? ''}';

  // ---------------------------------------------------------------- 1. listă
  Widget _vList(List<Map<String, dynamic>> rows, int shown, bool isMobile) {
    final headStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Container(
            color: Pb.hoverBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder:
                  (context, b) => Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(child: Text('Problema', style: headStyle)),
                      if (b.maxWidth >= _ExerciseListScreenState._cExampleMin && _hasExamples)
                        SizedBox(width: _ExerciseListScreenState._cExampleWidth + 20, child: Text('Exemplu', style: headStyle)),
                      SizedBox(width: 96, child: Text('Dificultate', style: headStyle)),
                    ],
                  ),
            ),
          ),
        for (var i = 0; i < shown; i++) ...[
          if (_grouped && (i == 0 || rows[i]['category'] != rows[i - 1]['category'])) _cChapterHead('${rows[i]['category'] ?? ''}', isMobile, first: i == 0),
          _cRow(rows[i], isMobile, index: i),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------- 2. carduri
  Widget _vCards(List<Map<String, dynamic>> rows, int shown, bool isMobile) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: LayoutBuilder(
        builder: (context, b) {
          const gap = 12.0;
          final cols = b.maxWidth < 460 ? 1 : (b.maxWidth / 250).floor().clamp(2, 4);
          final w = (b.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (var i = 0; i < shown; i++) SizedBox(width: w, height: cols == 1 ? null : 236, child: _card(rows[i], cols == 1))],
          );
        },
      ),
    );
  }

  Widget _card(Map<String, dynamic> e, bool loose) {
    final cat = '${e['category'] ?? ''}';
    final cc = _catColor(cat);
    final statement = _statementOf(e);
    final tag = _paperTag(e);
    return _open(
      e,
      (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h ? -3 : 0, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: h ? cc.withOpacity(AppColors.isDark ? 0.10 : 0.05) : Pb.surface.withOpacity(AppColors.isDark ? 0.55 : 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: h ? cc.withOpacity(0.6) : Pb.border, width: 1.2),
          boxShadow: h ? [BoxShadow(color: cc.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProblemThumb(chapter: cat, color: cc, width: 46, height: 46, dark: AppColors.isDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${e['id']}', style: _mono.copyWith(fontSize: 12.5, color: Pb.muted)),
                      const SizedBox(height: 2),
                      Text(
                        AppStyle.sentence(cat.replaceFirst(RegExp(r'^\d+\.\s*'), '')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: cc, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _statusIcon(e, 20),
              ],
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: _hlSpans('${e['title']}')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: h ? cc : Pb.text, height: 1.3),
            ),
            const SizedBox(height: 6),
            if (statement.isNotEmpty)
              loose
                  ? Text.rich(
                    TextSpan(children: _hlSpans(statement)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4),
                  )
                  : Expanded(
                    child: Text.rich(
                      TextSpan(children: _hlSpans(statement)),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4),
                    ),
                  )
            else if (!loose)
              const Spacer(),
            const SizedBox(height: 10),
            Row(
              children: [_diffPill('${e['difficulty'] ?? ''}', small: true), const SizedBox(width: 8), if (tag.isNotEmpty) Flexible(child: _tag(tag, _cBlue))],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 3. compact
  Widget _vCompact(List<Map<String, dynamic>> rows, int shown, bool isMobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < shown; i++) _compactRow(rows[i], i, isMobile)]);
  }

  Widget _compactRow(Map<String, dynamic> e, int i, bool isMobile) {
    final cc = _catColor('${e['category'] ?? ''}');
    final diff = '${e['difficulty'] ?? ''}';
    final dc = _diffColor(diff);
    final tag = _paperTag(e);
    return _open(
      e,
      (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 9),
        decoration: BoxDecoration(
          color: h ? cc.withOpacity(0.08) : (i.isOdd ? Pb.tableStripe.withOpacity(0.6) : Colors.transparent),
          border: Border(top: BorderSide(color: Pb.border.withOpacity(0.7)), left: BorderSide(color: h ? cc : Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            _statusIcon(e, 17),
            const SizedBox(width: 10),
            SizedBox(width: isMobile ? 40 : 52, child: Text('${e['id']}', style: _mono.copyWith(fontSize: 13, color: Pb.muted))),
            Expanded(
              child: Text.rich(
                TextSpan(children: _hlSpans('${e['title']}')),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: h ? cc : Pb.text),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 210,
                child: Text(
                  AppStyle.sentence('${e['category'] ?? ''}'.replaceFirst(RegExp(r'^\d+\.\s*'), '')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Pb.muted),
                ),
              ),
              SizedBox(width: 150, child: tag.isEmpty ? const SizedBox.shrink() : Align(alignment: Alignment.centerLeft, child: _tag(tag, _cBlue))),
            ],
            const SizedBox(width: 8),
            Tooltip(message: AppStyle.sentence(diff), child: Container(width: 9, height: 9, decoration: BoxDecoration(color: dc, shape: BoxShape.circle))),
            if (!isMobile) ...[
              const SizedBox(width: 6),
              SizedBox(width: 50, child: Text(AppStyle.sentence(diff), style: TextStyle(fontSize: 12.5, color: dc, fontWeight: FontWeight.w600))),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 4. tablă
  Widget _vBoard(List<Map<String, dynamic>> rows, bool isMobile) {
    final cols = [
      ('nerezolvate', 'De rezolvat', Icons.radio_button_unchecked, Pb.muted),
      ('incercate', 'Încercate', Icons.adjust, _cAmber),
      ('rezolvate', 'Rezolvate', Icons.check_circle, _cGreen),
    ];
    Widget column((String, String, IconData, Color) c) {
      final items = rows.where((e) => _statusOf(e) == c.$1).toList();
      final take = items.length < _cLimit ? items.length : _cLimit;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.$4.withOpacity(AppColors.isDark ? 0.07 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.$4.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Row(
                children: [
                  Icon(c.$3, size: 16, color: c.$4),
                  const SizedBox(width: 7),
                  Expanded(child: Text(c.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: c.$4.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                    child: Text('${items.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.$4)),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text('Nimic aici', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Pb.muted)),
              ),
            for (var i = 0; i < take; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: _boardCard(items[i])),
            if (items.length > take) Text('+ încă ${items.length - take}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final c in cols) Padding(padding: const EdgeInsets.only(bottom: 12), child: column(c))],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, c) in cols.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: column(c))],
                ],
              ),
    );
  }

  Widget _boardCard(Map<String, dynamic> e) {
    final cc = _catColor('${e['category'] ?? ''}');
    final diff = '${e['difficulty'] ?? ''}';
    final tag = _paperTag(e);
    return _open(
      e,
      (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: Matrix4.translationValues(h ? 2 : 0, 0, 0),
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
        decoration: BoxDecoration(
          color: Pb.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border(
            left: BorderSide(color: cc, width: 3.5),
            top: BorderSide(color: h ? cc.withOpacity(0.5) : Pb.border),
            right: BorderSide(color: h ? cc.withOpacity(0.5) : Pb.border),
            bottom: BorderSide(color: h ? cc.withOpacity(0.5) : Pb.border),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(h ? 0.10 : 0.04), blurRadius: h ? 10 : 3, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(children: _hlSpans('${e['title']}')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text, height: 1.3),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text('#${e['id']}', style: _mono.copyWith(fontSize: 12, color: Pb.muted)),
                const SizedBox(width: 8),
                Container(width: 7, height: 7, decoration: BoxDecoration(color: _diffColor(diff), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(AppStyle.sentence(diff), style: TextStyle(fontSize: 12, color: Pb.muted)),
                const SizedBox(width: 8),
                if (tag.isNotEmpty) Flexible(child: Text(tag, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: _cBlue))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 5. pe ani
  Widget _vYears(List<Map<String, dynamic>> rows, int shown, bool isMobile) {
    final byYear = rows.any((e) => e['year'] != null);
    final groups = <Object, List<Map<String, dynamic>>>{};
    // the newest year first (the easiest level first), so a page shows whole years
    final at = {for (final (i, e) in rows.indexed) e: i};
    int keyOf(Map<String, dynamic> e) => byYear ? -(e['year'] as int? ?? -99999) : ExFacets.diffRank('${e['difficulty']}');
    final ordered = List.of(rows)
      ..sort((a, b) {
        final c = keyOf(a).compareTo(keyOf(b));
        return c != 0 ? c : at[a]!.compareTo(at[b]!);
      });
    for (final e in ordered.take(shown)) {
      final Object k = byYear ? (e['year'] as int? ?? 0) : ExFacets.diffRank('${e['difficulty']}');
      (groups[k] ??= []).add(e);
    }
    final keys =
        groups.keys.toList()..sort((a, b) {
          final x = a as int, y = b as int;
          if (byYear) {
            if (x == 0) return 1;
            if (y == 0) return -1;
            return y.compareTo(x);
          }
          return x.compareTo(y);
        });
    const levels = ['Ușoare', 'Medii', 'Grele', 'Fără nivel'];
    const levelColors = [_cGreen, _cAmber, _cRose];

    Widget group(Object k, bool last) {
      final items = groups[k]!;
      final key = k as int;
      final c = byYear ? (key == 0 ? Pb.muted : _subjectColor) : (key < 3 ? levelColors[key] : Pb.muted);
      final label = byYear ? (key == 0 ? 'Fără an' : '$key') : levels[key];
      final total = rows.where((e) => byYear ? (e['year'] as int? ?? 0) == key : ExFacets.diffRank('${e['difficulty']}') == key).toList();
      final done = total.where(_isSolved).length;

      // the kinds of paper of the year, each with its problems
      final kinds = <String, List<Map<String, dynamic>>>{};
      for (final e in items) {
        (kinds[byYear ? '${e['type']}' : AppStyle.sentence('${e['category']}'.replaceFirst(RegExp(r'^\d+\.\s*'), ''))] ??= []).add(e);
      }
      final kindKeys = kinds.keys.toList();
      if (byYear) kindKeys.sort((a, b) => ExFacets.typeRank(a).compareTo(ExFacets.typeRank(b)));

      final dot = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          border: Border.all(color: Pb.surface, width: 3),
          boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 6)],
        ),
      );

      // the line of the timeline runs down the group's left edge, the year's dot on it
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(left: isMobile ? 10 : 14),
            padding: EdgeInsets.only(left: isMobile ? 16 : 22, bottom: 22),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: last ? Colors.transparent : Pb.border, width: 2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(label, style: TextStyle(fontSize: byYear ? 26 : 20, fontWeight: FontWeight.w800, color: Pb.text, height: 1, letterSpacing: -0.5)),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('${total.length} probleme · $done rezolvate', style: TextStyle(fontSize: 13, color: Pb.muted)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: total.isEmpty ? 0 : done / total.length, minHeight: 5, backgroundColor: Pb.border, color: c),
                  ),
                ),
                const SizedBox(height: 12),
                for (final kk in kindKeys) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 2),
                    child: Text(kk.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.8)),
                  ),
                  LayoutBuilder(
                    builder: (context, b) {
                      final cols = b.maxWidth < 520 ? 1 : (b.maxWidth < 700 ? 2 : 3);
                      final w = (b.maxWidth - 8 * (cols - 1)) / cols;
                      return Wrap(spacing: 8, runSpacing: 8, children: [for (final e in kinds[kk]!) SizedBox(width: w, child: _yearTile(e))]);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Positioned(left: (isMobile ? 10 : 14) - 6, top: 6, child: dot),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
      padding: EdgeInsets.fromLTRB(isMobile ? 8 : 14, 18, isMobile ? 12 : 18, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final (i, k) in keys.indexed) group(k, i == keys.length - 1)]),
    );
  }

  Widget _yearTile(Map<String, dynamic> e) {
    final cc = _catColor('${e['category'] ?? ''}');
    final sursa = '${e['sursa'] ?? ''}';
    // what is left of the source once the year and kind are said above: "Subiectul III.2"
    final rest = sursa.contains(' · ') ? sursa.split(' · ').last : '';
    return _open(
      e,
      (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: h ? cc.withOpacity(0.08) : Pb.surface.withOpacity(AppColors.isDark ? 0.5 : 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: h ? cc.withOpacity(0.55) : Pb.border),
        ),
        child: Row(
          children: [
            _statusIcon(e, 18),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: _hlSpans('${e['title']}')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: h ? cc : Pb.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [if (rest.isNotEmpty && rest != sursa) rest, '#${e['id']}', AppStyle.sentence('${e['difficulty'] ?? ''}')].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Pb.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
