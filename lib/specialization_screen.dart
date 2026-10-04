import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'home_ambient.dart' show HomeSky;
import 'retro_widgets.dart';
import 'sticky_footer.dart';
import 'ui_components.dart' show StyleBuilder, Pb, PbLink, PbContainer;

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({super.key});

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'TOATE';
  String _query = '';

  // Created once, so typing in search doesn't re-subscribe to Firestore.
  late final Stream<QuerySnapshot> _teachers =
      FirebaseFirestore.instance.collection('teachers').where('active', isEqualTo: true).snapshots();

  static const _categories = {'TOATE': 'Toate', 'REAL': 'Real', 'UMAN': 'Uman'};

  final List<Map<String, dynamic>> _disciplines = [
    {"name": "Matematică", "category": "REAL", "icon": Icons.functions, "color": AppColors.sunset, "desc": "Algebră, geometrie, analiză și pregătire pentru bacalaureat.", "tag": "Bac și gimnaziu"},
    {"name": "Informatică", "category": "REAL", "icon": Icons.data_object, "color": AppColors.forest, "desc": "Algoritmi în C++, structuri de date și olimpiadă.", "tag": "C++ și algoritmi"},
    {"name": "Fizică", "category": "REAL", "icon": Icons.bolt, "color": AppColors.sunset, "desc": "Mecanică, termodinamică, electricitate și optică.", "tag": "Real și tehnic"},
    {"name": "Chimie", "category": "REAL", "icon": Icons.science, "color": AppColors.sky, "desc": "Chimie organică, anorganică și admitere la Medicină.", "tag": "Medicină și bac"},
    {"name": "Biologie", "category": "REAL", "icon": Icons.eco, "color": AppColors.forest, "desc": "Anatomie, genetică și biologie vegetală.", "tag": "Medicină și bac"},
    {"name": "Limba Română", "category": "UMAN", "icon": Icons.menu_book, "color": AppColors.sky, "desc": "Gramatică, eseuri de literatură și bacalaureat.", "tag": "Bac și evaluare"},
    {"name": "Engleză", "category": "UMAN", "icon": Icons.language, "color": AppColors.mustard, "desc": "Gramatică, conversație, Cambridge și TOEFL.", "tag": "Cambridge și IELTS"},
    {"name": "Franceză", "category": "UMAN", "icon": Icons.translate, "color": AppColors.mustard, "desc": "Grammaire, vocabulaire și DELF/DALF.", "tag": "DELF / DALF"},
    {"name": "Istorie", "category": "UMAN", "icon": Icons.account_balance, "color": AppColors.sunset, "desc": "Istoria românilor, istorie universală și bac.", "tag": "Bacalaureat"},
    {"name": "Geografie", "category": "UMAN", "icon": Icons.public, "color": AppColors.sky, "desc": "Geografia României, a Europei și a lumii.", "tag": "Bacalaureat"},
  ];

  // ---- clean state
  final ScrollController _scroll = ScrollController();
  bool _hidden = false;
  final GlobalKey _topKey = GlobalKey();
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.toLowerCase();
    return _disciplines.where((d) {
      final catOk = _category == 'TOATE' || d['category'] == _category;
      final queryOk = q.isEmpty ||
          (d['name'] as String).toLowerCase().contains(q) ||
          (d['desc'] as String).toLowerCase().contains(q) ||
          (d['tag'] as String).toLowerCase().contains(q);
      return catOk && queryOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        if (s.isClean) return _buildClean(MediaQuery.of(context).size.width < 900);
        return RetroPage(
          footerSubtitle: 'Alege o materie și lucrează direct cu un mentor.',
          builder: (context, m) => [_header(m), _grid(m)],
        );
      },
    );
  }

  // ===========================================================================
  // CLEAN — "Profesori": hero with an avatar wall, subject cards with mentor stacks
  // ===========================================================================
  static const Map<String, Color> _cColors = {
    'Matematică': Color(0xFFE5484D),
    'Informatică': Pb.primary,
    'Fizică': Color(0xFF8B5CF6),
    'Chimie': Color(0xFF14B8A6),
    'Biologie': Color(0xFF22A06B),
    'Limba Română': Color(0xFF3B82F6),
    'Engleză': Color(0xFFF59E0B),
    'Franceză': Color(0xFF6366F1),
    'Istorie': Color(0xFFD97706),
    'Geografie': Color(0xFF0EA5E9),
  };

  Color _cColor(String name) => _cColors[name] ?? Pb.primary;

  List<Map<String, dynamic>> _teachersFor(List<Map<String, dynamic>> all, String subject) {
    final n = subject.toLowerCase();
    return all.where((t) => '${t['subject'] ?? ''}'.toLowerCase().contains(n)).toList();
  }

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
              hideLabel: 'Ascunde materiile',
              showLabel: 'Arată materiile',
              child: StreamBuilder<QuerySnapshot>(
                stream: _teachers,
                builder: (context, snap) {
                  final teachers = (snap.data?.docs ?? []).map((d) => d.data() as Map<String, dynamic>).toList();
                  final loading = !snap.hasData;
                  return StickyFooterScroll(
                    controller: _scroll,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isMobile ? 20 : 40),
                        box(1120, KeyedSubtree(key: _topKey, child: _SpReveal(child: _cHero(teachers, loading, isMobile)))),
                        SizedBox(height: isMobile ? 18 : 24),
                        box(1120, KeyedSubtree(key: _mainKey, child: _SpReveal(delayMs: 140, child: _cGrid(teachers, loading)))),
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

  Widget _cHero(List<Map<String, dynamic>> teachers, bool loading, bool isMobile) {
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

    Widget seg(String key, String label) {
      final sel = _category == key;
      final count = _disciplines.where((d) => key == 'TOATE' || d['category'] == key).length;
      return _SpHover(
        onTap: () => setState(() => _category = key),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
              const SizedBox(width: 6),
              Text('$count', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ),
      );
    }

    final search = TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v.trim()),
      style: TextStyle(fontSize: 15, color: Pb.text),
      cursorColor: Pb.primary,
      decoration: Pb.input(hint: 'Caută o materie sau un examen (ex. Bac, DELF)').copyWith(
        prefixIcon: Icon(Icons.search, size: 19, color: Pb.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 18, color: Pb.muted),
                splashRadius: 18,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      ),
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Profesori verificați', style: TextStyle(fontSize: 14, color: Pb.muted)),
        const SizedBox(height: 4),
        Text(
          'Găsește-ți profesorul',
          style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          'Alege materia, compară profesorii după preț, experiență și recenzii, apoi scrie-i direct. Meditații 1 la 1, online.',
          style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            stat(Icons.groups_outlined, loading ? '…' : '${teachers.length}', 'profesori activi', Pb.primary),
            stat(Icons.auto_stories_outlined, '${_disciplines.length}', 'materii', const Color(0xFF3B82F6)),
            stat(Icons.videocam_outlined, '1 la 1', 'online', const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 18),
        search,
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [for (final e in _categories.entries) seg(e.key, e.value)]),
          ),
        ),
      ],
    );

    final wall = _cAvatarWall(teachers, loading);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: _deco(r: 18),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 20), wall])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 28), SizedBox(width: 300, child: wall)],
            ),
    );
  }

  Widget _cAvatarWall(List<Map<String, dynamic>> teachers, bool loading) {
    final shown = teachers.take(8).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Pb.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Pb.primary.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: Pb.primary),
              const SizedBox(width: 8),
              Text('Profesorii noștri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text)),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)))
          else if (shown.isEmpty)
            Text('Primii profesori apar aici în curând.', style: TextStyle(fontSize: 13.5, color: Pb.muted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in shown)
                  Tooltip(
                    message: '${t['name'] ?? 'Profesor'}, ${t['subject'] ?? ''}',
                    child: _SpAvatar(name: '${t['name'] ?? ''}', image: '${t['image'] ?? ''}', size: 42, color: _cColor('${t['subject'] ?? ''}')),
                  ),
                if (teachers.length > shown.length)
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Pb.gray, shape: BoxShape.circle),
                    child: Text('+${teachers.length - shown.length}',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Pb.muted)),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          Text(
            'Fiecare profil e verificat de un administrator înainte să apară aici.',
            style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _cGrid(List<Map<String, dynamic>> teachers, bool loading) {
    final list = _filtered;
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: _deco(r: 14),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 34, color: Pb.muted),
            const SizedBox(height: 10),
            Text('Nicio materie găsită.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(height: 4),
            Text('Încearcă alt cuvânt sau alege „Toate”.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text('Materii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(width: 10),
              Text('${list.length}', style: TextStyle(fontSize: 13, color: Pb.muted)),
            ],
          ),
        ),
        LayoutBuilder(builder: (context, box) {
          final cols = box.maxWidth > 900 ? 3 : (box.maxWidth > 560 ? 2 : 1);
          const gap = 14.0;
          final w = (box.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final d in list)
                SizedBox(
                  width: w,
                  child: _SpSubjectCard(
                    icon: d['icon'] as IconData,
                    title: d['name'] as String,
                    tag: d['tag'] as String,
                    desc: d['desc'] as String,
                    color: _cColor(d['name'] as String),
                    teachers: _teachersFor(teachers, d['name'] as String),
                    loading: loading,
                    onTap: () => context.go('/materii/${Uri.encodeComponent(d['name'] as String)}', extra: d),
                  ),
                ),
            ],
          );
        }),
      ],
    );
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
  Widget _header(bool m) {
    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 24 : 44, Retro.gutter(m), 0),
      child: Column(
        children: [
          RetroSectionHeader(
            title: 'Alege materia',
            subtitle: 'Găsește mentorul potrivit și programează o sesiune 1-la-1.',
            isMobile: m,
          ),
          const SizedBox(height: 24),
          _searchField(m),
          const SizedBox(height: 16),
          _filters(),
        ],
      ),
    );
  }

  Widget _searchField(bool m) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Retro.border,
          boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.ink, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                cursorColor: AppColors.ink,
                decoration: InputDecoration(
                  hintText: 'Caută o materie sau un cuvânt cheie',
                  hintStyle: Retro.body(m ? 14 : 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                tooltip: 'Șterge căutarea',
                icon: Icon(Icons.clear, color: AppColors.ink, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _categories.entries.map((e) {
        final selected = _category == e.key;
        return Semantics(
          button: true,
          selected: selected,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _category = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Retro.strong : AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, offset: selected ? const Offset(1, 1) : const Offset(3, 3)),
                  ],
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? Retro.onStrong : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _grid(bool m) {
    final list = _filtered;

    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 24 : 36, Retro.gutter(m), 0),
      child: list.isEmpty
          ? _emptyState()
          : StreamBuilder<QuerySnapshot>(
              stream: _teachers,
              builder: (context, snap) {
                final subjects = (snap.data?.docs ?? [])
                    .map((doc) => ((doc.data() as Map<String, dynamic>)['subject'] ?? '').toString().toLowerCase())
                    .toList();

                return RetroGrid(
                  minItemWidth: 300,
                  spacing: m ? 16 : 24,
                  children: list.map((d) {
                    final name = d['name'] as String;
                    final count = subjects.where((s) => s.contains(name.toLowerCase())).length;
                    return RetroSubjectCard(
                      icon: d['icon'] as IconData,
                      color: d['color'] as Color,
                      title: name,
                      tag: d['tag'] as String,
                      description: d['desc'] as String,
                      badge: _countBadge(count, loading: !snap.hasData),
                      cta: 'Vezi mentorii',
                      isMobile: m,
                      onTap: () => context.go('/materii/${Uri.encodeComponent(name)}', extra: d),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _countBadge(int count, {required bool loading}) {
    if (loading) return RetroTag('…', color: AppColors.cardBg);
    if (count == 0) return RetroTag('Niciun mentor încă', color: AppColors.cardBg, textColor: AppColors.textMuted);
    return RetroTag(count == 1 ? '1 mentor' : '$count mentori', color: AppColors.forest, dot: Retro.mint);
  }

  Widget _emptyState() {
    return Center(
      child: RetroBlock(
        bgColor: AppColors.cloud,
        padding: 28,
        shadowOffset: 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Nicio materie găsită.', style: Retro.title(17)),
            const SizedBox(height: 4),
            Text('Încearcă alt cuvânt sau alege „Toate”.', style: Retro.body(14)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Clean helpers
// =============================================================================
class _SpAvatar extends StatelessWidget {
  final String name;
  final String image;
  final double size;
  final Color color;

  const _SpAvatar({required this.name, required this.image, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final initials = parts.isEmpty ? '?' : parts.map((w) => w[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Pb.surface, width: 2)),
      child: CircleAvatar(
        backgroundColor: color.withOpacity(0.16),
        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
        onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
        child: image.isEmpty
            ? Text(initials, style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: color))
            : null,
      ),
    );
  }
}

class _SpSubjectCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String tag;
  final String desc;
  final Color color;
  final List<Map<String, dynamic>> teachers;
  final bool loading;
  final VoidCallback onTap;

  const _SpSubjectCard({
    required this.icon,
    required this.title,
    required this.tag,
    required this.desc,
    required this.color,
    required this.teachers,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_SpSubjectCard> createState() => _SpSubjectCardState();
}

class _SpSubjectCardState extends State<_SpSubjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final n = widget.teachers.length;
    final stack = widget.teachers.take(3).toList();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.all(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.icon, size: 22, color: c),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(widget.tag, style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _hover ? c : Pb.text)),
              const SizedBox(height: 4),
              Text(widget.desc,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4)),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (stack.isNotEmpty)
                    SizedBox(
                      width: 28.0 + (stack.length - 1) * 20,
                      height: 28,
                      child: Stack(
                        children: [
                          for (var i = 0; i < stack.length; i++)
                            Positioned(
                              left: i * 20.0,
                              child: _SpAvatar(name: '${stack[i]['name'] ?? ''}', image: '${stack[i]['image'] ?? ''}', size: 28, color: c),
                            ),
                        ],
                      ),
                    ),
                  if (stack.isNotEmpty) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.loading
                          ? 'Se încarcă...'
                          : (n == 0 ? 'Niciun profesor încă' : (n == 1 ? '1 profesor' : '$n profesori')),
                      style: TextStyle(fontSize: 13, fontWeight: n > 0 ? FontWeight.w600 : FontWeight.w400, color: n > 0 ? Pb.text : Pb.muted),
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: _hover ? const Offset(0.25, 0) : Offset.zero,
                    child: Icon(Icons.arrow_forward, size: 16, color: _hover ? c : Pb.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;
  const _SpHover({required this.builder, this.onTap});

  @override
  State<_SpHover> createState() => _SpHoverState();
}

class _SpHoverState extends State<_SpHover> {
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

class _SpReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _SpReveal({required this.child, this.delayMs = 0});

  @override
  State<_SpReveal> createState() => _SpRevealState();
}

class _SpRevealState extends State<_SpReveal> with SingleTickerProviderStateMixin {
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