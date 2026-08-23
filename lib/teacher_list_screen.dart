import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final double fontSize;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.icon,
    this.fontSize = 14,
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
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: widget.fontSize + 2),
                const SizedBox(width: 6),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
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

class TeacherListScreen extends StatefulWidget {
  final Map<String, dynamic> specialization;

  const TeacherListScreen({super.key, required this.specialization});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _searchFilter = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _subjectName => widget.specialization['name']?.toString() ?? 'DISCIPLINE';

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('matemat')) return Icons.functions;
    if (s.contains('info')) return Icons.data_object;
    if (s.contains('fizic')) return Icons.bolt;
    if (s.contains('chim')) return Icons.science;
    if (s.contains('bio')) return Icons.eco;
    if (s.contains('român')) return Icons.menu_book;
    if (s.contains('englez') || s.contains('francez')) return Icons.language;
    if (s.contains('istorie')) return Icons.account_balance;
    if (s.contains('geograf')) return Icons.public;
    return Icons.school;
  }

  Future<String> _openOrCreateChat(BuildContext context, String teacherId, String teacherName) async {
    final currentUid = currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final currentUserDoc = await firestore.collection('users').doc(currentUid).get();
    final studentName = currentUserDoc.data()?['name'] ?? 'Elev';

    final existingChats = await firestore
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: currentUid)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    final newChat = await firestore.collection('chats').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': currentUid,
      'studentName': studentName,
      'isEnded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(isMobile),
                                const SizedBox(height: 28),
                                Expanded(
                                  child: _buildTeachersList(isMobile),
                                ),
                                const SizedBox(height: 48),
                                _buildFooter(isMobile),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, isMobile ? 20 : 32, 24, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: RetroBlock(
            bgColor: AppColors.mustard,
            padding: isMobile ? 20 : 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Centered Back Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/materii'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.border, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: AppColors.shadow, offset: const Offset(2.5, 2.5)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.arrow_back, color: AppColors.ink, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Subject Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(color: AppColors.border, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: AppColors.shadow, offset: const Offset(2.5, 2.5)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(_getSubjectIcon(_subjectName), color: AppColors.ink, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AVAILABLE MASTERS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.isDark ? const Color(0xFF10161A).withOpacity(0.8) : AppColors.ink.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            _subjectName.toUpperCase(),
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search Input inside Header
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border, width: 2.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: AppColors.ink, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchFilter = val.trim()),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                          cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                          decoration: InputDecoration(
                            hintText: "SEARCH MENTOR BY NAME...",
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchFilter.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: AppColors.ink, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchFilter = '');
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeachersList(bool isMobile) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1120),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('teachers').where('active', isEqualTo: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.sunset));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final allDocs = snapshot.data!.docs;

            final teachers = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sub = data['subject']?.toString().toLowerCase() ?? '';
              final name = data['name']?.toString().toLowerCase() ?? '';

              final matchesSubject = sub.contains(_subjectName.toLowerCase()) || _subjectName.toLowerCase().contains(sub);
              final matchesSearch = _searchFilter.isEmpty || name.contains(_searchFilter.toLowerCase());

              return matchesSubject && matchesSearch;
            }).toList();

            if (teachers.isEmpty) {
              return _buildEmptyState();
            }

            return Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.start,
              children: teachers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _TeacherCard(
                  id: doc.id,
                  data: data,
                  onMessage: () async {
                    if (currentUser == null) {
                      context.go('/login');
                      return;
                    }
                    final name = data['name'] ?? 'Profesor';
                    final chatId = await _openOrCreateChat(context, doc.id, name);
                    if (context.mounted) {
                      context.push('/chat/$chatId', extra: name);
                    }
                  },
                  onViewProfile: () {
                    context.push('/profesor/${doc.id}');
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          border: Border.all(color: AppColors.border, width: 2.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              "NO GUILD MASTERS REGISTERED YET.",
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "Check back soon or explore other disciplines.",
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 28 : 36),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'IMEDITATII // MASTERS',
              style: TextStyle(fontSize: isMobile ? 24 : 30, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0),
            ),
            const SizedBox(height: 6),
            Text(
              'LEVEL UP YOUR KNOWLEDGE WITH 1-ON-1 SESSIONS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherCard extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onMessage;
  final VoidCallback onViewProfile;

  const _TeacherCard({
    required this.id,
    required this.data,
    required this.onMessage,
    required this.onViewProfile,
  });

  @override
  State<_TeacherCard> createState() => _TeacherCardState();
}

class _TeacherCardState extends State<_TeacherCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'PROFESOR';
    final image = widget.data['image'] as String?;
    final exp = widget.data['experience']?.toString() ?? '1';
    final price = widget.data['price']?.toString() ?? '50';
    final subject = widget.data['subject']?.toString() ?? 'GENERAL';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onViewProfile();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 340,
          transform: Matrix4.translationValues(
            _isPressed ? 3.0 : (_isHovering ? -3.0 : 0.0),
            _isPressed ? 3.0 : (_isHovering ? -3.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: _isPressed ? const Offset(0, 0) : const Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar & Details Header
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        border: Border.all(color: AppColors.border, width: 2.5),
                        image: image != null && image.isNotEmpty
                            ? DecorationImage(image: CachedNetworkImageProvider(image), fit: BoxFit.cover)
                            : null,
                      ),
                      child: image == null || image.isEmpty
                          ? Icon(Icons.person, size: 40, color: AppColors.ink)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            color: AppColors.sky,
                            child: Text(
                              subject.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.military_tech, size: 16, color: AppColors.sunset),
                              const SizedBox(width: 4),
                              Text(
                                "$exp ${int.tryParse(exp) == 1 ? 'AN' : 'ANI'} EXPERIENȚĂ",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 2, color: AppColors.border),
              // Hourly Rate Strip
              Container(
                color: AppColors.cloud,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "HOURLY BOUNTY:",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mustard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Text(
                        "$price RON / HR",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 2, color: AppColors.border),
              // Actions
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        text: "PROFILE",
                        bgColor: AppColors.cardBg,
                        textColor: AppColors.ink,
                        fontSize: 12,
                        onPressed: widget.onViewProfile,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: RetroButton(
                        text: "INITIATE COMMS",
                        icon: Icons.send,
                        bgColor: AppColors.forest,
                        textColor: Colors.white,
                        fontSize: 12,
                        onPressed: widget.onMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}