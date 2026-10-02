import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // CLEAN — pbinfo-style homepage
  // ===========================================================================
  Widget _buildClean(bool isMobile) {
    final sidebar = [
      _cleanProgressCard(),
      const SizedBox(height: 20),
      _cleanDailyCard(),
      const SizedBox(height: 20),
      _cleanSubjectsCard(),
    ];

    final posts = [
      _PbPost(
        title: 'Lecții noi pentru clasele IX–XII',
        author: ResourcesData.defaultAuthor,
        date: ResourcesData.defaultDate,
        body: 'Am adăugat lecții de Python, C++ și matematică, organizate pe clase și module după programa de liceu. '
            'Fiecare lecție are exemple de cod și greșelile care apar cel mai des la Bacalaureat.',
        linkText: 'Vezi lecțiile',
        onLink: () => context.go('/resurse'),
      ),
      const SizedBox(height: 20),
      _PbPost(
        title: 'Probleme cu evaluare automată',
        author: ResourcesData.defaultAuthor,
        date: ResourcesData.defaultDate,
        body: 'Scrii soluția direct în browser, iar codul este compilat și rulat pe teste. '
            'Vezi imediat ce teste au trecut și ce rezultat era așteptat.',
        linkText: 'Începe să rezolvi',
        onLink: () => context.go('/exercitii'),
      ),
      const SizedBox(height: 20),
      _PbPost(
        title: 'Lecții 1-la-1 cu profesori verificați',
        author: ResourcesData.defaultAuthor,
        date: ResourcesData.defaultDate,
        body: 'Lucrezi cu profesorul pe tablă interactivă, prin apel video. '
            'Alege materia și vezi profesorii disponibili.',
        linkText: 'Vezi profesorii',
        onLink: () => context.go('/materii'),
      ),
    ];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cleanHero(isMobile),
                    if (_showNotice) _cleanNotice(),
                    const SizedBox(height: 32),
                    PbContainer(
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [...sidebar, const SizedBox(height: 20), ...posts],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 400,
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sidebar),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: posts),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 48),
                    _cleanFooter(isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanHero(bool isMobile) {
    return Container(
      color: Pb.hero,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 76),
      child: PbContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'iMeditații',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 42 : 62,
                fontWeight: FontWeight.w700,
                height: 1.05,
                shadows: [Shadow(color: Colors.black.withOpacity(0.35), offset: const Offset(2, 2))],
              ),
            ),
            SizedBox(height: isMobile ? 14 : 22),
            Text(
              'Aici înveți! Probleme, lecții și profesori pentru liceu.',
              style: TextStyle(color: Colors.white, fontSize: isMobile ? 20 : 30, fontWeight: FontWeight.w300, height: 1.3),
            ),
            SizedBox(height: isMobile ? 22 : 30),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PbButton(
                  text: 'Vezi problemele',
                  variant: PbVariant.light,
                  size: PbSize.lg,
                  onPressed: () => context.go('/exercitii'),
                ),
                PbButton(
                  text: 'Găsește un profesor',
                  variant: PbVariant.outlineLight,
                  size: PbSize.lg,
                  onPressed: () => context.go('/materii'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cleanNotice() {
    return Container(
      color: Pb.infoStrip,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Lecțiile pentru clasele IX–XII sunt disponibile în secțiunea Lecții.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Pb.infoStripText, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _showNotice = false),
              child: Icon(Icons.close, size: 22, color: Pb.infoStripText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanProgressCard() {
    final rank = _completedQuests > 10 ? 'Avansat' : (_completedQuests > 3 ? 'Intermediar' : 'Începător');
    final inLevel = _completedQuests % 5 == 0 && _completedQuests > 0 ? 5 : _completedQuests % 5;

    return PbCard(
      title: 'Progresul tău',
      footer: Text(
        'Progresul se salvează pe acest dispozitiv.',
        style: TextStyle(color: Pb.muted, fontSize: 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Probleme rezolvate', style: Pb.body())),
              _isLoadingStats
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('$_completedQuests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
            ],
          ),
          const SizedBox(height: 10),
          PbProgress(value: _progressValue, label: '$inLevel / 5'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Nivel', style: Pb.body())),
              PbBadge(text: rank, color: Pb.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cleanDailyCard() {
    return PbCard(
      title: 'Problema zilei',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PbBadge(text: '#1', color: Pb.primary, fontSize: 13),
              const SizedBox(width: 10),
              Flexible(child: PbLink(text: 'Informatică, clasa a IX-a', onTap: _startDailyQuest, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Problemă de programare în C++, evaluată automat pe teste.',
            style: TextStyle(color: Pb.muted, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 14),
          PbButton(text: 'Rezolvă problema', onPressed: _startDailyQuest),
        ],
      ),
    );
  }

  Widget _cleanSubjectsCard() {
    return PbCard(
      title: 'Materii',
      padding: EdgeInsets.zero,
      child: PbListGroup(
        flush: true,
        items: [
          PbListItem('Matematică', icon: Icons.functions, onTap: () => _openSubject('Matematică')),
          PbListItem('Informatică', icon: Icons.data_object, onTap: () => _openSubject('Informatică')),
          PbListItem('Limbi străine', icon: Icons.language, onTap: () => _openSubject('Engleză')),
        ],
      ),
    );
  }

  Widget _cleanFooter(bool isMobile) {
    final links = [
      PbLink(text: 'Termeni și condiții', fontSize: 15, onTap: () => context.go('/termeni-si-conditii')),
      PbLink(text: 'Politica de confidențialitate', fontSize: 15, onTap: () => context.go('/politica-confidentialitate')),
    ];
    final copy = Text('© 2026 iMeditații', style: TextStyle(color: Pb.muted, fontSize: 15));

    return Container(
      decoration: BoxDecoration(color: Pb.cardHeader, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: PbContainer(
        child: isMobile
            ? Column(children: [copy, const SizedBox(height: 10), Wrap(spacing: 18, runSpacing: 8, alignment: WrapAlignment.center, children: links)])
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

// =============================================================================
// pbinfo-style news post (collapsible)
// =============================================================================
class _PbPost extends StatefulWidget {
  final String title;
  final String author;
  final String date;
  final String body;
  final String linkText;
  final VoidCallback onLink;

  const _PbPost({
    required this.title,
    required this.author,
    required this.date,
    required this.body,
    required this.linkText,
    required this.onLink,
  });

  @override
  State<_PbPost> createState() => _PbPostState();
}

class _PbPostState extends State<_PbPost> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final line = Container(height: 1, color: Pb.border);
    final metaStyle = TextStyle(fontSize: 14, color: Pb.text);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Pb.surface, borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Pb.cardHeader,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _open = !_open),
                    child: AnimatedRotation(
                      turns: _open ? 0 : -0.25,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.expand_circle_down, size: 26, color: Pb.text),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: PbLink(text: widget.title, onTap: widget.onLink, fontSize: 24)),
              ],
            ),
          ),
          line,
          Container(
            color: Pb.postMeta,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text('Postat de', style: metaStyle),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Pb.secondary,
                  child: Text(widget.author.isNotEmpty ? widget.author[0] : 'A',
                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
                Text(widget.author, style: metaStyle.copyWith(color: Pb.link, fontWeight: FontWeight.w700)),
                Text('•', style: metaStyle),
                Icon(Icons.event, size: 15, color: Pb.text),
                Text(widget.date, style: metaStyle.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (_open) ...[
            line,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.body, style: Pb.body(16)),
                  const SizedBox(height: 16),
                  PbLink(text: widget.linkText, onTap: widget.onLink, underline: true),
                ],
              ),
            ),
            line,
            Container(
              color: Pb.cardHeader,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, size: 15, color: Pb.text),
                  const SizedBox(width: 4),
                  Text(widget.date, style: metaStyle.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}