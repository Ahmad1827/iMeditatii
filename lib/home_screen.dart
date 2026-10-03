import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
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
  }

  @override
  void dispose() {
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
  String _hGrade = 'toate';
  String _hSubject = 'toate';
  String _hQuery = '';
  int _hLimit = 15;
  int _hOpenPost = -1;
  List<Map<String, dynamic>>? _hExercises;
  Set<String> _hSolved = {};
  List<Map<String, dynamic>>? _hPosts;
  List<Map<String, dynamic>>? _hLeaders;
  bool _hLeadersError = false;

  static const Map<String, String> _hRoman = {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'};

  Widget _buildClean(bool isMobile) {
    if (!_hStarted) {
      _hStarted = true;
      Future.microtask(_hLoadAll);
    }

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PbContainer(child: _hWelcome(isMobile)),
                    const SizedBox(height: 24),
                    PbContainer(child: _hCatalog(isMobile)),
                    const SizedBox(height: 24),
                    PbContainer(
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [_hLeaderboard(), const SizedBox(height: 16), _hPostsCard()],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _hPostsCard()),
                                const SizedBox(width: 24),
                                SizedBox(width: 340, child: _hLeaderboard()),
                              ],
                            ),
                    ),
                    const SizedBox(height: 48),
                    _hFooter(isMobile),
                  ],
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
  BoxDecoration get _hCardDeco =>
      BoxDecoration(color: Pb.surface, borderRadius: Pb.radius, border: Border.all(color: Pb.border));

  Widget _hLoading(String text) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 14, color: Pb.muted)),
          ],
        ),
      );

  Widget _hChip(String label, bool sel, VoidCallback onTap) => _HHover(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? Pb.text : (h ? Pb.hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sel ? Pb.text : Pb.border),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Pb.surface : Pb.text)),
        ),
      );

  // ---------------------------------------------------------------- welcome
  Widget _hWelcome(bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    final first = (user?.displayName ?? '').trim().split(' ').first;
    final title = user == null
        ? 'Exersează pentru Bacalaureat'
        : (first.isEmpty ? 'Bine ai revenit' : 'Bine ai revenit, $first');
    final rank = _completedQuests > 10 ? 'Avansat' : (_completedQuests > 3 ? 'Intermediar' : 'Începător');
    final inLevel = _completedQuests % 5 == 0 && _completedQuests > 0 ? 5 : _completedQuests % 5;

    Widget tile({required String label, IconData? icon, required Widget value, Widget? footer, VoidCallback? onTap}) => _HHover(
          onTap: onTap,
          builder: (h) => Container(
            width: isMobile ? double.infinity : 190,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Pb.surface,
              borderRadius: Pb.radius,
              border: Border.all(color: h && onTap != null ? Pb.primary : Pb.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[Icon(icon, size: 15, color: Pb.muted), const SizedBox(width: 6)],
                    Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Pb.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                value,
                if (footer != null) ...[const SizedBox(height: 6), footer],
              ],
            ),
          ),
        );

    final tiles = [
      tile(
        label: 'Probleme rezolvate',
        icon: Icons.check_circle_outline,
        value: Text(_isLoadingStats ? '–' : '$_completedQuests',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Pb.text)),
        footer: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _progressValue, minHeight: 4, backgroundColor: Pb.gray, color: Pb.primary),
        ),
      ),
      tile(
        label: 'Nivel',
        icon: Icons.trending_up,
        value: Text(rank, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Pb.text)),
        footer: Text('$inLevel din 5 spre următorul', style: TextStyle(fontSize: 12, color: Pb.muted)),
      ),
      tile(
        label: 'Problema zilei',
        icon: Icons.today_outlined,
        value: Text('Informatică, a IX-a', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
        footer: Text('Rezolvă acum', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Pb.link)),
        onTap: _startDailyQuest,
      ),
    ];

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text(
          'Probleme cu evaluare automată și lecții pe programa de liceu, clasele IX–XII.',
          style: TextStyle(fontSize: 15, color: Pb.muted, height: 1.5),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          intro,
          const SizedBox(height: 16),
          for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const SizedBox(height: 10), tiles[i]],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: intro),
        const SizedBox(width: 20),
        for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const SizedBox(width: 12), tiles[i]],
      ],
    );
  }

  // ---------------------------------------------------------------- catalog
  Widget _hCatalog(bool isMobile) {
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

    void switchTo(bool lessons) => setState(() {
          _hShowLessons = lessons;
          _hSubject = 'toate';
          _hLimit = 15;
        });

    Widget seg(String label, int count, bool sel, VoidCallback onTap) => _HHover(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? Pb.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
                const SizedBox(width: 6),
                Text('$count', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ],
            ),
          ),
        );

    final toggle = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Exerciții', exercises.length, !_hShowLessons, () => switchTo(false)),
          seg('Lecții', lessonsAll.length, _hShowLessons, () => switchTo(true)),
        ],
      ),
    );

    final search = SizedBox(
      width: isMobile ? double.infinity : 250,
      child: TextField(
        onChanged: (v) => setState(() {
          _hQuery = v;
          _hLimit = 15;
        }),
        style: TextStyle(fontSize: 14, color: Pb.text),
        cursorColor: Pb.text,
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
        for (final s in subjects) _hChip(s, _hSubject == s, () => setState(() => _hSubject = s)),
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
                    SizedBox(width: 36, child: Text('', style: headStyle)),
                    SizedBox(width: 44, child: Text('#', style: headStyle)),
                    Expanded(child: Text('Titlu', style: headStyle)),
                    SizedBox(width: 130, child: Text('Materie', style: headStyle)),
                    SizedBox(width: 90, child: Text('Dificultate', style: headStyle)),
                    SizedBox(width: 70, child: Text('Tip', style: headStyle)),
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
      rows = [for (var i = 0; i < shown; i++) _hExerciseRow(exRows[i], isMobile)];
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _hCardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  Align(alignment: Alignment.centerLeft, child: toggle),
                  const SizedBox(height: 10),
                  search,
                ] else
                  Row(children: [toggle, const Spacer(), search]),
                const SizedBox(height: 12),
                filters,
              ],
            ),
          ),
          if (tableHead != null) tableHead,
          ...rows,
          if (total > 0)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text('Afișate $shown din $total', style: TextStyle(fontSize: 13, color: Pb.muted))),
                  if (total > shown)
                    PbButton(
                      text: 'Arată mai multe',
                      variant: PbVariant.outlineSecondary,
                      size: PbSize.sm,
                      onPressed: () => setState(() => _hLimit += 15),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hExerciseRow(Map<String, dynamic> e, bool isMobile) {
    final key = '${e['subject']}_${e['grade']}_${e['id']}';
    final solved = _hSolved.contains(key);
    final diff = (e['difficulty'] ?? '').toString();
    final dl = diff.toLowerCase();
    final Color diffColor = dl.startsWith('u') || dl.startsWith('e')
        ? const Color(0xFF00A67E)
        : dl.startsWith('m')
            ? const Color(0xFFD99A00)
            : (dl.startsWith('g') || dl.startsWith('h') || dl.startsWith('d'))
                ? const Color(0xFFE5484D)
                : Pb.muted;
    final kind = e['kind'] == 'grila' ? 'Grilă' : (e['kind'] == 'text' ? 'Răspuns' : 'Cod');
    final grade = '${e['grade']}';

    void open() => context.go(
        '/exercitiu/${e['id']}?materie=${Uri.encodeComponent('${e['subject']}')}&clasa=${Uri.encodeComponent(grade)}');

    return _HHover(
      onTap: open,
      builder: (h) => Container(
        decoration: BoxDecoration(
          color: h ? Pb.hoverBg : Colors.transparent,
          border: Border(top: BorderSide(color: Pb.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(solved ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18, color: solved ? Pb.success : Pb.border),
            ),
            if (!isMobile) SizedBox(width: 44, child: Text('${e['id']}', style: TextStyle(fontSize: 13.5, color: Pb.muted))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e['title']}',
                    maxLines: isMobile ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: h ? Pb.link : Pb.text),
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
                child: Text('${e['subject']}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: Pb.text)),
              ),
              SizedBox(
                width: 90,
                child: Text(diff.isEmpty ? '–' : AppStyle.sentence(diff),
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: diffColor)),
              ),
              SizedBox(width: 70, child: Text(kind, style: TextStyle(fontSize: 13, color: Pb.muted))),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- posts
  Widget _hPostsCard() {
    final posts = _hPosts;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _hCardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, size: 18, color: Pb.primary),
                const SizedBox(width: 8),
                Text('Noutăți', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
              ],
            ),
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
    final open = _hOpenPost == i;
    final link = p['link'] as String?;
    final date = '${p['date'] ?? ''}';
    final author = '${p['author'] ?? ''}';

    return _HHover(
      onTap: () => setState(() => _hOpenPost = open ? -1 : i),
      builder: (h) => Container(
        decoration: BoxDecoration(
          color: h ? Pb.hoverBg : Colors.transparent,
          border: Border(top: BorderSide(color: Pb.border)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('${p['title']}', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Pb.text))),
                Icon(open ? Icons.expand_less : Icons.expand_more, size: 20, color: Pb.muted),
              ],
            ),
            const SizedBox(height: 3),
            Text(date.isEmpty ? author : '$author, $date', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            const SizedBox(height: 8),
            Text(
              '${p['body']}',
              maxLines: open ? null : 2,
              overflow: open ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Pb.text, height: 1.55),
            ),
            if (open && link != null && link.isNotEmpty) ...[
              const SizedBox(height: 10),
              PbLink(text: 'Deschide', fontSize: 14, onTap: () => context.go(link)),
            ],
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _hCardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 18, color: Color(0xFFD99A00)),
                const SizedBox(width: 8),
                Expanded(child: Text('Clasament elevi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text))),
                Text('rezolvate', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ],
            ),
          ),
          body,
        ],
      ),
    );
  }

  Widget _hLeaderRow(int i, Map<String, dynamic> u, bool isMe) {
    const medals = [Color(0xFFE6B422), Color(0xFFA8B0B8), Color(0xFFCD7F32)];
    final name = '${u['name']}'.trim();
    final photo = '${u['photo']}';
    final initials = name.isEmpty
        ? '?'
        : name.split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return _HHover(
      onTap: () => context.go('/elev/${u['uid']}'),
      builder: (h) => Container(
        decoration: BoxDecoration(
          color: isMe ? Pb.primary.withOpacity(0.08) : (h ? Pb.hoverBg : Colors.transparent),
          border: Border(top: BorderSide(color: Pb.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: i < 3
                    ? Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: medals[i], shape: BoxShape.circle),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      )
                    : Text('${i + 1}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.muted)),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Pb.primary.withOpacity(0.15),
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              onBackgroundImageError: photo.isNotEmpty ? (_, __) {} : null,
              child: photo.isEmpty
                  ? Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Pb.primary))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMe ? '$name (tu)' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: h ? Pb.link : Pb.text),
              ),
            ),
            Text('${u['count']}', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Pb.text)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- footer
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
    final color = subject == 'Matematică'
        ? const Color(0xFFE5484D)
        : (subject == 'Python' ? const Color(0xFF3B82F6) : Pb.primary);
    final readTime = (d['readTime'] ?? '').toString().toLowerCase();
    final grade = d['grade'].toString();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _hover ? Pb.hoverBg : Colors.transparent,
            border: Border(top: BorderSide(color: Pb.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text('${widget.index}', style: TextStyle(fontSize: 13.5, color: Pb.muted))),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['title'].toString(),
                      maxLines: widget.isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: _hover ? Pb.link : Pb.text),
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
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
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
