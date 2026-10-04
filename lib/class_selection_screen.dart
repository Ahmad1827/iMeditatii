import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize;

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

class LevelTile extends StatefulWidget {
  final int level;
  final Color bgColor;
  final VoidCallback onTap;

  const LevelTile({
    super.key,
    required this.level,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<LevelTile> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.bgColor,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
                ),
                child: Text(
                  'LEVEL',
                  style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${widget.level}',
                    style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassSelectionScreen extends StatefulWidget {
  final String subject;

  const ClassSelectionScreen({super.key, required this.subject});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  static const List<int> clase = [5, 6, 7, 8, 9, 10, 11, 12];

  Map<int, int> _solved = {};
  final GlobalKey _cardKey = GlobalKey();

  String get subject => widget.subject;

  @override
  void initState() {
    super.initState();
    _loadSolved();
  }

  /// Solved problems per grade, from local progress keys "<materie>_<clasa>_<id>".
  Future<void> _loadSolved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final re = RegExp('^${RegExp.escape(subject)}_(\\d+)_');
      final map = <int, int>{};
      for (final k in prefs.getKeys()) {
        final m = re.firstMatch(k);
        if (m == null || prefs.get(k) != true) continue;
        final g = int.parse(m.group(1)!);
        map[g] = (map[g] ?? 0) + 1;
      }
      if (mounted) setState(() => _solved = map);
    } catch (_) {}
  }

  void _open(int grade) {
    // /lista-exercitii is the route that exists in main.dart; it has its own grade picker.
    context.go('/lista-exercitii?materie=${Uri.encodeComponent(subject)}&clasa=$grade');
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/exercitii');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — grades grouped into Gimnaziu / Liceu, exam-year badges (EN, Bac)
  // and your solved count per grade. Dragon scene.
  // ===========================================================================
  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final c = ckSubjectColor(subject);
    final total = _solved.values.fold(0, (a, b) => a + b);

    Widget group(String title, String sub, List<int> grades) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
                const SizedBox(width: 8),
                Text(sub, style: TextStyle(fontSize: 13, color: Pb.muted)),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth > 560 ? 4 : 2;
              const gap = 10.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final g in grades)
                    SizedBox(
                      width: w,
                      child: _GradeTile(
                        grade: g,
                        color: c,
                        solved: _solved[g] ?? 0,
                        exam: g == 8 ? 'Evaluare Națională' : (g == 12 ? 'Bacalaureat' : null),
                        onTap: () => _open(g),
                      ),
                    ),
                ],
              );
            }),
          ],
        );

    final card = Container(
      key: _cardKey,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: ckDeco(r: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PbButton(text: 'Înapoi', icon: Icons.arrow_back, variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _back),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(ckSubjectIcon(subject), size: 26, color: c),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                    Text('Alege clasa', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
                  ],
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Pb.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                  child: Text('$total rezolvate', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.link)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          group('Gimnaziu', 'clasele V–VIII', const [5, 6, 7, 8]),
          const SizedBox(height: 22),
          group('Liceu', 'clasele IX–XII', const [9, 10, 11, 12]),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: HomeSky(
        scene: HomeScene.fantasy,
        blockers: [_cardKey],
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 24 : 48),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: CkReveal(child: card)),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(BuildContext context) {
    final List<Color> tileColors = [AppColors.sky, AppColors.mustard, AppColors.sunset, AppColors.forest];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(subject.toUpperCase(), style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
              onPressed: _back,
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: RetroBlock(
                      bgColor: AppColors.cloud,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videogame_asset, size: 40, color: AppColors.ink),
                          const SizedBox(width: 16),
                          Text(
                            'SELECT YOUR LEVEL',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: clase.length,
                      itemBuilder: (context, i) {
                        final color = tileColors[i % tileColors.length];
                        return LevelTile(
                          level: clase[i],
                          bgColor: color,
                          onTap: () => context.go('/exercitii/$subject/${clase[i]}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradeTile extends StatefulWidget {
  final int grade;
  final Color color;
  final int solved;
  final String? exam;
  final VoidCallback onTap;

  const _GradeTile({required this.grade, required this.color, required this.solved, required this.exam, required this.onTap});

  @override
  State<_GradeTile> createState() => _GradeTileState();
}

class _GradeTileState extends State<_GradeTile> {
  bool _hover = false;

  static const _roman = {5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X', 11: 'XI', 12: 'XII'};

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          height: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hover ? c.withOpacity(0.06) : Pb.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hover ? c.withOpacity(0.6) : Pb.border),
            boxShadow: _hover ? [BoxShadow(color: c.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Clasa', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  const Spacer(),
                  if (widget.solved > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Pb.primary),
                        const SizedBox(width: 3),
                        Text('${widget.solved}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.link)),
                      ],
                    ),
                ],
              ),
              const Spacer(),
              Text(_roman[widget.grade] ?? '${widget.grade}',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _hover ? c : Pb.text, height: 1, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              if (widget.exam != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                  child: Text(widget.exam!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                )
              else
                Text('a ${widget.grade}-a', style: TextStyle(fontSize: 12, color: Pb.muted)),
            ],
          ),
        ),
      ),
    );
  }
}