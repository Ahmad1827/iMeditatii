import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart';
import 'resources_data.dart';
import 'ui_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _completedQuests = 0;
  bool _isLoadingStats = true;
  bool _showNotice = true;
  String _grade = '9';

  // Progress keys look like "<materie>_<clasa>_<id>" (see ExerciseDetailScreen).
  static final RegExp _progressKey = RegExp(r'^.+_\d+_.+$');

  @override
  void initState() {
    super.initState();
    _loadPlayerStats();
    _hFactTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _hFactIdx++);
    });
  }

  @override
  void dispose() {
    _hFactTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // prefs.get(), not getBool(): getBool throws on String values (e.g. 'app_style').
      final completed = prefs.getKeys().where((k) => _progressKey.hasMatch(k) && prefs.get(k) == true).length;
      if (!mounted) return;
      setState(() {
        _completedQuests = completed;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint("Error loading stats: $e");
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _startDailyQuest() {
    const exerciseId = '1';
    final encodedMaterie = Uri.encodeComponent('Informatică');
    final encodedClasa = Uri.encodeComponent('9');
    context.go('/exercitiu/$exerciseId?materie=$encodedMaterie&clasa=$encodedClasa');
  }

  void _openSubject(String route) {
    context.go('/lista-exercitii?materie=${Uri.encodeComponent(route)}');
  }

  double get _progressValue =>
      (_completedQuests % 5) / 5.0 == 0 && _completedQuests > 0 ? 1.0 : (_completedQuests % 5) / 5.0;

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        return s.isClean
            ? _buildClean(MediaQuery.of(context).size.width < 900)
            : _buildRetro(MediaQuery.of(context).size.width < 880);
      },
    );
  }

  // ===========================================================================
  // CLEAN — home: welcome, catalog (exerciții/lecții), noutăți + clasament
  // ===========================================================================
  bool _hStarted = false;
  bool _hShowLessons = false;
  bool _hShowLeaders = false;
  final GlobalKey _hTopKey = GlobalKey();
  final GlobalKey _hMainKey = GlobalKey();
  final GlobalKey _hFootKey = GlobalKey();
  String _hGrade = 'toate';
  String _hSubject = 'toate';
  String _hQuery = '';
  int _hLimit = 6;
  int _hOpenPost = -1;
  List<Map<String, dynamic>>? _hExercises;
  Set<String> _hSolved = {};
  List<Map<String, dynamic>>? _hPosts;
  List<Map<String, dynamic>>? _hLeaders;
  bool _hLeadersError = false;
  bool _hCardsHidden = false;
  int _hFactIdx = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
  Timer? _hFactTimer;

  void _hNextFact() {
    _hFactTimer?.cancel();
    setState(() => _hFactIdx++);
    _hFactTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _hFactIdx++);
    });
  }

  static const Map<String, String> _hRoman = {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'};

  Widget _buildClean(bool isMobile) {
    if (!_hStarted) {
      _hStarted = true;
      Future.microtask(_hLoadAll);
    }

    final catalog = _HReveal(
      delayMs: 140,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        offset: _hCardsHidden ? const Offset(-3.2, 0) : Offset.zero,
        child: IgnorePointer(ignoring: _hCardsHidden, child: _hCatalog(isMobile)),
      ),
    );
    final posts = _HReveal(
      delayMs: 200,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        offset: _hCardsHidden ? const Offset(3.2, 0) : Offset.zero,
        child: IgnorePointer(ignoring: _hCardsHidden, child: _hPostsCard()),
      ),
    );

    Widget box(double max, Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
              child: child,
            ),
          ),
        );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              blockers: [_hTopKey, if (!_hCardsHidden) _hMainKey, _hFootKey],
              cardsHidden: _hCardsHidden,
              onToggleCards: () => setState(() => _hCardsHidden = !_hCardsHidden),
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isMobile ? 24 : 44),
                      box(760, KeyedSubtree(key: _hTopKey, child: _HReveal(child: _hWelcome(isMobile)))),
                      SizedBox(height: isMobile ? 24 : 36),
                      box(
                        1320,
                        KeyedSubtree(
                          key: _hMainKey,
                          child: LayoutBuilder(
                            builder: (context, b) => (isMobile || b.maxWidth < 900)
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [catalog, const SizedBox(height: 20), posts],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 6, child: catalog),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 5, child: posts),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      KeyedSubtree(key: _hFootKey, child: _hFooter(isMobile)),
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
  // ---------------------------------------------------------------- data
  Future<void> _hLoadAll() async {
    await Future.wait([_hLoadExercises(), _hLoadPosts(), _hLoadLeaders()]);
  }

  Future<void> _hLoadExercises() async {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void add(String subject, String grade, String id, Map ex) {
      final key = '${subject}_${grade}_$id';
      if (!seen.add(key)) return;
      out.add({
        'subject': subject,
        'grade': grade,
        'id': id,
        'title': '${ex['title'] ?? 'Problema $id'}',
        'kind': ex['tip_exercitiu']?.toString() ?? (ex['raspuns_corect'] != null ? 'text' : 'cod'),
        'difficulty': (ex['dificultate'] ?? ex['difficulty'])?.toString(),
      });
    }

    try {
      final raw = json.decode(await rootBundle.loadString('assets/data/exercise_details.json'));
      if (raw is Map) {
        raw.forEach((subject, grades) {
          if (grades is! Map) return;
          grades.forEach((grade, items) {
            if (items is! Map) return;
            items.forEach((id, ex) {
              if (ex is Map) add('$subject', '$grade', '$id', ex);
            });
          });
        });
      }
    } catch (e) {
      debugPrint('Exercises (json): $e');
    }

    try {
      final snap = await FirebaseFirestore.instance.collection('exercises').limit(200).get();
      for (final d in snap.docs) {
        final m = d.data();
        if (m['title'] == null) continue;
        add('${m['materie'] ?? m['subject'] ?? 'Informatică'}', '${m['clasa'] ?? m['grade'] ?? '9'}', d.id, m);
      }
    } catch (e) {
      debugPrint('Exercises (firestore): $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final solved = prefs.getKeys().where((k) => prefs.get(k) == true).toSet();
    if (mounted) {
      setState(() {
        _hExercises = out;
        _hSolved = solved;
      });
    }
  }

  Future<void> _hLoadPosts() async {
    var posts = <Map<String, dynamic>>[];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      posts = snap.docs
          .map((d) {
            final m = d.data();
            final ts = m['createdAt'];
            final dt = ts is Timestamp ? ts.toDate() : null;
            return <String, dynamic>{
              'title': '${m['title'] ?? ''}',
              'body': '${m['body'] ?? ''}',
              'author': '${m['author'] ?? 'Echipa iMeditații'}',
              'date': dt == null
                  ? ''
                  : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
              'link': m['link']?.toString(),
            };
          })
          .where((p) => (p['title'] as String).isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Posts: $e');
    }

    if (posts.isEmpty) {
      posts = [
        {
          'title': 'Lecții noi pentru clasele IX–XII',
          'body': 'Am adăugat lecții de Python, C++ și matematică, organizate pe clase și module după programa de liceu. '
              'Fiecare lecție are exemple de cod și greșelile care apar cel mai des la Bacalaureat.',
          'author': ResourcesData.defaultAuthor,
          'date': ResourcesData.defaultDate,
          'link': '/resurse',
        },
        {
          'title': 'Probleme cu evaluare automată',
          'body': 'Scrii soluția direct în browser, iar codul e rulat pe teste. '
              'Vezi imediat ce teste au trecut și ce rezultat era așteptat.',
          'author': ResourcesData.defaultAuthor,
          'date': ResourcesData.defaultDate,
          'link': '/exercitii',
        },
        {
          'title': 'Clasamentul elevilor',
          'body': 'Fiecare problemă rezolvată cât ești autentificat intră în clasament. Profilul tău apare acolo cu numărul de probleme rezolvate.',
          'author': ResourcesData.defaultAuthor,
          'date': ResourcesData.defaultDate,
          'link': null,
        },
      ];
    }
    if (mounted) setState(() => _hPosts = posts);
  }

  Future<void> _hLoadLeaders() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('solvedCount', descending: true)
          .limit(25)
          .get();
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final m = d.data();
        if (m['role'] == 'teacher') continue;
        final count = (m['solvedCount'] as num?)?.toInt() ?? 0;
        if (count <= 0) continue;
        list.add({
          'uid': d.id,
          'name': (m['name'] ?? m['fullName'] ?? m['displayName'] ?? m['nume'] ?? 'Elev').toString(),
          'photo': (m['photoUrl'] ?? m['avatarUrl'] ?? m['photo'] ?? '').toString(),
          'count': count,
        });
        if (list.length == 10) break;
      }
      if (mounted) setState(() => _hLeaders = list);
    } catch (e) {
      debugPrint('Leaderboard: $e');
      if (mounted) {
        setState(() {
          _hLeaders = [];
          _hLeadersError = true;
        });
      }
    }
  }

  // ---------------------------------------------------------------- helpers
  static const Color _cGreen = Color(0xFF10B981);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cRose = Color(0xFFE5484D);
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cGold = Color(0xFFE6B422);
  static const Color _cViolet = Color(0xFF8B5CF6);
  static const Color _cTeal = Color(0xFF14B8A6);

  Color _hSubjectColor(String s) => _hSubjColor(s);

  Color _hDiffColor(String d) {
    final l = d.toLowerCase();
    if (l.startsWith('u') || l.startsWith('e')) return _cGreen;
    if (l.startsWith('m')) return _cAmber;
    if (l.startsWith('g') || l.startsWith('h') || l.startsWith('d')) return _cRose;
    return Pb.muted;
  }

  // Card with a thin gradient strip on top. On hover the border and the
  // shadow pick up the card's accent colour.
  Widget _hCard({required List<Color> accent, required Widget child}) => _HHover(
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: h ? accent.first.withOpacity(0.45) : Pb.border.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: h
                    ? accent.first.withOpacity(AppColors.isDark ? 0.20 : 0.16)
                    : Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06),
                blurRadius: h ? 34 : 24,
                offset: Offset(0, h ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: accent))),
              child,
            ],
          ),
        ),
      );

  Widget _hCardHeader(IconData icon, Color color, String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 18, 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Pb.text))),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _hLoading(String text) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _cGreen)),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 14, color: Pb.muted)),
          ],
        ),
      );

  // Filter chip. Subject chips carry their own colour (dot + tint).
  Widget _hChip(String label, bool sel, VoidCallback onTap, {Color? color}) {
    final c = color ?? Pb.link;
    return _HHover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? c.withOpacity(0.14) : (h ? c.withOpacity(0.07) : Colors.transparent),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? c.withOpacity(0.65) : (h ? c.withOpacity(0.45) : Pb.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: sel || h ? 8 : 6,
                height: sel || h ? 8 : 6,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel || h ? c : Pb.text),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- welcome
  Widget _hWelcome(bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    final first = (user?.displayName ?? '').trim().split(' ').first;
    final greeting = user == null
        ? 'Bun venit pe iMeditații'
        : (first.isEmpty ? 'Bine ai revenit' : 'Bine ai revenit, $first');
    final rank = _completedQuests > 10 ? 'Avansat' : (_completedQuests > 3 ? 'Intermediar' : 'Începător');
    final rankColor = _completedQuests > 10 ? _cViolet : (_completedQuests > 3 ? _cBlue : _cGreen);
    final inLevel = _completedQuests % 5 == 0 && _completedQuests > 0 ? 5 : _completedQuests % 5;

    final fact = _hFacts[_hFactIdx % _hFacts.length];

    // Soft wash of the card's colour in one corner; stronger on hover.
    BoxDecoration cardDeco(Color tint, bool h) => BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.alphaBlend(tint.withOpacity(h ? 0.14 : 0.07), Pb.surface), Pb.surface],
            stops: const [0, 0.6],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: h ? tint.withOpacity(0.5) : Pb.border.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: h
                  ? tint.withOpacity(AppColors.isDark ? 0.22 : 0.18)
                  : Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.07),
              blurRadius: h ? 36 : 28,
              offset: Offset(0, h ? 14 : 10),
            ),
          ],
        );

    final ringSize = isMobile ? 96.0 : 112.0;
    final ring = SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progressValue),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(
              value: v,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: rankColor.withOpacity(0.15),
              color: rankColor,
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _isLoadingStats ? 0 : _completedQuests.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '${v.round()}',
                style: TextStyle(fontSize: isMobile ? 32 : 40, fontWeight: FontWeight.w700, color: Pb.text, height: 1),
              ),
            ),
          ),
        ],
      ),
    );

    final info = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(greeting, style: TextStyle(fontSize: 14.5, color: Pb.muted)),
        const SizedBox(height: 4),
        Text(
          _completedQuests == 1 ? 'problemă rezolvată' : 'probleme rezolvate',
          style: TextStyle(fontSize: isMobile ? 26 : 30, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: rankColor.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
              child: Text(rank, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: rankColor)),
            ),
            Text('$inLevel din 5 spre nivelul următor', style: TextStyle(fontSize: 14, color: Pb.muted)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            PbButton(text: 'Problema zilei', icon: Icons.play_arrow, onPressed: _startDailyQuest),
            PbButton(text: 'Toate lecțiile', variant: PbVariant.outlineSecondary, onPressed: () => context.go('/resurse')),
          ],
        ),
      ],
    );

    Widget statCard(bool h) => AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
      padding: EdgeInsets.all(isMobile ? 22 : 26),
      decoration: cardDeco(rankColor, h),
      child: isMobile
          ? Column(children: [ring, const SizedBox(height: 18), info])
          : Row(children: [ring, const SizedBox(width: 28), Expanded(child: info)]),
    );

    Widget factCard(bool h) => AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: cardDeco(_cAmber, h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: h ? _cAmber : _cAmber.withOpacity(0.16),
              borderRadius: BorderRadius.circular(11),
              boxShadow: h ? [BoxShadow(color: _cAmber.withOpacity(0.45), blurRadius: 14)] : null,
            ),
            child: Icon(h ? Icons.lightbulb : Icons.lightbulb_outline, size: 20, color: h ? Colors.white : _cAmber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Știai că?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Pb.text)),
                    ),
                    for (var i = 0; i < _hFacts.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: i == _hFactIdx % _hFacts.length ? 14 : 5,
                        height: 5,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          color: i == _hFactIdx % _hFacts.length ? _cAmber : Pb.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Alt fapt',
                      icon: Icon(Icons.arrow_forward, size: 16, color: Pb.muted),
                      splashRadius: 16,
                      visualDensity: VisualDensity.compact,
                      onPressed: _hNextFact,
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, if (cur != null) cur]),
                  child: Text(
                    fact,
                    key: ValueKey(fact),
                    style: TextStyle(fontSize: 15, color: Pb.text, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_HHover(builder: statCard), const SizedBox(height: 16), _HHover(builder: factCard)],
    );
  }

  static const List<String> _hFacts = [
    'Cuvântul „algoritm” vine de la numele matematicianului persan al-Khwarizmi, care a trăit în secolul al IX-lea.',
    'Primul „bug” documentat a fost o molie reală, găsită în 1947 într-un releu al calculatorului Harvard Mark II.',
    'Algoritmul lui Euclid pentru cmmdc are peste 2.000 de ani și e folosit și azi, de exemplu în criptografie.',
    'Există exact 5 poliedre regulate: tetraedrul, cubul, octaedrul, dodecaedrul și icosaedrul.',
    'Numărul 1 nu este prim: un număr prim are exact doi divizori, pe 1 și pe el însuși.',
    'C++ a fost creat de Bjarne Stroustrup și s-a numit la început „C with Classes”.',
    'Python își ia numele de la grupul de comedie Monty Python, nu de la șarpe.',
    'Suma primelor n numere impare este n²: 1 + 3 + 5 + 7 = 16.',
    'Într-un grup de doar 23 de persoane, șansa ca două să aibă aceeași zi de naștere depășește 50%.',
    'Căutarea binară găsește un element într-un vector sortat de un milion de elemente în cel mult 20 de pași.',
  ];

  // ---------------------------------------------------------------- catalog
  Widget _hCatalog(bool isMobile) =>
      LayoutBuilder(builder: (context, box) => _hCatalogBody(isMobile, isMobile || box.maxWidth < 760));

  Widget _hCatalogBody(bool isMobile, bool compact) {
    final exercises = _hExercises ?? const <Map<String, dynamic>>[];
    final lessonsAll = ResourcesData.allArticles;
    final q = _hQuery.trim().toLowerCase();

    final Iterable<String> subjSrc = _hShowLessons
        ? lessonsAll.map((a) => AppStyle.sentence('${a['subject']}'))
        : exercises.map((e) => '${e['subject']}');
    final subjects = subjSrc.toSet().toList()..sort();

    bool matches(String subject, String grade, String text) =>
        (_hGrade == 'toate' || grade == _hGrade) &&
        (_hSubject == 'toate' || subject == _hSubject) &&
        (q.isEmpty || text.toLowerCase().contains(q));

    final lessonRows = lessonsAll
        .where((a) => matches(AppStyle.sentence('${a['subject']}'), '${a['grade']}', '${a['title']} ${a['desc']}'))
        .toList();
    final exRows = exercises.where((e) => matches('${e['subject']}', '${e['grade']}', '${e['title']}')).toList();
    final total = _hShowLessons ? lessonRows.length : exRows.length;
    final shown = total < _hLimit ? total : _hLimit;

    void switchTo(int tab) => setState(() {
          _hShowLessons = tab == 1;
          _hShowLeaders = tab == 2;
          _hSubject = 'toate';
          _hLimit = 6;
        });

    Widget seg(String label, IconData icon, int count, bool sel, Color c, VoidCallback onTap) => _HHover(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.6) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? c.withOpacity(0.4) : Colors.transparent),
              boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: sel || h ? c : Pb.muted),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel || h ? Pb.text : Pb.muted)),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: sel ? c.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? c : Pb.muted)),
                ),
              ],
            ),
          ),
        );

    final toggle = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Exerciții', Icons.code, exercises.length, !_hShowLessons && !_hShowLeaders, _cGreen, () => switchTo(0)),
          seg('Lecții', Icons.menu_book_outlined, lessonsAll.length, _hShowLessons, _cBlue, () => switchTo(1)),
          seg('Clasament', Icons.emoji_events_outlined, _hLeaders?.length ?? 0, _hShowLeaders, _cGold, () => switchTo(2)),
        ],
      ),
    );

    final search = SizedBox(
      width: (isMobile || compact) ? double.infinity : 250,
      child: TextField(
        onChanged: (v) => setState(() {
          _hQuery = v;
          _hLimit = 6;
        }),
        style: TextStyle(fontSize: 14, color: Pb.text),
        cursorColor: Pb.primary,
        decoration: Pb.input(hint: _hShowLessons ? 'Caută o lecție' : 'Caută o problemă').copyWith(
          prefixIcon: Icon(Icons.search, size: 18, color: Pb.muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
    );

    final filters = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _hChip('Toate clasele', _hGrade == 'toate', () => setState(() => _hGrade = 'toate')),
        for (final g in const ['9', '10', '11', '12'])
          _hChip('a ${_hRoman[g]}-a', _hGrade == g, () => setState(() => _hGrade = g)),
        Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6), color: Pb.border),
        _hChip('Toate materiile', _hSubject == 'toate', () => setState(() => _hSubject = 'toate')),
        for (final s in subjects)
          _hChip(s, _hSubject == s, () => setState(() => _hSubject = s), color: _hSubjectColor(s)),
      ],
    );

    final headStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted);
    final tableHead = isMobile
        ? null
        : Container(
            color: Pb.hoverBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _hShowLessons
                ? Row(children: [
                    SizedBox(width: 30, child: Text('#', style: headStyle)),
                    Expanded(child: Text('Titlu', style: headStyle)),
                    SizedBox(width: 110, child: Text('Materie', style: headStyle)),
                    SizedBox(width: 64, child: Text('Durată', textAlign: TextAlign.right, style: headStyle)),
                  ])
                : Row(children: [
                    const SizedBox(width: 36),
                    if (!compact) SizedBox(width: 44, child: Text('#', style: headStyle)),
                    Expanded(child: Text('Titlu', style: headStyle)),
                    SizedBox(width: 130, child: Text('Materie', style: headStyle)),
                    SizedBox(width: 90, child: Text('Dificultate', style: headStyle)),
                    if (!compact) SizedBox(width: 70, child: Text('Tip', style: headStyle)),
                  ]),
          );

    final List<Widget> rows;
    if (!_hShowLessons && _hExercises == null) {
      rows = [_hLoading('Se încarcă problemele...')];
    } else if (total == 0) {
      rows = [
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
          padding: const EdgeInsets.all(24),
          child: Text('Nimic nu se potrivește filtrelor.', style: TextStyle(fontSize: 14, color: Pb.muted)),
        ),
      ];
    } else if (_hShowLessons) {
      rows = [
        for (var i = 0; i < shown; i++)
          _HLessonRow(
            index: i + 1,
            data: lessonRows[i],
            isMobile: isMobile,
            onTap: () => context.go('/resurse/${lessonRows[i]['id']}'),
          ),
      ];
    } else {
      rows = [for (var i = 0; i < shown; i++) _hExerciseRow(exRows[i], isMobile, compact)];
    }

    final switchKey = '${_hShowLessons}_${_hGrade}_${_hSubject}_${_hExercises == null}';
    final extras = !_hShowLeaders;

    return _hCard(
      accent: const [_cGreen, _cTeal, _cBlue],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile || compact) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: toggle),
                  ),
                  if (extras) ...[const SizedBox(height: 10), search],
                ] else
                  Row(children: [toggle, const Spacer(), if (extras) search]),
                if (extras) ...[const SizedBox(height: 12), filters],
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, if (cur != null) cur]),
            child: _hShowLeaders
                ? KeyedSubtree(key: const ValueKey('leaders'), child: _hLeaderboardBody())
                : Column(
                    key: ValueKey(switchKey),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [if (tableHead != null) tableHead, ...rows],
                  ),
          ),
          if (!_hShowLeaders && total > 0)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _hShowLessons ? '$shown din $total lecții' : '$shown din $total probleme',
                      style: TextStyle(fontSize: 13, color: Pb.muted),
                    ),
                  ),
                  PbButton(
                    text: _hShowLessons ? 'Toate lecțiile' : 'Toate problemele',
                    icon: Icons.arrow_forward,
                    variant: PbVariant.outlinePrimary,
                    size: PbSize.sm,
                    onPressed: () => context.go(_hShowLessons ? '/resurse' : '/exercitii'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hLeaderboardBody() {
    final leaders = _hLeaders;
    final me = FirebaseAuth.instance.currentUser?.uid;

    Widget body;
    if (leaders == null) {
      body = _hLoading('Se încarcă clasamentul...');
    } else if (leaders.isEmpty) {
      body = Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
        padding: const EdgeInsets.all(20),
        child: Text(
          _hLeadersError
              ? 'Clasamentul nu poate fi încărcat acum.'
              : 'Încă nu e nimeni în clasament. Rezolvă o problemă și fii primul.',
          style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.5),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < leaders.length; i++) _hLeaderRow(i, leaders[i], leaders[i]['uid'] == me)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Text(
            'Fiecare problemă rezolvată cât ești autentificat te urcă în clasament.',
            style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _hExerciseRow(Map<String, dynamic> e, bool isMobile, bool compact) {
    final key = '${e['subject']}_${e['grade']}_${e['id']}';
    final solved = _hSolved.contains(key);
    final diff = (e['difficulty'] ?? '').toString();
    final dc = _hDiffColor(diff);
    final sc = _hSubjectColor('${e['subject']}');
    final kind = e['kind'] == 'grila' ? 'Grilă' : (e['kind'] == 'text' ? 'Răspuns' : 'Cod');
    final grade = '${e['grade']}';

    void open() => context.go(
        '/exercitiu/${e['id']}?materie=${Uri.encodeComponent('${e['subject']}')}&clasa=${Uri.encodeComponent(grade)}');

    return _HHover(
      onTap: open,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [sc.withOpacity(h ? 0.13 : 0), sc.withOpacity(h ? 0.02 : 0)]),
          border: Border(
            top: BorderSide(color: Pb.border),
            left: BorderSide(color: h ? sc : Colors.transparent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(
                solved ? Icons.check_circle : (h ? Icons.play_circle_outline : Icons.radio_button_unchecked),
                size: 18,
                color: solved ? _cGreen : (h ? sc : Pb.border),
              ),
            ),
            if (!compact)
              SizedBox(width: 44, child: Text('${e['id']}', style: TextStyle(fontSize: 13.5, color: h ? sc : Pb.muted))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e['title']}',
                    maxLines: isMobile ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: h ? sc : Pb.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMobile
                        ? '${e['subject']}, clasa a $grade-a${diff.isEmpty ? '' : ', ${AppStyle.sentence(diff)}'}'
                        : 'Clasa a ${_hRoman[grade] ?? grade}-a',
                    style: TextStyle(fontSize: 12.5, color: Pb.muted),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              SizedBox(
                width: 130,
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: h ? 10 : 7,
                          height: h ? 10 : 7,
                          decoration: BoxDecoration(color: sc, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${e['subject']}',
                          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: Pb.text)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: diff.isEmpty
                      ? Text('–', style: TextStyle(fontSize: 13.5, color: Pb.muted))
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: dc.withOpacity(h ? 0.24 : 0.14), borderRadius: BorderRadius.circular(999)),
                          child: Text(AppStyle.sentence(diff),
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: dc)),
                        ),
                ),
              ),
              if (!compact) SizedBox(width: 70, child: Text(kind, style: TextStyle(fontSize: 13, color: Pb.muted))),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- posts
  Widget _hPostsCard() {
    final posts = _hPosts;
    return _hCard(
      accent: const [_cAmber, _cRose, _cViolet],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hCardHeader(
            Icons.forum_outlined,
            _cAmber,
            'Postări',
            trailing: Text(posts == null ? '' : '${posts.length} postări', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Anunțuri și articole de la echipa iMeditații.', style: TextStyle(fontSize: 13, color: Pb.muted)),
          ),
          if (posts == null)
            _hLoading('Se încarcă noutățile...')
          else
            for (var i = 0; i < posts.length; i++) _hPostRow(i, posts[i]),
        ],
      ),
    );
  }

  Widget _hPostRow(int i, Map<String, dynamic> p) {
    final c = const [_cAmber, _cBlue, _cViolet, _cTeal, _cRose][i % 5];
    final open = _hOpenPost == i;
    final link = p['link'] as String?;
    final date = '${p['date'] ?? ''}';
    final author = '${p['author'] ?? ''}';

    return _HHover(
      onTap: () => setState(() => _hOpenPost = open ? -1 : i),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withOpacity(h || open ? 0.12 : 0), c.withOpacity(h || open ? 0.02 : 0)]),
          border: Border(
            top: BorderSide(color: Pb.border),
            left: BorderSide(color: h || open ? c : Colors.transparent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(13, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: h || open ? c : c.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                boxShadow: h || open ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 3))] : null,
              ),
              child: Icon(Icons.article_outlined, size: 19, color: h || open ? Colors.white : c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p['title']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: h || open ? c : Pb.text)),
                  const SizedBox(height: 3),
                  Text(date.isEmpty ? author : '$author, $date', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  const SizedBox(height: 7),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topLeft,
                    child: Text(
                      '${p['body']}',
                      maxLines: open ? null : 3,
                      overflow: open ? null : TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Pb.text, height: 1.55),
                    ),
                  ),
                  if (open && link != null && link.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    PbLink(text: 'Deschide', fontSize: 14, onTap: () => context.go(link)),
                  ],
                ],
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, size: 20, color: h || open ? c : Pb.muted),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- leaderboard
  Widget _hLeaderboard() {
    final leaders = _hLeaders;
    final me = FirebaseAuth.instance.currentUser?.uid;

    Widget body;
    if (leaders == null) {
      body = _hLoading('Se încarcă clasamentul...');
    } else if (leaders.isEmpty) {
      body = Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
        padding: const EdgeInsets.all(16),
        child: Text(
          _hLeadersError
              ? 'Clasamentul nu poate fi încărcat acum.'
              : 'Încă nu e nimeni în clasament. Rezolvă o problemă și fii primul.',
          style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.5),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < leaders.length; i++) _hLeaderRow(i, leaders[i], leaders[i]['uid'] == me)],
      );
    }

    return _hCard(
      accent: const [_cGold, _cAmber],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hCardHeader(
            Icons.emoji_events_outlined,
            const Color(0xFFD99A00),
            'Clasament elevi',
            trailing: Text('rezolvate', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
          ),
          body,
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text('Fiecare problemă rezolvată cât ești autentificat te urcă în clasament.',
                style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _hLeaderRow(int i, Map<String, dynamic> u, bool isMe) {
    const medals = [_cGold, Color(0xFFA8B0B8), Color(0xFFCD7F32)];
    final top = i < 3;
    final mc = top ? medals[i] : Pb.link;
    final name = '${u['name']}'.trim();
    final photo = '${u['photo']}';
    final initials = name.isEmpty
        ? '?'
        : name.split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return _HHover(
      onTap: () => context.go('/elev/${u['uid']}'),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isMe
              ? Pb.link.withOpacity(h ? 0.16 : 0.09)
              : top
                  ? mc.withOpacity(h ? 0.18 : 0.08)
                  : (h ? mc.withOpacity(0.08) : Colors.transparent),
          border: Border(
            top: BorderSide(color: Pb.border),
            left: BorderSide(color: h ? mc : Colors.transparent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(13, 10, 16, 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: top
                    ? Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mc,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      )
                    : Text('${i + 1}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.muted)),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: top || h ? mc : Colors.transparent, width: 2),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Pb.primary.withOpacity(0.15),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                onBackgroundImageError: photo.isNotEmpty ? (_, __) {} : null,
                child: photo.isEmpty
                    ? Text(initials, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Pb.primary))
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMe ? '$name (tu)' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: h ? mc : Pb.text),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: mc.withOpacity(h ? 0.3 : 0.16), borderRadius: BorderRadius.circular(999)),
              child: Text('${u['count']}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Pb.text)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _hFooter(bool isMobile) {
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
  Widget _buildRetro(bool isMobile) {
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
                child: Column(
                  children: [
                    _retroHero(isMobile),
                    _retroPaths(isMobile),
                    _retroMasters(isMobile),
                    SizedBox(height: isMobile ? 14 : 28),
                    _retroFooter(isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retroSection({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1120), child: child),
      ),
    );
  }

  Widget _retroHero(bool isMobile) {
    final heroInk = AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink;

    final leftContent = RetroBlock(
      bgColor: AppColors.mustard,
      padding: isMobile ? 18 : 36,
      shadowOffset: isMobile ? 3.5 : 6.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('SYSTEM OPERATIONAL',
                            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: isMobile ? 11 : 12, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: AppColors.sunset,
                    child: const Text("SEASON 1",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 14 : 20),
              Text(
                "LEVEL UP YOUR\nKNOWLEDGE.",
                style: TextStyle(fontSize: isMobile ? 26 : 48, fontWeight: FontWeight.w900, color: heroInk, height: 1.1, letterSpacing: 1.0),
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Text(
                "Alege o materie. Găsește un mentor verificat și rezolvă quest-uri interactive pentru a avansa în nivel.",
                style: TextStyle(fontSize: isMobile ? 14 : 17, color: heroInk, fontWeight: FontWeight.bold, height: 1.45),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 28),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RetroButton(
                  text: "FIND A MASTER",
                  icon: Icons.search,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  bgColor: AppColors.forest,
                  isFullWidth: true,
                  onPressed: () => context.go('/materii'),
                ),
                const SizedBox(height: 10),
                RetroButton(
                  text: "DAILY QUESTS",
                  icon: Icons.track_changes,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  isFullWidth: true,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            )
          else
            Row(
              children: [
                RetroButton(text: "FIND A MASTER", icon: Icons.search, bgColor: AppColors.forest, onPressed: () => context.go('/materii')),
                const SizedBox(width: 16),
                RetroButton(
                  text: "DAILY QUESTS",
                  icon: Icons.track_changes,
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            ),
        ],
      ),
    );

    final rightContent = RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 18 : 32,
      shadowOffset: isMobile ? 3.5 : 6.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("YOUR PROGRESS",
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: isMobile ? 14 : 16, letterSpacing: 1.2)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.sky, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(
                      _completedQuests > 10 ? "GOLD GUILD" : (_completedQuests > 3 ? "SILVER RANK" : "NOVICE"),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("QUESTS CLEARED", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12)),
                        _isLoadingStats
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text("$_completedQuests SOLVED",
                                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progressValue,
                      backgroundColor: AppColors.border.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("DAILY BOUNTY",
                      style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                  Icon(Icons.star, color: AppColors.mustard, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text("INFORMATICĂ // CLASA A 9-A",
                  style: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text("RECOMPENSĂ: +50 EXP // AUTO-CHECK",
                  style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          RetroButton(
            text: "ACCEPT BOUNTY",
            icon: Icons.play_arrow,
            bgColor: AppColors.sunset,
            isFullWidth: true,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: _startDailyQuest,
          ),
        ],
      ),
    );

    return _retroSection(
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, isMobile ? 16 : 36, isMobile ? 14 : 24, isMobile ? 16 : 28),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftContent, const SizedBox(height: 14), rightContent])
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: leftContent),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: rightContent),
                ],
              ),
            ),
    );
  }

  Widget _retroPaths(bool isMobile) {
    final List<Map<String, dynamic>> paths = [
      {"icon": Icons.functions, "title": "MATEMATICĂ", "color": AppColors.sunset, "desc": "ALGEBRĂ & GEOMETRIE", "route": "Matematică"},
      {"icon": Icons.data_object, "title": "INFORMATICĂ", "color": AppColors.forest, "desc": "ALGORITMI & C++", "route": "Informatică"},
      {"icon": Icons.language, "title": "LIMBI STRĂINE", "color": AppColors.sky, "desc": "ENGLEZĂ & ROMÂNĂ", "route": "Engleză"},
    ];

    final List<Widget> pathCards = paths.map((path) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: isMobile && path != paths.last ? 12 : 0,
          right: !isMobile && path != paths.last ? 20 : 0,
        ),
        child: GestureDetector(
          onTap: () => _openSubject(path["route"] as String),
          child: RetroBlock(
            bgColor: AppColors.cardBg,
            padding: isMobile ? 16 : 24,
            shadowOffset: isMobile ? 3.5 : 6.0,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 18),
                  decoration: BoxDecoration(
                    color: path["color"],
                    border: Border.all(color: AppColors.border, width: 2.5),
                    boxShadow: AppStyle.hardShadow(3),
                  ),
                  child: Icon(path["icon"], size: isMobile ? 26 : 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(path["title"], textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(path["desc"], textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return _retroSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 28, horizontal: isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("CHOOSE YOUR PATH", textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 22 : 34, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text("SELECTEAZĂ O DISCIPLINĂ PENTRU ANTRENAMENT.", textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 11 : 15, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          SizedBox(height: isMobile ? 18 : 24),
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: pathCards)
              : Row(children: pathCards.map((card) => Expanded(child: card)).toList()),
        ],
      ),
    );
  }

  Widget _retroMasters(bool isMobile) {
    final leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
          child: const Text("GUILD ROSTER",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10)),
        ),
        const SizedBox(height: 12),
        Text(isMobile ? "MEET THE MASTERS." : "MEET THE\nMASTERS.",
            style: TextStyle(fontSize: isMobile ? 24 : 40, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.1, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        Text("Mentori verificați gata să te ghideze 1-la-1 cu tablă interactivă live și conexiune securizată.",
            style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.ink, fontWeight: FontWeight.bold, height: 1.45)),
        SizedBox(height: isMobile ? 16 : 22),
        RetroButton(
          text: "EXPLOREAZĂ PROFESORII",
          icon: Icons.groups,
          bgColor: AppColors.sunset,
          isFullWidth: isMobile,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          onPressed: () => context.go('/materii'),
        ),
      ],
    );

    Widget avatar(IconData icon, String label, Color color) => Container(
          decoration: BoxDecoration(color: color, border: Border.all(color: AppColors.border, width: 2.5), boxShadow: AppStyle.hardShadow(3)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: AppColors.isDark && color == AppColors.mustard ? const Color(0xFF10161A) : Colors.white),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.ink,
                child: Text(label,
                    style: TextStyle(
                        color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
              ),
            ],
          ),
        );

    final rightContent = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isMobile ? 1.25 : 1.1,
      children: [
        avatar(Icons.calculate, "MATH", AppColors.sky),
        avatar(Icons.terminal, "CODE", AppColors.mustard),
        avatar(Icons.bolt, "PHYSICS", AppColors.forest),
        avatar(Icons.science, "CHEM", AppColors.sunset),
      ],
    );

    return _retroSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 36, horizontal: isMobile ? 14 : 24),
      child: RetroBlock(
        bgColor: AppColors.cloud,
        padding: isMobile ? 16 : 36,
        shadowOffset: isMobile ? 3.5 : 6.0,
        child: isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftContent, const SizedBox(height: 20), rightContent])
            : Row(children: [Expanded(child: leftContent), const SizedBox(width: 36), Expanded(child: rightContent)]),
      ),
    );
  }

  Widget _retroFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 26 : 44),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text('IMEDITATII // GUILD',
                style: TextStyle(fontSize: isMobile ? 22 : 32, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            const SizedBox(height: 6),
            Text('SYSTEM LOG: LEVEL UP YOUR LEARNING IN 2026.', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// One colour per subject, shared by the exercise rows, lesson rows and chips.
Color _hSubjColor(String s) {
  final l = s.toLowerCase();
  if (l.startsWith('mat')) return const Color(0xFFE5484D); // rose
  if (l.contains('python')) return const Color(0xFF3B82F6); // blue
  if (l.contains('c++') || l.contains('info')) return const Color(0xFF8B5CF6); // violet
  if (l.contains('engl') || l.contains('limb') || l.contains('rom')) return const Color(0xFF14B8A6); // teal
  return const Color(0xFFF59E0B); // amber
}

class _HLessonRow extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool isMobile;
  final VoidCallback onTap;

  const _HLessonRow({required this.index, required this.data, required this.isMobile, required this.onTap});

  @override
  State<_HLessonRow> createState() => _HLessonRowState();
}

class _HLessonRowState extends State<_HLessonRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final subject = AppStyle.sentence(d['subject'].toString());
    final color = _hSubjColor(subject);
    final readTime = (d['readTime'] ?? '').toString().toLowerCase();
    final grade = d['grade'].toString();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(_hover ? 0.13 : 0), color.withOpacity(_hover ? 0.02 : 0)]),
            border: Border(
              top: BorderSide(color: Pb.border),
              left: BorderSide(color: _hover ? color : Colors.transparent, width: 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text('${widget.index}', style: TextStyle(fontSize: 13.5, color: _hover ? color : Pb.muted))),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['title'].toString(),
                      maxLines: widget.isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: _hover ? color : Pb.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isMobile ? '$subject, clasa a $grade-a, $readTime' : 'Clasa a $grade-a',
                      style: TextStyle(fontSize: 12.5, color: Pb.muted),
                    ),
                  ],
                ),
              ),
              if (!widget.isMobile) ...[
                SizedBox(
                  width: 110,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(_hover ? 0.22 : 0.12), borderRadius: BorderRadius.circular(999)),
                      child: Text(subject, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: color)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(readTime, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, color: Pb.muted)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _HHover({required this.builder, this.onTap});

  @override
  State<_HHover> createState() => _HHoverState();
}

class _HHoverState extends State<_HHover> {
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

class _HReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _HReveal({required this.child, this.delayMs = 0});

  @override
  State<_HReveal> createState() => _HRevealState();
}

class _HRevealState extends State<_HReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
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

class _HGridPaper extends CustomPainter {
  final Color minor;
  final Color major;
  final double step;
  final int majorEvery;

  const _HGridPaper({required this.minor, required this.major, this.step = 24, this.majorEvery = 5});

  @override
  void paint(Canvas canvas, Size size) {
    final pMinor = Paint()
      ..color = minor
      ..strokeWidth = 1;
    final pMajor = Paint()
      ..color = major
      ..strokeWidth = 1;

    var i = 0;
    for (double x = 0; x <= size.width; x += step, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % majorEvery == 0 ? pMajor : pMinor);
    }
    i = 0;
    for (double y = 0; y <= size.height; y += step, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % majorEvery == 0 ? pMajor : pMinor);
    }
  }

  @override
  bool shouldRepaint(_HGridPaper old) => old.minor != minor || old.major != major || old.step != step;
}