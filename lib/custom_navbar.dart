import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_colors.dart';
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
// CLEAN PIECES (Bootstrap navbar-dark)
// =============================================================================
class _PbNavLink extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _PbNavLink({required this.label, required this.onTap, this.icon, this.active = false});

  @override
  State<_PbNavLink> createState() => _PbNavLinkState();
}

class _PbNavLinkState extends State<_PbNavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = (widget.active || _hover) ? Pb.text : Pb.muted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: widget.active ? Pb.primary : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 17, color: widget.active ? Pb.primary : color),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(fontSize: 14.5, fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500, color: color),
              ),
            ],
          ),
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

    final brand = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Pb.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('iM', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 9),
            Text('iMeditații', style: TextStyle(color: Pb.text, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          ],
        ),
      ),
    );

    final right = user == null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PbButton(text: 'Autentificare', variant: PbVariant.link, size: PbSize.sm, onPressed: () => context.go('/login')),
              const SizedBox(width: 6),
              PbButton(text: 'Creează cont', size: PbSize.sm, onPressed: () => context.go('/inregistrare')),
            ],
          )
        : _cleanUserMenu(context, user);

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(color: Pb.surface, border: Border(bottom: BorderSide(color: Pb.border))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Pb.containerMax),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
            child: Row(
              children: [
                brand,
                if (isDesktop) ...[
                  const SizedBox(width: 28),
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
                  if (user != null) _cleanUserMenu(context, user),
                  IconButton(
                    icon: Icon(Icons.menu, color: Pb.text),
                    onPressed: () => _showCleanMenu(context, user),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cleanUserMenu(BuildContext context, User user) {
    final label = ((user.displayName ?? '').trim().isNotEmpty ? user.displayName! : (user.email ?? '?')).trim();
    final initial = label.isEmpty ? '?' : label[0].toUpperCase();
    final photo = user.photoURL;

    Widget row(IconData i, String t) => Row(
          children: [
            Icon(i, size: 18, color: Pb.muted),
            const SizedBox(width: 10),
            Text(t, style: TextStyle(fontSize: 14, color: Pb.text)),
          ],
        );

    return PopupMenuButton<String>(
      tooltip: 'Contul meu',
      offset: const Offset(0, 48),
      color: Pb.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Pb.border)),
      onSelected: (v) {
        if (v == 'dash') _handleDashboardRouting(context, user);
        if (v == 'profile') _handleProfileRouting(context, user);
        if (v == 'logout') _signOut(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
              if (user.email != null && user.email != label)
                Text(user.email!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'dash', child: row(Icons.dashboard_outlined, 'Panoul meu')),
        PopupMenuItem<String>(value: 'profile', child: row(Icons.person_outline, 'Profil')),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'logout', child: row(Icons.logout, 'Ieșire')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Pb.primary.withOpacity(0.15),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              onBackgroundImageError: photo != null ? (_, __) {} : null,
              child: photo == null
                  ? Text(initial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.primary))
                  : null,
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: Pb.muted),
          ],
        ),
      ),
    );
  }

  void _showCleanMenu(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback onTap) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(ctx).pop();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 17)),
                  ],
                ),
              ),
            );
        final divider = Container(height: 1, color: Colors.white.withOpacity(0.12));

        return Container(
          color: const Color(0xFF1F2430),
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('iMeditații', style: TextStyle(color: Colors.white, fontSize: 20))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                divider,
                item(Icons.code, 'Probleme', () => context.go('/exercitii')),
                item(Icons.groups_outlined, 'Profesori', () => context.go('/materii')),
                item(Icons.menu_book_outlined, 'Lecții', () => context.go('/resurse')),
                divider,
                if (user == null) ...[
                  item(Icons.login, 'Autentificare', () => context.go('/login')),
                  item(Icons.person_add_alt, 'Înregistrare', () => context.go('/inregistrare')),
                ] else ...[
                  item(Icons.dashboard_outlined, 'Panoul meu', () => _handleDashboardRouting(context, user)),
                  item(Icons.person_outline, 'Profil', () => _handleProfileRouting(context, user)),
                  item(Icons.logout, 'Ieșire', () => _signOut(context)),
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