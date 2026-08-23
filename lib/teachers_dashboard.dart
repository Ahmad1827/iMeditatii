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

class TeachersDashboard extends StatefulWidget {
  const TeachersDashboard({super.key});

  @override
  State<TeachersDashboard> createState() => _TeachersDashboardState();
}

class _TeachersDashboardState extends State<TeachersDashboard> {
  final bool _isAdmin = true;
  int _selectedIndex = 0;

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
    final String teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final teacherFuture = FirebaseFirestore.instance.collection('teachers').doc(teacherId).get();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/adauga-exercitiu'),
            backgroundColor: AppColors.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.border, width: 2),
            ),
            icon: Icon(Icons.add_task, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white),
            label: Text(
              "NEW QUEST",
              style: TextStyle(
                color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
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
                            future: teacherFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox(
                                  height: 120,
                                  child: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
                                );
                              }
                              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                              final teacherName = data['name'] ?? 'MASTER';
                              return _buildHeaderSection(teacherName, teacherId);
                            },
                          ),
                          const SizedBox(height: 48),
                          if (_isAdmin) _buildTabBar(),
                          const SizedBox(height: 32),
                          _selectedIndex == 0 ? _buildChatList(teacherId) : _buildPendingQuests(),
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

  Widget _buildTabBar() {
    return Row(
      children: [
        _buildTab(0, "PLAYER LOGS", Icons.forum),
        const SizedBox(width: 16),
        _buildTab(1, "ADMIN PENDING", Icons.security),
      ],
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              if (!isSelected) BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4), blurRadius: 0),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                    : AppColors.ink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                      : AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String teacherName, String teacherId) {
    return RetroBlock(
      bgColor: AppColors.sky,
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
                    "GUILD MASTER TERMINAL",
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
                  "GREETINGS, ${teacherName.split(' ')[0].toUpperCase()}!",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Oversee your apprentices and initialize new quest parameters.",
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          RetroButton(
            onPressed: () => context.go('/profesor/$teacherId'),
            text: "PROFILE",
            icon: Icons.person,
            bgColor: AppColors.cardBg,
            textColor: AppColors.ink,
          )
        ],
      ),
    );
  }

  Widget _buildChatList(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('teacherId', isEqualTo: teacherId)
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("COMMUNICATIONS CHANNEL EMPTY", "Incoming apprentice transmissions will be logged here.");
        }

        final chats = snapshot.data!.docs;

        return Column(
          children: chats.map((chatDoc) {
            final data = chatDoc.data()! as Map<String, dynamic>;
            final chatId = chatDoc.id;
            final studentId = data['studentId'] ?? '';
            if (studentId.isEmpty) return const SizedBox.shrink();

            final lastMsg = data['lastMessage'] ?? '...';
            final timestamp = data['updatedAt'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return _chatCardSkeleton();
                if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();

                final userData = userSnap.data!.data() as Map<String, dynamic>;
                final userName = userData['name'] ?? 'UNKNOWN PLAYER';
                final userAvatar = userData['image'] as String? ?? '';

                return _chatCard(
                  name: userName,
                  avatarUrl: userAvatar,
                  lastMessage: lastMsg,
                  timestamp: timestamp,
                  onTap: () => context.go('/chat/$chatId', extra: userName),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPendingQuests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exercises')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.sunset));
        }
        if (snapshot.hasError) return Center(child: Text('ERROR: ${snapshot.error}', style: TextStyle(color: AppColors.sunset)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("NO PENDING QUESTS", "All submissions have been verified and processed.");
        }

        final quests = snapshot.data!.docs;

        return Column(
          children: quests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RetroBlock(
                bgColor: AppColors.cardBg,
                padding: 24,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
                      child: Icon(Icons.pending_actions, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['title'] ?? 'UNKNOWN').toString().toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${data['subject']} | LVL ${data['grade']} | ${data['tip_exercitiu']}".toUpperCase(),
                            style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    RetroButton(
                      text: "APPROVE",
                      bgColor: AppColors.forest,
                      textColor: Colors.white,
                      onPressed: () => FirebaseFirestore.instance.collection('exercises').doc(doc.id).update({'approved': true}),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.sunset, size: 32),
                      onPressed: () => FirebaseFirestore.instance.collection('exercises').doc(doc.id).delete(),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _chatCard({required String name, required String avatarUrl, required String lastMessage, Timestamp? timestamp, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: RetroBlock(
          bgColor: AppColors.cardBg,
          padding: 20,
          shadowOffset: 4,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                  image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                ),
                child: avatarUrl.isEmpty
                    ? Center(child: Text(_getInitials(name), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 20)))
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMessage,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w600),
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
                  if (timestamp != null)
                    Text(
                      DateFormat('HH:mm').format(timestamp.toDate()),
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
            Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2))),
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

  Widget _buildEmptyState(String title, String subtitle) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: 60,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_off, size: 80, color: AppColors.textMuted),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}