import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'sticky_footer.dart';
import 'retro_widgets.dart';
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer;

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  // Progress keys look like "<materie>_<clasa>_<id>" (see ExerciseDetailScreen).
  static final RegExp _progressKey = RegExp(r'^(.+)_\d+_.+$');

  final ScrollController _scroll = ScrollController();
  Map<String, int> _solvedBySubject = {};
  int _solvedTotal = 0;
  bool _hidden = false;
  final GlobalKey _topKey = GlobalKey();
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, int>{};
      var total = 0;
      for (final k in prefs.getKeys()) {
        final m = _progressKey.firstMatch(k);
        if (m == null || prefs.get(k) != true) continue;
        map[m.group(1)!] = (map[m.group(1)!] ?? 0) + 1;
        total++;
      }
      if (mounted) {
        setState(() {
          _solvedBySubject = map;
          _solvedTotal = total;
        });
      }
    } catch (e) {
      debugPrint('Progres: $e');
    }
  }

  void _open(BuildContext context, String materie) {
    context.go('/lista-exercitii?materie=${Uri.encodeComponent(materie)}');
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        if (s.isClean) return _buildClean(context, MediaQuery.of(context).size.width < 900);
        return RetroPage(
          footerSubtitle: 'Exersează zilnic. Stăpânește programa.',
          builder: (context, m) => [_hero(context, m), _subjects(context, m)],
        );
      },
    );
  }

  // ===========================================================================
  // CLEAN — arena: hero + how-it-works, subject cards, fantasy sky
  // ===========================================================================
  static const Color _cRose = Color(0xFFE5484D);
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cViolet = Color(0xFF8B5CF6);
  static const Color _cTeal = Color(0xFF14B8A6);

  static const List<(IconData, String, String, Color, String)> _materii = [
    (Icons.data_object, 'Informatică', 'Algoritmi și C++, evaluate pe teste', Pb.primary, 'Cod evaluat automat'),
    (Icons.functions, 'Matematică', 'Algebră, analiză și geometrie', _cRose, 'Răspuns scurt'),
    (Icons.menu_book_outlined, 'Limba Română', 'Gramatică și literatură', _cBlue, 'Grile'),
    (Icons.language, 'Engleză', 'Gramatică și vocabular', _cAmber, 'Grile'),
    (Icons.bolt, 'Fizică', 'Mecanică și optică', _cViolet, 'Răspuns scurt'),
    (Icons.science_outlined, 'Chimie', 'Anorganică și organică', _cTeal, 'Răspuns scurt'),
  ];

  BoxDecoration _deco({double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  Widget _buildClean(BuildContext context, bool isMobile) {
    Widget box(double max, Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24), child: child),
          ),
        );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              scene: HomeScene.fantasy,
              blockers: [_topKey, if (!_hidden) _mainKey, _footKey],
              cardsHidden: _hidden,
              onToggleCards: () => setState(() => _hidden = !_hidden),
              hideLabel: 'Ascunde materiile',
              showLabel: 'Arată materiile',
              child: StickyFooterScroll(
                controller: _scroll,
                body: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isMobile ? 20 : 40),
                      box(1120, KeyedSubtree(key: _topKey, child: _EReveal(child: _cHero(context, isMobile)))),
                      SizedBox(height: isMobile ? 18 : 26),
                      box(
                        1120,
                        KeyedSubtree(
                          key: _mainKey,
                          child: _EReveal(
                            delayMs: 140,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeInOutCubic,
                              offset: _hidden ? const Offset(0, 1.6) : Offset.zero,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: _hidden ? 0 : 1,
                                child: IgnorePointer(ignoring: _hidden, child: _cSubjects(context, isMobile)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                footer: KeyedSubtree(key: _footKey, child: _cFooter(context, isMobile)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cHero(BuildContext context, bool isMobile) {
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

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Arena iMeditații', style: TextStyle(fontSize: 14, color: Pb.muted)),
        const SizedBox(height: 4),
        Text(
          'Probleme cu evaluare automată',
          style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          'Alege o materie. Codul tău C++ e rulat pe teste, iar răspunsurile sunt verificate pe loc. Fiecare problemă rezolvată te urcă în clasament.',
          style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            stat(Icons.emoji_events_outlined, '$_solvedTotal', _solvedTotal == 1 ? 'problemă rezolvată' : 'probleme rezolvate', Pb.primary),
            stat(Icons.memory, 'C++20', 'Judge0', _cBlue),
            stat(Icons.bolt, 'Instant', 'feedback', _cAmber),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PbButton(text: 'Începe cu Informatică', icon: Icons.play_arrow, onPressed: () => _open(context, 'Informatică')),
            PbButton(text: 'Lecții', variant: PbVariant.outlineSecondary, onPressed: () => context.go('/resurse')),
          ],
        ),
      ],
    );

    Widget step(int n, String title, String body, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withOpacity(0.14), shape: BoxShape.circle),
                child: Text('$n', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                    const SizedBox(height: 2),
                    Text(body, style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );

    final how = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: BoxDecoration(
        color: Pb.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Pb.primary.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 18, color: Pb.primary),
              const SizedBox(width: 8),
              Text('Cum funcționează', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text)),
            ],
          ),
          const SizedBox(height: 14),
          step(1, 'Alegi problema', 'Pe clasă, capitol și dificultate.', Pb.primary),
          step(2, 'Scrii soluția', 'Direct în editorul din browser.', _cBlue),
          step(3, 'Rulezi exemplele', 'Vezi ce iese și ce era așteptat.', _cAmber),
          step(4, 'Trimiți', 'Testele ascunse decid punctajul.', _cRose),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: _deco(r: 18),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 20), how])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 28), SizedBox(width: 320, child: how)],
            ),
    );
  }

  Widget _cSubjects(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text('Alege materia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(width: 10),
              Text('${_materii.length} materii', style: TextStyle(fontSize: 13, color: Pb.muted)),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 900 ? 3 : (box.maxWidth > 560 ? 2 : 1);
            const gap = 14.0;
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final m in _materii)
                  SizedBox(
                    width: w,
                    child: _SubjectCard(
                      icon: m.$1,
                      title: m.$2,
                      tagline: m.$3,
                      color: m.$4,
                      kind: m.$5,
                      solved: _solvedBySubject[m.$2] ?? 0,
                      onTap: () => _open(context, m.$2),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _cFooter(BuildContext context, bool isMobile) {
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
  Widget _hero(BuildContext context, bool m) {
    final text = Column(
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
                RetroTag('Arena de antrenament', color: AppColors.cardBg, dot: Colors.green),
                RetroTag('+50 XP bonus', color: AppColors.sunset),
              ],
            ),
            SizedBox(height: m ? 18 : 24),
            Text('EXERSEAZĂ.\nAVANSEAZĂ ZILNIC.', style: Retro.display(m ? 30 : 48, color: Retro.darkInk)),
            SizedBox(height: m ? 12 : 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                'Alege o disciplină. Testele automate îți verifică codul C++ și răspunsurile pe loc.',
                style: Retro.body(m ? 15 : 17, color: Retro.darkInk).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: m ? 20 : 30),
        RetroButton(
          text: 'Începe cu Informatică',
          icon: Icons.code,
          isFullWidth: m,
          bgColor: AppColors.forest,
          onPressed: () => _open(context, 'Informatică'),
        ),
      ],
    );

    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 20 : 40, Retro.gutter(m), 0),
      child: RetroBlock(
        bgColor: AppColors.mustard,
        padding: m ? 20 : 36,
        shadowOffset: Retro.shadow(m),
        child: m
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [text, const SizedBox(height: 20), _registry(m)],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: text),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _registry(m)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _registry(bool m) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: m ? 16 : 22,
      shadowOffset: 4,
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
                  Text('Cum funcționează', style: Retro.title(16)),
                  Icon(Icons.shield, color: AppColors.forest, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
                child: Column(
                  children: [
                    _row('Exerciții', '50+'),
                    const SizedBox(height: 8),
                    _row('Evaluare', 'Judge0, C++20'),
                    const SizedBox(height: 8),
                    _row('Feedback', 'Instant'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.forest, size: 16),
              const SizedBox(width: 6),
              Text('Gata de evaluare', style: Retro.title(13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Retro.body(13)),
        Text(value, style: Retro.title(13)),
      ],
    );
  }

  Widget _subjects(BuildContext context, bool m) {
    final materii = [
      (Icons.functions, 'Matematică', 'Algebră și geometrie', AppColors.sunset),
      (Icons.menu_book, 'Limba Română', 'Gramatică și literatură', AppColors.sky),
      (Icons.language, 'Engleză', 'Gramatică și vocabular', AppColors.mustard),
      (Icons.data_object, 'Informatică', 'Algoritmi și C++', AppColors.forest),
      (Icons.bolt, 'Fizică', 'Mecanică și optică', AppColors.sunset),
      (Icons.science, 'Chimie', 'Anorganică și organică', AppColors.sky),
    ];

    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 32 : 56, Retro.gutter(m), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroSectionHeader(
            title: 'Alege disciplina',
            subtitle: 'Fiecare set are teste automate, deci știi imediat dacă ai rezolvat corect.',
            isMobile: m,
          ),
          SizedBox(height: m ? 20 : 32),
          RetroGrid(
            minItemWidth: 300,
            spacing: m ? 16 : 24,
            children: materii
                .map((x) => RetroSubjectCard(
                      icon: x.$1,
                      title: x.$2,
                      tag: x.$3,
                      color: x.$4,
                      cta: 'Intră în arenă',
                      isMobile: m,
                      onTap: () => _open(context, x.$2),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Clean subject card
// =============================================================================
class _SubjectCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String tagline;
  final Color color;
  final String kind;
  final int solved;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.color,
    required this.kind,
    required this.solved,
    required this.onTap,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _hover = false;

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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hover ? c.withOpacity(0.55) : Pb.border.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: (_hover ? c : Colors.black).withOpacity(_hover ? 0.16 : (AppColors.isDark ? 0.3 : 0.06)),
                blurRadius: _hover ? 28 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.icon, size: 22, color: c),
                  ),
                  const Spacer(),
                  if (widget.solved > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text('${widget.solved} rezolvate',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _hover ? c : Pb.text)),
              const SizedBox(height: 4),
              Text(widget.tagline, style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(widget.kind, style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ),
                  const Spacer(),
                  Text('Intră', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _hover ? c : Pb.muted)),
                  const SizedBox(width: 4),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: _hover ? const Offset(0.25, 0) : Offset.zero,
                    child: Icon(Icons.arrow_forward, size: 16, color: _hover ? c : Pb.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _EReveal({required this.child, this.delayMs = 0});

  @override
  State<_EReveal> createState() => _ERevealState();
}

class _ERevealState extends State<_EReveal> with SingleTickerProviderStateMixin {
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