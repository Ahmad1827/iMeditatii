import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

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
            border: Border.all(
              color: isHovered ? AppColors.border : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: widget.isMobile ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomNavbar extends StatelessWidget {
  const CustomNavbar({super.key});

  Future<void> _handleDashboardRouting(BuildContext context, User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && context.mounted) {
        final role = (userDoc.data() as Map<String, dynamic>)['role'];
        if (role == 'teacher') {
          context.go('/panou-profesor');
        } else {
          context.go('/panou-elev');
        }
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
        if (role == 'teacher') {
          context.go('/profesor/${user.uid}');
        } else {
          context.go('/elev/${user.uid}');
        }
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  void _showMobileMenu(BuildContext context, User? user) {
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
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.ink, size: 32),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NavTextLink(text: 'Guild Masters', isMobile: true, onTap: () { context.pop(); context.go('/materii'); }),
              const SizedBox(height: 8),
              NavTextLink(text: 'Daily Quest', isMobile: true, onTap: () { context.pop(); context.go('/exercitii'); }),
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
                  text: 'Log Out', icon: Icons.logout, isFullWidth: true, bgColor: AppColors.sunset, textColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;

            return Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // LOGO SECTION
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.go('/'),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.sunset,
                                    border: Border.all(color: AppColors.border, width: 2),
                                  ),
                                  child: const Icon(Icons.videogame_asset, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'IMEDITATII',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // DESKTOP NAVIGATION
                        if (isDesktop) ...[
                          Row(
                            children: [
                              NavTextLink(text: 'Guild Masters', onTap: () => context.go('/materii')),
                              const SizedBox(width: 16),
                              NavTextLink(text: 'Daily Quest', onTap: () => context.go('/exercitii')),
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
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      if (context.mounted) context.go('/');
                                    },
                                  ),
                                ),
                              ]
                            ],
                          )
                        ]
                        // MOBILE NAVIGATION
                        else ...[
                          IconButton(
                            icon: Icon(Icons.menu, color: AppColors.ink, size: 36),
                            onPressed: () => _showMobileMenu(context, user),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}