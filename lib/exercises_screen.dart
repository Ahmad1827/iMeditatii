import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.icon,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
            isPressed ? 3.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 3.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          padding: widget.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveText, size: widget.fontSize + 2),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveText,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
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

  Widget _heroSection(bool isMobile) {
    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 36, horizontal: isMobile ? 16 : 24),
      child: RetroBlock(
        bgColor: AppColors.mustard,
        padding: isMobile ? 18 : 36,
        shadowOffset: isMobile ? 3.5 : 6.0,
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heroLeftContent(isMobile),
                  const SizedBox(height: 18),
                  _buildRegistryCard(isMobile),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _heroLeftContent(isMobile)),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildRegistryCard(isMobile)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _heroLeftContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                        'TRAINING ARENA',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 11 : 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: AppColors.sunset,
                  child: const Text(
                    "+50 EXP BOOST",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 14 : 20),
            Text(
              "PRACTICE SMART.\nLEVEL UP DAILY.",
              style: TextStyle(
                fontSize: isMobile ? 26 : 44,
                fontWeight: FontWeight.w900,
                color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                height: 1.1,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              "Selectează o disciplină. Suita automată de teste îți validează codul C++ și răspunsurile în timp real.",
              style: TextStyle(
                fontSize: isMobile ? 13 : 16,
                color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                fontWeight: FontWeight.bold,
                height: 1.45,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 18 : 28),
        RetroButton(
          text: "QUICK START: INFORMATICĂ",
          icon: Icons.code,
          isFullWidth: isMobile,
          fontSize: isMobile ? 13 : 15,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 14),
          bgColor: AppColors.forest,
          textColor: Colors.white,
          onPressed: () {
            final encodedSubj = Uri.encodeComponent("Informatică");
            context.go('/lista-exercitii?materie=$encodedSubj');
          },
        ),
      ],
    );
  }

  Widget _buildRegistryCard(bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 16 : 24,
      shadowOffset: isMobile ? 3 : 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ARENA REGISTRY",
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 14 : 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Icon(Icons.shield, color: AppColors.forest, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    _registryRow("ACTIVE QUESTS", "50+ PROBLEMS"),
                    const SizedBox(height: 6),
                    _registryRow("EVALUATION", "JUDGE0 (C++20)"),
                    const SizedBox(height: 6),
                    _registryRow("FEEDBACK", "INSTANT (TESTS)"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.forest, size: 16),
                const SizedBox(width: 6),
                Text(
                  "READY FOR EVALUATION",
                  style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _registryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: const Text(
              "TRAINING TRACKS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 22 : 32,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _materiiSection(bool isMobile) {
    final List<Map<String, dynamic>> materii = [
      {"icon": Icons.functions, "title": "Matematică", "color": AppColors.sunset, "tag": "ALGEBRĂ & GEOMETRIE"},
      {"icon": Icons.menu_book, "title": "Limba Română", "color": AppColors.sky, "tag": "GRAMATICĂ & LITERATURĂ"},
      {"icon": Icons.language, "title": "Engleză", "color": AppColors.mustard, "tag": "GRAMMAR & VOCAB"},
      {"icon": Icons.data_object, "title": "Informatică", "color": AppColors.forest, "tag": "ALGORITMI & C++"},
      {"icon": Icons.bolt, "title": "Fizică", "color": AppColors.sunset, "tag": "MECANICĂ & OPTICĂ"},
      {"icon": Icons.science, "title": "Chimie", "color": AppColors.sky, "tag": "ANORGANICĂ & ORGANICĂ"},
    ];

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 0),
      child: Wrap(
        spacing: isMobile ? 14 : 24,
        runSpacing: isMobile ? 14 : 24,
        alignment: WrapAlignment.center,
        children: materii.map((m) {
          return _MaterieCard(
            title: m["title"] as String,
            icon: m["icon"] as IconData,
            color: m["color"] as Color,
            tag: m["tag"] as String,
            isMobile: isMobile,
            onTap: () {
              final encodedSubj = Uri.encodeComponent(m["title"] as String);
              context.go('/lista-exercitii?materie=$encodedSubj');
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 28 : 44),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII // ARENA',
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'LEVEL UP YOUR LOGIC. CONQUER THE CURRICULUM.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.cloud, fontSize: isMobile ? 11 : 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                  controller: _pageScrollController,
                  child: SingleChildScrollView(
                    controller: _pageScrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heroSection(isMobile),
                        _buildConstrainedSection(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 14 : 24),
                          child: Column(
                            children: [
                              _sectionTitle("Select Discipline", isMobile),
                              _materiiSection(isMobile),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 28 : 48),
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

class _MaterieCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String tag;
  final bool isMobile;
  final VoidCallback onTap;

  const _MaterieCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.tag,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_MaterieCard> createState() => _MaterieCardState();
}

class _MaterieCardState extends State<_MaterieCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isMustard = widget.color == AppColors.mustard;
    final cardTextColor = isMustard && AppColors.isDark ? const Color(0xFF10161A) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isMobile ? double.infinity : 310,
          transform: Matrix4.translationValues(
            _isPressed ? 3.0 : (_isHovering ? -3.0 : 0.0),
            _isPressed ? 3.0 : (_isHovering ? -3.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: _isPressed ? const Offset(0, 0) : Offset(widget.isMobile ? 3.5 : 5, widget.isMobile ? 3.5 : 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.cardBg,
                padding: EdgeInsets.symmetric(vertical: widget.isMobile ? 18 : 24),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Icon(widget.icon, size: widget.isMobile ? 36 : 48, color: AppColors.ink),
                  ),
                ),
              ),
              Container(height: 2.5, color: AppColors.border),
              Padding(
                padding: EdgeInsets.all(widget.isMobile ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tag,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isMustard && AppColors.isDark ? const Color(0xFF10161A).withOpacity(0.7) : Colors.white70,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: widget.isMobile ? 18 : 20,
                        fontWeight: FontWeight.w900,
                        color: cardTextColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ENTER ARENA",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.play_arrow, size: 14, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}