import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final effectiveTextColor = widget.textColor ?? Colors.white;

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: 24),
                const SizedBox(width: 12),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveTextColor,
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

class UserProfileViewScreen extends StatelessWidget {
  final String userId;

  const UserProfileViewScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<String> _openOrCreateChat(BuildContext context, String otherUserId, String otherName) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUid = currentUser.uid;
    final firestore = FirebaseFirestore.instance;

    final currentUserDoc = await firestore.collection('users').doc(currentUid).get();
    final otherUserDoc = await firestore.collection('users').doc(otherUserId).get();

    final currentRole = currentUserDoc.data()?['role'] ?? 'student';

    String teacherId, teacherName, studentId, studentName;

    if (currentRole == 'teacher') {
      teacherId = currentUid;
      teacherName = currentUserDoc.data()?['name'] ?? '';
      studentId = otherUserId;
      studentName = otherUserDoc.data()?['name'] ?? otherName;
    } else {
      teacherId = otherUserId;
      teacherName = otherUserDoc.data()?['name'] ?? otherName;
      studentId = currentUid;
      studentName = currentUserDoc.data()?['name'] ?? '';
    }

    final existingChats = await firestore
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    final newChat = await firestore.collection('chats').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': studentId,
      'studentName': studentName,
      'isEnded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
            title: Text(
              "PLAYER LOGS",
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 2.0),
            ),
            centerTitle: true,
          ),
          body: FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.sunset));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: RetroBlock(
                    bgColor: AppColors.cloud,
                    child: Text(
                      "PLAYER DATA CORRUPTED OR NOT FOUND.",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 18),
                    ),
                  ),
                );
              }

              final data = snapshot.data!;
              final image = data['image'];
              final name = data['name'] ?? 'UNKNOWN PLAYER';
              final bio = data['bio'] ?? 'NO BIO LOGGED';
              final contact = data['contact'] ?? 'UNSPECIFIED';
              final email = data['email'] ?? 'UNKNOWN';

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RetroBlock(
                          bgColor: AppColors.cloud,
                          padding: 40,
                          child: Column(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  border: Border.all(color: AppColors.border, width: 4),
                                  boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6))],
                                  image: image != null
                                      ? DecorationImage(
                                          image: NetworkImage(image),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: image == null
                                    ? Icon(Icons.person, size: 80, color: AppColors.ink)
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                color: AppColors.ink,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  "PLAYER ACCOUNT",
                                  style: TextStyle(
                                    color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                name.toString().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  border: Border.all(color: AppColors.border, width: 2),
                                ),
                                child: Text(
                                  bio.toString().toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _infoTile(
                                'COMMUNICATION LINK',
                                email,
                                AppColors.sky,
                                Icons.email,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _infoTile(
                                'CONTACT NODE',
                                contact,
                                AppColors.mustard,
                                Icons.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        RetroButton(
                          text: "OPEN COMM CHANNEL",
                          icon: Icons.chat_bubble,
                          bgColor: AppColors.forest,
                          textColor: Colors.white,
                          isFullWidth: true,
                          onPressed: () async {
                            final chatId = await _openOrCreateChat(context, userId, name);
                            if (context.mounted) {
                              context.pushReplacement('/chat/$chatId', extra: name);
                            }
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

  Widget _infoTile(String title, String? value, Color bgColor, IconData icon) {
    final textColor = AppColors.isDark && bgColor == AppColors.mustard ? const Color(0xFF10161A) : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (value ?? '-').toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}