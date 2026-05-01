import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'custom_navbar.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor,
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

class TeacherListScreen extends StatefulWidget {
  final Map<String, dynamic> specialization;

  const TeacherListScreen({required this.specialization, super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  Future<void> _handleMessageTap(BuildContext context, String teacherId, String teacherName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LOGIN REQUIRED FOR COMMS.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.sunset,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.ink, width: 3)),
        ),
      );
      return;
    }

    if (currentUser.uid == teacherId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('INVALID TARGET: SELF.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.mustard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.ink, width: 3)),
        ),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    String chatId;

    if (chatQuery.docs.isNotEmpty) {
      chatId = chatQuery.docs.first.id;
    } else {
      final newChat = await FirebaseFirestore.instance.collection('chats').add({
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentId': currentUser.uid,
        'studentName': currentUser.displayName ?? 'PLAYER',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'isEnded': false,
        'isSessionPaid': false,
        'isStudentAccepted': false,
      });
      chatId = newChat.id;
    }

    if (mounted) {
      context.go('/chat/$chatId', extra: teacherName);
    }
  }

  Widget _buildNavbar() {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.sunset,
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: const Icon(Icons.school, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'IMEDITATII',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/materii'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.mustard,
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: const Text(
                            "GUILD MASTERS",
                            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/exercitii'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            "DAILY QUESTS",
                            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 3, height: 32, color: AppColors.ink),
                    const SizedBox(width: 16),
                    _buildAuthActions(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthActions() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.sunset, strokeWidth: 3));
        }
        final user = snapshot.data;

        if (user == null) {
          return RetroButton(
            text: 'LOG IN',
            bgColor: Colors.white,
            textColor: AppColors.ink,
            onPressed: () => context.go('/login'),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/panou-profesor');
                    } else {
                      context.go('/panou-elev');
                    }
                  }
                } catch (e) {
                  debugPrint("ERROR: $e");
                }
              },
              icon: const Icon(Icons.dashboard, color: AppColors.ink, size: 32),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/profesor/${user.uid}');
                    } else {
                      context.go('/elev/${user.uid}');
                    }
                  }
                } catch (e) {
                  debugPrint("ERROR: $e");
                }
              },
              icon: const Icon(Icons.account_box, color: AppColors.ink, size: 32),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.sunset,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) context.go('/');
                },
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(String specName, Color themeColor, IconData themeIcon) {
    return RetroBlock(
      bgColor: AppColors.cloud,
      padding: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor,
                  border: Border.all(color: AppColors.ink, width: 3),
                ),
                child: Icon(themeIcon, color: AppColors.ink, size: 40),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AVAILABLE MASTERS",
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 16),
                    ),
                    Text(
                      specName.toUpperCase(),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.ink, width: 3),
                  boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
                ),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, size: 32, color: AppColors.ink),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "SELECT A MASTER AND INITIATE CONTACT TO SCHEDULE YOUR TRAINING.",
            style: TextStyle(fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specName = widget.specialization['name'] ?? 'DISCIPLINE';
    final themeColor = widget.specialization['color'] as Color? ?? AppColors.sky;
    final themeIcon = widget.specialization['icon'] as IconData? ?? Icons.school;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(specName, themeColor, themeIcon),
                      const SizedBox(height: 48),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('teachers')
                            .where('subject', isEqualTo: specName)
                            .where('active', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: AppColors.sunset),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'ERROR: ${snapshot.error}'.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return RetroBlock(
                              bgColor: Colors.white,
                              padding: 60,
                              child: Column(
                                children: const [
                                  Icon(Icons.search_off, size: 80, color: AppColors.ink),
                                  SizedBox(height: 24),
                                  Text(
                                    "NO MASTERS AVAILABLE YET.",
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "AWAITING GUILD APPROVALS FOR THIS DISCIPLINE.",
                                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 500,
                              mainAxisSpacing: 32,
                              crossAxisSpacing: 32,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data()! as Map<String, dynamic>;
                              final teacherId = docs[index].id;
                              final price = data['price']?.toString() ?? '50';

                              return _RetroTeacherCard(
                                data: data,
                                teacherId: teacherId,
                                price: price,
                                themeColor: themeColor,
                                onMessageTap: () => _handleMessageTap(context, teacherId, data['name'] ?? 'MASTER'),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetroTeacherCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String teacherId;
  final String price;
  final Color themeColor;
  final VoidCallback onMessageTap;

  const _RetroTeacherCard({
    required this.data,
    required this.teacherId,
    required this.price,
    required this.themeColor,
    required this.onMessageTap,
  });

  @override
  State<_RetroTeacherCard> createState() => _RetroTeacherCardState();
}

class _RetroTeacherCardState extends State<_RetroTeacherCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data['image'] ?? '';
    final name = widget.data['name'] ?? 'UNKNOWN';
    final experience = widget.data['experience'] ?? '0';
    final education = widget.data['education'] ?? '';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
            _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
            _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: _isPressed ? const Offset(0, 0) : const Offset(8, 8),
                blurRadius: 0,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: widget.themeColor,
                              border: Border.all(color: AppColors.ink, width: 3),
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person, size: 40, color: AppColors.ink)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.mustard,
                              border: Border.all(color: AppColors.ink, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${widget.price} RON',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink),
                                ),
                                const Text(
                                  '/ HOUR',
                                  style: TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        name.toString().toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: AppColors.ink,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.military_tech, size: 24, color: AppColors.ink),
                          const SizedBox(width: 8),
                          Text(
                            '$experience YEARS EXP.',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (education.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.school, size: 24, color: AppColors.ink),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                education.toString().toUpperCase(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Container(height: 3, color: AppColors.ink),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        text: 'PROFILE',
                        bgColor: AppColors.cloud,
                        textColor: AppColors.ink,
                        onPressed: () => context.go('/profesor/${widget.teacherId}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RetroButton(
                        text: 'MESSAGE',
                        icon: Icons.send,
                        bgColor: widget.themeColor,
                        onPressed: widget.onMessageTap,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}