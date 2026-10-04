import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_colors.dart';
import 'brand_mark.dart';
import 'ui_components.dart';

// =============================================================================
// RETRO PIECES (original)
// =============================================================================
class NavRetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final IconData? icon;
  final bool isFullWidth;

  const NavRetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  State<NavRetroButton> createState() => _NavRetroButtonState();
}

class _NavRetroButtonState extends State<NavRetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.bgColor ?? AppColors.cardBg;
    final effectiveTextColor = widget.textColor ?? AppColors.ink;

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
            isPressed ? 2.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 2.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavTextLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isMobile;

  const NavTextLink({super.key, required this.text, required this.onTap, this.isMobile = false});

  @override
  State<NavTextLink> createState() => _NavTextLinkState();
}

class _NavTextLinkState extends State<NavTextLink> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isMobile ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered ? AppColors.mustard : Colors.transparent,
            border: Border.all(color: isHovered ? AppColors.border : Colors.transparent, width: 2),
          ),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: widget.isMobile ? TextAlign.center : TextAlign.left,
            style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CLEAN PIECES
// =============================================================================
const List<Color> _navGrad = [Color(0xFF22C55E), Color(0xFF0F766E)];

/// Hover helper: rebuilds its child with the current hover state.
class _NavHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _NavHover({required this.builder, this.onTap});

  @override
  State<_NavHover> createState() => _NavHoverState();
}

class _NavHoverState extends State<_NavHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(_hover);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.onTap == null
          ? child
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: child),
    );
  }
}

/// Pill-shaped nav link. Active = tinted pill, hover = soft grey pill.
class _PbNavLink extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _PbNavLink({required this.label, required this.onTap, this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return _NavHover(
      onTap: onTap,
      builder: (h) {
        final color = active ? Pb.link : (h ? Pb.text : Pb.muted);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: active ? Pb.link.withOpacity(0.12) : (h ? Pb.hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? Pb.link.withOpacity(0.28) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AnimatedScale(
                  scale: h && !active ? 1.15 : 1,
                  duration: const Duration(milliseconds: 170),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 7),
              ],
              Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        );
      },
    );
  }
}

/// Quiet text button ("Autentificare").
class _NavGhost extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavGhost({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _NavHover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: h ? Pb.hoverBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: h ? Pb.link : Pb.text)),
      ),
    );
  }
}

/// Gradient call-to-action ("Creează cont"). The arrow slides on hover.
class _NavCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _NavCta({required this.label, required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return _NavHover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        width: fullWidth ? double.infinity : null,
        transform: Matrix4.translationValues(0, h ? -1 : 0, 0),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: fullWidth ? 13 : 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _navGrad),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(h ? 0.45 : 0.22),
              blurRadius: h ? 16 : 8,
              offset: Offset(0, h ? 6 : 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(width: 6),
            AnimatedSlide(
              offset: Offset(h ? 0.25 : 0, 0),
              duration: const Duration(milliseconds: 170),
              child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NAVBAR
// =============================================================================
class CustomNavbar extends StatelessWidget {
  const CustomNavbar({super.key});

  Future<void> _handleDashboardRouting(BuildContext context, User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && context.mounted) {
        final role = (userDoc.data() as Map<String, dynamic>)['role'];
        context.go(role == 'teacher' ? '/panou-profesor' : '/panou-elev');
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  Future<void> _handleProfileRouting(BuildContext context, User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && context.mounted) {
        final role = (userDoc.data() as Map<String, dynamic>)['role'];
        context.go(role == 'teacher' ? '/profesor/${user.uid}' : '/elev/${user.uid}');
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/');
  }

  String _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isCompactPhone = screenWidth < 380;

    return StyleBuilder(
      builder: (context, s) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return s.isClean
                ? _buildClean(context, user, isDesktop)
                : _buildRetro(context, user, isDesktop, isCompactPhone);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------- CLEAN
  Widget _buildClean(BuildContext context, User? user, bool isDesktop) {
    final path = _currentPath(context);

    final brand = _NavHover(
      onTap: () => context.go('/'),
      builder: (h) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedRotation(
            turns: h ? -0.03 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedScale(
              scale: h ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: BrandMark(size: 32, glow: h),
            ),
          ),
          const SizedBox(width: 10),
          BrandWordmark(color: Pb.text, accent: Pb.link, fontSize: 18),
        ],
      ),
    );

    final right = user == null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavGhost(label: 'Autentificare', onTap: () => context.go('/login')),
              const SizedBox(width: 8),
              _NavCta(label: 'Creează cont', onTap: () => context.go('/inregistrare')),
            ],
          )
        : _cleanUserMenu(context, user, showName: true);

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        // A hint of green on the logo side, fading into the plain surface.
        gradient: LinearGradient(
          colors: [Color.alphaBlend(Pb.link.withOpacity(0.06), Pb.surface), Pb.surface, Pb.surface],
          stops: const [0, 0.45, 1],
        ),
        border: Border(bottom: BorderSide(color: Pb.border)),
      ),
      child: Stack(
        children: [
          // Thin accent line that glows in the middle of the bottom edge.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _navGrad[0].withOpacity(0),
                      _navGrad[0].withOpacity(0.75),
                      const Color(0xFF14B8A6).withOpacity(0.75),
                      _navGrad[1].withOpacity(0),
                    ],
                    stops: const [0, 0.3, 0.7, 1],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Pb.containerMax),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 14),
                child: Row(
                  children: [
                    brand,
                    if (isDesktop) ...[
                      const SizedBox(width: 18),
                      Container(width: 1, height: 22, color: Pb.border),
                      const SizedBox(width: 14),
                      _PbNavLink(
                        label: 'Probleme',
                        icon: Icons.code,
                        active: path.startsWith('/exercit') || path.startsWith('/lista-exercitii'),
                        onTap: () => context.go('/exercitii'),
                      ),
                      _PbNavLink(
                        label: 'Lecții',
                        icon: Icons.menu_book_outlined,
                        active: path.startsWith('/resurse'),
                        onTap: () => context.go('/resurse'),
                      ),
                      _PbNavLink(
                        label: 'Profesori',
                        icon: Icons.school_outlined,
                        active: path.startsWith('/materii') || path.startsWith('/profesor'),
                        onTap: () => context.go('/materii'),
                      ),
                      const Spacer(),
                      right,
                    ] else ...[
                      const Spacer(),
                      if (user != null) ...[
                        _cleanUserMenu(context, user, showName: false),
                        const SizedBox(width: 8),
                      ],
                      _NavHover(
                        onTap: () => _showCleanMenu(context, user, path),
                        builder: (h) => AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: h ? Pb.hoverBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Pb.border),
                          ),
                          child: Icon(Icons.menu, size: 20, color: Pb.text),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanAvatar(User user, String label, double radius) {
    final initial = label.isEmpty ? '?' : label[0].toUpperCase();
    final photo = user.photoURL;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _navGrad),
      ),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Pb.surface),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Pb.link.withOpacity(0.16),
          backgroundImage: photo != null ? NetworkImage(photo) : null,
          onBackgroundImageError: photo != null ? (_, __) {} : null,
          child: photo == null
              ? Text(initial, style: TextStyle(fontSize: radius * 0.85, fontWeight: FontWeight.w700, color: Pb.link))
              : null,
        ),
      ),
    );
  }

  Widget _cleanUserMenu(BuildContext context, User user, {bool showName = true}) {
    final label = ((user.displayName ?? '').trim().isNotEmpty ? user.displayName! : (user.email ?? '?')).trim();
    final short = label.contains('@') ? label.split('@').first : label.split(RegExp(r'\s+')).first;

    Widget row(IconData i, String t, Color c) => _NavHover(
          builder: (h) => Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withOpacity(h ? 0.22 : 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(i, size: 17, color: c),
              ),
              const SizedBox(width: 11),
              Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: h ? c : Pb.text)),
            ],
          ),
        );

    return PopupMenuButton<String>(
      tooltip: 'Contul meu',
      offset: const Offset(0, 50),
      elevation: 10,
      color: Pb.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Pb.border)),
      onSelected: (v) {
        if (v == 'dash') _handleDashboardRouting(context, user);
        if (v == 'profile') _handleProfileRouting(context, user);
        if (v == 'logout') _signOut(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              _cleanAvatar(user, label, 17),
              const SizedBox(width: 11),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                    if (user.email != null && user.email != label)
                      Text(user.email!,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'dash', child: row(Icons.dashboard_outlined, 'Panoul meu', Pb.link)),
        PopupMenuItem<String>(value: 'profile', child: row(Icons.person_outline, 'Profil', const Color(0xFF3B82F6))),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'logout', child: row(Icons.logout, 'Ieșire', const Color(0xFFE5484D))),
      ],
      child: _NavHover(
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: EdgeInsets.fromLTRB(4, 4, showName ? 8 : 4, 4),
          decoration: BoxDecoration(
            color: h ? Pb.hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: h ? Pb.link.withOpacity(0.5) : Pb.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cleanAvatar(user, label, 13),
              if (showName) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(short,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: h ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, size: 18, color: Pb.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCleanMenu(BuildContext context, User? user, String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        void go(VoidCallback onTap) {
          Navigator.of(ctx).pop();
          onTap();
        }

        Widget item(IconData icon, String label, Color c, VoidCallback onTap, {bool active = false}) => _NavHover(
              onTap: () => go(onTap),
              builder: (h) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                decoration: BoxDecoration(
                  color: active ? c.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: c, size: 19),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              color: active ? c : Pb.text, fontSize: 16, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Pb.muted),
                  ],
                ),
              ),
            );

        Widget section(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pb.muted, letterSpacing: 0.4)),
            );

        const blue = Color(0xFF3B82F6);
        const violet = Color(0xFF8B5CF6);
        const rose = Color(0xFFE5484D);

        return Container(
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: Pb.border)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(color: Pb.border, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 0, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BrandLogo(color: Pb.text, accent: Pb.link, markSize: 32, fontSize: 19),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                ),
                section('NAVIGARE'),
                item(Icons.code, 'Probleme', Pb.link, () => context.go('/exercitii'),
                    active: path.startsWith('/exercit') || path.startsWith('/lista-exercitii')),
                item(Icons.menu_book_outlined, 'Lecții', blue, () => context.go('/resurse'),
                    active: path.startsWith('/resurse')),
                item(Icons.school_outlined, 'Profesori', violet, () => context.go('/materii'),
                    active: path.startsWith('/materii') || path.startsWith('/profesor')),
                section('CONT'),
                if (user == null) ...[
                  item(Icons.login, 'Autentificare', Pb.link, () => context.go('/login')),
                  const SizedBox(height: 8),
                  _NavCta(label: 'Creează cont', fullWidth: true, onTap: () => go(() => context.go('/inregistrare'))),
                ] else ...[
                  item(Icons.dashboard_outlined, 'Panoul meu', Pb.link, () => _handleDashboardRouting(context, user)),
                  item(Icons.person_outline, 'Profil', blue, () => _handleProfileRouting(context, user)),
                  item(Icons.logout, 'Ieșire', rose, () => _signOut(context)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- RETRO
  void _showRetroMenu(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border, width: 4)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("SYSTEM MENU", style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  IconButton(icon: Icon(Icons.close, color: AppColors.ink, size: 32), onPressed: () => context.pop()),
                ],
              ),
              const SizedBox(height: 24),
              NavTextLink(text: 'Teachers', isMobile: true, onTap: () { context.pop(); context.go('/materii'); }),
              const SizedBox(height: 8),
              NavTextLink(text: 'Exercises', isMobile: true, onTap: () { context.pop(); context.go('/exercitii'); }),
              const SizedBox(height: 8),
              NavTextLink(text: 'Resources', isMobile: true, onTap: () { context.pop(); context.go('/resurse'); }),
              const SizedBox(height: 24),
              Container(height: 3, color: AppColors.border),
              const SizedBox(height: 24),
              if (user == null) ...[
                NavRetroButton(text: 'Log In', isFullWidth: true, bgColor: AppColors.cardBg, textColor: AppColors.ink, onPressed: () { context.pop(); context.go('/login'); }),
                const SizedBox(height: 16),
                NavRetroButton(text: 'Start Playing', isFullWidth: true, bgColor: AppColors.sky, textColor: Colors.white, onPressed: () { context.pop(); context.go('/inregistrare'); }),
              ] else ...[
                NavRetroButton(text: 'Terminal', icon: Icons.dashboard, isFullWidth: true, bgColor: AppColors.mustard, textColor: AppColors.ink, onPressed: () { context.pop(); _handleDashboardRouting(context, user); }),
                const SizedBox(height: 16),
                NavRetroButton(text: 'Profile', icon: Icons.person, isFullWidth: true, bgColor: AppColors.cardBg, textColor: AppColors.ink, onPressed: () { context.pop(); _handleProfileRouting(context, user); }),
                const SizedBox(height: 16),
                NavRetroButton(
                  text: 'Log Out',
                  icon: Icons.logout,
                  isFullWidth: true,
                  bgColor: AppColors.sunset,
                  textColor: Colors.white,
                  onPressed: () async {
                    context.pop();
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetro(BuildContext context, User? user, bool isDesktop, bool isCompactPhone) {
    return Container(
      height: isDesktop ? 90 : 78,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 8 : 6),
                          decoration: BoxDecoration(
                            color: AppColors.sunset,
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Icon(Icons.videogame_asset, color: Colors.white, size: isDesktop ? 28 : 22),
                        ),
                        SizedBox(width: isDesktop ? 16 : 10),
                        Text(
                          'IMEDITATII',
                          style: TextStyle(
                            fontSize: isDesktop ? 32 : (isCompactPhone ? 20 : 24),
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: isDesktop ? 2.0 : 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  Row(
                    children: [
                      NavTextLink(text: 'Teachers', onTap: () => context.go('/materii')),
                      const SizedBox(width: 16),
                      NavTextLink(text: 'Exercises', onTap: () => context.go('/exercitii')),
                      const SizedBox(width: 14),
                      NavTextLink(text: 'Resources', onTap: () => context.go('/resurse')),
                    ],
                  ),
                  Row(
                    children: [
                      if (user == null) ...[
                        NavRetroButton(text: 'Log In', bgColor: AppColors.cardBg, textColor: AppColors.ink, onPressed: () => context.go('/login')),
                        const SizedBox(width: 16),
                        NavRetroButton(text: 'Start Playing', bgColor: AppColors.sky, textColor: Colors.white, onPressed: () => context.go('/inregistrare')),
                      ] else ...[
                        IconButton(icon: Icon(Icons.dashboard, color: AppColors.ink, size: 28), onPressed: () => _handleDashboardRouting(context, user)),
                        const SizedBox(width: 8),
                        IconButton(icon: Icon(Icons.person, color: AppColors.ink, size: 28), onPressed: () => _handleProfileRouting(context, user)),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(color: AppColors.sunset, border: Border.all(color: AppColors.border, width: 2)),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                            onPressed: () => _signOut(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.menu, color: AppColors.ink, size: 32),
                    onPressed: () => _showRetroMenu(context, user),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}