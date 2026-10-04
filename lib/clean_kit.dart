import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'ui_components.dart' show Pb, PbLink, PbContainer;

// =============================================================================
// Small shared pieces for the Clean screens (dashboards + profiles).
// =============================================================================

BoxDecoration ckDeco({double r = 16}) => BoxDecoration(
      color: Pb.surface,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: Pb.border.withOpacity(0.7)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
      ],
    );

String ckInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
  return parts.isEmpty ? '?' : parts.map((w) => w[0].toUpperCase()).join();
}

const List<Color> _ckPalette = [
  Color(0xFF15803D),
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFFE5484D),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
];

Color ckColorFor(String seed) => _ckPalette[seed.hashCode.abs() % _ckPalette.length];

Color ckSubjectColor(String s) {
  final l = s.toLowerCase();
  if (l.contains('matemat')) return const Color(0xFFE5484D);
  if (l.contains('info')) return Pb.primary;
  if (l.contains('fizic')) return const Color(0xFF8B5CF6);
  if (l.contains('chim')) return const Color(0xFF14B8A6);
  if (l.contains('bio')) return const Color(0xFF22A06B);
  if (l.contains('român')) return const Color(0xFF3B82F6);
  if (l.contains('englez')) return const Color(0xFFF59E0B);
  if (l.contains('francez')) return const Color(0xFF6366F1);
  if (l.contains('istorie')) return const Color(0xFFD97706);
  if (l.contains('geograf')) return const Color(0xFF0EA5E9);
  return Pb.primary;
}

IconData ckSubjectIcon(String s) {
  final l = s.toLowerCase();
  if (l.contains('matemat')) return Icons.functions;
  if (l.contains('info')) return Icons.data_object;
  if (l.contains('fizic')) return Icons.bolt;
  if (l.contains('chim')) return Icons.science_outlined;
  if (l.contains('bio')) return Icons.eco_outlined;
  if (l.contains('român')) return Icons.menu_book_outlined;
  if (l.contains('englez') || l.contains('francez')) return Icons.language;
  if (l.contains('istorie')) return Icons.account_balance_outlined;
  if (l.contains('geograf')) return Icons.public;
  return Icons.school_outlined;
}

Widget ckCardTitle(IconData icon, String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Pb.muted),
          const SizedBox(width: 9),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text))),
          if (trailing != null) trailing,
        ],
      ),
    );

// ----------------------------------------------------------------- hover / reveal
class CkHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;
  const CkHover({super.key, required this.builder, this.onTap});

  @override
  State<CkHover> createState() => _CkHoverState();
}

class _CkHoverState extends State<CkHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: widget.builder(_hover)),
    );
  }
}

class CkReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const CkReveal({super.key, required this.child, this.delayMs = 0});

  @override
  State<CkReveal> createState() => _CkRevealState();
}

class _CkRevealState extends State<CkReveal> with SingleTickerProviderStateMixin {
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
      child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a), child: widget.child),
    );
  }
}

// ----------------------------------------------------------------- avatar
class CkAvatar extends StatelessWidget {
  final String name;
  final String image;
  final double size;
  final Color? color;
  const CkAvatar({super.key, required this.name, required this.image, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? ckColorFor(name);
    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        backgroundColor: c.withOpacity(0.15),
        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
        onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
        child: image.isEmpty ? Text(ckInitials(name), style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w700, color: c)) : null,
      ),
    );
  }
}

// ----------------------------------------------------------------- footer
class CkFooter extends StatelessWidget {
  final bool isMobile;
  const CkFooter({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
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
}

// ----------------------------------------------------------------- profile cover
/// Gradient banner + overlapping avatar + padded content.
class CkCover extends StatelessWidget {
  final Color color;
  final String name;
  final String image;
  final bool isMobile;
  final Widget? topRight;
  final Widget? avatarOverlay;
  final Widget child;

  const CkCover({
    super.key,
    required this.color,
    required this.name,
    required this.image,
    required this.isMobile,
    required this.child,
    this.topRight,
    this.avatarOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = isMobile ? 92.0 : 108.0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ckDeco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: isMobile ? 96 : 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.85), Color.lerp(color, const Color(0xFF3B82F6), 0.45)!.withOpacity(0.7)],
                  ),
                ),
                child: topRight == null
                    ? null
                    : Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(14), child: topRight)),
              ),
              Positioned(
                left: isMobile ? 18 : 28,
                bottom: -avatar / 2,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: avatar,
                      height: avatar,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Pb.surface, shape: BoxShape.circle),
                      child: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                        onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
                        child: image.isEmpty
                            ? Text(ckInitials(name), style: TextStyle(fontSize: avatar * 0.3, fontWeight: FontWeight.w700, color: color))
                            : null,
                      ),
                    ),
                    if (avatarOverlay != null) avatarOverlay!,
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: avatar / 2 + 12),
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 18 : 28, 0, isMobile ? 18 : 28, isMobile ? 20 : 26),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- achievements
class CkAchievement {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final int have;
  final int goal;
  const CkAchievement(this.icon, this.title, this.desc, this.color, this.have, this.goal);

  bool get earned => have >= goal;
  double get progress => goal == 0 ? 1 : (have / goal).clamp(0.0, 1.0).toDouble();
}

/// [total] = problems solved, [bySubject] = problems solved per subject name.
List<CkAchievement> ckAchievements(int total, Map<String, int> bySubject) {
  int sub(String s) => bySubject.entries.where((e) => e.key.toLowerCase().contains(s)).fold(0, (a, e) => a + e.value);
  return [
    CkAchievement(Icons.flag_outlined, 'Prima problemă', 'Rezolvă o problemă.', const Color(0xFF10B981), total, 1),
    CkAchievement(Icons.local_fire_department_outlined, 'Încălzirea', '5 probleme rezolvate.', const Color(0xFFF59E0B), total, 5),
    CkAchievement(Icons.bolt, 'În formă', '10 probleme rezolvate.', const Color(0xFF3B82F6), total, 10),
    CkAchievement(Icons.directions_run, 'Maratonist', '25 de probleme rezolvate.', const Color(0xFFE5484D), total, 25),
    CkAchievement(Icons.code, 'Informatician', '5 probleme de Informatică.', Pb.primary, sub('info'), 5),
    CkAchievement(Icons.functions, 'Matematician', '5 probleme de Matematică.', const Color(0xFFE5484D), sub('matemat'), 5),
    CkAchievement(Icons.public, 'Explorator', 'Rezolvă la 3 materii diferite.', const Color(0xFF8B5CF6), bySubject.length, 3),
  ];
}

class CkBadgeGrid extends StatelessWidget {
  final List<CkAchievement> items;
  final bool onlyEarned;
  const CkBadgeGrid({super.key, required this.items, this.onlyEarned = false});

  @override
  Widget build(BuildContext context) {
    final list = onlyEarned ? items.where((a) => a.earned).toList() : items;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final a in list)
          Tooltip(
            message: a.earned ? '${a.title}: obținută' : '${a.title}: ${a.have} din ${a.goal}',
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: a.earned ? a.color.withOpacity(0.09) : Pb.hoverBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: a.earned ? a.color.withOpacity(0.4) : Pb.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: a.earned ? a.color.withOpacity(0.18) : Pb.gray,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.earned ? a.icon : Icons.lock_outline, size: 17, color: a.earned ? a.color : Pb.muted),
                      ),
                      const Spacer(),
                      if (a.earned) Icon(Icons.check_circle, size: 16, color: a.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a.title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: a.earned ? Pb.text : Pb.muted)),
                  const SizedBox(height: 2),
                  Text(a.desc, style: TextStyle(fontSize: 12, color: Pb.muted, height: 1.35)),
                  if (!a.earned) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: a.progress, minHeight: 4, color: a.color, backgroundColor: Pb.gray),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}