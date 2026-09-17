import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({super.key});

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'TOATE';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _disciplines = [
    {
      "name": "Matematică",
      "category": "REAL",
      "icon": Icons.functions,
      "color": AppColors.sunset,
      "desc": "Algebră, Geometrie, Analiză & Bacalaureat",
      "tag": "BAC & GIMNAZIU",
    },
    {
      "name": "Informatică",
      "category": "REAL",
      "icon": Icons.data_object,
      "color": AppColors.forest,
      "desc": "Algoritmi C++, Structuri de Date & Olimpiadă",
      "tag": "C++ & ALGORITMI",
    },
    {
      "name": "Fizică",
      "category": "REAL",
      "icon": Icons.bolt,
      "color": AppColors.sunset,
      "desc": "Mecanică, Termodinamică, Electricitate & Optică",
      "tag": "REAL & TEHNIC",
    },
    {
      "name": "Chimie",
      "category": "REAL",
      "icon": Icons.science,
      "color": AppColors.sky,
      "desc": "Chimie Organică, Anorganică & Admitere Medicină",
      "tag": "MEDICINĂ & BAC",
    },
    {
      "name": "Biologie",
      "category": "REAL",
      "icon": Icons.eco,
      "color": AppColors.forest,
      "desc": "Anatomie, Genetică & Biologie Vegetală",
      "tag": "MEDICINĂ & BAC",
    },
    {
      "name": "Limba Română",
      "category": "UMAN",
      "icon": Icons.menu_book,
      "color": AppColors.sky,
      "desc": "Gramatică, Eseuri Literatură & Bacalaureat",
      "tag": "BAC & EVALUARE",
    },
    {
      "name": "Engleză",
      "category": "UMAN",
      "icon": Icons.language,
      "color": AppColors.mustard,
      "desc": "Grammar, Conversație, Cambridge & TOEFL",
      "tag": "CAMBRIDGE & IELTS",
    },
    {
      "name": "Franceză",
      "category": "UMAN",
      "icon": Icons.translate,
      "color": AppColors.mustard,
      "desc": "Grammaire, Vocabulaire & DELF/DALF",
      "tag": "DELF / DALF",
    },
    {
      "name": "Istorie",
      "category": "UMAN",
      "icon": Icons.account_balance,
      "color": AppColors.sunset,
      "desc": "Istoria Românilor, Istorie Universală & Bac",
      "tag": "BACALAUREAT",
    },
    {
      "name": "Geografie",
      "category": "UMAN",
      "icon": Icons.public,
      "color": AppColors.sky,
      "desc": "Geografia României, a Europei & a Lumii",
      "tag": "BACALAUREAT",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDisciplines {
    return _disciplines.where((d) {
      final matchesCat = _selectedCategory == 'TOATE' || d['category'] == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          d['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d['desc'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d['tag'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();
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
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeroSearch(isMobile),
                        _buildCategoryFilter(),
                        const SizedBox(height: 28),
                        _buildDisciplinesGrid(isMobile),
                        const SizedBox(height: 60),
                        _buildFooter(isMobile),
                      ],
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

  Widget _buildHeroSearch(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 24 : 40, isMobile ? 16 : 24, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
                child: const Text(
                  "GUILD ROSTER",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "SELECT DISCIPLINE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 30 : 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "GĂSEȘTE MENTORUL POTRIVIT ȘI PROGRAMEAZĂ-ȚI ANTRENAMENTUL 1-LA-1.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isMobile ? 12 : 15, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              // Retro Search Input
              Container(
                constraints: const BoxConstraints(maxWidth: 680),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4), blurRadius: 0),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.ink, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                        decoration: InputDecoration(
                          hintText: "SEARCH DISCIPLINE OR KEYWORD...",
                          hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14, letterSpacing: 1.0),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: AppColors.ink, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
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

  Widget _buildCategoryFilter() {
    final categories = ["TOATE", "REAL", "UMAN"];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? (AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink) : AppColors.cardBg,
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: isSelected ? const Offset(1, 1) : const Offset(3, 3),
                ),
              ],
            ),
            child: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isSelected ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white) : AppColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisciplinesGrid(bool isMobile) {
    final list = _filteredDisciplines;

    if (list.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                "NO DISCIPLINES MATCH YOUR SEARCH.",
                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 1120),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teachers').where('active', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          final teacherDocs = snapshot.data?.docs ?? [];

          return Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: isMobile ? 16 : 24,
            alignment: WrapAlignment.center,
            children: list.map((d) {
              final count = teacherDocs.where((doc) {
                final sub = (doc.data() as Map<String, dynamic>)['subject']?.toString().toLowerCase() ?? '';
                return sub.contains(d['name'].toString().toLowerCase());
              }).length;

              return _SpecializationCard(
                data: d,
                teacherCount: count,
                isMobile: isMobile,
                onTap: () {
                  final name = d['name'] as String;
                  context.go('/materii/${Uri.encodeComponent(name)}', extra: d);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 32 : 44),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII // ROSTER',
              style: TextStyle(fontSize: isMobile ? 26 : 32, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0),
            ),
            const SizedBox(height: 8),
            Text(
              'CHOOSE A DISCIPLINE. CONNECT DIRECTLY WITH GUILD MASTERS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecializationCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int teacherCount;
  final bool isMobile;
  final VoidCallback onTap;

  const _SpecializationCard({
    required this.data,
    required this.teacherCount,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_SpecializationCard> createState() => _SpecializationCardState();
}

class _SpecializationCardState extends State<_SpecializationCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] as String;
    final icon = widget.data['icon'] as IconData;
    final color = widget.data['color'] as Color;
    final desc = widget.data['desc'] as String;
    final tag = widget.data['tag'] as String;
    final count = widget.teacherCount;

    return MouseRegion(
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
          width: widget.isMobile ? double.infinity : 320,
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
              // Header Banner with Icon & Count
              Container(
                color: AppColors.cloud,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2.5, 2.5))],
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.forest : AppColors.sunset,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: count > 0 ? const Color(0xFF55EFC4) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$count ${count == 1 ? 'MASTER' : 'MASTERS'}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 2.5, color: AppColors.border),
              // Body
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.sunset, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "VIEW MASTERS",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.ink),
                          child: Icon(Icons.arrow_forward, size: 14, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white),
                        ),
                      ],
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