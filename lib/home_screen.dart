import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_manager.dart';
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
      int completed = 0;
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (prefs.getBool(key) == true) {
          completed++;
        }
      }
      setState(() {
        _completedQuests = completed;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint("Error loading stats: $e");
      setState(() {
        _isLoadingStats = false;
      });
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

  Widget _buildHeroSection(bool isMobile) {
    final isClean = ThemeManager.isClean;

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
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: isClean ? BorderRadius.circular(6) : BorderRadius.zero,
                      border: Border.all(
                        color: isClean ? Colors.transparent : AppColors.border,
                        width: isClean ? 1 : 2,
                      ),
                      boxShadow: [
                        if (isClean)
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM OPERATIONAL',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: isMobile ? 11 : 12,
                            letterSpacing: isClean ? 0.5 : 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sunset,
                      borderRadius: isClean ? BorderRadius.circular(4) : BorderRadius.zero,
                    ),
                    child: Text(
                      "SEASON 1",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: isClean ? 0.5 : 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 14 : 20),
              Text(
                "LEVEL UP YOUR\nKNOWLEDGE.",
                style: TextStyle(
                  fontSize: isMobile ? 26 : 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                  height: 1.1,
                  letterSpacing: isClean ? 0.2 : 1.0,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Text(
                "Alege o materie. Găsește un mentor verificat și rezolvă quest-uri interactive pentru a avansa în nivel.",
                style: TextStyle(
                  fontSize: isMobile ? 14 : 17,
                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                  fontWeight: isClean ? FontWeight.w500 : FontWeight.bold,
                  height: 1.45,
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
                RetroButton(
                  text: "FIND A MASTER",
                  icon: Icons.search,
                  bgColor: AppColors.forest,
                  onPressed: () => context.go('/materii'),
                ),
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
                  Text(
                    "YOUR PROGRESS",
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 14 : 16,
                      letterSpacing: isClean ? 0.5 : 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: isClean ? BorderRadius.circular(4) : BorderRadius.zero,
                      border: Border.all(color: isClean ? Colors.transparent : AppColors.border, width: 2),
                    ),
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
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: isClean ? BorderRadius.circular(8) : BorderRadius.zero,
                  border: Border.all(
                    color: isClean ? Colors.black.withOpacity(0.05) : AppColors.border,
                    width: isClean ? 1 : 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("QUESTS CLEARED", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12)),
                        _isLoadingStats
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text("$_completedQuests SOLVED", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: isClean ? BorderRadius.circular(4) : BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: (_completedQuests % 5) / 5.0 == 0 && _completedQuests > 0 ? 1.0 : (_completedQuests % 5) / 5.0,
                        backgroundColor: AppColors.border.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("DAILY BOUNTY", style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                  Icon(Icons.star, color: AppColors.mustard, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "INFORMATICĂ // CLASA A 9-A",
                style: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(
                "RECOMPENSĂ: +50 EXP // AUTO-CHECK",
                style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 11),
              ),
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
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: rightContent),
                ],
              ),
            ),
    );
  }

  Widget _buildPathsSection(bool isMobile) {
    final isClean = ThemeManager.isClean;
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
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 18),
                  decoration: BoxDecoration(
                    color: path["color"],
                    borderRadius: isClean ? BorderRadius.circular(12) : BorderRadius.zero,
                    border: Border.all(
                      color: isClean ? Colors.white.withOpacity(0.2) : AppColors.border,
                      width: isClean ? 1 : 2.5,
                    ),
                    boxShadow: [
                      if (!isClean)
                        BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))
                      else
                        BoxShadow(color: (path["color"] as Color).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(path["icon"], size: isMobile ? 26 : 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  path["title"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: isClean ? 0.3 : 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path["desc"],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: isClean ? FontWeight.w600 : FontWeight.bold, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 28, horizontal: isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "CHOOSE YOUR PATH",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 22 : 34,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: isClean ? 0.5 : 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "SELECTEAZĂ O DISCIPLINĂ PENTRU ANTRENAMENT.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 11 : 15, fontWeight: isClean ? FontWeight.w500 : FontWeight.bold, color: AppColors.textMuted),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: pathCards)
              : Row(children: pathCards.map((card) => Expanded(child: card)).toList()),
        ],
      ),
    );
  }

  Widget _buildMastersSection(bool isMobile) {
    final isClean = ThemeManager.isClean;

    final leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
            borderRadius: isClean ? BorderRadius.circular(4) : BorderRadius.zero,
          ),
          child: Text(
            "GUILD ROSTER",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: isClean ? 0.8 : 1.5,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isMobile ? "MEET THE MASTERS." : "MEET THE\nMASTERS.",
          style: TextStyle(
            fontSize: isMobile ? 24 : 40,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            height: 1.1,
            letterSpacing: isClean ? 0.2 : 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Mentori verificați gata să te ghideze 1-la-1 cu tablă interactivă live și conexiune securizată.",
          style: TextStyle(
            fontSize: isMobile ? 13 : 16,
            color: AppColors.ink,
            fontWeight: isClean ? FontWeight.w500 : FontWeight.bold,
            height: 1.45,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 22),
        RetroButton(
          text: "EXPLOREAZĂ PROFESORII",
          icon: Icons.groups,
          bgColor: AppColors.sunset,
          isFullWidth: isMobile,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
        _buildMasterAvatar(Icons.calculate, "MATH", AppColors.sky, isClean),
        _buildMasterAvatar(Icons.terminal, "CODE", AppColors.mustard, isClean),
        _buildMasterAvatar(Icons.bolt, "PHYSICS", AppColors.forest, isClean),
        _buildMasterAvatar(Icons.science, "CHEM", AppColors.sunset, isClean),
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

  Widget _buildMasterAvatar(IconData icon, String label, Color color, bool isClean) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: isClean ? BorderRadius.circular(10) : BorderRadius.zero,
        border: Border.all(
          color: isClean ? Colors.white.withOpacity(0.2) : AppColors.border,
          width: isClean ? 1 : 2.5,
        ),
        boxShadow: [
          if (!isClean)
            BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))
          else
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: AppColors.isDark && color == AppColors.mustard ? const Color(0xFF10161A) : Colors.white),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: isClean ? BorderRadius.circular(4) : BorderRadius.zero,
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    final isClean = ThemeManager.isClean;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 26 : 44),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: isClean ? Colors.white.withOpacity(0.08) : AppColors.border, width: isClean ? 1 : 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII // GUILD',
              style: TextStyle(
                fontSize: isMobile ? 22 : 32,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: isClean ? 1.0 : 2.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SYSTEM LOG: LEVEL UP YOUR LEARNING IN 2026.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 14, fontWeight: isClean ? FontWeight.w500 : FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
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
                        _buildHeroSection(isMobile),
                        _buildPathsSection(isMobile),
                        _buildMastersSection(isMobile),
                        SizedBox(height: isMobile ? 14 : 28),
                        _buildFooter(isMobile),
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