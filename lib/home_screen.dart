import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
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
      // prefs.get() instead of getBool(): getBool throws on String keys (e.g. 'app_style').
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

  Widget _buildConstrainedSection({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------------
  Widget _buildRetroStatusChips(bool isMobile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'SYSTEM OPERATIONAL',
                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: isMobile ? 11 : 12, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        AppBadge(text: "SEASON 1", color: AppColors.sunset, fontSize: 10),
      ],
    );
  }

  Widget _buildHeroSection(AppStyle s, bool isMobile) {
    final heroInk = s.heroInk;

    final findTeacher = s.pick("FIND A MASTER", "Găsește un profesor");
    final seeExercises = s.pick("DAILY QUESTS", "Vezi exercițiile");

    final leftContent = RetroBlock(
      bgColor: s.heroBg,
      preserveColor: true,
      padding: isMobile ? 18 : (s.isClean ? 40 : 36),
      shadowOffset: isMobile ? 3.5 : 6.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.isRetro)
                _buildRetroStatusChips(isMobile)
              else
                AppBadge(text: 'Pregătire pentru Bacalaureat', color: AppColors.sky, icon: Icons.school_outlined, fontSize: 12),
              SizedBox(height: isMobile ? 14 : 20),
              Text(
                s.pick("LEVEL UP YOUR\nKNOWLEDGE.", "Învață, exersează\nși vezi cât ai progresat."),
                style: s.display(isMobile ? s.pick(26.0, 28.0) : s.pick(48.0, 44.0), color: heroInk),
              ),
              SizedBox(height: isMobile ? 10 : 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  s.pick(
                    "Alege o materie. Găsește un mentor verificat și rezolvă quest-uri interactive pentru a avansa în nivel.",
                    "Alege o materie, lucrează cu un profesor verificat și rezolvă probleme cu evaluare automată, pe programa de liceu.",
                  ),
                  style: s.body(
                    isMobile ? 14 : 17,
                    color: s.isClean ? AppColors.textMuted : heroInk,
                    height: 1.5,
                    retroWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 28),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RetroButton(
                  text: findTeacher,
                  icon: Icons.search,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  bgColor: s.primaryFill(AppColors.forest),
                  textColor: s.primaryText(Colors.white),
                  isFullWidth: true,
                  onPressed: () => context.go('/materii'),
                ),
                const SizedBox(height: 10),
                RetroButton(
                  text: seeExercises,
                  icon: s.pick(Icons.track_changes, Icons.code),
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
                RetroButton(
                  text: findTeacher,
                  icon: Icons.search,
                  bgColor: s.primaryFill(AppColors.forest),
                  textColor: s.primaryText(Colors.white),
                  onPressed: () => context.go('/materii'),
                ),
                SizedBox(width: s.pick(16.0, 12.0)),
                RetroButton(
                  text: seeExercises,
                  icon: s.pick(Icons.track_changes, Icons.code),
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            ),
        ],
      ),
    );

    final rank = _completedQuests > 10
        ? s.pick("GOLD GUILD", "Avansat")
        : (_completedQuests > 3 ? s.pick("SILVER RANK", "Intermediar") : s.pick("NOVICE", "Începător"));

    final progressValue = (_completedQuests % 5) / 5.0 == 0 && _completedQuests > 0 ? 1.0 : (_completedQuests % 5) / 5.0;

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
                  Text(
                    s.pick("YOUR PROGRESS", "Progresul tău"),
                    style: s.isClean ? s.heading(isMobile ? 15 : 17) : s.overline(isMobile ? 14 : 16),
                  ),
                  AppBadge(text: rank, color: AppColors.sky, outlined: true, fontSize: 10),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: s.insetBox(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.pick("QUESTS CLEARED", "Probleme rezolvate"),
                          style: s.isClean
                              ? TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 13)
                              : TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        _isLoadingStats
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                s.pick("$_completedQuests SOLVED", "$_completedQuests"),
                                style: s.isClean
                                    ? TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)
                                    : TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(s.isClean ? 4 : 0),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: s.isClean ? s.line : AppColors.border.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                        minHeight: s.isClean ? 6 : 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.pick("DAILY BOUNTY", "Problema zilei"),
                    style: s.isClean
                        ? s.overline(13)
                        : TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                  ),
                  if (s.isRetro) Icon(Icons.star, color: AppColors.mustard, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s.pick("INFORMATICĂ // CLASA A 9-A", "Informatică, clasa a IX-a"),
                style: s.isClean
                    ? s.heading(isMobile ? 15 : 16)
                    : TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(
                s.pick("RECOMPENSĂ: +50 EXP // AUTO-CHECK", "Problemă de programare cu evaluare automată"),
                style: s.isClean
                    ? s.muted(13)
                    : TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          RetroButton(
            text: s.pick("ACCEPT BOUNTY", "Rezolvă problema"),
            icon: s.pick(Icons.play_arrow, null),
            bgColor: s.primaryFill(AppColors.sunset),
            textColor: s.primaryText(Colors.white),
            isFullWidth: true,
            fontSize: 14,
            padding: EdgeInsets.symmetric(vertical: s.pick(10.0, 12.0)),
            onPressed: _startDailyQuest,
          ),
        ],
      ),
    );

    return _buildConstrainedSection(
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, isMobile ? 16 : 36, isMobile ? 14 : 24, isMobile ? 16 : 28),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftContent,
                const SizedBox(height: 14),
                rightContent,
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: leftContent),
                  SizedBox(width: s.pick(24.0, 20.0)),
                  Expanded(flex: 2, child: rightContent),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // PATHS
  // ---------------------------------------------------------------------------
  Widget _buildPathsSection(AppStyle s, bool isMobile) {
    final paths = <Map<String, dynamic>>[
      {
        "icon": Icons.functions,
        "title": s.pick("MATEMATICĂ", "Matematică"),
        "desc": s.pick("ALGEBRĂ & GEOMETRIE", "Algebră, geometrie, analiză"),
        "color": AppColors.sunset,
        "route": "Matematică",
      },
      {
        "icon": Icons.data_object,
        "title": s.pick("INFORMATICĂ", "Informatică"),
        "desc": s.pick("ALGORITMI & C++", "Algoritmi în C++ și Python"),
        "color": AppColors.forest,
        "route": "Informatică",
      },
      {
        "icon": Icons.language,
        "title": s.pick("LIMBI STRĂINE", "Limbi străine"),
        "desc": s.pick("ENGLEZĂ & ROMÂNĂ", "Engleză și română"),
        "color": AppColors.sky,
        "route": "Engleză",
      },
    ];

    final pathCards = <Widget>[];
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final isLast = i == paths.length - 1;
      pathCards.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: isMobile && !isLast ? 12 : 0,
            right: !isMobile && !isLast ? s.pick(20.0, 16.0) : 0,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final encoded = Uri.encodeComponent(path["route"] as String);
                context.go('/lista-exercitii?materie=$encoded');
              },
              child: RetroBlock(
                bgColor: AppColors.cardBg,
                padding: isMobile ? 16 : 24,
                shadowOffset: isMobile ? 3.5 : 6.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppIconTile(
                      icon: path["icon"] as IconData,
                      color: path["color"] as Color,
                      iconSize: isMobile ? 26 : s.pick(36.0, 30.0),
                      padding: isMobile ? 12 : s.pick(18.0, 16.0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      path["title"] as String,
                      textAlign: TextAlign.center,
                      style: s.heading(isMobile ? 16 : s.pick(20.0, 18.0)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path["desc"] as String,
                      textAlign: TextAlign.center,
                      style: s.isClean
                          ? s.muted(isMobile ? 13 : 14)
                          : TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 28, horizontal: isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.pick("CHOOSE YOUR PATH", "Alege materia"),
            textAlign: TextAlign.center,
            style: s.display(isMobile ? 22 : s.pick(34.0, 30.0)),
          ),
          const SizedBox(height: 6),
          Text(
            s.pick("SELECTEAZĂ O DISCIPLINĂ PENTRU ANTRENAMENT.", "Vezi problemele disponibile pentru fiecare disciplină."),
            textAlign: TextAlign.center,
            style: s.isClean
                ? s.muted(isMobile ? 14 : 16)
                : TextStyle(fontSize: isMobile ? 11 : 15, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: pathCards)
              : Row(children: pathCards.map((card) => Expanded(child: card)).toList()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MASTERS
  // ---------------------------------------------------------------------------
  Widget _buildMastersSection(AppStyle s, bool isMobile) {
    final leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBadge(
          text: s.pick("GUILD ROSTER", "Profesori"),
          color: s.pick(AppColors.isDark ? AppColors.sunset : AppColors.ink, AppColors.sky),
          fontSize: 10,
        ),
        const SizedBox(height: 12),
        Text(
          s.pick(
            isMobile ? "MEET THE MASTERS." : "MEET THE\nMASTERS.",
            isMobile ? "Lecții 1-la-1 cu profesori verificați." : "Lecții 1-la-1 cu\nprofesori verificați.",
          ),
          style: s.display(isMobile ? 24 : s.pick(40.0, 34.0)),
        ),
        const SizedBox(height: 10),
        Text(
          s.pick(
            "Mentori verificați gata să te ghideze 1-la-1 cu tablă interactivă live și conexiune securizată.",
            "Fiecare profesor e verificat înainte de a preda. Lecțiile au loc online, cu tablă interactivă și apel video.",
          ),
          style: s.body(isMobile ? 13 : 16, color: s.isClean ? AppColors.textMuted : AppColors.ink, height: 1.5, retroWeight: FontWeight.bold),
        ),
        SizedBox(height: isMobile ? 16 : 22),
        RetroButton(
          text: s.pick("EXPLOREAZĂ PROFESORII", "Vezi profesorii"),
          icon: s.pick(Icons.groups, Icons.groups_outlined),
          bgColor: s.primaryFill(AppColors.sunset),
          textColor: s.primaryText(Colors.white),
          isFullWidth: isMobile,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          onPressed: () => context.go('/materii'),
        ),
      ],
    );

    final rightContent = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isMobile ? 1.25 : 1.1,
      children: [
        _buildMasterAvatar(s, Icons.calculate, s.pick("MATH", "Matematică"), AppColors.sky),
        _buildMasterAvatar(s, Icons.terminal, s.pick("CODE", "Informatică"), AppColors.mustard),
        _buildMasterAvatar(s, Icons.bolt, s.pick("PHYSICS", "Fizică"), AppColors.forest),
        _buildMasterAvatar(s, Icons.science, s.pick("CHEM", "Chimie"), AppColors.sunset),
      ],
    );

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 36, horizontal: isMobile ? 14 : 24),
      child: RetroBlock(
        bgColor: AppColors.cloud,
        padding: isMobile ? 16 : 36,
        shadowOffset: isMobile ? 3.5 : 6.0,
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftContent,
                  const SizedBox(height: 20),
                  rightContent,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: leftContent),
                  const SizedBox(width: 36),
                  Expanded(child: rightContent),
                ],
              ),
      ),
    );
  }

  Widget _buildMasterAvatar(AppStyle s, IconData icon, String label, Color color) {
    if (s.isClean) {
      return Container(
        decoration: BoxDecoration(
          color: s.inset,
          borderRadius: s.rTile,
          border: Border.all(color: s.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconTile(icon: icon, color: color, iconSize: 22, padding: 12),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: s.hardShadow(3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: AppColors.isDark && color == AppColors.mustard ? const Color(0xFF10161A) : Colors.white),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: AppColors.ink,
            child: Text(
              label,
              style: TextStyle(color: s.onInk, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildFooter(AppStyle s, bool isMobile) {
    if (s.isClean) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 24 : 36),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: s.line)),
        ),
        child: Center(
          child: Column(
            children: [
              Text('iMeditații', style: s.heading(isMobile ? 18 : 20)),
              const SizedBox(height: 6),
              Text(
                '© 2026 iMeditații. Pregătire pentru liceu și Bacalaureat.',
                textAlign: TextAlign.center,
                style: s.muted(isMobile ? 12.5 : 14),
              ),
            ],
          ),
        ),
      );
    }

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
            Text(
              'IMEDITATII // GUILD',
              style: TextStyle(fontSize: isMobile ? 22 : 32, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0),
            ),
            const SizedBox(height: 6),
            Text(
              'SYSTEM LOG: LEVEL UP YOUR LEARNING IN 2026.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;

    return StyleBuilder(
      builder: (context, s) {
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
                        _buildHeroSection(s, isMobile),
                        _buildPathsSection(s, isMobile),
                        _buildMastersSection(s, isMobile),
                        SizedBox(height: isMobile ? 14 : 28),
                        _buildFooter(s, isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}