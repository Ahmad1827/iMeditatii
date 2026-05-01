import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

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
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 24),
                const SizedBox(width: 12),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 20,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'GUILD MASTER PROFILE',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.sunset));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: RetroBlock(
                bgColor: AppColors.cloud,
                child: const Text(
                  'MASTER DATA CORRUPTED OR NOT FOUND.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final imageUrl = data['image'] ?? '';
          final specialization = data['specialization'] ?? data['subject'] ?? 'UNKNOWN DISCIPLINE';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // PROFILE HEADER
                    RetroBlock(
                      bgColor: AppColors.mustard,
                      padding: 40,
                      child: Column(
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.ink, width: 4),
                              boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(6, 6))],
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person, size: 80, color: AppColors.ink)
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            color: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: const Text(
                              "VERIFIED MASTER",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (data['name'] ?? 'UNKNOWN').toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            specialization.toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // STATS & INFO
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            'EXPERIENCE',
                            '${data['experience'] ?? 0} YEARS',
                            AppColors.sky,
                            Icons.star,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _infoTile(
                            'EDUCATION',
                            data['education'] ?? 'NOT SPECIFIED',
                            AppColors.cloud,
                            Icons.school,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _infoTile(
                      'COMMUNICATION LINK',
                      data['email'] ?? 'UNKNOWN',
                      Colors.white,
                      Icons.email,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    _infoTile(
                      'SYSTEM UID',
                      teacherId,
                      AppColors.ink,
                      Icons.fingerprint,
                      isFullWidth: true,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 48),

                    // ACTIONS
                    RetroButton(
                      text: 'INITIATE CONTACT',
                      icon: Icons.forum,
                      bgColor: AppColors.forest,
                      isFullWidth: true,
                      onPressed: () {
                        // Keeps your original logic but styled!
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'CONTACT CHANNEL OPENED. PHONE: ${data['contact'] ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            backgroundColor: AppColors.ink,
                            behavior: SnackBarBehavior.floating,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: AppColors.cloud, width: 3),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    RetroButton(
                      text: 'VIEW PLAYER REVIEWS',
                      icon: Icons.rate_review,
                      bgColor: AppColors.sky,
                      textColor: AppColors.ink,
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
  }

  Widget _infoTile(String title, String? value, Color bgColor, IconData icon, {bool isFullWidth = false, Color textColor = AppColors.ink}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (value ?? '-').toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}