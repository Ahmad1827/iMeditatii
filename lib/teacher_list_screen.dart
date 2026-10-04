import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky;
import 'sticky_footer.dart';
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer;

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

  // One subscription for the whole screen (typing doesn't re-subscribe).
  late final Stream<QuerySnapshot> _stream =
      FirebaseFirestore.instance.collection('teachers').where('active', isEqualTo: true).snapshots();

  // ---- clean state
  String _sort = 'recomandat'; // recomandat | pret | experienta
  bool _hidden = false;
  bool _opening = false;
  final GlobalKey _topKey = GlobalKey();
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

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

  Future<void> _message(String teacherId, Map<String, dynamic> data) async {
    if (currentUser == null) {
      context.go('/login');
      return;
    }
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final name = data['name'] ?? 'Profesor';
      final chatId = await _openOrCreateChat(context, teacherId, name);
      if (mounted) context.push('/chat/$chatId', extra: name);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  List<QueryDocumentSnapshot> _matching(List<QueryDocumentSnapshot> all) {
    return all.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final sub = data['subject']?.toString().toLowerCase() ?? '';
      final name = data['name']?.toString().toLowerCase() ?? '';

      final matchesSubject = sub.contains(_subjectName.toLowerCase()) || _subjectName.toLowerCase().contains(sub);
      final matchesSearch = _searchFilter.isEmpty || name.contains(_searchFilter.toLowerCase());

      return matchesSubject && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) => s.isClean
          ? _buildClean(MediaQuery.of(context).size.width < 900)
          : _buildRetro(MediaQuery.of(context).size.width < 880),
    );
  }

  // ===========================================================================
  // CLEAN — subject header with price/experience insights, sortable teacher cards
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);

  Color get _subjectColor {
    final s = _subjectName.toLowerCase();
    if (s.contains('matemat')) return const Color(0xFFE5484D);
    if (s.contains('info')) return Pb.primary;
    if (s.contains('fizic')) return const Color(0xFF8B5CF6);
    if (s.contains('chim')) return const Color(0xFF14B8A6);
    if (s.contains('bio')) return const Color(0xFF22A06B);
    if (s.contains('român')) return _cBlue;
    if (s.contains('englez')) return _cAmber;
    if (s.contains('francez')) return const Color(0xFF6366F1);
    if (s.contains('istorie')) return const Color(0xFFD97706);
    if (s.contains('geograf')) return const Color(0xFF0EA5E9);
    return Pb.primary;
  }

  static num _num(dynamic v, num fallback) => v is num ? v : (num.tryParse('${v ?? ''}') ?? fallback);

  BoxDecoration _deco({double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  Widget _buildClean(bool isMobile) {
    Widget box(double max, Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24), child: child),
          ),
        );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              blockers: [_topKey, _mainKey, _footKey],
              cardsHidden: _hidden,
              onToggleCards: () => setState(() => _hidden = !_hidden),
              hideLabel: 'Ascunde profesorii',
              showLabel: 'Arată profesorii',
              child: StreamBuilder<QuerySnapshot>(
                stream: _stream,
                builder: (context, snap) {
                  final loading = snap.connectionState == ConnectionState.waiting && !snap.hasData;
                  final list = _matching(snap.data?.docs ?? []);
                  if (_sort == 'pret') {
                    list.sort((a, b) => _num((a.data() as Map)['price'], 50).compareTo(_num((b.data() as Map)['price'], 50)));
                  } else if (_sort == 'experienta') {
                    list.sort((a, b) => _num((b.data() as Map)['experience'], 0).compareTo(_num((a.data() as Map)['experience'], 0)));
                  }
                  return StickyFooterScroll(
                    controller: _scrollController,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isMobile ? 20 : 36),
                        box(1120, KeyedSubtree(key: _topKey, child: _TlReveal(child: _cHeader(list, loading, isMobile)))),
                        SizedBox(height: isMobile ? 16 : 22),
                        box(1120, KeyedSubtree(key: _mainKey, child: _TlReveal(delayMs: 140, child: _cBody(list, loading)))),
                      ],
                    ),
                    footer: KeyedSubtree(key: _footKey, child: _cFooter(isMobile)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cHeader(List<QueryDocumentSnapshot> list, bool loading, bool isMobile) {
    final c = _subjectColor;
    final prices = list.map((d) => _num((d.data() as Map)['price'], 50)).toList();
    final exps = list.map((d) => _num((d.data() as Map)['experience'], 0)).toList();
    final avg = prices.isEmpty ? 0 : (prices.reduce((a, b) => a + b) / prices.length).round();
    final minP = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
    final maxExp = exps.isEmpty ? 0 : exps.reduce((a, b) => a > b ? a : b);

    Widget insight(IconData i, String v, String l, Color col) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: 18, color: col),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text, height: 1.1)),
                  Text(l, style: TextStyle(fontSize: 12, color: Pb.muted)),
                ],
              ),
            ],
          ),
        );

    Widget sortChip(String key, String label, IconData icon) {
      final sel = _sort == key;
      return _TlHover(
        onTap: () => setState(() => _sort = key),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? c.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sel ? c.withOpacity(0.6) : Pb.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: sel ? c : Pb.muted),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? c : Pb.text)),
            ],
          ),
        ),
      );
    }

    final search = TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchFilter = v.trim()),
      style: TextStyle(fontSize: 15, color: Pb.text),
      cursorColor: Pb.primary,
      decoration: Pb.input(hint: 'Caută un profesor după nume').copyWith(
        prefixIcon: Icon(Icons.search, size: 19, color: Pb.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: _searchFilter.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 18, color: Pb.muted),
                splashRadius: 18,
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchFilter = '');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );

    final title = Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(_getSubjectIcon(_subjectName), size: 26, color: c),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PbLink(text: 'Profesori', fontSize: 13, onTap: () => context.go('/materii')),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('/', style: TextStyle(fontSize: 13, color: Pb.muted)),
                  ),
                  Text(_subjectName, style: TextStyle(fontSize: 13, color: Pb.muted)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Profesori de $_subjectName',
                style: TextStyle(fontSize: isMobile ? 24 : 30, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: _deco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              insight(Icons.groups_outlined, loading ? '…' : '${list.length}', list.length == 1 ? 'profesor' : 'profesori', c),
              if (list.isNotEmpty) ...[
                insight(Icons.payments_outlined, '$avg RON', 'preț mediu / oră', _cAmber),
                insight(Icons.savings_outlined, 'de la $minP RON', 'cea mai mică ofertă', Pb.primary),
                insight(Icons.military_tech_outlined, '$maxExp ani', 'cea mai mare experiență', _cBlue),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (isMobile) ...[
            search,
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              sortChip('recomandat', 'Recomandați', Icons.auto_awesome_outlined),
              sortChip('pret', 'Preț mic', Icons.arrow_downward),
              sortChip('experienta', 'Experiență', Icons.military_tech_outlined),
            ]),
          ] else
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 14),
                Text('Sortează:', style: TextStyle(fontSize: 13, color: Pb.muted)),
                const SizedBox(width: 8),
                sortChip('recomandat', 'Recomandați', Icons.auto_awesome_outlined),
                const SizedBox(width: 6),
                sortChip('pret', 'Preț mic', Icons.arrow_downward),
                const SizedBox(width: 6),
                sortChip('experienta', 'Experiență', Icons.military_tech_outlined),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cBody(List<QueryDocumentSnapshot> list, bool loading) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: _deco(r: 14),
        child: Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)),
            const SizedBox(width: 12),
            Text('Se încarcă profesorii...', style: TextStyle(fontSize: 14, color: Pb.muted)),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      final searching = _searchFilter.isNotEmpty;
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: _deco(r: 14),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _subjectColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.person_search_outlined, size: 28, color: _subjectColor),
            ),
            const SizedBox(height: 12),
            Text(
              searching ? 'Niciun profesor cu numele acesta.' : 'Încă nu avem profesori de $_subjectName.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: Pb.text),
            ),
            const SizedBox(height: 6),
            Text(
              searching ? 'Verifică ortografia sau șterge căutarea.' : 'Ești profesor? Creează un cont și apari aici după aprobare.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Pb.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (!searching) PbButton(text: 'Devino profesor', icon: Icons.school_outlined, size: PbSize.sm, onPressed: () => context.go('/inregistrare')),
                PbButton(text: 'Alte materii', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: () => context.go('/materii')),
              ],
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 900 ? 3 : (box.maxWidth > 580 ? 2 : 1);
      const gap = 14.0;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < list.length; i++)
            SizedBox(
              width: w,
              child: _TlTeacherCard(
                data: list[i].data() as Map<String, dynamic>,
                color: _subjectColor,
                highlight: _sort == 'pret' && i == 0 ? 'Cel mai accesibil' : (_sort == 'experienta' && i == 0 ? 'Cel mai experimentat' : null),
                busy: _opening,
                onProfile: () => context.push('/profesor/${list[i].id}'),
                onMessage: () => _message(list[i].id, list[i].data() as Map<String, dynamic>),
              ),
            ),
        ],
      );
    });
  }

  Widget _cFooter(bool isMobile) {
    final links = [
      PbLink(text: 'Termeni și condiții', fontSize: 14, onTap: () => context.go('/termeni-si-conditii')),
      PbLink(text: 'Politica de confidențialitate', fontSize: 14, onTap: () => context.go('/politica-confidentialitate')),
    ];
    final copy = Text('© 2026 iMeditații', style: TextStyle(color: Pb.muted, fontSize: 14));
    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: PbContainer(
        child: isMobile
            ? Column(children: [
                copy,
                const SizedBox(height: 10),
                Wrap(spacing: 18, runSpacing: 8, alignment: WrapAlignment.center, children: links),
              ])
            : Row(children: [copy, const Spacer(), ...links.expand((l) => [const SizedBox(width: 22), l])]),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(bool isMobile) {
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
                            SizedBox(height: isMobile ? 18 : 28),
                            Expanded(
                              child: _buildTeachersList(isMobile),
                            ),
                            SizedBox(height: isMobile ? 32 : 48),
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
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 16 : 32, isMobile ? 16 : 24, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: RetroBlock(
            bgColor: AppColors.mustard,
            padding: isMobile ? 16 : 28,
            shadowOffset: isMobile ? 4.0 : 6.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
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
                    const SizedBox(width: 14),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.bold),
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
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        child: StreamBuilder<QuerySnapshot>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.sunset));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final teachers = _matching(snapshot.data!.docs);

            if (teachers.isEmpty) {
              return _buildEmptyState();
            }

            return Wrap(
              spacing: isMobile ? 16 : 24,
              runSpacing: isMobile ? 16 : 24,
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              children: teachers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _TeacherCard(
                  id: doc.id,
                  data: data,
                  isMobile: isMobile,
                  onMessage: () => _message(doc.id, data),
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

// =============================================================================
// Clean teacher card
// =============================================================================
class _TlTeacherCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color color;
  final String? highlight;
  final bool busy;
  final VoidCallback onProfile;
  final VoidCallback onMessage;

  const _TlTeacherCard({
    required this.data,
    required this.color,
    required this.highlight,
    required this.busy,
    required this.onProfile,
    required this.onMessage,
  });

  @override
  State<_TlTeacherCard> createState() => _TlTeacherCardState();
}

class _TlTeacherCardState extends State<_TlTeacherCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final d = widget.data;
    final name = '${d['name'] ?? 'Profesor'}';
    final image = '${d['image'] ?? ''}';
    final exp = '${d['experience'] ?? 0}';
    final price = '${d['price'] ?? 50}';
    final bio = '${d['bio'] ?? ''}'.trim();
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final initials = parts.isEmpty ? '?' : parts.map((w) => w[0].toUpperCase()).join();
    final expN = int.tryParse(exp) ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onProfile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hover ? c.withOpacity(0.55) : Pb.border.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: (_hover ? c : Colors.black).withOpacity(_hover ? 0.16 : (AppColors.isDark ? 0.3 : 0.06)),
                blurRadius: _hover ? 28 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.highlight != null)
                Container(
                  color: c.withOpacity(0.10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 15, color: c),
                      const SizedBox(width: 6),
                      Text(widget.highlight!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.withOpacity(0.5), width: 2)),
                      child: CircleAvatar(
                        backgroundColor: c.withOpacity(0.14),
                        backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
                        child: image.isEmpty
                            ? Text(initials, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _hover ? c : Pb.text)),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.verified, size: 15, color: Color(0xFF10B981)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            expN == 0 ? 'Profesor nou' : '$expN ${expN == 1 ? 'an' : 'ani'} de experiență',
                            style: TextStyle(fontSize: 13, color: Pb.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$price RON', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
                        Text('/ oră', style: TextStyle(fontSize: 12, color: Pb.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  bio.isEmpty ? 'Meditații 1 la 1, online, cu tablă interactivă și pregătire pentru examene.' : bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: Pb.border),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: PbButton(
                        text: 'Profil',
                        variant: PbVariant.outlineSecondary,
                        size: PbSize.sm,
                        fullWidth: true,
                        onPressed: widget.onProfile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: PbButton(
                        text: 'Scrie un mesaj',
                        icon: Icons.chat_bubble_outline,
                        size: PbSize.sm,
                        fullWidth: true,
                        loading: widget.busy,
                        onPressed: widget.busy ? null : widget.onMessage,
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

class _TlHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;
  const _TlHover({required this.builder, this.onTap});

  @override
  State<_TlHover> createState() => _TlHoverState();
}

class _TlHoverState extends State<_TlHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: widget.builder(_hover)),
    );
  }
}

class _TlReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _TlReveal({required this.child, this.delayMs = 0});

  @override
  State<_TlReveal> createState() => _TlRevealState();
}

class _TlRevealState extends State<_TlReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a), child: widget.child),
    );
  }
}

// =============================================================================
// Retro teacher card (original)
// =============================================================================
class _TeacherCard extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isMobile;
  final VoidCallback onMessage;
  final VoidCallback onViewProfile;

  const _TeacherCard({
    required this.id,
    required this.data,
    required this.isMobile,
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
          width: widget.isMobile ? double.infinity : 340,
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
                offset: _isPressed ? const Offset(0, 0) : Offset(widget.isMobile ? 4 : 5, widget.isMobile ? 4 : 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      child: image == null || image.isEmpty ? Icon(Icons.person, size: 40, color: AppColors.ink) : null,
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.8),
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