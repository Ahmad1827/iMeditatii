import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';
import 'resources_data.dart';

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

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedSubject = 'PYTHON'; // PYTHON, C++, MATEMATICĂ
  String _selectedGrade = '9'; // 9, 10, 11, 12
  String _searchQuery = '';

  final Map<String, GlobalKey> _moduleKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToModule(String module) {
    final key = _moduleKeys[module];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('resources')
                      .where('approved', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    List<Map<String, dynamic>> allArticles = List.from(ResourcesData.allArticles);

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        allArticles.add(data);
                      }
                    }

                    final filtered = allArticles.where((a) {
                      final matchSubject = (a['subject']?.toString().toUpperCase() ?? '') == _selectedSubject;
                      final matchGrade = (a['grade']?.toString() ?? '') == _selectedGrade;
                      final matchQuery = _searchQuery.isEmpty ||
                          (a['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                          (a['desc']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                      return matchSubject && matchGrade && matchQuery;
                    }).toList();

                    // Group by Module
                    final Map<String, List<Map<String, dynamic>>> groupedModules = {};
                    for (var art in filtered) {
                      final mod = art['module']?.toString().toUpperCase() ?? "GENERAL";
                      groupedModules.putIfAbsent(mod, () => []).add(art);
                      _moduleKeys.putIfAbsent(mod, () => GlobalKey());
                    }

                    return Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 18 : 36),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1140),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderBanner(isMobile),
                                SizedBox(height: isMobile ? 18 : 24),
                                _buildSubjectSelector(isMobile),
                                SizedBox(height: isMobile ? 12 : 16),
                                _buildGradeSelector(isMobile),
                                SizedBox(height: isMobile ? 14 : 20),
                                _buildSearchBar(isMobile),
                                SizedBox(height: isMobile ? 22 : 32),

                                if (groupedModules.isEmpty)
                                  _buildEmptyState(isMobile)
                                else if (!isMobile)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // LEFT SIDEBAR: Cuprins Capitole (Chapter Navigator)
                                      SizedBox(
                                        width: 280,
                                        child: _buildChapterNavigator(groupedModules.keys.toList()),
                                      ),
                                      const SizedBox(width: 24),
                                      // RIGHT MAIN FEED
                                      Expanded(
                                        child: Column(
                                          children: groupedModules.entries.map((entry) {
                                            return _buildModuleSection(entry.key, entry.value, isMobile);
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  // MOBILE: Horizontal quick jump strip
                                  _buildMobileChapterChips(groupedModules.keys.toList()),
                                  const SizedBox(height: 18),
                                  ...groupedModules.entries.map((entry) {
                                    return _buildModuleSection(entry.key, entry.value, isMobile);
                                  }),
                                ],

                                SizedBox(height: isMobile ? 24 : 48),
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

  Widget _buildChapterNavigator(List<String> modules) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: AppColors.ink, size: 20),
              const SizedBox(width: 8),
              Text(
                "CUPRINS CAPITOLE",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Apasă pe un capitol pentru a naviga direct la secțiune:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(height: 2, color: AppColors.border),
          const SizedBox(height: 14),
          ...modules.map((mod) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _scrollToModule(mod),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, color: AppColors.sunset, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mod,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileChapterChips(List<String> modules) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modules.map((mod) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.cardBg,
              side: BorderSide(color: AppColors.border, width: 2),
              avatar: Icon(Icons.arrow_downward, size: 14, color: AppColors.ink),
              label: Text(
                mod,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              onPressed: () => _scrollToModule(mod),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.mustard,
      padding: isMobile ? 18 : 28,
      shadowOffset: isMobile ? 3.5 : 5.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: AppColors.ink,
                child: Text(
                  "THE GUILD CODEX // RESURSE & TEORIE",
                  style: TextStyle(
                    color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.sunset,
                child: const Text(
                  "2026 CURRICULUM",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            "COMPENDIU DE CUNOȘTINȚE",
            style: TextStyle(
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.w900,
              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Teorie structurată pe module, optimizată pentru învățare rapidă cu exemple interactive de cod. Selectează materia și clasa pentru a naviga prin capitole.",
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(bool isMobile) {
    final subjects = [
      {"name": "PYTHON", "label": "PYTHON", "icon": Icons.terminal, "color": AppColors.forest},
      {"name": "C++", "label": "C++", "icon": Icons.code, "color": AppColors.sky},
      {"name": "MATEMATICĂ", "label": "MATEMATICĂ", "icon": Icons.functions, "color": AppColors.sunset},
    ];

    return Row(
      children: subjects.map((sub) {
        final isSelected = _selectedSubject == sub['name'];
        final color = sub['color'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubject = sub['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: isSelected ? const Offset(1.5, 1.5) : Offset(isMobile ? 2.5 : 4, isMobile ? 2.5 : 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sub['icon'] as IconData,
                      size: isMobile ? 16 : 20,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        sub['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 11.5 : 14,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradeSelector(bool isMobile) {
    final grades = [
      {"grade": "9", "label": "CLASA A 9-A"},
      {"grade": "10", "label": "CLASA A 10-A"},
      {"grade": "11", "label": "CLASA A 11-A"},
      {"grade": "12", "label": "CLASA A 12-A"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: grades.map((g) {
          final isSelected = _selectedGrade == g['grade'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGrade = g['grade']!),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 7 : 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (AppColors.isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F))
                      : AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: isSelected ? const Offset(1, 1) : const Offset(2.5, 2.5),
                    ),
                  ],
                ),
                child: Text(
                  g['label']!,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: isSelected
                        ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                        : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.ink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
              cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
              decoration: InputDecoration(
                hintText: "CAUTĂ DUPĂ TITLU, TERMENI SAU LECȚIE...",
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: isMobile ? 11.5 : 13, fontWeight: FontWeight.bold),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: AppColors.ink, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModuleSection(String moduleTitle, List<Map<String, dynamic>> articles, bool isMobile) {
    return Container(
      key: _moduleKeys[moduleTitle],
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
                child: Text(
                  moduleTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(height: 2.5, color: AppColors.border),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: articles.map((article) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildArticleCard(article, isMobile),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, bool isMobile) {
    final Color tagColor = (article['color'] as Color?) ?? AppColors.forest;
    final String author = article['author'] ?? ResourcesData.defaultAuthor;
    final String date = article['date'] ?? ResourcesData.defaultDate;
    final String readTime = article['readTime'] ?? "5 MIN";

    return GestureDetector(
      onTap: () => context.go('/resurse/${article['id']}'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.border, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: tagColor,
                  child: Text(
                    article['tag'] ?? 'DOCUMENTAȚIE',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      readTime,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article['title'] ?? 'UNTITLED',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18.5,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article['desc'] ?? '',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Container(height: 1.5, color: AppColors.border.withOpacity(0.4)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.mustard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        author.isNotEmpty ? author[0].toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "BY ${author.toUpperCase()}",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.event_note, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.menu_book, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              "NICIUN ARTICOL PENTRU ACEASTĂ CONFIGURAȚIE.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: isMobile ? 13 : 15),
            ),
            const SizedBox(height: 6),
            Text(
              "Schimbă clasa sau materia din filtrele de mai sus.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 24 : 36),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII // CODEX',
              style: TextStyle(
                fontSize: isMobile ? 20 : 26,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MASTER YOUR KNOWLEDGE • REPUTATION REWARDED.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}