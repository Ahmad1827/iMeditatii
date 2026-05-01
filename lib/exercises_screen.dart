import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_navbar.dart';

class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor = Colors.white,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
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
  final Color bgColor;
  final Color textColor;
  final bool isFullWidth;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
    this.isFullWidth = false,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
            color: widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
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
      padding: padding ?? const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }

  Widget _heroSection() {
    final isWide = MediaQuery.of(context).size.width > 800;

    return _buildConstrainedSection(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: RetroBlock(
        bgColor: AppColors.mustard,
        padding: isWide ? 60 : 32,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: const Text(
                      'STUDY ZONE',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "PRACTICE SMART.\nLEVEL UP DAILY.",
                    style: TextStyle(
                      fontSize: isWide ? 56 : 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      height: 1.1,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Select a discipline to master. The system tracks your progress and validates your answers in real-time.",
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  RetroButton(
                    text: "INITIATE MATHEMATICS",
                    bgColor: AppColors.forest,
                    textColor: Colors.white,
                    onPressed: () {
                      final encodedSubj = Uri.encodeComponent("Matematică");
                      context.go('/lista-exercitii?materie=$encodedSubj');
                    },
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 60),
              Expanded(
                flex: 2,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    border: Border.all(color: AppColors.ink, width: 4),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(8, 8)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.rocket_launch, size: 120, color: AppColors.sunset),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              "AVAILABLE PATHS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _materiiSection() {
    final List<Map<String, dynamic>> materii = [
      {"icon": Icons.functions, "title": "Matematică", "color": AppColors.sunset},
      {"icon": Icons.menu_book, "title": "Limba Română", "color": AppColors.sky},
      {"icon": Icons.language, "title": "Engleză", "color": AppColors.mustard},
      {"icon": Icons.data_object, "title": "Informatică", "color": AppColors.forest},
      {"icon": Icons.bolt, "title": "Fizică", "color": AppColors.sunset},
      {"icon": Icons.science, "title": "Chimie", "color": AppColors.sky},
    ];

    return _buildConstrainedSection(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Wrap(
        spacing: 32,
        runSpacing: 32,
        alignment: WrapAlignment.center,
        children: materii.map((m) {
          return _MaterieCard(
            title: m["title"] as String,
            icon: m["icon"] as IconData,
            color: m["color"] as Color,
            onTap: () {
              final encodedSubj = Uri.encodeComponent(m["title"] as String);
              context.go('/lista-exercitii?materie=$encodedSubj');
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: const Center(
        child: Column(
          children: [
            Text('IMEDITATII', style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('© 2024 - 2025. Level up your learning.', style: TextStyle(color: AppColors.cloud, fontSize: 22)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    _heroSection(),
                    _buildConstrainedSection(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Column(
                        children: [
                          _sectionTitle("Select Discipline"),
                          _materiiSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterieCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MaterieCard({
    required this.title,
    required this.icon,
    required this.color,
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
    return MouseRegion(
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
          width: 280,
          transform: Matrix4.translationValues(
            _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
            _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: _isPressed ? const Offset(0, 0) : const Offset(8, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Icon(widget.icon, size: 80, color: AppColors.ink),
              ),
              Container(
                height: 3,
                color: AppColors.ink,
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "START",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.play_arrow, size: 20, color: AppColors.ink),
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