import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Future<DocumentSnapshot> _userFuture =
      FirebaseFirestore.instance.collection('users').doc(_uid.isEmpty ? 'none' : _uid).get();
  late final Stream<QuerySnapshot> _chatsStream = _uid.isEmpty
      ? const Stream<QuerySnapshot>.empty()
      : FirebaseFirestore.instance
          .collection('chats')
          .where('studentId', isEqualTo: _uid)
          .orderBy('updatedAt', descending: true)
          .snapshots();

  // ---- clean state
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  String _q = '';
  bool _hidden = false;
  Map<String, int> _solved = {};
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  // keys look like "<materie>_<clasa>_<id>"
  static final RegExp _progressKey = RegExp(r'^(.+?)_(\d+)_(.+)$');

  @override
  void initState() {
    super.initState();
    _loadSolved();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadSolved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, int>{};
      for (final k in prefs.getKeys()) {
        final m = _progressKey.firstMatch(k);
        if (m == null || prefs.get(k) != true) continue;
        map[m.group(1)!] = (map[m.group(1)!] ?? 0) + 1;
      }
      if (mounted) setState(() => _solved = map);
    } catch (e) {
      debugPrint('Progres: $e');
    }
  }

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
    return StyleBuilder(
      builder: (context, s) {
        if (_uid.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/materii');
          });
          return Scaffold(
            backgroundColor: s.isClean ? Pb.page : AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: s.isClean ? Pb.primary : AppColors.sunset)),
          );
        }
        final w = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(w < 880) : _buildRetro(w < 750);
      },
    );
  }

  // ===========================================================================
  // CLEAN — "Panoul meu": greeting, searchable conversations and a progress
  // card with a level ring and per-subject bars. Dragon scene.
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);

  String _when(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) return DateFormat('HH:mm').format(d);
    return DateFormat('dd.MM').format(d);
  }

  int get _total => _solved.values.fold(0, (a, b) => a + b);

  Widget _buildClean(bool isMobile) {
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
              hideLabel: 'Ascunde panoul',
              showLabel: 'Arată panoul',
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatsStream,
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? const <QueryDocumentSnapshot>[];
                  final loading = snap.connectionState == ConnectionState.waiting && !snap.hasData;
                  return StickyFooterScroll(
                    controller: _scroll,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 36, isMobile ? 12 : 24, 0),
                          child: KeyedSubtree(key: _mainKey, child: CkReveal(child: _cBody(docs, loading, isMobile))),
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

  Widget _cBody(List<QueryDocumentSnapshot> docs, bool loading, bool isMobile) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_cChats(docs, loading)],
    );
    final right = _cProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cHeader(docs.length, isMobile),
        const SizedBox(height: 14),
        if (isMobile) ...[right, const SizedBox(height: 14), left] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: left), const SizedBox(width: 14), SizedBox(width: 310, child: right)],
          ),
      ],
    );
  }

  Widget _cHeader(int chats, bool isMobile) {
    Widget stat(IconData i, String v, String l, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: c.withOpacity(0.09), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: 17, color: c),
              const SizedBox(width: 8),
              Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(width: 5),
              Text(l, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: ckDeco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Panoul meu', style: TextStyle(fontSize: 14, color: Pb.muted)),
          const SizedBox(height: 2),
          FutureBuilder<DocumentSnapshot>(
            future: _userFuture,
            builder: (context, snap) {
              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final first = '${data['name'] ?? ''}'.trim().split(' ').first;
              return Text(
                first.isEmpty ? 'Bine ai revenit' : 'Bine ai revenit, $first',
                style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
              );
            },
          ),
          const SizedBox(height: 6),
          Text('Continuă de unde ai rămas: exersează, citește o lecție sau scrie unui profesor.',
              style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              stat(Icons.emoji_events_outlined, '$_total', _total == 1 ? 'problemă rezolvată' : 'probleme rezolvate', Pb.primary),
              stat(Icons.forum_outlined, '$chats', chats == 1 ? 'conversație' : 'conversații', _cBlue),
              stat(Icons.bolt, '${_total * 50}', 'XP', _cAmber),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PbButton(text: 'Exersează', icon: Icons.play_arrow, onPressed: () => context.go('/exercitii')),
              PbButton(text: 'Găsește profesori', icon: Icons.school_outlined, variant: PbVariant.outlinePrimary, onPressed: () => context.go('/materii')),
              PbButton(text: 'Profilul meu', icon: Icons.person_outline, variant: PbVariant.outlineSecondary, onPressed: () => context.go('/elev/$_uid')),
            ],
          ),
        ],
      ),
    );
  }

  /// Unique: level ring (every 5 problems = a level) + progress per subject.
  Widget _cProgress() {
    final level = _total ~/ 5 + 1;
    final inLevel = _total % 5;
    final entries = _solved.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final best = entries.isEmpty ? 1 : entries.first.value;
    final rank = _total > 10 ? 'Avansat' : (_total > 3 ? 'Intermediar' : 'Începător');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ckCardTitle(Icons.trending_up, 'Progresul tău'),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: inLevel / 5),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Pb.gray,
                        color: Pb.primary,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$level', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Pb.text, height: 1)),
                          Text('nivel', style: TextStyle(fontSize: 11.5, color: Pb.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rank, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
                    const SizedBox(height: 3),
                    Text('$inLevel din 5 spre nivelul ${level + 1}', style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
              child: Text('Nu ai rezolvat nicio problemă încă. Prima te urcă deja în clasament.',
                  style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45)),
            )
          else
            for (final e in entries.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(ckSubjectIcon(e.key), size: 15, color: ckSubjectColor(e.key)),
                        const SizedBox(width: 7),
                        Expanded(child: Text(e.key, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Pb.text))),
                        Text('${e.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: e.value / best),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, color: ckSubjectColor(e.key), backgroundColor: Pb.gray),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          PbButton(text: 'Continuă să exersezi', icon: Icons.arrow_forward, size: PbSize.sm, fullWidth: true, onPressed: () => context.go('/exercitii')),
        ],
      ),
    );
  }

  Widget _cChats(List<QueryDocumentSnapshot> docs, bool loading) {
    final q = _q.trim().toLowerCase();
    final list = docs.where((d) {
      final m = d.data() as Map<String, dynamic>;
      if (q.isEmpty) return true;
      return '${m['teacherName'] ?? ''} ${m['lastMessage'] ?? ''}'.toLowerCase().contains(q);
    }).toList();

    final search = TextField(
      controller: _search,
      onChanged: (v) => setState(() => _q = v),
      style: TextStyle(fontSize: 14.5, color: Pb.text),
      cursorColor: Pb.primary,
      decoration: Pb.input(hint: 'Caută un profesor sau un mesaj').copyWith(
        prefixIcon: Icon(Icons.search, size: 18, color: Pb.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        suffixIcon: _q.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 17, color: Pb.muted),
                splashRadius: 16,
                onPressed: () {
                  _search.clear();
                  setState(() => _q = '');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ckCardTitle(Icons.forum_outlined, 'Mesaje cu profesorii', trailing: Text('${list.length}', style: TextStyle(fontSize: 13, color: Pb.muted))),
                search,
              ],
            ),
          ),
          if (loading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)))
          else if (list.isEmpty)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(docs.isEmpty ? Icons.forum_outlined : Icons.search_off, size: 32, color: Pb.muted),
                  const SizedBox(height: 8),
                  Text(docs.isEmpty ? 'Nu ai scris încă niciunui profesor.' : 'Nicio conversație nu se potrivește.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
                  const SizedBox(height: 3),
                  Text(docs.isEmpty ? 'Alege o materie și găsește un profesor potrivit.' : 'Încearcă alt nume sau șterge căutarea.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                  if (docs.isEmpty) ...[
                    const SizedBox(height: 14),
                    PbButton(text: 'Găsește un profesor', icon: Icons.school_outlined, size: PbSize.sm, onPressed: () => context.go('/materii')),
                  ],
                ],
              ),
            )
          else
            for (final d in list)
              _UdChatRow(
                data: d.data() as Map<String, dynamic>,
                when: _when((d.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?),
                onOpen: (name) => context.go('/chat/${d.id}', extra: name),
              ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(bool isMobile) {
    final String userId = _uid;

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
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: _userFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
                            );
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                          final userName = data['name'] ?? 'PLAYER';
                          return _buildHeaderSection(userName, userId, isMobile);
                        },
                      ),
                      SizedBox(height: isMobile ? 32 : 48),
                      Row(
                        children: [
                          Icon(Icons.forum, color: AppColors.ink, size: isMobile ? 24 : 28),
                          const SizedBox(width: 12),
                          Text(
                            "MASTER LOGS (MESSAGES)",
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildChatList(userId, isMobile),
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

  Widget _buildHeaderSection(String userName, String userId, bool isMobile) {
    if (isMobile) {
      return RetroBlock(
        bgColor: AppColors.forest,
        padding: 20,
        shadowOffset: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: AppColors.ink,
              child: Text(
                "PLAYER TERMINAL",
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
              "GREETINGS, ${userName.split(' ')[0].toUpperCase()}!",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            const Text(
              "ACCESS YOUR COMMS AND TRACK QUEST PROGRESS.",
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RetroButton(
              text: "PROFILE",
              icon: Icons.person,
              isFullWidth: true,
              bgColor: AppColors.cardBg,
              textColor: AppColors.ink,
              onPressed: () => context.go('/elev/$userId'),
            ),
          ],
        ),
      );
    }

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

  Widget _buildChatList(String userId, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: List.generate(3, (index) => _chatCardSkeleton(isMobile)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'TERMINAL ERROR: ${snapshot.error}'.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(isMobile);

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
                if (teacherSnap.connectionState == ConnectionState.waiting) return _chatCardSkeleton(isMobile);
                if (!teacherSnap.hasData || !teacherSnap.data!.exists) return const SizedBox.shrink();

                final teacherData = teacherSnap.data!.data() as Map<String, dynamic>;
                final teacherName = teacherData['name'] ?? 'UNKNOWN MASTER';
                final teacherAvatar = teacherData['image'] as String? ?? '';

                return _RetroChatCard(
                  name: teacherName,
                  avatarUrl: teacherAvatar,
                  lastMessage: lastMsg,
                  timestamp: timestamp,
                  isMobile: isMobile,
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

  Widget _chatCardSkeleton(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RetroBlock(
        bgColor: AppColors.cardBg,
        padding: isMobile ? 14 : 20,
        shadowOffset: isMobile ? 3 : 4,
        child: Row(
          children: [
            Container(
              width: isMobile ? 48 : 60,
              height: isMobile ? 48 : 60,
              decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
            ),
            SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 16, color: AppColors.cloud),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, color: AppColors.bg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 32 : 60,
      shadowOffset: isMobile ? 4 : 6,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.speaker_notes_off, size: isMobile ? 54 : 80, color: AppColors.textMuted),
            const SizedBox(height: 18),
            Text(
              "COMMS CHANNEL EMPTY",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 17 : 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            Text(
              "NO LOGS FROM MASTERS YET.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
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

// =============================================================================
// Clean conversation row (fetches the teacher's photo once)
// =============================================================================
class _UdChatRow extends StatefulWidget {
  final Map<String, dynamic> data;
  final String when;
  final void Function(String name) onOpen;

  const _UdChatRow({required this.data, required this.when, required this.onOpen});

  @override
  State<_UdChatRow> createState() => _UdChatRowState();
}

class _UdChatRowState extends State<_UdChatRow> {
  late final Future<DocumentSnapshot> _teacher = FirebaseFirestore.instance
      .collection('teachers')
      .doc('${widget.data['teacherId'] ?? ''}'.isEmpty ? 'none' : '${widget.data['teacherId']}')
      .get();

  @override
  Widget build(BuildContext context) {
    final fallback = '${widget.data['teacherName'] ?? 'Profesor'}';
    final last = '${widget.data['lastMessage'] ?? ''}';

    return FutureBuilder<DocumentSnapshot>(
      future: _teacher,
      builder: (context, snap) {
        final t = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final name = '${t['name'] ?? fallback}';
        final image = '${t['image'] ?? ''}';
        final subject = '${t['subject'] ?? ''}';
        final c = subject.isEmpty ? ckColorFor(name) : ckSubjectColor(subject);
        return CkHover(
          onTap: () => widget.onOpen(name),
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: h ? c.withOpacity(0.05) : Colors.transparent,
              border: Border(top: BorderSide(color: Pb.border), left: BorderSide(color: h ? c : Colors.transparent, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(15, 12, 18, 12),
            child: Row(
              children: [
                CkAvatar(name: name, image: image, size: 42, color: c),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: h ? c : Pb.text))),
                          if (subject.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                              child: Text(subject, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(last.isEmpty ? 'Nicio replică încă' : last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.when, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right, size: 18, color: h ? c : Pb.border),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Retro chat card (original)
// =============================================================================
class _RetroChatCard extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final Timestamp? timestamp;
  final String initials;
  final bool isMobile;
  final VoidCallback onTap;

  const _RetroChatCard({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timestamp,
    required this.initials,
    required this.isMobile,
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
      padding: const EdgeInsets.only(bottom: 16),
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
                  offset: _isPressed ? const Offset(0, 0) : Offset(widget.isMobile ? 4 : 6, widget.isMobile ? 4 : 6),
                  blurRadius: 0,
                )
              ],
            ),
            padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
            child: Row(
              children: [
                Container(
                  width: widget.isMobile ? 48 : 60,
                  height: widget.isMobile ? 48 : 60,
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    border: Border.all(color: AppColors.border, width: 2),
                    image: widget.avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(widget.avatarUrl), fit: BoxFit.cover) : null,
                  ),
                  child: widget.avatarUrl.isEmpty
                      ? Center(
                          child: Text(
                            widget.initials,
                            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: widget.isMobile ? 16 : 20),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: widget.isMobile ? 12 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: widget.isMobile ? 15 : 18, color: AppColors.ink, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lastMessage,
                        style: TextStyle(color: AppColors.textMuted, fontSize: widget.isMobile ? 13 : 15, fontWeight: FontWeight.bold),
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
                    if (widget.timestamp != null)
                      Text(
                        DateFormat('HH:mm').format(widget.timestamp!.toDate()),
                        style: TextStyle(color: AppColors.ink, fontSize: widget.isMobile ? 11 : 13, fontWeight: FontWeight.w900),
                      ),
                    const SizedBox(height: 6),
                    Icon(Icons.arrow_forward, color: AppColors.ink, size: widget.isMobile ? 16 : 20),
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