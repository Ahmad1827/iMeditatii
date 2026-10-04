import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer;

class ExerciseListScreen extends StatefulWidget {
  final String subject;
  final String? grade;

  const ExerciseListScreen({super.key, required this.subject, this.grade});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> allExercises = [];
  List<Map<String, dynamic>> displayedExercises = [];

  String selectedGrade = "9";
  String selectedCategory = "Toate";
  String searchQuery = "";

  List<String> availableGrades = [];
  List<String> availableCategories = [];

  bool isLoading = true;
  int completedCount = 0;

  // ---- clean state
  final ScrollController _cScroll = ScrollController();
  final TextEditingController _cSearch = TextEditingController();
  Set<String> _solved = {};
  String _cDiff = 'toate';
  bool _cUnsolved = false;
  bool _cHidden = false;
  int _cLimit = 25;
  final GlobalKey _cTopKey = GlobalKey();
  final GlobalKey _cMainKey = GlobalKey();
  final GlobalKey _cFootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.grade ?? "9";
    _loadAllExercises();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cScroll.dispose();
    _cSearch.dispose();
    super.dispose();
  }

  Future<void> _loadAllExercises() async {
    setState(() => isLoading = true);

    List<Map<String, dynamic>> fetched = [];
    Set<String> tempGrades = {};

    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final data = json.decode(response);

      final subjectData = data[widget.subject];
      if (subjectData != null) {
        (subjectData as Map<String, dynamic>).forEach((gradeKey, categoriesMap) {
          tempGrades.add(gradeKey);
          (categoriesMap as Map<String, dynamic>).forEach((categoryName, exercisesList) {
            for (var ex in (exercisesList as List<dynamic>)) {
              fetched.add({
                'id': ex['id'],
                'grade': gradeKey,
                'category': categoryName,
                'title': ex['title'] ?? "Fără titlu",
                'difficulty': ex['difficulty'] ?? "ușoară",
                'source': 'json',
              });
            }
          });
        });
      }
    } catch (e) {
      debugPrint("Eroare JSON: $e");
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('subject', isEqualTo: widget.subject)
          .where('approved', isEqualTo: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final gradeStr = data['grade']?.toString() ?? "N/A";

        fetched.add({
          'id': doc.id,
          'grade': gradeStr,
          'category': data['category'] ?? "General",
          'title': data['title'] ?? "Fără titlu",
          'difficulty': data['difficulty'] ?? "ușoară",
          'source': 'firebase',
        });
        tempGrades.add(gradeStr);
      }
    } catch (e) {
      debugPrint("Eroare Firestore: $e");
    }

    if (mounted) {
      setState(() {
        allExercises = fetched;
        availableGrades = tempGrades.toList()
          ..sort((a, b) => (int.tryParse(a) ?? 99).compareTo(int.tryParse(b) ?? 99));

        if (!availableGrades.contains(selectedGrade) && availableGrades.isNotEmpty) {
          selectedGrade = availableGrades.first;
        }
        isLoading = false;
      });

      _updateCategoriesAndFilter();
    }
  }

  void _updateCategoriesAndFilter() async {
    Set<String> tempCategories = {};
    List<Map<String, dynamic>> gradeFiltered = [];

    for (var ex in allExercises) {
      if (ex['grade'] == selectedGrade) {
        tempCategories.add(ex['category']);
        gradeFiltered.add(ex);
      }
    }

    int done = 0;
    final prefs = await SharedPreferences.getInstance();
    final solved = prefs.getKeys().where((k) => prefs.get(k) == true).toSet();
    for (var ex in gradeFiltered) {
      final key = "${widget.subject}_${selectedGrade}_${ex['id']}";
      if (solved.contains(key)) done++;
    }

    if (!mounted) return;
    setState(() {
      _solved = solved;
      completedCount = done;
      availableCategories = tempCategories.toList()..sort();

      if (selectedCategory != "Toate" && !availableCategories.contains(selectedCategory)) {
        selectedCategory = "Toate";
      }

      var filtered = gradeFiltered;
      if (selectedCategory != "Toate") {
        filtered = filtered.where((ex) => ex['category'] == selectedCategory).toList();
      }

      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((ex) {
          final t = (ex['title'] as String).toLowerCase();
          final c = (ex['category'] as String).toLowerCase();
          return t.contains(searchQuery.toLowerCase()) || c.contains(searchQuery.toLowerCase());
        }).toList();
      }

      displayedExercises = filtered;
    });
  }

  Future<bool> _isExerciseDone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${selectedGrade}_$id";
    return prefs.get(key) == true;
  }

  Future<void> _openExercise(Map<String, dynamic> ex) async {
    final encodedMaterie = Uri.encodeComponent(widget.subject);
    final encodedClasa = Uri.encodeComponent(selectedGrade);
    await context.push('/exercitiu/${ex["id"]}?materie=$encodedMaterie&clasa=$encodedClasa');
    if (mounted) _updateCategoriesAndFilter();
  }

  void _selectGrade(String g) {
    setState(() {
      selectedGrade = g;
      _cLimit = 25;
    });
    _updateCategoriesAndFilter();
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) => s.isClean
          ? _buildClean(MediaQuery.of(context).size.width < 900)
          : _buildRetro(MediaQuery.of(context).size.width < 800),
    );
  }

  // ===========================================================================
  // CLEAN — subject header with progress ring, categories, problem table
  // ===========================================================================
  static const Color _cGreen = Color(0xFF10B981);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cRose = Color(0xFFE5484D);
  static const Color _cBlue = Color(0xFF3B82F6);
  static const List<Color> _catColors = [Pb.primary, _cBlue, _cAmber, _cRose, Color(0xFF8B5CF6), Color(0xFF14B8A6)];
  static const Map<String, String> _roman = {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'};

  Color get _subjectColor {
    final l = widget.subject.toLowerCase();
    if (l.startsWith('mat')) return _cRose;
    if (l.contains('info')) return Pb.primary;
    if (l.contains('engl')) return _cAmber;
    if (l.contains('rom')) return _cBlue;
    if (l.contains('fiz')) return const Color(0xFF8B5CF6);
    if (l.contains('chim')) return const Color(0xFF14B8A6);
    return Pb.primary;
  }

  String _gradeLabel(String g) => 'a ${_roman[g] ?? g}-a';

  Color _catColor(String cat) {
    final i = availableCategories.indexOf(cat);
    return _catColors[(i < 0 ? 0 : i) % _catColors.length];
  }

  Color _diffColor(String d) {
    final l = d.toLowerCase();
    if (l.startsWith('u') || l.startsWith('e')) return _cGreen;
    if (l.startsWith('m')) return _cAmber;
    if (l.startsWith('g') || l.startsWith('h') || l.startsWith('d')) return _cRose;
    return Pb.muted;
  }

  String _diffKey(String d) {
    final l = d.toLowerCase();
    if (l.startsWith('u') || l.startsWith('e')) return 'usoara';
    if (l.startsWith('m')) return 'medie';
    if (l.startsWith('g') || l.startsWith('h') || l.startsWith('d')) return 'grea';
    return 'alta';
  }

  bool _isSolved(Map<String, dynamic> ex) => _solved.contains("${widget.subject}_${selectedGrade}_${ex['id']}");

  BoxDecoration _cDeco({double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  Widget _buildClean(bool isMobile) {
    final inGrade = allExercises.where((e) => e['grade'] == selectedGrade).toList();
    final rows = displayedExercises.where((e) {
      if (_cDiff != 'toate' && _diffKey('${e['difficulty']}') != _cDiff) return false;
      if (_cUnsolved && _isSolved(e)) return false;
      return true;
    }).toList();

    Widget box(double max, Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24), child: child),
          ),
        );

    Widget slide(double dx, Widget child) => AnimatedSlide(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          offset: _cHidden ? Offset(dx, 0) : Offset.zero,
          child: IgnorePointer(ignoring: _cHidden, child: child),
        );

    final Widget body;
    if (isLoading) {
      body = Container(
        padding: const EdgeInsets.all(28),
        decoration: _cDeco(r: 14),
        child: Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)),
            const SizedBox(width: 12),
            Text('Se încarcă problemele...', style: TextStyle(fontSize: 14, color: Pb.muted)),
          ],
        ),
      );
    } else if (isMobile) {
      body = slide(
        -1.4,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_cCategoryChips(inGrade), const SizedBox(height: 12), _cTable(rows, isMobile)],
        ),
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 260, child: slide(-3.2, _cCategories(inGrade))),
          const SizedBox(width: 20),
          Expanded(child: slide(1.6, _cTable(rows, isMobile))),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              scene: HomeScene.fantasy,
              blockers: [_cTopKey, if (!_cHidden) _cMainKey, _cFootKey],
              cardsHidden: _cHidden,
              onToggleCards: () => setState(() => _cHidden = !_cHidden),
              hideLabel: 'Ascunde problemele',
              showLabel: 'Arată problemele',
              child: Scrollbar(
                controller: _cScroll,
                child: SingleChildScrollView(
                  controller: _cScroll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isMobile ? 20 : 36),
                      box(1180, KeyedSubtree(key: _cTopKey, child: _LReveal(child: _cHeader(inGrade, isMobile)))),
                      SizedBox(height: isMobile ? 14 : 20),
                      box(1180, KeyedSubtree(key: _cMainKey, child: _LReveal(delayMs: 140, child: body))),
                      const SizedBox(height: 56),
                      KeyedSubtree(key: _cFootKey, child: _cFooter(isMobile)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _cHeader(List<Map<String, dynamic>> inGrade, bool isMobile) {
    final c = _subjectColor;
    final total = inGrade.length;
    final ratio = total == 0 ? 0.0 : completedCount / total;

    final ring = SizedBox(
      width: isMobile ? 84 : 96,
      height: isMobile ? 84 : 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(
              value: v,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: Pb.gray,
              color: c,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$completedCount', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w700, color: Pb.text, height: 1)),
                Text('din $total', style: TextStyle(fontSize: 12, color: Pb.muted)),
              ],
            ),
          ),
        ],
      ),
    );

    Widget seg(String g) {
      final sel = selectedGrade == g;
      final count = allExercises.where((e) => e['grade'] == g).length;
      return _LHover(
        onTap: () => _selectGrade(g),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_gradeLabel(g),
                  style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
              const SizedBox(width: 6),
              Text('$count', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ),
      );
    }

    final toggle = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [for (final g in availableGrades) seg(g)]),
    );

    final search = TextField(
      controller: _cSearch,
      onChanged: (v) {
        searchQuery = v;
        _cLimit = 25;
        _updateCategoriesAndFilter();
      },
      style: TextStyle(fontSize: 14.5, color: Pb.text),
      cursorColor: Pb.primary,
      decoration: Pb.input(hint: 'Caută după titlu sau capitol').copyWith(
        prefixIcon: Icon(Icons.search, size: 18, color: Pb.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 17, color: Pb.muted),
                splashRadius: 16,
                onPressed: () {
                  _cSearch.clear();
                  searchQuery = '';
                  _updateCategoriesAndFilter();
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PbLink(text: 'Probleme', fontSize: 13, onTap: () => context.go('/exercitii')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('/', style: TextStyle(fontSize: 13, color: Pb.muted)),
            ),
            Text(widget.subject, style: TextStyle(fontSize: 13, color: Pb.muted)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.subject,
                style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? 'Nu sunt încă probleme pentru clasa ${_gradeLabel(selectedGrade)}.'
              : 'Clasa ${_gradeLabel(selectedGrade)}: $total probleme în ${availableCategories.length} capitole. '
                  '${completedCount == total && total > 0 ? 'Le-ai rezolvat pe toate!' : 'Mai ai ${total - completedCount} de rezolvat.'}',
          style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: _cDeco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 14), ring])
              : Row(children: [Expanded(child: info), const SizedBox(width: 24), ring]),
          const SizedBox(height: 18),
          if (isMobile) ...[
            if (availableGrades.isNotEmpty)
              Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: toggle)),
            const SizedBox(height: 10),
            search,
          ] else
            Row(
              children: [
                if (availableGrades.isNotEmpty) toggle,
                const SizedBox(width: 16),
                Expanded(child: search),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- categories
  Widget _cCategories(List<Map<String, dynamic>> inGrade) {
    Widget row(String cat, int count, int done, Color? c) {
      final sel = selectedCategory == cat;
      final accent = c ?? Pb.primary;
      return _LHover(
        onTap: () {
          setState(() {
            selectedCategory = cat;
            _cLimit = 25;
          });
          _updateCategoriesAndFilter();
        },
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: sel ? accent.withOpacity(0.08) : (h ? Pb.hoverBg : Colors.transparent),
            border: Border(
              top: BorderSide(color: Pb.border),
              left: BorderSide(color: sel ? accent : Colors.transparent, width: 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(13, 10, 14, 10),
          child: Row(
            children: [
              if (c != null)
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle))
              else
                Icon(Icons.apps, size: 14, color: sel ? accent : Pb.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStyle.sentence(cat),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel || h ? Pb.text : Pb.muted),
                ),
              ),
              const SizedBox(width: 8),
              Text(done > 0 ? '$done/$count' : '$count', style: TextStyle(fontSize: 12.5, color: done == count && count > 0 ? _cGreen : Pb.muted)),
            ],
          ),
        ),
      );
    }

    int doneIn(Iterable<Map<String, dynamic>> l) => l.where(_isSolved).length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cDeco(r: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 18, color: Pb.muted),
                const SizedBox(width: 8),
                Text('Capitole', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ],
            ),
          ),
          row('Toate', inGrade.length, doneIn(inGrade), null),
          for (final cat in availableCategories)
            row(cat, inGrade.where((e) => e['category'] == cat).length, doneIn(inGrade.where((e) => e['category'] == cat)), _catColor(cat)),
        ],
      ),
    );
  }

  Widget _cChip(String label, bool sel, VoidCallback onTap, {Color? color, IconData? icon}) {
    final accent = color ?? Pb.link;
    return _LHover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? accent.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? accent.withOpacity(0.6) : Pb.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[Icon(icon, size: 14, color: sel ? accent : Pb.muted), const SizedBox(width: 5)],
            Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? accent : Pb.text)),
          ],
        ),
      ),
    );
  }

  Widget _cCategoryChips(List<Map<String, dynamic>> inGrade) {
    void pick(String c) {
      setState(() => selectedCategory = c);
      _updateCategoriesAndFilter();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(padding: const EdgeInsets.only(right: 6), child: _cChip('Toate capitolele', selectedCategory == 'Toate', () => pick('Toate'))),
          for (final cat in availableCategories)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _cChip(AppStyle.sentence(cat), selectedCategory == cat, () => pick(cat), color: _catColor(cat)),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- table
  Widget _cTable(List<Map<String, dynamic>> rows, bool isMobile) {
    final shown = rows.length < _cLimit ? rows.length : _cLimit;
    final headStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted);

    final filters = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _cChip('Orice dificultate', _cDiff == 'toate', () => setState(() => _cDiff = 'toate')),
        _cChip('Ușoară', _cDiff == 'usoara', () => setState(() => _cDiff = 'usoara'), color: _cGreen),
        _cChip('Medie', _cDiff == 'medie', () => setState(() => _cDiff = 'medie'), color: _cAmber),
        _cChip('Grea', _cDiff == 'grea', () => setState(() => _cDiff = 'grea'), color: _cRose),
        Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 4), color: Pb.border),
        _cChip('Doar nerezolvate', _cUnsolved, () => setState(() => _cUnsolved = !_cUnsolved), icon: Icons.radio_button_unchecked),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cDeco(r: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedCategory == 'Toate' ? 'Toate problemele' : AppStyle.sentence(selectedCategory),
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text),
                      ),
                    ),
                    Text('${rows.length} probleme', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                filters,
              ],
            ),
          ),
          if (!isMobile && rows.isNotEmpty)
            Container(
              color: Pb.hoverBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const SizedBox(width: 36),
                SizedBox(width: 52, child: Text('#', style: headStyle)),
                Expanded(child: Text('Titlu', style: headStyle)),
                SizedBox(width: 170, child: Text('Capitol', style: headStyle)),
                SizedBox(width: 96, child: Text('Dificultate', style: headStyle)),
              ]),
            ),
          if (rows.isEmpty)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 30, color: Pb.muted),
                  const SizedBox(height: 8),
                  Text('Nicio problemă nu se potrivește filtrelor.', style: TextStyle(fontSize: 14, color: Pb.muted)),
                  const SizedBox(height: 12),
                  PbButton(
                    text: 'Resetează filtrele',
                    variant: PbVariant.outlineSecondary,
                    size: PbSize.sm,
                    onPressed: () {
                      _cSearch.clear();
                      searchQuery = '';
                      setState(() {
                        _cDiff = 'toate';
                        _cUnsolved = false;
                        selectedCategory = 'Toate';
                      });
                      _updateCategoriesAndFilter();
                    },
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < shown; i++) _cRow(rows[i], isMobile),
          if (rows.isNotEmpty)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text('Afișate $shown din ${rows.length}', style: TextStyle(fontSize: 13, color: Pb.muted))),
                  if (rows.length > shown)
                    PbButton(
                      text: 'Arată mai multe',
                      variant: PbVariant.outlinePrimary,
                      size: PbSize.sm,
                      onPressed: () => setState(() => _cLimit += 25),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cRow(Map<String, dynamic> e, bool isMobile) {
    final solved = _isSolved(e);
    final diff = '${e['difficulty'] ?? ''}';
    final dc = _diffColor(diff);
    final cat = '${e['category'] ?? ''}';
    final cc = _catColor(cat);

    return _LHover(
      onTap: () => _openExercise(e),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: h ? cc.withOpacity(0.06) : Colors.transparent,
          border: Border(
            top: BorderSide(color: Pb.border),
            left: BorderSide(color: h ? cc : Colors.transparent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(
                solved ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: solved ? _cGreen : Pb.border,
              ),
            ),
            if (!isMobile) SizedBox(width: 52, child: Text('${e['id']}', style: TextStyle(fontSize: 13.5, color: Pb.muted))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e['title']}',
                    maxLines: isMobile ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: h ? cc : Pb.text),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 2),
                    Text('#${e['id']}, ${AppStyle.sentence(cat)}, ${AppStyle.sentence(diff)}',
                        style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ],
                ],
              ),
            ),
            if (!isMobile) ...[
              SizedBox(
                width: 170,
                child: Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: cc, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(AppStyle.sentence(cat),
                          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: Pb.text)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: diff.isEmpty
                      ? Text('–', style: TextStyle(fontSize: 13.5, color: Pb.muted))
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: dc.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
                          child: Text(AppStyle.sentence(diff),
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: dc)),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cFooter(bool isMobile) {
    final links = [
      PbLink(text: 'Termeni și condiții', fontSize: 14, onTap: () => context.go('/termeni-si-conditii')),
      PbLink(text: 'Politica de confidențialitate', fontSize: 14, onTap: () => context.go('/politica-confidentialitate')),
    ];
    final copy = Text('© 2026 iMeditații', style: TextStyle(color: Pb.muted, fontSize: 14));

    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: PbContainer(
        child: isMobile
            ? Column(children: [
                copy,
                const SizedBox(height: 10),
                Wrap(spacing: 18, runSpacing: 8, alignment: WrapAlignment.center, children: links),
              ])
            : Row(children: [copy, const Spacer(), ...links.expand((l) => [const SizedBox(width: 22), l])]),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.go('/exercitii'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                border: Border.all(color: AppColors.border, width: 2),
                                boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2, 2))],
                              ),
                              child: Icon(Icons.arrow_back, color: AppColors.ink, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.subject.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.isDark ? const Color(0xFFEAB334) : AppColors.ink,
                              fontSize: 18,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Row(
                          children: availableGrades.map((g) {
                            final isSel = g == selectedGrade;
                            return GestureDetector(
                              onTap: () => _selectGrade(g),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                color: isSel
                                    ? (AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F))
                                    : Colors.transparent,
                                child: Text(
                                  "CLASA $g",
                                  style: TextStyle(
                                    color: isSel
                                        ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/exercitii'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.border, width: 2.5),
                            boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
                          ),
                          child: Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.isDark ? const Color(0xFFEAB334) : AppColors.ink,
                            fontSize: 24,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          "RESOLVE PROBLEMS • EARN XP",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(color: AppColors.border, width: 2.5),
                        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
                      ),
                      child: Row(
                        children: availableGrades.map((g) {
                          final isSel = g == selectedGrade;
                          return GestureDetector(
                            onTap: () => _selectGrade(g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F))
                                    : Colors.transparent,
                              ),
                              child: Text(
                                "CLASA $g",
                                style: TextStyle(
                                  color: isSel
                                      ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isMobile) {
    final totalInGrade = allExercises.where((e) => e['grade'] == selectedGrade).length;
    final progressPercent = totalInGrade > 0 ? (completedCount / totalInGrade) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4))],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "QUEST PROGRESS",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 12 : 13, color: AppColors.ink, letterSpacing: 0.5),
                    ),
                    Text(
                      "$completedCount / $totalInGrade",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 12 : 14, color: AppColors.forest),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.bg,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                    minHeight: isMobile ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 14 : 22),
          Text(
            "SEARCH QUEST",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: TextField(
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
              cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
              decoration: InputDecoration(
                hintText: "Caută exercițiu...",
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 16, color: AppColors.ink),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              onChanged: (val) {
                searchQuery = val;
                _updateCategoriesAndFilter();
              },
            ),
          ),
          SizedBox(height: isMobile ? 14 : 22),
          Text(
            "CATEGORIES",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          if (isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Toate", ...availableCategories].map((cat) {
                  final isSelected = cat == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() => selectedCategory = cat);
                        _updateCategoriesAndFilter();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F))
                              : AppColors.cardBg,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Text(
                          cat.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            ...["Toate", ...availableCategories].map((cat) {
              final isSelected = cat == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() => selectedCategory = cat);
                    _updateCategoriesAndFilter();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F))
                          : AppColors.cardBg,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cat.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                                  : AppColors.ink,
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.arrow_right,
                              color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRetro(bool isMobile) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'QUEST LOG',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: isMobile ? 15 : 16),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.border, height: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isMobile),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 16 : 22),
                          child: isMobile
                              ? ListView(
                                  children: [
                                    _buildSidebar(isMobile),
                                    const SizedBox(height: 18),
                                    _buildSingleColumnList(isMobile),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 330, child: _buildSidebar(isMobile)),
                                    const SizedBox(width: 28),
                                    Expanded(child: _buildSingleColumnList(isMobile)),
                                  ],
                                ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleColumnList(bool isMobile) {
    final listWidget = displayedExercises.isEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 36, color: AppColors.ink),
                const SizedBox(height: 10),
                Text("NICIUN EXERCIȚIU GĂSIT",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
              ],
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            shrinkWrap: isMobile,
            physics: isMobile ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
            padding: EdgeInsets.only(right: isMobile ? 0 : 14, bottom: 24),
            itemCount: displayedExercises.length,
            itemBuilder: (context, index) {
              final ex = displayedExercises[index];
              return FutureBuilder<bool>(
                future: _isExerciseDone(ex["id"]),
                builder: (context, snapshot) {
                  final isDone = snapshot.data ?? false;
                  return SingleColumnQuestCard(
                    index: index,
                    exercise: ex,
                    isDone: isDone,
                    isMobile: isMobile,
                    onTap: () => _openExercise(ex),
                  );
                },
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "AVAILABLE QUESTS (${displayedExercises.length})",
              style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.6),
            ),
            Text(
              "FILTRU: ${selectedCategory.toUpperCase()}",
              style: TextStyle(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isMobile)
          listWidget
        else
          Expanded(
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: Radius.zero,
              thumbColor: AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F),
              trackColor: AppColors.sidebarBg,
              trackBorderColor: AppColors.border,
              padding: const EdgeInsets.only(left: 6),
              child: listWidget,
            ),
          ),
      ],
    );
  }
}

class SingleColumnQuestCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> exercise;
  final bool isDone;
  final bool isMobile;
  final VoidCallback onTap;

  const SingleColumnQuestCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.isDone,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<SingleColumnQuestCard> createState() => _SingleColumnQuestCardState();
}

class _SingleColumnQuestCardState extends State<SingleColumnQuestCard> {
  bool _isHover = false;
  bool _isPressed = false;

  List<Color> get _badgeColors => [
        AppColors.sky,
        AppColors.orange,
        AppColors.purple,
        AppColors.mustard,
        AppColors.sunset,
        AppColors.forest,
      ];

  Color _getBadgeColor() {
    if (widget.isDone) return AppColors.forest;
    return _badgeColors[widget.index % _badgeColors.length];
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară":
        return AppColors.forest;
      case "medie":
        return AppColors.mustard;
      case "grea":
        return AppColors.sunset;
      default:
        return AppColors.sky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.exercise["title"] ?? "UNKNOWN";
    final category = widget.exercise["category"] ?? "";
    final diff = widget.exercise["difficulty"] ?? "ușoară";
    final id = widget.exercise["id"] ?? "";

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          margin: const EdgeInsets.only(bottom: 12),
          transform: Matrix4.translationValues(
            _isPressed ? 2.5 : (_isHover ? -2.0 : 0.0),
            _isPressed ? 2.5 : (_isHover ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isDone
                ? (AppColors.isDark ? const Color(0xFF141C22) : const Color(0xFFF0EFE9))
                : AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: _isPressed ? const Offset(0, 0) : Offset(widget.isMobile ? 3 : 4, widget.isMobile ? 3 : 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: widget.isMobile ? 54 : 68,
                  decoration: BoxDecoration(
                    color: _getBadgeColor(),
                    border: Border(right: BorderSide(color: AppColors.border, width: 2.5)),
                  ),
                  child: Center(
                    child: Text(
                      widget.isDone ? "✓" : "#$id",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: widget.isMobile ? 14 : 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 18, vertical: widget.isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: widget.isMobile ? 13.5 : 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: widget.isMobile ? 11 : 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 10 : 16),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.border, width: 2.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 7 : 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _difficultyColor(diff).withOpacity(AppColors.isDark ? 0.25 : 0.15),
                          border: Border.all(color: _difficultyColor(diff), width: 1.5),
                        ),
                        child: Text(
                          diff.toUpperCase(),
                          style: TextStyle(
                            fontSize: widget.isMobile ? 9.5 : 11,
                            fontWeight: FontWeight.w900,
                            color: _difficultyColor(diff),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: widget.isMobile ? 13 : 16, color: AppColors.ink),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// small helpers (Clean)
// =============================================================================
class _LHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _LHover({required this.builder, this.onTap});

  @override
  State<_LHover> createState() => _LHoverState();
}

class _LHoverState extends State<_LHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(_hover),
      ),
    );
  }
}

class _LReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _LReveal({required this.child, this.delayMs = 0});

  @override
  State<_LReveal> createState() => _LRevealState();
}

class _LRevealState extends State<_LReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}