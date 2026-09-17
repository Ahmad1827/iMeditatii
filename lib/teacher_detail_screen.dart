import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

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

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.icon,
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
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveText, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherDetailScreen extends StatelessWidget {
  final String teacherId;

  const TeacherDetailScreen({required this.teacherId, super.key});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('teachers').doc(teacherId);
    final isMobile = MediaQuery.of(context).size.width < 750;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              'GUILD MASTER PROFILE',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 22,
                letterSpacing: 2.0,
              ),
            ),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.ink, size: isMobile ? 26 : 32),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
          body: FutureBuilder<DocumentSnapshot>(
            future: docRef.get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.sunset));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: RetroBlock(
                    bgColor: AppColors.cloud,
                    child: Text(
                      'MASTER DATA CORRUPTED OR NOT FOUND.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final imageUrl = data['image'] ?? '';
              final specialization = data['specialization'] ?? data['subject'] ?? 'UNKNOWN DISCIPLINE';

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // PROFILE HEADER
                        RetroBlock(
                          bgColor: AppColors.mustard,
                          padding: isMobile ? 24 : 40,
                          shadowOffset: isMobile ? 4 : 6,
                          child: Column(
                            children: [
                              Container(
                                width: isMobile ? 110 : 140,
                                height: isMobile ? 110 : 140,
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  border: Border.all(color: AppColors.border, width: 4),
                                  boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6))],
                                  image: imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageUrl.isEmpty
                                    ? Icon(Icons.person, size: isMobile ? 64 : 80, color: AppColors.ink)
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                color: AppColors.ink,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                child: Text(
                                  "VERIFIED MASTER",
                                  style: TextStyle(
                                    color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                (data['name'] ?? 'UNKNOWN').toString().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 40,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                specialization.toString().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 32),

                        // STATS & INFO
                        if (isMobile) ...[
                          _infoTile('EXPERIENCE', '${data['experience'] ?? 0} YEARS', AppColors.sky, Icons.star, isMobile),
                          const SizedBox(height: 14),
                          _infoTile('EDUCATION', data['education'] ?? 'NOT SPECIFIED', AppColors.cloud, Icons.school, isMobile),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _infoTile('EXPERIENCE', '${data['experience'] ?? 0} YEARS', AppColors.sky, Icons.star, isMobile),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _infoTile('EDUCATION', data['education'] ?? 'NOT SPECIFIED', AppColors.cloud, Icons.school, isMobile),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: isMobile ? 14 : 24),
                        _infoTile('COMMUNICATION LINK', data['email'] ?? 'UNKNOWN', AppColors.cardBg, Icons.email, isMobile, isFullWidth: true),
                        SizedBox(height: isMobile ? 14 : 24),
                        _infoTile('SYSTEM UID', teacherId, AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink, Icons.fingerprint, isMobile, isFullWidth: true, textColor: Colors.white),
                        SizedBox(height: isMobile ? 28 : 48),

                        // ACTIONS
                        RetroButton(
                          text: 'INITIATE CONTACT',
                          icon: Icons.forum,
                          bgColor: AppColors.forest,
                          textColor: Colors.white,
                          isFullWidth: true,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'CONTACT CHANNEL OPENED. PHONE: ${data['contact'] ?? 'N/A'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                backgroundColor: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: BorderSide(color: AppColors.border, width: 3),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        RetroButton(
                          text: 'VIEW PLAYER REVIEWS',
                          icon: Icons.rate_review,
                          bgColor: AppColors.sky,
                          textColor: Colors.white,
                          isFullWidth: true,
                          onPressed: () {
                            context.push('/profesor/$teacherId/recenzii');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoTile(String title, String? value, Color bgColor, IconData icon, bool isMobile, {bool isFullWidth = false, Color? textColor}) {
    final effectiveTextColor = textColor ?? AppColors.ink;

    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: effectiveTextColor, size: isMobile ? 20 : 24),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: effectiveTextColor,
                  fontSize: isMobile ? 12 : 14,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (value ?? '-').toUpperCase(),
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: effectiveTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}