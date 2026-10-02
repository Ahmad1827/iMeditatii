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
  final bool isClean;

  const NavTextLink({
    super.key,
    required this.text,
    required this.onTap,
    this.isMobile = false,
    this.isClean = false,
  });

  @override
  State<NavTextLink> createState() => _NavTextLinkState();
}

class _NavTextLinkState extends State<NavTextLink> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isClean) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              widget.text,
              textAlign: widget.isMobile ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                color: isHovered ? const Color(0xFF55EFC4) : Colors.white.withOpacity(0.9),
                fontSize: 14.5,
                fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }

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

  void _showMobileMenu(BuildContext context, User? user, bool isClean) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isClean ? const Color(0xFF1E2327) : AppColors.bg,
          borderRadius: isClean ? const BorderRadius.vertical(top: Radius.circular(16)) : BorderRadius.zero,
          border: isClean ? null : Border(top: BorderSide(color: AppColors.border, width: 4)),
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
                  Text(
                    isClean ? "Meniu Navigare" : "SYSTEM MENU",
                    style: TextStyle(
                      color: isClean ? Colors.white : AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isClean ? 0.5 : 2.0,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isClean ? Colors.white70 : AppColors.ink, size: 28),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              NavTextLink(text: isClean ? 'Probleme & Exerciții' : 'Daily Quest', isMobile: true, isClean: isClean, onTap: () { context.pop(); context.go('/exercitii'); }),
              const SizedBox(height: 6),
              NavTextLink(text: isClean ? 'Teorie & Articole (Codex)' : 'The Codex', isMobile: true, isClean: isClean, onTap: () { context.pop(); context.go('/resurse'); }),
              const SizedBox(height: 6),
              NavTextLink(text: isClean ? 'Profesori & Meditații' : 'Guild Masters', isMobile: true, isClean: isClean, onTap: () { context.pop(); context.go('/materii'); }),
              const SizedBox(height: 18),
              Container(height: 1, color: isClean ? Colors.white12 : AppColors.border),
              const SizedBox(height: 18),

              if (user == null) ...[
                if (isClean) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () { context.pop(); context.go('/login'); },
                    child: const Text("Autentificare", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20BF6B), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () { context.pop(); context.go('/inregistrare'); },
                    child: const Text("Înregistrare Cont", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  NavRetroButton(text: 'Log In', isFullWidth: true, bgColor: AppColors.cardBg, textColor: AppColors.ink, onPressed: () { context.pop(); context.go('/login'); }),
                  const SizedBox(height: 16),
                  NavRetroButton(text: 'Start Playing', isFullWidth: true, bgColor: AppColors.sky, textColor: Colors.white, onPressed: () { context.pop(); context.go('/inregistrare'); }),
                ]
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClean ? const Color(0xFF2C3E50) : AppColors.mustard,
                    foregroundColor: isClean ? Colors.white : AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.dashboard, size: 20),
                  label: Text(isClean ? "Panou Control" : "Terminal"),
                  onPressed: () { context.pop(); _handleDashboardRouting(context, user); },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClean ? const Color(0xFF2C3E50) : AppColors.cardBg,
                    foregroundColor: isClean ? Colors.white : AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.person, size: 20),
                  label: Text(isClean ? "Profilul Meu" : "Profile"),
                  onPressed: () { context.pop(); _handleProfileRouting(context, user); },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunset,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text("Deconectare"),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isClean = ThemeManager.isClean;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // ----------------------------------------------------
        // PBINFO-INSPIRED ACADEMIC CLEAN NAVBAR
        // ----------------------------------------------------
        if (isClean) {
          return Container(
            height: isDesktop ? 64 : 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2327), // Authentic pbinfo dark graphite header
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
                  child: Row(
                    children: [
                      // Clean Academic Logo
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF20BF6B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.school, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "iMeditatii",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isDesktop) ...[
                        const SizedBox(width: 28),
                        // Desktop Direct Academic Links
                        NavTextLink(text: "Probleme", isClean: true, onTap: () => context.go('/exercitii')),
                        NavTextLink(text: "Resurse & Teorie", isClean: true, onTap: () => context.go('/resurse')),
                        NavTextLink(text: "Profesori", isClean: true, onTap: () => context.go('/materii')),

                        const Spacer(),

                        // Clean inline search input
                        Container(
                          width: 240,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 16, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  cursorColor: const Color(0xFF55EFC4),
                                  decoration: InputDecoration(
                                    hintText: "Caută probleme, teorie...",
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (query) {
                                    if (query.trim().isNotEmpty) {
                                      context.go('/lista-exercitii?materie=${Uri.encodeComponent(query.trim())}');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),

                        // Auth Actions
                        if (user == null) ...[
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text("Autentificare", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF20BF6B),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                            onPressed: () => context.go('/inregistrare'),
                            child: const Text("Cont Nou", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.dashboard_outlined, color: Colors.white70, size: 22),
                            tooltip: "Panou",
                            onPressed: () => _handleDashboardRouting(context, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_outline, color: Colors.white70, size: 22),
                            tooltip: "Profil",
                            onPressed: () => _handleProfileRouting(context, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                            tooltip: "Deconectare",
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) context.go('/');
                            },
                          ),
                        ],
                      ] else ...[
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                          onPressed: () => _showMobileMenu(context, user, true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // ----------------------------------------------------
        // ORIGINAL 8-BIT RETRO NAVBAR
        // ----------------------------------------------------
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
                                fontSize: isDesktop ? 32 : 24,
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
                          NavTextLink(text: 'Guild Masters', onTap: () => context.go('/materii')),
                          const SizedBox(width: 14),
                          NavTextLink(text: 'Daily Quest', onTap: () => context.go('/exercitii')),
                          const SizedBox(width: 14),
                          NavTextLink(text: 'The Codex', onTap: () => context.go('/resurse')),
                        ],
                      ),
                      Row(
                        children: [
                          if (user == null) ...[
                            NavRetroButton(text: 'Log In', bgColor: AppColors.cardBg, textColor: AppColors.ink, onPressed: () => context.go('/login')),
                            const SizedBox(width: 14),
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
                    ] else ...[
                      IconButton(
                        icon: Icon(Icons.menu, color: AppColors.ink, size: 32),
                        onPressed: () => _showMobileMenu(context, user, false),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}