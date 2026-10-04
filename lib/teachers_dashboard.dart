import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'clean_kit.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky;
import 'sticky_footer.dart';
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize, showPbModal;

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

  // ---- cached data (so rebuilds don't refetch)
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Future<DocumentSnapshot> _teacherFuture =
      FirebaseFirestore.instance.collection('teachers').doc(_uid.isEmpty ? 'none' : _uid).get();
  late final Stream<QuerySnapshot> _chatsStream = _uid.isEmpty
      ? const Stream<QuerySnapshot>.empty()
      : FirebaseFirestore.instance
          .collection('chats')
          .where('teacherId', isEqualTo: _uid)
          .orderBy('updatedAt', descending: true)
          .snapshots();
  late final Stream<QuerySnapshot> _pendQuests = _isAdmin
      ? FirebaseFirestore.instance.collection('exercises').where('approved', isEqualTo: false).snapshots()
      : const Stream<QuerySnapshot>.empty();
  late final Stream<QuerySnapshot> _pendArticles = _isAdmin
      ? FirebaseFirestore.instance.collection('resources').where('approved', isEqualTo: false).snapshots()
      : const Stream<QuerySnapshot>.empty();

  // ---- clean state
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  String _q = '';
  bool _hidden = false;
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
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
        final w = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(w < 800) : _buildRetro(w < 750);
      },
    );
  }

  // ===========================================================================
  // CLEAN — "Panou profesor": stats, student strip, searchable conversations,
  // admin review queue with live counters. Meadow scene.
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cGreen = Color(0xFF10B981);

  String _when(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) return DateFormat('HH:mm').format(d);
    return DateFormat('dd.MM').format(d);
  }

  Widget _buildClean(bool isMobile) {
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
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
                        constraints: const BoxConstraints(maxWidth: 980),
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
    // distinct students (id -> name / chat)
    final names = <String, String>{};
    final chatIds = <String, String>{};
    for (final d in docs) {
      final m = d.data() as Map<String, dynamic>;
      final id = '${m['studentId'] ?? ''}';
      if (id.isEmpty || names.containsKey(id)) continue;
      names[id] = '${m['studentName'] ?? 'Elev'}';
      chatIds[id] = d.id;
    }

    final showChats = !_isAdmin || _selectedIndex == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cHeader(docs.length, names.length, isMobile),
        const SizedBox(height: 14),
        if (_isAdmin) ...[_cTabs(), const SizedBox(height: 14)],
        if (showChats) ...[
          if (names.isNotEmpty) ...[_cStudentStrip(names, chatIds), const SizedBox(height: 14)],
          _cChats(docs, loading),
        ] else
          _cPending(isMobile),
      ],
    );
  }

  Widget _cHeader(int chats, int students, bool isMobile) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isAdmin ? _cBlue : Pb.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isAdmin ? Icons.admin_panel_settings_outlined : Icons.school_outlined, size: 14, color: _isAdmin ? _cBlue : Pb.primary),
                    const SizedBox(width: 5),
                    Text(_isAdmin ? 'Administrator' : 'Profesor',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _isAdmin ? _cBlue : Pb.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<DocumentSnapshot>(
            future: _teacherFuture,
            builder: (context, snap) {
              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final first = '${data['name'] ?? ''}'.trim().split(' ').first;
              return Text(
                first.isEmpty ? 'Bine ai venit' : 'Bună, $first',
                style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            _isAdmin
                ? 'Răspunde elevilor, aprobă problemele și lecțiile trimise și ține evidența profesorilor.'
                : 'Răspunde elevilor tăi și adaugă probleme sau lecții noi pentru comunitate.',
            style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              stat(Icons.forum_outlined, '$chats', chats == 1 ? 'conversație' : 'conversații', Pb.primary),
              stat(Icons.groups_outlined, '$students', students == 1 ? 'elev' : 'elevi', _cBlue),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PbButton(text: 'Problemă nouă', icon: Icons.add_task, onPressed: () => context.go('/adauga-exercitiu')),
              PbButton(
                text: 'Lecție nouă',
                icon: Icons.menu_book_outlined,
                variant: PbVariant.outlinePrimary,
                onPressed: () => context.go('/adauga-articol'),
              ),
              if (_uid.isNotEmpty)
                PbButton(
                  text: 'Profilul meu',
                  icon: Icons.person_outline,
                  variant: PbVariant.outlineSecondary,
                  onPressed: () => context.go('/profesor/$_uid'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cTabs() {
    Widget badge(Stream<QuerySnapshot> s) => StreamBuilder<QuerySnapshot>(
          stream: s,
          builder: (context, snap) {
            final n = snap.data?.docs.length ?? 0;
            if (n == 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: _cAmber.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
              child: Text('$n', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
            );
          },
        );

    Widget seg(int i, String label, IconData icon, {List<Stream<QuerySnapshot>> badges = const []}) {
      final sel = _selectedIndex == i;
      return CkHover(
        onTap: () => setState(() => _selectedIndex = i),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: sel ? Pb.link : Pb.muted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
              for (final b in badges) badge(b),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg(0, 'Conversații', Icons.forum_outlined),
            seg(1, 'De aprobat', Icons.fact_check_outlined, badges: [_pendQuests, _pendArticles]),
          ],
        ),
      ),
    );
  }

  /// Unique: a strip with every student you've talked to; tap to jump into the chat.
  Widget _cStudentStrip(Map<String, String> names, Map<String, String> chatIds) {
    final entries = names.entries.toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ckCardTitle(Icons.groups_outlined, 'Elevii tăi', trailing: Text('${entries.length}', style: TextStyle(fontSize: 13, color: Pb.muted))),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final e = entries[i];
                return CkHover(
                  onTap: () => context.go('/chat/${chatIds[e.key]}', extra: e.value),
                  builder: (h) => SizedBox(
                    width: 64,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: h ? ckColorFor(e.value) : Colors.transparent, width: 2),
                          ),
                          child: CkAvatar(name: e.value, image: '', size: 44),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          e.value.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: h ? Pb.text : Pb.muted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cChats(List<QueryDocumentSnapshot> docs, bool loading) {
    final q = _q.trim().toLowerCase();
    final list = docs.where((d) {
      final m = d.data() as Map<String, dynamic>;
      if ('${m['studentId'] ?? ''}'.isEmpty) return false;
      if (q.isEmpty) return true;
      return '${m['studentName'] ?? ''} ${m['lastMessage'] ?? ''}'.toLowerCase().contains(q);
    }).toList();

    final search = TextField(
      controller: _search,
      onChanged: (v) => setState(() => _q = v),
      style: TextStyle(fontSize: 14.5, color: Pb.text),
      cursorColor: Pb.primary,
      decoration: Pb.input(hint: 'Caută un elev sau un mesaj').copyWith(
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
                ckCardTitle(Icons.forum_outlined, 'Conversații', trailing: Text('${list.length}', style: TextStyle(fontSize: 13, color: Pb.muted))),
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
                  Text(
                    docs.isEmpty ? 'Încă nu ai conversații.' : 'Nicio conversație nu se potrivește.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    docs.isEmpty ? 'Când un elev îți scrie, mesajele apar aici.' : 'Încearcă alt nume sau șterge căutarea.',
                    style: TextStyle(fontSize: 13.5, color: Pb.muted),
                  ),
                ],
              ),
            )
          else
            for (final d in list)
              _TdChatRow(
                data: d.data() as Map<String, dynamic>,
                when: _when((d.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?),
                onOpen: (name) => context.go('/chat/${d.id}', extra: name),
              ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- admin queue
  Future<void> _confirmDelete(String title, VoidCallback onYes) {
    return showPbModal<void>(
      context,
      title: 'Ștergi definitiv?',
      body: Text('„$title” va fi șters și nu mai poate fi recuperat.'),
      actions: (ctx) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
        PbButton(
          text: 'Șterge',
          variant: PbVariant.danger,
          onPressed: () {
            Navigator.of(ctx).pop();
            onYes();
          },
        ),
      ],
    );
  }

  Widget _cPending(bool isMobile) {
    Widget seg(int i, String label, Stream<QuerySnapshot> s) {
      final sel = _adminSubIndex == i;
      return CkHover(
        onTap: () => setState(() => _adminSubIndex = i),
        builder: (h) => StreamBuilder<QuerySnapshot>(
          stream: s,
          builder: (context, snap) {
            final n = snap.data?.docs.length ?? 0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? Pb.link.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: sel ? Pb.link.withOpacity(0.6) : Pb.border),
              ),
              child: Text('$label ($n)', style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.link : Pb.text)),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ckCardTitle(Icons.fact_check_outlined, 'De aprobat'),
          Wrap(spacing: 6, children: [seg(0, 'Probleme', _pendQuests), seg(1, 'Lecții', _pendArticles)]),
          const SizedBox(height: 14),
          _adminSubIndex == 0 ? _cPendingQuests() : _cPendingArticles(),
        ],
      ),
    );
  }

  Widget _pendingShell(String title, String meta, {String? body, required VoidCallback onApprove, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _cAmber.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.hourglass_top_rounded, size: 18, color: _cAmber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text)),
                const SizedBox(height: 2),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.35)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PbButton(text: 'Aprobă', icon: Icons.check, variant: PbVariant.success, size: PbSize.sm, onPressed: onApprove),
          const SizedBox(width: 6),
          IconButton(tooltip: 'Respinge și șterge', splashRadius: 18, icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE5484D)), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget _emptyPending(String text) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.task_alt, size: 22, color: _cGreen),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Pb.muted))),
          ],
        ),
      );

  Widget _cPendingQuests() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendQuests,
      builder: (context, snap) {
        if (snap.hasError) return Text('Eroare: ${snap.error}', style: const TextStyle(color: Color(0xFFE5484D)));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyPending('Nicio problemă în așteptare. Totul e verificat.');
        return Column(
          children: [
            for (final doc in docs)
              Builder(builder: (context) {
                final d = doc.data() as Map<String, dynamic>;
                final title = '${d['title'] ?? 'Fără titlu'}';
                return _pendingShell(
                  title,
                  '${d['subject'] ?? ''}, clasa a ${d['grade'] ?? '?'}-a, ${d['tip_exercitiu'] ?? ''}',
                  onApprove: () => FirebaseFirestore.instance.collection('exercises').doc(doc.id).update({'approved': true}),
                  onDelete: () => _confirmDelete(title, () => FirebaseFirestore.instance.collection('exercises').doc(doc.id).delete()),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _cPendingArticles() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendArticles,
      builder: (context, snap) {
        if (snap.hasError) return Text('Eroare: ${snap.error}', style: const TextStyle(color: Color(0xFFE5484D)));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyPending('Nicio lecție în așteptare. Totul e verificat.');
        return Column(
          children: [
            for (final doc in docs)
              Builder(builder: (context) {
                final d = doc.data() as Map<String, dynamic>;
                final title = '${d['title'] ?? 'Fără titlu'}';
                return _pendingShell(
                  title,
                  '${d['subject'] ?? ''}, clasa a ${d['grade'] ?? '?'}-a, de ${d['author'] ?? 'profesor'}',
                  body: '${d['desc'] ?? ''}',
                  onApprove: () => FirebaseFirestore.instance.collection('resources').doc(doc.id).update({'approved': true}),
                  onDelete: () => _confirmDelete(title, () => FirebaseFirestore.instance.collection('resources').doc(doc.id).delete()),
                );
              }),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(bool isMobile) {
    final String teacherId = _uid;

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
                        future: _teacherFuture,
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
      stream: FirebaseFirestore.instance.collection('resources').where('approved', isEqualTo: false).snapshots(),
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
      stream: FirebaseFirestore.instance.collection('exercises').where('approved', isEqualTo: false).snapshots(),
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
      stream: _chatsStream,
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

// =============================================================================
// Clean conversation row (fetches the student's photo once)
// =============================================================================
class _TdChatRow extends StatefulWidget {
  final Map<String, dynamic> data;
  final String when;
  final void Function(String name) onOpen;

  const _TdChatRow({required this.data, required this.when, required this.onOpen});

  @override
  State<_TdChatRow> createState() => _TdChatRowState();
}

class _TdChatRowState extends State<_TdChatRow> {
  late final Future<DocumentSnapshot> _user = FirebaseFirestore.instance
      .collection('users')
      .doc('${widget.data['studentId'] ?? ''}'.isEmpty ? 'none' : '${widget.data['studentId']}')
      .get();

  @override
  Widget build(BuildContext context) {
    final fallback = '${widget.data['studentName'] ?? 'Elev'}';
    final last = '${widget.data['lastMessage'] ?? ''}';

    return FutureBuilder<DocumentSnapshot>(
      future: _user,
      builder: (context, snap) {
        final u = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final name = '${u['name'] ?? fallback}';
        final image = '${u['image'] ?? ''}';
        return CkHover(
          onTap: () => widget.onOpen(name),
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: h ? Pb.hoverBg : Colors.transparent,
              border: Border(top: BorderSide(color: Pb.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                CkAvatar(name: name, image: image, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: h ? Pb.link : Pb.text)),
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
                    Icon(Icons.chevron_right, size: 18, color: h ? Pb.link : Pb.border),
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