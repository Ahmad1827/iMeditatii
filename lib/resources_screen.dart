import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart';
import 'resources_data.dart';
import 'ui_components.dart';

// RetroBlock now comes from ui_components.dart (same retro look, and it also
// adapts to Clean mode), so the local copy that used to live here is gone.

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ScrollController _scrollController = ScrollController();
  late final Stream<QuerySnapshot> _stream =
      FirebaseFirestore.instance.collection('resources').where('approved', isEqualTo: true).snapshots();

  // ---- retro state
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubject = 'PYTHON'; // PYTHON, C++, MATEMATICĂ
  String _selectedGrade = '9'; // 9, 10, 11, 12
  String _searchQuery = '';
  final Map<String, GlobalKey> _moduleKeys = {};

  // ---- clean state
  final TextEditingController _cSearch = TextEditingController();
  final FocusNode _cSearchFocus = FocusNode();
  String _cSubject = 'toate';
  String _cGrade = '9';
  String _cQuery = '';
  bool _cUnread = false;
  bool _cHidden = false;
  Set<String> _cRead = {};
  final Map<String, GlobalKey> _cKeys = {};
  final GlobalKey _cTopKey = GlobalKey();
  final GlobalKey _cMainKey = GlobalKey();
  final GlobalKey _cFootKey = GlobalKey();
  static const String _readPrefix = 'lectie_citita:';

  @override
  void initState() {
    super.initState();
    _cLoadRead();
    HardwareKeyboard.instance.addHandler(_cOnKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_cOnKey);
    _scrollController.dispose();
    _searchController.dispose();
    _cSearch.dispose();
    _cSearchFocus.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _collect(AsyncSnapshot<QuerySnapshot> snapshot) {
    final all = <Map<String, dynamic>>[...ResourcesData.allArticles];
    if (snapshot.hasData) {
      for (final doc in snapshot.data!.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        all.add(data);
      }
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final isMobile = MediaQuery.of(context).size.width < 900;
        return StreamBuilder<QuerySnapshot>(
          stream: _stream,
          builder: (context, snapshot) {
            final all = _collect(snapshot);
            return s.isClean ? _buildClean(all, isMobile) : _buildRetro(all, isMobile);
          },
        );
      },
    );
  }

  // ===========================================================================
  // CLEAN — biblioteca de lecții: hero + căutare, filtre, cuprins, capitole
  // ===========================================================================
  static const Color _cRose = Color(0xFFE5484D);
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cGreen = Color(0xFF10B981);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Map<String, String> _roman = {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'};

  static String _subj(Map a) => '${a['subject'] ?? ''}'.toUpperCase();

  static String _subjName(String s) {
    switch (s) {
      case 'PYTHON':
        return 'Python';
      case 'C++':
        return 'C++';
      case 'MATEMATICĂ':
      case 'MATEMATICA':
        return 'Matematică';
    }
    return AppStyle.sentence(s);
  }

  static Color _subjColor(String s) {
    final l = s.toLowerCase();
    if (l.startsWith('mat')) return _cRose;
    if (l.contains('python')) return _cBlue;
    if (l.contains('c++') || l.contains('info')) return Pb.primary;
    return _cAmber;
  }

  static Color _groupColor(List<Map<String, dynamic>> items) {
    final s = items.map(_subj).toSet();
    return s.length == 1 ? _subjColor(s.first) : Pb.primary;
  }

  static int _minutes(Map a) =>
      int.tryParse(RegExp(r'\d+').firstMatch('${a['readTime'] ?? ''}')?.group(0) ?? '') ?? 5;

  static String? _chapterNum(String m) => RegExp(r'^\s*(\d+)\.').firstMatch(m)?.group(1);

  static String _fixWords(String t) {
    var r = t.replaceAll(RegExp(r'c\+\+', caseSensitive: false), 'C++');
    const words = {
      'python': 'Python',
      'sql': 'SQL',
      'oop': 'OOP',
      'i/o': 'I/O',
      'bacalaureat': 'Bacalaureat',
      'divide et impera': 'Divide et Impera',
    };
    for (final e in words.entries) {
      r = r.replaceAll(RegExp('(?<![\\w])${RegExp.escape(e.key)}(?![\\w])', caseSensitive: false), e.value);
    }
    return r;
  }

  static String _chapterName(String m) =>
      _fixWords(AppStyle.sentence(m.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '')));

  static String _tagName(String t) => t.length <= 4 ? t : _fixWords(AppStyle.sentence(t));

  Future<void> _cLoadRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs
          .getKeys()
          .where((k) => k.startsWith(_readPrefix) && prefs.get(k) == true)
          .map((k) => k.substring(_readPrefix.length))
          .toSet();
      if (mounted) setState(() => _cRead = read);
    } catch (e) {
      debugPrint('Lecții citite: $e');
    }
  }

  Future<void> _cOpen(Map<String, dynamic> a) async {
    final id = '${a['id']}';
    if (!_cRead.contains(id)) {
      setState(() => _cRead.add(id));
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('$_readPrefix$id', true);
      } catch (e) {
        debugPrint('Lecții citite: $e');
      }
    }
    if (mounted) context.go('/resurse/$id');
  }

  /// "/" focuses the search, Esc leaves it (Clean only).
  bool _cOnKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted || !AppStyle.current.isClean) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (e.character == '/' && !_cSearchFocus.hasFocus) {
      _cSearchFocus.requestFocus();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.escape && _cSearchFocus.hasFocus) {
      _cSearchFocus.unfocus();
      return true;
    }
    return false;
  }

  void _cScrollTo(String key) {
    final ctx = _cKeys[key]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic, alignment: 0.04);
  }

  void _cReset() {
    _cSearch.clear();
    setState(() {
      _cSubject = 'toate';
      _cUnread = false;
      _cQuery = '';
    });
  }

  BoxDecoration _cDeco({double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  Widget _buildClean(List<Map<String, dynamic>> all, bool isMobile) {
    final q = _cQuery.trim().toLowerCase();
    final inGrade = all.where((a) => '${a['grade']}' == _cGrade).toList();
    final subjects = all.map(_subj).where((s) => s.isNotEmpty).toSet().toList()..sort();

    final filtered = inGrade.where((a) {
      if (_cSubject != 'toate' && _subj(a) != _cSubject) return false;
      if (_cUnread && _cRead.contains('${a['id']}')) return false;
      if (q.isEmpty) return true;
      return '${a['title']} ${a['desc']} ${a['tag']} ${a['module']}'.toLowerCase().contains(q);
    }).toList();

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final a in filtered) {
      final m = '${a['module'] ?? 'GENERAL'}'.toUpperCase();
      groups.putIfAbsent(m, () => []).add(a);
      _cKeys.putIfAbsent(m, () => GlobalKey());
    }

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

    final entries = groups.entries.toList();
    final Widget body;
    if (groups.isEmpty) {
      body = slide(-1.4, _cEmpty());
    } else if (isMobile) {
      body = slide(
        -1.4,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cChapterChips(entries.map((e) => e.key).toList()),
            const SizedBox(height: 12),
            for (var i = 0; i < entries.length; i++) ...[
              _cModule(entries[i].key, entries[i].value, i, isMobile),
              const SizedBox(height: 14),
            ],
          ],
        ),
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 272, child: slide(-3.2, _cToc(groups))),
          const SizedBox(width: 20),
          Expanded(
            child: slide(
              1.6,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    _cModule(entries[i].key, entries[i].value, i, isMobile),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
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
              blockers: [_cTopKey, if (!_cHidden) _cMainKey, _cFootKey],
              cardsHidden: _cHidden,
              onToggleCards: () => setState(() => _cHidden = !_cHidden),
              hideLabel: 'Ascunde lecțiile',
              showLabel: 'Arată lecțiile',
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isMobile ? 20 : 40),
                      box(
                        1180,
                        KeyedSubtree(
                          key: _cTopKey,
                          child: _RReveal(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _cHero(all, isMobile),
                                const SizedBox(height: 14),
                                _cFilters(all, subjects, inGrade, isMobile),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 22),
                      box(1180, KeyedSubtree(key: _cMainKey, child: _RReveal(delayMs: 140, child: body))),
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

  // ---------------------------------------------------------------- hero
  Widget _cHero(List<Map<String, dynamic>> all, bool isMobile) {
    final total = all.length;
    final chapters = all.map((a) => '${a['grade']}|${a['module']}').toSet().length;
    final minutes = all.fold<int>(0, (s, a) => s + _minutes(a));
    final read = all.where((a) => _cRead.contains('${a['id']}')).length;
    final complete = all.where((a) => ResourcesData.curatedLectures.containsKey('${a['id']}')).length;
    final ratio = total == 0 ? 0.0 : read / total;

    Widget stat(IconData i, String v, String l, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: c.withOpacity(0.09), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: 17, color: c),
              const SizedBox(width: 8),
              Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(width: 5),
              Text(l, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
            ],
          ),
        );

    final keyCap = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Pb.border)),
      child: Text('/', style: Pb.mono(12.5, color: Pb.muted)),
    );

    final search = TextField(
      controller: _cSearch,
      focusNode: _cSearchFocus,
      onChanged: (v) => setState(() => _cQuery = v),
      style: TextStyle(fontSize: 15, color: Pb.text),
      cursorColor: Pb.primary,
      decoration: Pb.input(hint: 'Caută o lecție, un algoritm sau o formulă').copyWith(
        prefixIcon: Icon(Icons.search, size: 19, color: Pb.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: _cQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close, size: 18, color: Pb.muted),
                splashRadius: 18,
                onPressed: () {
                  _cSearch.clear();
                  setState(() => _cQuery = '');
                },
              )
            : (isMobile ? null : Padding(padding: const EdgeInsets.only(right: 10), child: keyCap)),
        suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      ),
    );

    final progress = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                read == 0 ? 'Încă n-ai deschis nicio lecție.' : 'Ai deschis $read din $total lecții',
                style: TextStyle(fontSize: 13.5, color: Pb.muted),
              ),
            ),
            Text('${(ratio * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: Pb.gray, color: Pb.primary),
          ),
        ),
      ],
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Biblioteca iMeditații', style: TextStyle(fontSize: 14, color: Pb.muted)),
        const SizedBox(height: 4),
        Text(
          'Lecții pentru liceu',
          style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          'Teorie pe capitole, după programa claselor IX–XII, cu exemple de cod și greșelile care apar des la Bacalaureat.',
          style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            stat(Icons.menu_book_outlined, '$total', 'lecții', Pb.primary),
            stat(Icons.view_list_outlined, '$chapters', 'capitole', _cBlue),
            stat(Icons.schedule, '$minutes', 'minute de citit', _cAmber),
            stat(Icons.verified_outlined, '$complete', 'lecții complete', _cGreen),
          ],
        ),
        const SizedBox(height: 18),
        search,
        const SizedBox(height: 14),
        progress,
      ],
    );

    final daily = _cDaily(all);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: _cDeco(r: 18),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 20), daily])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 28), SizedBox(width: 320, child: daily)],
            ),
    );
  }

  Widget _cDaily(List<Map<String, dynamic>> all) {
    final curated = all.where((a) => ResourcesData.curatedLectures.containsKey('${a['id']}')).toList();
    if (curated.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final a = curated[now.difference(DateTime(now.year)).inDays % curated.length];
    final subj = _subj(a);
    final c = _subjColor(subj);
    final read = _cRead.contains('${a['id']}');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 18, color: c),
              const SizedBox(width: 8),
              Expanded(child: Text('Lecția zilei', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Pb.text))),
              if (read) const Icon(Icons.check_circle, size: 17, color: _cGreen),
            ],
          ),
          const SizedBox(height: 12),
          Text('${a['title']}', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text, height: 1.3)),
          const SizedBox(height: 6),
          Text(
            '${a['desc'] ?? ''}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '${_subjName(subj)}, clasa a ${_roman['${a['grade']}'] ?? a['grade']}-a, ${_minutes(a)} min',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Pb.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PbButton(
            text: read ? 'Recitește' : 'Citește',
            icon: Icons.arrow_forward,
            size: PbSize.sm,
            onPressed: () => _cOpen(a),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- filters
  Widget _cChip(String label, bool sel, VoidCallback onTap, {int? count, Color? color, IconData? icon}) {
    final accent = color ?? Pb.link;
    return _RHover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
            if (icon != null) ...[
              Icon(icon, size: 15, color: sel ? accent : Pb.muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? accent : Pb.text),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text('$count', style: TextStyle(fontSize: 12, color: Pb.muted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cFilters(
    List<Map<String, dynamic>> all,
    List<String> subjects,
    List<Map<String, dynamic>> inGrade,
    bool isMobile,
  ) {
    int countGrade(String g) => all.where((a) => '${a['grade']}' == g).length;
    int countSubj(String s) => inGrade.where((a) => _subj(a) == s).length;

    Widget seg(String g) {
      final sel = _cGrade == g;
      return _RHover(
        onTap: () => setState(() => _cGrade = g),
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
              Text(
                'a ${_roman[g]}-a',
                style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted),
              ),
              const SizedBox(width: 6),
              Text('${countGrade(g)}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ),
      );
    }

    final toggle = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [for (final g in const ['9', '10', '11', '12']) seg(g)]),
    );

    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _cChip('Toate materiile', _cSubject == 'toate', () => setState(() => _cSubject = 'toate'), count: inGrade.length),
        for (final s in subjects)
          _cChip(_subjName(s), _cSubject == s, () => setState(() => _cSubject = s), count: countSubj(s), color: _subjColor(s)),
        Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 4), color: Pb.border),
        _cChip('Doar necitite', _cUnread, () => setState(() => _cUnread = !_cUnread), icon: Icons.mark_email_unread_outlined),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cDeco(r: 14),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: toggle)),
                const SizedBox(height: 10),
                chips,
              ],
            )
          : Row(children: [toggle, const SizedBox(width: 16), Expanded(child: chips)]),
    );
  }

  // ---------------------------------------------------------------- table of contents
  Widget _cToc(Map<String, List<Map<String, dynamic>>> groups) {
    final entries = groups.entries.toList();
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
                Icon(Icons.toc, size: 19, color: Pb.muted),
                const SizedBox(width: 8),
                Expanded(child: Text('Cuprins', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text))),
                Text('Clasa a ${_roman[_cGrade]}-a', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ],
            ),
          ),
          for (var i = 0; i < entries.length; i++)
            _RHover(
              onTap: () => _cScrollTo(entries[i].key),
              builder: (h) {
                final items = entries[i].value;
                final done = items.every((a) => _cRead.contains('${a['id']}'));
                final num = _chapterNum(entries[i].key) ?? '${i + 1}';
                final c = _groupColor(items);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: h ? c.withOpacity(0.06) : Colors.transparent,
                    border: Border(top: BorderSide(color: Pb.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: done ? _cGreen : c.withOpacity(0.14), shape: BoxShape.circle),
                        child: done
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : Text(num, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _chapterName(entries[i].key),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: h ? c : Pb.text, height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${items.length}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                    ],
                  ),
                );
              },
            ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(
              'Apasă pe un capitol ca să sari direct la el. Tasta / deschide căutarea.',
              style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cChapterChips(List<String> keys) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _cChip('${_chapterNum(keys[i]) ?? i + 1}. ${_chapterName(keys[i])}', false, () => _cScrollTo(keys[i])),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- chapters + lessons
  Widget _cModule(String key, List<Map<String, dynamic>> items, int order, bool isMobile) {
    final c = _groupColor(items);
    final num = _chapterNum(key) ?? '${order + 1}';
    final read = items.where((a) => _cRead.contains('${a['id']}')).length;
    final mins = items.fold<int>(0, (s, a) => s + _minutes(a));

    final head = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(num, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capitolul $num, ${items.length} ${items.length == 1 ? 'lecție' : 'lecții'}, $mins min',
                  style: TextStyle(fontSize: 12.5, color: Pb.muted),
                ),
                const SizedBox(height: 2),
                Text(_chapterName(key), style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$read/${items.length} deschise', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: items.isEmpty ? 0 : read / items.length,
                      minHeight: 5,
                      color: c,
                      backgroundColor: Pb.gray,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Container(
      key: _cKeys[key],
      clipBehavior: Clip.antiAlias,
      decoration: _cDeco(r: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          for (var i = 0; i < items.length; i++) _cLessonRow(items[i], i + 1, c, isMobile),
        ],
      ),
    );
  }

  Widget _cLessonRow(Map<String, dynamic> a, int index, Color c, bool isMobile) {
    final id = '${a['id']}';
    final read = _cRead.contains(id);
    final complete = ResourcesData.curatedLectures.containsKey(id);
    final tag = _tagName('${a['tag'] ?? 'Lecție'}');
    final time = '${_minutes(a)} min';

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: _cGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: _cGreen),
          SizedBox(width: 3),
          Text('Completă', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _cGreen)),
        ],
      ),
    );

    return _RHover(
      onTap: () => _cOpen(a),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: h ? c.withOpacity(0.05) : Colors.transparent,
          border: Border(
            top: BorderSide(color: Pb.border),
            left: BorderSide(color: h ? c : Colors.transparent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: read
                    ? const Icon(Icons.check_circle, size: 18, color: _cGreen)
                    : Text('$index', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${a['title'] ?? ''}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: h ? c : Pb.text, height: 1.35)),
                      if (complete) badge,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${a['desc'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 6),
                    Text('$tag, $time', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ],
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                    child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: Pb.muted),
                      const SizedBox(width: 4),
                      Text(time, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right, size: 18, color: h ? c : Pb.border),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cEmpty() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cDeco(r: 14),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 34, color: Pb.muted),
          const SizedBox(height: 10),
          Text('Nicio lecție nu se potrivește.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Pb.text)),
          const SizedBox(height: 4),
          Text(
            'Încearcă alt cuvânt, altă clasă sau toate materiile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Pb.muted),
          ),
          const SizedBox(height: 14),
          PbButton(text: 'Resetează filtrele', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _cReset),
        ],
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
  // RETRO — original layout (unchanged look)
  // ===========================================================================
  void _scrollToModule(String module) {
    final key = _moduleKeys[module];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  Widget _buildRetro(List<Map<String, dynamic>> allArticles, bool isMobile) {
    final filtered = allArticles.where((a) {
      final matchSubject = (a['subject']?.toString().toUpperCase() ?? '') == _selectedSubject;
      final matchGrade = (a['grade']?.toString() ?? '') == _selectedGrade;
      final matchQuery = _searchQuery.isEmpty ||
          (a['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (a['desc']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchSubject && matchGrade && matchQuery;
    }).toList();

    // Group by Module
    final Map<String, List<Map<String, dynamic>>> groupedModules = {};
    for (var art in filtered) {
      final mod = art['module']?.toString().toUpperCase() ?? "GENERAL";
      groupedModules.putIfAbsent(mod, () => []).add(art);
      _moduleKeys.putIfAbsent(mod, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 18 : 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderBanner(isMobile),
                        SizedBox(height: isMobile ? 18 : 24),
                        _buildSubjectSelector(isMobile),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildGradeSelector(isMobile),
                        SizedBox(height: isMobile ? 14 : 20),
                        _buildSearchBar(isMobile),
                        SizedBox(height: isMobile ? 22 : 32),
                        if (groupedModules.isEmpty)
                          _buildEmptyState(isMobile)
                        else if (!isMobile)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 280,
                                child: _buildChapterNavigator(groupedModules.keys.toList()),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: groupedModules.entries.map((entry) {
                                    return _buildModuleSection(entry.key, entry.value, isMobile);
                                  }).toList(),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildMobileChapterChips(groupedModules.keys.toList()),
                          const SizedBox(height: 18),
                          ...groupedModules.entries.map((entry) {
                            return _buildModuleSection(entry.key, entry.value, isMobile);
                          }),
                        ],
                        SizedBox(height: isMobile ? 24 : 48),
                        _buildFooter(isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterNavigator(List<String> modules) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: AppColors.ink, size: 20),
              const SizedBox(width: 8),
              Text(
                "CUPRINS CAPITOLE",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Apasă pe un capitol pentru a naviga direct la secțiune:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(height: 2, color: AppColors.border),
          const SizedBox(height: 14),
          ...modules.map((mod) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _scrollToModule(mod),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, color: AppColors.sunset, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mod,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  Widget _buildMobileChapterChips(List<String> modules) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modules.map((mod) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.cardBg,
              side: BorderSide(color: AppColors.border, width: 2),
              avatar: Icon(Icons.arrow_downward, size: 14, color: AppColors.ink),
              label: Text(
                mod,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              onPressed: () => _scrollToModule(mod),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.mustard,
      padding: isMobile ? 18 : 28,
      shadowOffset: isMobile ? 3.5 : 5.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: AppColors.ink,
                child: Text(
                  "THE GUILD CODEX // RESURSE & TEORIE",
                  style: TextStyle(
                    color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.sunset,
                child: const Text(
                  "2026 CURRICULUM",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            "COMPENDIU DE CUNOȘTINȚE",
            style: TextStyle(
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.w900,
              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Teorie structurată pe module, optimizată pentru învățare rapidă cu exemple interactive de cod. Selectează materia și clasa pentru a naviga prin capitole.",
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(bool isMobile) {
    final subjects = [
      {"name": "PYTHON", "label": "PYTHON", "icon": Icons.terminal, "color": AppColors.forest},
      {"name": "C++", "label": "C++", "icon": Icons.code, "color": AppColors.sky},
      {"name": "MATEMATICĂ", "label": "MATEMATICĂ", "icon": Icons.functions, "color": AppColors.sunset},
    ];

    return Row(
      children: subjects.map((sub) {
        final isSelected = _selectedSubject == sub['name'];
        final color = sub['color'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubject = sub['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: isSelected ? const Offset(1.5, 1.5) : Offset(isMobile ? 2.5 : 4, isMobile ? 2.5 : 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sub['icon'] as IconData,
                      size: isMobile ? 16 : 20,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        sub['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 11.5 : 14,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradeSelector(bool isMobile) {
    final grades = [
      {"grade": "9", "label": "CLASA A 9-A"},
      {"grade": "10", "label": "CLASA A 10-A"},
      {"grade": "11", "label": "CLASA A 11-A"},
      {"grade": "12", "label": "CLASA A 12-A"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: grades.map((g) {
          final isSelected = _selectedGrade == g['grade'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGrade = g['grade']!),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 7 : 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F))
                      : AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: isSelected ? const Offset(1, 1) : const Offset(2.5, 2.5),
                    ),
                  ],
                ),
                child: Text(
                  g['label']!,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
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
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.ink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
              cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
              decoration: InputDecoration(
                hintText: "CAUTĂ DUPĂ TITLU, TERMENI SAU LECȚIE...",
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: isMobile ? 11.5 : 13, fontWeight: FontWeight.bold),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: AppColors.ink, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModuleSection(String moduleTitle, List<Map<String, dynamic>> articles, bool isMobile) {
    return Container(
      key: _moduleKeys[moduleTitle],
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
                child: Text(
                  moduleTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(height: 2.5, color: AppColors.border),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: articles.map((article) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildArticleCard(article, isMobile),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, bool isMobile) {
    final rawColor = article['color'];
    final Color tagColor = rawColor is Color ? rawColor : AppColors.forest;
    final String author = '${article['author'] ?? ResourcesData.defaultAuthor}';
    final String date = '${article['date'] ?? ResourcesData.defaultDate}';
    final String readTime = '${article['readTime'] ?? "5 MIN"}';

    return GestureDetector(
      onTap: () => context.go('/resurse/${article['id']}'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.border, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: tagColor,
                  child: Text(
                    '${article['tag'] ?? 'DOCUMENTAȚIE'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      readTime,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${article['title'] ?? 'UNTITLED'}',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18.5,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${article['desc'] ?? ''}',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Container(height: 1.5, color: AppColors.border.withOpacity(0.4)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.mustard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        author.isNotEmpty ? author[0].toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "BY ${author.toUpperCase()}",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.event_note, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.menu_book, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              "NICIUN ARTICOL PENTRU ACEASTĂ CONFIGURAȚIE.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: isMobile ? 13 : 15),
            ),
            const SizedBox(height: 6),
            Text(
              "Schimbă clasa sau materia din filtrele de mai sus.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 24 : 36),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII // CODEX',
              style: TextStyle(
                fontSize: isMobile ? 20 : 26,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MASTER YOUR KNOWLEDGE • REPUTATION REWARDED.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// small helpers (Clean)
// =============================================================================
class _RHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _RHover({required this.builder, this.onTap});

  @override
  State<_RHover> createState() => _RHoverState();
}

class _RHoverState extends State<_RHover> {
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

class _RReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _RReveal({required this.child, this.delayMs = 0});

  @override
  State<_RReveal> createState() => _RRevealState();
}

class _RRevealState extends State<_RReveal> with SingleTickerProviderStateMixin {
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