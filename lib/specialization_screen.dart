import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'retro_widgets.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
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
    return RetroPage(
      footerSubtitle: 'Alege o materie și lucrează direct cu un mentor.',
      builder: (context, m) => [_header(m), _grid(m)],
    );
  }

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