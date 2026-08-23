import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveText, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/materii');
          });
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
          );
        }

        final String userId = user.uid;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox(
                                  height: 120,
                                  child: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
                                );
                              }
                              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                              final userName = data['name'] ?? 'PLAYER';
                              return _buildHeaderSection(userName, userId);
                            },
                          ),
                          const SizedBox(height: 48),
                          Row(
                            children: [
                              Icon(Icons.forum, color: AppColors.ink, size: 28),
                              const SizedBox(width: 16),
                              Text(
                                "MASTER LOGS (MESSAGES)",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildChatList(userId),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(String userName, String userId) {
    return RetroBlock(
      bgColor: AppColors.forest,
      padding: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: AppColors.ink,
                  child: Text(
                    "PLAYER TERMINAL",
                    style: TextStyle(
                      color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "GREETINGS, ${userName.split(' ')[0].toUpperCase()}!",
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                const Text(
                  "ACCESS YOUR COMMS AND TRACK QUEST PROGRESS.",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          RetroButton(
            text: "PROFILE",
            icon: Icons.person,
            bgColor: AppColors.cardBg,
            textColor: AppColors.ink,
            onPressed: () => context.go('/elev/$userId'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('studentId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: List.generate(3, (index) => _chatCardSkeleton()));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'TERMINAL ERROR: ${snapshot.error}'.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

        final chats = snapshot.data!.docs;

        return Column(
          children: chats.map((chatDoc) {
            final data = chatDoc.data()! as Map<String, dynamic>;
            final chatId = chatDoc.id;
            final teacherId = data['teacherId'] ?? '';
            final lastMsg = data['lastMessage'] ?? '...';
            final timestamp = data['updatedAt'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('teachers').doc(teacherId).get(),
              builder: (context, teacherSnap) {
                if (teacherSnap.connectionState == ConnectionState.waiting) return _chatCardSkeleton();
                if (!teacherSnap.hasData || !teacherSnap.data!.exists) return const SizedBox.shrink();

                final teacherData = teacherSnap.data!.data() as Map<String, dynamic>;
                final teacherName = teacherData['name'] ?? 'UNKNOWN MASTER';
                final teacherAvatar = teacherData['image'] as String? ?? '';

                return _RetroChatCard(
                  name: teacherName,
                  avatarUrl: teacherAvatar,
                  lastMessage: lastMsg,
                  timestamp: timestamp,
                  initials: _getInitials(teacherName),
                  onTap: () => context.go('/chat/$chatId', extra: teacherName),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _chatCardSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: RetroBlock(
        bgColor: AppColors.cardBg,
        padding: 20,
        shadowOffset: 4,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 18, color: AppColors.cloud),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 14, color: AppColors.bg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: 60,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.speaker_notes_off, size: 80, color: AppColors.textMuted),
            const SizedBox(height: 24),
            Text(
              "COMMS CHANNEL EMPTY",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Text(
              "NO LOGS FROM MASTERS YET.",
              style: TextStyle(fontSize: 16, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            RetroButton(
              text: "SEARCH MASTERS",
              bgColor: AppColors.forest,
              textColor: Colors.white,
              onPressed: () => context.go('/materii'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetroChatCard extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final Timestamp? timestamp;
  final String initials;
  final VoidCallback onTap;

  const _RetroChatCard({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timestamp,
    required this.initials,
    required this.onTap,
  });

  @override
  State<_RetroChatCard> createState() => _RetroChatCardState();
}

class _RetroChatCardState extends State<_RetroChatCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(
              _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
              _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
              0,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: _isPressed ? const Offset(0, 0) : const Offset(6, 6),
                  blurRadius: 0,
                )
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    border: Border.all(color: AppColors.border, width: 2),
                    image: widget.avatarUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(widget.avatarUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: widget.avatarUrl.isEmpty
                      ? Center(
                          child: Text(
                            widget.initials,
                            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 20),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.lastMessage,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.timestamp != null)
                      Text(
                        DateFormat('HH:mm').format(widget.timestamp!.toDate()),
                        style: TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_forward, color: AppColors.ink, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}