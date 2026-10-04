import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'clean_kit.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'sticky_footer.dart';
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize;

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 17,
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

class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({super.key, required this.userId});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  late Future<Map<String, dynamic>?> _future = _getUserData();
  final ScrollController _scroll = ScrollController();
  bool _busy = false;
  bool _hidden = false;
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  String get userId => widget.userId;

  @override
  void didUpdateWidget(covariant UserProfileViewScreen old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) _future = _getUserData();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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

  Future<void> _openChat(BuildContext context, String name, {bool replace = true}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      context.go('/login');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final chatId = await _openOrCreateChat(context, userId, name);
      if (!context.mounted) return;
      if (replace) {
        context.pushReplacement('/chat/$chatId', extra: name);
      } else {
        context.push('/chat/$chatId', extra: name);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final w = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(context, w < 750) : _buildRetro(context, w < 750);
      },
    );
  }

  // ===========================================================================
  // CLEAN — public player card: cover banner, stats, badges and LEADERBOARD
  // RANK computed from the real standings. Dragon scene.
  // ===========================================================================
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cBlue = Color(0xFF3B82F6);

  static final RegExp _progressKey = RegExp(r'^(.+?)_(\d+)_(.+)$');

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF212529),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Pb.radius),
      ),
    );
  }

  Future<int?> _rankOf(int solved) async {
    if (solved <= 0) return null;
    try {
      final agg = await FirebaseFirestore.instance.collection('users').where('solvedCount', isGreaterThan: solved).count().get();
      return (agg.count ?? 0) + 1;
    } catch (_) {
      return null;
    }
  }

  Widget _buildClean(BuildContext context, bool isMobile) {
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              scene: HomeScene.fantasy,
              blockers: [_mainKey, _footKey],
              cardsHidden: _hidden,
              onToggleCards: () => setState(() => _hidden = !_hidden),
              hideLabel: 'Ascunde profilul',
              showLabel: 'Arată profilul',
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _future,
                builder: (context, snap) {
                  Widget body;
                  if (snap.connectionState == ConnectionState.waiting) {
                    body = const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: Pb.primary)));
                  } else if (!snap.hasData || snap.data == null) {
                    body = Container(
                      padding: const EdgeInsets.all(30),
                      decoration: ckDeco(r: 16),
                      child: Column(
                        children: [
                          Icon(Icons.person_off_outlined, size: 36, color: Pb.muted),
                          const SizedBox(height: 10),
                          Text('Profilul nu a fost găsit.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Pb.text)),
                          const SizedBox(height: 16),
                          PbButton(text: 'Înapoi', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: () => _back(context)),
                        ],
                      ),
                    );
                  } else {
                    body = _cProfile(context, snap.data!, isMobile);
                  }
                  return StickyFooterScroll(
                    controller: _scroll,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 40, isMobile ? 12 : 24, 0),
                          child: KeyedSubtree(key: _mainKey, child: CkReveal(child: body)),
                        ),
                      ),
                    ),
                    footer: KeyedSubtree(key: _footKey, child: CkFooter(isMobile: isMobile)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cProfile(BuildContext context, Map<String, dynamic> data, bool isMobile) {
    final name = '${data['name'] ?? 'Jucător'}';
    final image = '${data['image'] ?? ''}';
    final bio = '${data['bio'] ?? ''}'.trim();
    final contact = '${data['contact'] ?? ''}'.trim();
    final email = '${data['email'] ?? ''}'.trim();
    final isTeacher = data['role'] == 'teacher';
    final ids = ((data['solvedIds'] as List?) ?? const []).map((e) => '$e').toList();
    final solved = (data['solvedCount'] as num?)?.toInt() ?? ids.length;
    final by = <String, int>{};
    for (final id in ids) {
      final m = _progressKey.firstMatch(id);
      if (m == null) continue;
      by[m.group(1)!] = (by[m.group(1)!] ?? 0) + 1;
    }
    final level = solved ~/ 5 + 1;
    final color = isTeacher ? _cBlue : Pb.primary;
    final badges = ckAchievements(solved, by);
    final earned = badges.where((b) => b.earned).toList();
    final isMe = FirebaseAuth.instance.currentUser?.uid == userId;

    Widget tile(IconData i, String label, String value, Color col, {Widget? trailing}) => Container(
          padding: const EdgeInsets.all(16),
          decoration: ckDeco(r: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(i, size: 19, color: col),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                    const SizedBox(height: 2),
                    Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        );

    Widget copyBtn(String v, String msg) => IconButton(
          tooltip: 'Copiază',
          splashRadius: 18,
          icon: Icon(Icons.copy_rounded, size: 18, color: Pb.muted),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: v));
            _toast(context, msg);
          },
        );

    final cover = CkCover(
      color: color,
      name: name,
      image: image,
      isMobile: isMobile,
      topRight: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(999)),
        child: Text('Nivelul $level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontSize: isMobile ? 24 : 30, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(isTeacher ? 'Profesor' : 'Elev', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
              ),
              Text('$solved ${solved == 1 ? 'problemă rezolvată' : 'probleme rezolvate'}', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(bio, style: TextStyle(fontSize: 14.5, color: Pb.text, height: 1.6)),
          ],
        ],
      ),
    );

    final stats = FutureBuilder<int?>(
      future: _rankOf(solved),
      builder: (context, rs) {
        final rank = rs.data;
        Widget t(IconData i, String l, String v, String s, Color c) => Expanded(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: ckDeco(r: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                          child: Icon(i, size: 16, color: c),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isMobile ? 17 : 21, fontWeight: FontWeight.w700, color: Pb.text)),
                    Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ],
                ),
              ),
            );
        return Row(
          children: [
            t(Icons.leaderboard_outlined, 'Clasament', rank == null ? (solved <= 0 ? '–' : '...') : '#$rank', solved <= 0 ? 'încă neîncadrat' : 'în clasamentul general', Pb.primary),
            SizedBox(width: isMobile ? 8 : 12),
            t(Icons.bolt, 'Experiență', '${solved * 50} XP', 'nivelul $level', _cAmber),
            SizedBox(width: isMobile ? 8 : 12),
            t(Icons.emoji_events_outlined, 'Realizări', '${earned.length}/${badges.length}', 'obținute', _cBlue),
          ],
        );
      },
    );

    final achievements = Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ckCardTitle(Icons.emoji_events_outlined, 'Realizări'),
          if (earned.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
              child: Text('Încă nicio realizare. Apar pe măsură ce rezolvă probleme.', style: TextStyle(fontSize: 14, color: Pb.muted)),
            )
          else
            CkBadgeGrid(items: badges, onlyEarned: true),
        ],
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile(Icons.mail_outline, 'Email', email.isEmpty ? 'Nespecificat' : email, Pb.primary, trailing: email.isEmpty ? null : copyBtn(email, 'Emailul a fost copiat.')),
        const SizedBox(height: 10),
        tile(Icons.phone_outlined, 'Telefon', (contact.isEmpty || contact == 'N/A') ? 'Nespecificat' : contact, _cAmber,
            trailing: (contact.isEmpty || contact == 'N/A') ? null : copyBtn(contact, 'Numărul a fost copiat.')),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: PbButton(text: 'Înapoi', icon: Icons.arrow_back, variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: () => _back(context)),
        ),
        const SizedBox(height: 14),
        cover,
        const SizedBox(height: 14),
        stats,
        const SizedBox(height: 14),
        achievements,
        const SizedBox(height: 14),
        info,
        const SizedBox(height: 18),
        if (!isMe)
          PbButton(
            text: 'Deschide conversația',
            icon: Icons.chat_bubble_outline,
            fullWidth: true,
            loading: _busy,
            onPressed: _busy ? null : () => _openChat(context, name),
          ),
      ],
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(BuildContext context, bool isMobile) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.ink, size: isMobile ? 26 : 32),
          onPressed: () => _back(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.border, height: 3),
        ),
        title: Text(
          "PLAYER LOGS",
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: isMobile ? 18 : 22, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
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
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RetroBlock(
                      bgColor: AppColors.cloud,
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
                              image: image != null
                                  ? DecorationImage(
                                      image: NetworkImage(image),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: image == null ? Icon(Icons.person, size: isMobile ? 64 : 80, color: AppColors.ink) : null,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            color: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            child: Text(
                              "PLAYER ACCOUNT",
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
                            name.toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Text(
                              bio.toString().toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.ink, fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 32),
                    if (isMobile) ...[
                      _infoTile('COMMUNICATION LINK', email, AppColors.sky, Icons.email, isMobile),
                      const SizedBox(height: 14),
                      _infoTile('CONTACT NODE', contact, AppColors.mustard, Icons.phone, isMobile),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _infoTile('COMMUNICATION LINK', email, AppColors.sky, Icons.email, isMobile),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _infoTile('CONTACT NODE', contact, AppColors.mustard, Icons.phone, isMobile),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: isMobile ? 28 : 48),
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
  }

  Widget _infoTile(String title, String? value, Color bgColor, IconData icon, bool isMobile) {
    final textColor = AppColors.isDark && bgColor == AppColors.mustard ? const Color(0xFF10161A) : AppColors.ink;

    return Container(
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
              Icon(icon, color: textColor, size: isMobile ? 20 : 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    fontSize: isMobile ? 12 : 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (value ?? '-').toUpperCase(),
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
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