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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveText, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveText,
                  fontSize: 15,
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

class TeachersDashboard extends StatefulWidget {
  const TeachersDashboard({super.key});

  @override
  State<TeachersDashboard> createState() => _TeachersDashboardState();
}

class _TeachersDashboardState extends State<TeachersDashboard> {
  int _selectedIndex = 0;
  int _adminSubIndex = 0; // 0 = Exercises, 1 = Articles

  bool get _isAdmin => FirebaseAuth.instance.currentUser?.email == 'ahmadarnaoute1896@gmail.com';

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
    final isMobile = MediaQuery.of(context).size.width < 750;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
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
                              return _buildHeaderSection(teacherName, teacherId, isMobile);
                            },
                          ),
                          SizedBox(height: isMobile ? 24 : 36),

                          // Submission Action Strip (Available for Teachers and Admin)
                          _buildCreationBar(isMobile),
                          SizedBox(height: isMobile ? 28 : 40),

                          if (_isAdmin) ...[
                            _buildTabBar(isMobile),
                            SizedBox(height: isMobile ? 20 : 28),
                          ],

                          _selectedIndex == 0 ? _buildChatList(teacherId, isMobile) : _buildAdminPendingConsole(isMobile),
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

  Widget _buildCreationBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("GUILD CONTRIBUTIONS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 14 : 16, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text("Add quests for the Arena or lessons for the Codex.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            text: "+ QUEST",
            icon: Icons.add_task,
            bgColor: AppColors.forest,
            textColor: Colors.white,
            onPressed: () => context.go('/adauga-exercitiu'),
          ),
          const SizedBox(width: 8),
          RetroButton(
            text: "+ ARTICLE",
            icon: Icons.menu_book,
            bgColor: AppColors.sky,
            textColor: Colors.white,
            onPressed: () => context.go('/adauga-articol'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Row(
      children: [
        _buildTab(0, "PLAYER LOGS", Icons.forum, isMobile),
        SizedBox(width: isMobile ? 10 : 16),
        _buildTab(1, "ADMIN PENDING", Icons.security, isMobile),
      ],
    );
  }

  Widget _buildTab(int index, String title, IconData icon, bool isMobile) {
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
              if (!isSelected) BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4), blurRadius: 0),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white) : AppColors.ink,
                size: isMobile ? 18 : 20,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white) : AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 13 : 16,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPendingConsole(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _adminSubIndex = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _adminSubIndex == 0 ? AppColors.sunset : AppColors.cloud,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Text(
                    "PENDING QUESTS",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _adminSubIndex == 0 ? Colors.white : AppColors.ink),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _adminSubIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _adminSubIndex == 1 ? AppColors.sky : AppColors.cloud,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Text(
                    "PENDING ARTICLES",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _adminSubIndex == 1 ? Colors.white : AppColors.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _adminSubIndex == 0 ? _buildPendingQuests(isMobile) : _buildPendingArticles(isMobile),
      ],
    );
  }

  Widget _buildPendingArticles(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('resources')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.sunset));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("NO PENDING ARTICLES", "All submitted Codex articles have been verified and processed.", isMobile);
        }

        final articles = snapshot.data!.docs;

        return Column(
          children: articles.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RetroBlock(
                bgColor: AppColors.cardBg,
                padding: isMobile ? 14 : 20,
                shadowOffset: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          color: AppColors.sky,
                          child: Text(
                            "${data['subject']} // CLASA A ${data['grade']}-A",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                          ),
                        ),
                        Text("BY: ${(data['author'] ?? 'TEACHER').toString().toUpperCase()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(data['title'] ?? 'UNTITLED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(data['desc'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RetroButton(
                            text: "APPROVE & PUBLISH",
                            bgColor: AppColors.forest,
                            textColor: Colors.white,
                            onPressed: () => FirebaseFirestore.instance.collection('resources').doc(doc.id).update({'approved': true}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppColors.sunset, size: 26),
                          tooltip: "REJECT & DELETE",
                          onPressed: () => FirebaseFirestore.instance.collection('resources').doc(doc.id).delete(),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPendingQuests(bool isMobile) {
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
          return _buildEmptyState("NO PENDING QUESTS", "All submissions have been verified and processed.", isMobile);
        }

        final quests = snapshot.data!.docs;

        return Column(
          children: quests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RetroBlock(
                bgColor: AppColors.cardBg,
                padding: isMobile ? 14 : 20,
                shadowOffset: 4,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
                      child: Icon(Icons.pending_actions, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['title'] ?? 'UNKNOWN').toString().toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${data['subject']} | LVL ${data['grade']} | ${data['tip_exercitiu']}".toUpperCase(),
                            style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    RetroButton(
                      text: "APPROVE",
                      bgColor: AppColors.forest,
                      textColor: Colors.white,
                      onPressed: () => FirebaseFirestore.instance.collection('exercises').doc(doc.id).update({'approved': true}),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.sunset, size: 26),
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

  Widget _buildHeaderSection(String teacherName, String teacherId, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.sky,
      padding: isMobile ? 18 : 32,
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: AppColors.ink,
            child: Text(
              _isAdmin ? "ADMIN CONTROL CENTER" : "GUILD MASTER TERMINAL",
              style: TextStyle(
                color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "GREETINGS, ${teacherName.split(' ')[0].toUpperCase()}!",
            style: TextStyle(
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.w900,
              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdmin
                ? "Manage community quests, review incoming Codex articles, and supervise teachers."
                : "Oversee your apprentices and submit new quests or lectures to the guild.",
            style: TextStyle(
              fontSize: isMobile ? 14 : 17,
              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(String teacherId, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: List.generate(3, (index) => _chatCardSkeleton(isMobile)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("COMMUNICATIONS CHANNEL EMPTY", "Incoming apprentice transmissions will be logged here.", isMobile);
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
                if (userSnap.connectionState == ConnectionState.waiting) return _chatCardSkeleton(isMobile);
                if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();

                final userData = userSnap.data!.data() as Map<String, dynamic>;
                final userName = userData['name'] ?? 'UNKNOWN PLAYER';
                final userAvatar = userData['image'] as String? ?? '';

                return _chatCard(
                  name: userName,
                  avatarUrl: userAvatar,
                  lastMessage: lastMsg,
                  timestamp: timestamp,
                  isMobile: isMobile,
                  onTap: () => context.go('/chat/$chatId', extra: userName),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _chatCard({
    required String name,
    required String avatarUrl,
    required String lastMessage,
    Timestamp? timestamp,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: RetroBlock(
          bgColor: AppColors.cardBg,
          padding: isMobile ? 12 : 18,
          shadowOffset: 3,
          child: Row(
            children: [
              Container(
                width: isMobile ? 44 : 54,
                height: isMobile ? 44 : 54,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                  image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                ),
                child: avatarUrl.isEmpty
                    ? Center(child: Text(_getInitials(name), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: isMobile ? 15 : 18)))
                    : null,
              ),
              SizedBox(width: isMobile ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 14 : 17, color: AppColors.ink, letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastMessage,
                      style: TextStyle(color: AppColors.textMuted, fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (timestamp != null)
                    Text(
                      DateFormat('HH:mm').format(timestamp.toDate()),
                      style: TextStyle(color: AppColors.ink, fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_forward, color: AppColors.ink, size: isMobile ? 16 : 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatCardSkeleton(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RetroBlock(
        bgColor: AppColors.cardBg,
        padding: isMobile ? 12 : 18,
        shadowOffset: 3,
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: AppColors.cloud),
                  const SizedBox(height: 6),
                  Container(width: double.infinity, height: 10, color: AppColors.bg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 24 : 40,
      shadowOffset: 4,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_off, size: isMobile ? 48 : 64, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 12 : 14, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}