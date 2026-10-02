import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_colors.dart';
import 'ui_components.dart';

/// Kept for backwards compatibility — now a thin wrapper over RetroButton,
/// so it follows the design system automatically.
class NavRetroButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return RetroButton(
      text: text,
      onPressed: onPressed,
      bgColor: bgColor ?? AppColors.cardBg,
      textColor: textColor ?? AppColors.ink,
      icon: icon,
      isFullWidth: isFullWidth,
      fontSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    final s = AppStyle.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isMobile ? double.infinity : null,
          padding: s.isClean
              ? EdgeInsets.symmetric(horizontal: 14, vertical: widget.isMobile ? 14 : 10)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: s.isClean
              ? BoxDecoration(
                  color: isHovered ? AppColors.ink.withOpacity(AppColors.isDark ? 0.08 : 0.06) : Colors.transparent,
                  borderRadius: s.rButton,
                )
              : BoxDecoration(
                  color: isHovered ? AppColors.mustard : Colors.transparent,
                  border: Border.all(color: isHovered ? AppColors.border : Colors.transparent, width: 2),
                ),
          child: Text(
            s.caps(widget.text),
            textAlign: widget.isMobile ? TextAlign.center : TextAlign.left,
            style: s.isClean
                ? TextStyle(
                    color: isHovered ? AppColors.ink : AppColors.ink.withOpacity(0.78),
                    fontSize: widget.isMobile ? 16 : 15,
                    fontWeight: FontWeight.w500,
                  )
                : TextStyle(
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
      builder: (context) {
        final s = AppStyle.of(context);
        return Container(
          decoration: s.isClean
              ? BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: s.softShadow(2),
                )
              : BoxDecoration(
                  color: AppColors.bg,
                  border: Border(top: BorderSide(color: AppColors.border, width: 4)),
                ),
          padding: EdgeInsets.fromLTRB(24, s.isClean ? 12 : 24, 24, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.isClean) ...[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: s.lineStrong, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.pick("SYSTEM MENU", "Meniu"),
                      style: s.isClean
                          ? s.heading(18)
                          : TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.ink, size: s.pick(32.0, 24.0)),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                SizedBox(height: s.pick(24.0, 12.0)),
                NavTextLink(text: s.pick('Teachers', 'Profesori'), isMobile: true, onTap: () { context.pop(); context.go('/materii'); }),
                const SizedBox(height: 8),
                NavTextLink(text: s.pick('Exercises', 'Exerciții'), isMobile: true, onTap: () { context.pop(); context.go('/exercitii'); }),
                const SizedBox(height: 8),
                NavTextLink(text: s.pick('Resources', 'Lecții'), isMobile: true, onTap: () { context.pop(); context.go('/resurse'); }),
                const SizedBox(height: 24),
                AppDivider(retroThickness: 3),
                const SizedBox(height: 24),

                if (user == null) ...[
                  NavRetroButton(
                    text: s.pick('Log In', 'Autentificare'),
                    isFullWidth: true,
                    bgColor: AppColors.cardBg,
                    textColor: AppColors.ink,
                    onPressed: () { context.pop(); context.go('/login'); },
                  ),
                  const SizedBox(height: 16),
                  NavRetroButton(
                    text: s.pick('Start Playing', 'Creează cont'),
                    isFullWidth: true,
                    bgColor: s.primaryFill(AppColors.sky),
                    textColor: s.primaryText(Colors.white),
                    onPressed: () { context.pop(); context.go('/inregistrare'); },
                  ),
                ] else ...[
                  NavRetroButton(
                    text: s.pick('Terminal', 'Panoul meu'),
                    icon: s.pick(Icons.dashboard, Icons.dashboard_outlined),
                    isFullWidth: true,
                    bgColor: AppColors.mustard,
                    textColor: AppColors.ink,
                    onPressed: () { context.pop(); _handleDashboardRouting(context, user); },
                  ),
                  const SizedBox(height: 16),
                  NavRetroButton(
                    text: s.pick('Profile', 'Profil'),
                    icon: s.pick(Icons.person, Icons.person_outline),
                    isFullWidth: true,
                    bgColor: AppColors.cardBg,
                    textColor: AppColors.ink,
                    onPressed: () { context.pop(); _handleProfileRouting(context, user); },
                  ),
                  const SizedBox(height: 16),
                  NavRetroButton(
                    text: s.pick('Log Out', 'Deconectare'),
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
        );
      },
    );
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

            return Container(
              height: isDesktop ? 90 : 78,
              width: double.infinity,
              decoration: BoxDecoration(
                color: s.pick(AppColors.bg, AppColors.cardBg),
                border: Border(
                  bottom: s.isClean
                      ? BorderSide(color: s.line, width: 1)
                      : BorderSide(color: AppColors.border, width: 3),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
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
                                  padding: EdgeInsets.all(isDesktop ? 8 : 6),
                                  decoration: s.isClean
                                      ? BoxDecoration(color: AppColors.sunset, borderRadius: BorderRadius.circular(10))
                                      : BoxDecoration(
                                          color: AppColors.sunset,
                                          border: Border.all(color: AppColors.border, width: 2),
                                        ),
                                  child: Icon(
                                    s.pick(Icons.videogame_asset, Icons.school_rounded),
                                    color: Colors.white,
                                    size: isDesktop ? s.pick(28.0, 24.0) : s.pick(22.0, 20.0),
                                  ),
                                ),
                                SizedBox(width: isDesktop ? s.pick(16.0, 12.0) : 10),
                                Text(
                                  s.pick('IMEDITATII', 'iMeditații'),
                                  style: s.isClean
                                      ? TextStyle(
                                          fontSize: isDesktop ? 24 : (isCompactPhone ? 18 : 20),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                          letterSpacing: -0.5,
                                        )
                                      : TextStyle(
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

                        // DESKTOP NAVIGATION
                        if (isDesktop) ...[
                          Row(
                            children: [
                              NavTextLink(text: s.pick('Teachers', 'Profesori'), onTap: () => context.go('/materii')),
                              SizedBox(width: s.pick(16.0, 4.0)),
                              NavTextLink(text: s.pick('Exercises', 'Exerciții'), onTap: () => context.go('/exercitii')),
                              SizedBox(width: s.pick(14.0, 4.0)),
                              NavTextLink(text: s.pick('Resources', 'Lecții'), onTap: () => context.go('/resurse')),
                            ],
                          ),
                          Row(
                            children: [
                              if (user == null) ...[
                                NavRetroButton(
                                  text: s.pick('Log In', 'Autentificare'),
                                  bgColor: AppColors.cardBg,
                                  textColor: AppColors.ink,
                                  onPressed: () => context.go('/login'),
                                ),
                                SizedBox(width: s.pick(16.0, 10.0)),
                                NavRetroButton(
                                  text: s.pick('Start Playing', 'Creează cont'),
                                  bgColor: s.primaryFill(AppColors.sky),
                                  textColor: s.primaryText(Colors.white),
                                  onPressed: () => context.go('/inregistrare'),
                                ),
                              ] else ...[
                                IconButton(
                                  tooltip: s.pick('Terminal', 'Panoul meu'),
                                  icon: Icon(s.pick(Icons.dashboard, Icons.dashboard_outlined), color: AppColors.ink, size: s.pick(28.0, 24.0)),
                                  onPressed: () => _handleDashboardRouting(context, user),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: s.pick('Profile', 'Profil'),
                                  icon: Icon(s.pick(Icons.person, Icons.person_outline), color: AppColors.ink, size: s.pick(28.0, 24.0)),
                                  onPressed: () => _handleProfileRouting(context, user),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: s.isClean
                                      ? BoxDecoration(color: s.tint(AppColors.sunset), borderRadius: s.rButton)
                                      : BoxDecoration(
                                          color: AppColors.sunset,
                                          border: Border.all(color: AppColors.border, width: 2),
                                        ),
                                  child: IconButton(
                                    tooltip: s.pick('Log Out', 'Deconectare'),
                                    icon: Icon(
                                      Icons.logout,
                                      color: s.isClean ? s.accentText(AppColors.sunset) : Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      if (context.mounted) context.go('/');
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ]
                        // MOBILE NAVIGATION
                        else ...[
                          IconButton(
                            icon: Icon(s.pick(Icons.menu, Icons.menu_rounded), color: AppColors.ink, size: s.pick(32.0, 28.0)),
                            onPressed: () => _showMobileMenu(context, user),
                          ),
                        ],
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