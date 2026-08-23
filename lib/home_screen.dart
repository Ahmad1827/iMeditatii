import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final double padding;
  final double shadowOffset;
  final Color? borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = bgColor ?? AppColors.cardBg;
    final effectiveBorder = borderColor ?? AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(color: effectiveBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final double fontSize;
  final EdgeInsets padding;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.fontSize = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.bgColor ?? AppColors.sunset;
    final effectiveText = widget.textColor ?? Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: widget.padding,
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveText,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

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
    final exerciseId = '1';
    final encodedMaterie = Uri.encodeComponent('Informatică');
    final encodedClasa = Uri.encodeComponent('9');
    context.go('/exercitiu/$exerciseId?materie=$encodedMaterie&clasa=$encodedClasa');
  }

  Widget _buildConstrainedSection({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    final leftContent = RetroBlock(
      bgColor: AppColors.mustard,
      padding: isMobile ? 32 : 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Text(
              'SYSTEM ONLINE',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2.0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "LEVEL UP YOUR\nKNOWLEDGE.",
            style: TextStyle(
              fontSize: isMobile ? 40 : 56,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.1,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Choose a discipline. Find a guild master. Complete daily quests to gain EXP.",
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RetroButton(
                  text: "FIND A MASTER",
                  bgColor: AppColors.forest,
                  isFullWidth: true,
                  fontSize: 16,
                  onPressed: () => context.go('/materii'),
                ),
                const SizedBox(height: 16),
                RetroButton(
                  text: "DAILY QUESTS",
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  isFullWidth: true,
                  fontSize: 16,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            )
          else
            Row(
              children: [
                RetroButton(
                  text: "FIND A MASTER",
                  bgColor: AppColors.forest,
                  onPressed: () => context.go('/materii'),
                ),
                const SizedBox(width: 24),
                RetroButton(
                  text: "DAILY QUESTS",
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            ),
        ],
      ),
    );

    final rightContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBlock(
          bgColor: AppColors.sky,
          padding: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "PLAYER STATS",
                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),
              Container(height: 3, color: AppColors.border),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("QUESTS CLEARED:", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 14)),
                  _isLoadingStats
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 3))
                      : Text("$_completedQuests", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 24)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("SYSTEM STATUS:", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("OPTIMAL", style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        RetroBlock(
          bgColor: AppColors.cloud,
          padding: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("DAILY QUEST", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                  Icon(Icons.star, color: AppColors.sunset, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "SOLVE: INFORMATICĂ LVL 9",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                "REWARD: +50 EXP",
                style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const SizedBox(height: 24),
              RetroButton(
                text: "ACCEPT QUEST",
                bgColor: AppColors.sunset,
                isFullWidth: true,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _startDailyQuest,
              ),
            ],
          ),
        ),
      ],
    );

    return _buildConstrainedSection(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 32 : 60, 24, isMobile ? 32 : 40),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftContent,
                const SizedBox(height: 32),
                rightContent,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftContent),
                const SizedBox(width: 40),
                Expanded(flex: 2, child: rightContent),
              ],
            ),
    );
  }

  Widget _buildPathsSection(bool isMobile) {
    final List<Map<String, dynamic>> paths = [
      {"icon": Icons.functions, "title": "MATHEMATICS", "color": AppColors.sunset, "desc": "ALGEBRA & LOGIC"},
      {"icon": Icons.data_object, "title": "COMP. SCIENCE", "color": AppColors.forest, "desc": "ALGORITHMS & C++"},
      {"icon": Icons.language, "title": "LANGUAGES", "color": AppColors.sky, "desc": "ENGLISH & ROMANIAN"},
    ];

    final List<Widget> pathCards = paths.map((path) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: isMobile && path != paths.last ? 24 : 0,
          right: !isMobile && path != paths.last ? 24 : 0,
        ),
        child: RetroBlock(
          bgColor: AppColors.cardBg,
          padding: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: path["color"],
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: Icon(path["icon"], size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                path["title"],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                path["desc"],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 40, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "CHOOSE YOUR PATH",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 40,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "SELECT A DISCIPLINE TO BEGIN YOUR TRAINING.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 14 : 18, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 40),
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: pathCards)
              : Row(children: pathCards.map((card) => Expanded(child: card)).toList()),
        ],
      ),
    );
  }

  Widget _buildMastersSection(bool isMobile) {
    final leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
          child: Text(
            "THE GUILD",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isMobile ? "MEET THE MASTERS." : "MEET THE\nMASTERS.",
          style: TextStyle(
            fontSize: isMobile ? 36 : 48,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            height: 1.1,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Our verified experts are ready to guide you. Initiate comms and start leveling up today.",
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        RetroButton(
          text: "VIEW ROSTER",
          bgColor: AppColors.sunset,
          isFullWidth: isMobile,
          fontSize: 16,
          onPressed: () => context.go('/materii'),
        ),
      ],
    );

    final rightContent = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildMasterAvatar(Icons.person, AppColors.sky),
        _buildMasterAvatar(Icons.person_3, AppColors.mustard),
        _buildMasterAvatar(Icons.person_2, AppColors.forest),
        _buildMasterAvatar(Icons.person_4, AppColors.sunset),
      ],
    );

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60, horizontal: 24),
      child: RetroBlock(
        bgColor: AppColors.cloud,
        padding: isMobile ? 32 : 48,
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftContent,
                  const SizedBox(height: 48),
                  rightContent,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: leftContent),
                  const SizedBox(width: 48),
                  Expanded(child: rightContent),
                ],
              ),
      ),
    );
  }

  Widget _buildMasterAvatar(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      child: Center(
        child: Icon(icon, size: 64, color: AppColors.ink),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 40 : 60),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII',
              style: TextStyle(
                fontSize: isMobile ? 32 : 40,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SYSTEM LOG: 2025 - 2026. LEVEL UP YOUR LEARNING.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

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
                        SizedBox(height: isMobile ? 24 : 40),
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