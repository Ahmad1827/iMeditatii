import 'package:flutter/material.dart';
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

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedTrack = 'PYTHON';

  final List<Map<String, dynamic>> _articles = [
    {
      "id": "py-intro",
      "track": "PYTHON",
      "grade": "9",
      "title": "Introducere în Python & Scurt Istoric",
      "desc": "Cum funcționează interpretorul, compilare vs interpretare, și primul tău print('Hello World!').",
      "readTime": "4 MIN",
      "tag": "BAZELE LIMBAJULUI",
      "icon": Icons.terminal,
      "color": AppColors.forest,
    },
    {
      "id": "py-vars",
      "track": "PYTHON",
      "grade": "9",
      "title": "Variabile, Tipuri de Date & input()",
      "desc": "Tipare dinamică: int, float, str, bool. Operații de citire și scriere cu conversie de tip.",
      "readTime": "6 MIN",
      "tag": "SINTAXĂ",
      "icon": Icons.data_object,
      "color": AppColors.sky,
    },
    {
      "id": "py-control",
      "track": "PYTHON",
      "grade": "9",
      "title": "Structuri de Control: if, elif & else",
      "desc": "Ramificări decizionale, operatori logici (and, or, not) și indentarea strictă PEP 8.",
      "readTime": "5 MIN",
      "tag": "CONTROL FLOW",
      "icon": Icons.alt_route,
      "color": AppColors.mustard,
    },
    {
      "id": "py-loops",
      "track": "PYTHON",
      "grade": "9",
      "title": "Structuri Repetitive: while & for range()",
      "desc": "Bucle determinate și nedeterminate. Funcția range(), instrucțiunile break și continue.",
      "readTime": "7 MIN",
      "tag": "BUCLE",
      "icon": Icons.repeat,
      "color": AppColors.sunset,
    },
    {
      "id": "cpp-intro",
      "track": "C++",
      "grade": "9",
      "title": "Bazele C++: Directiva #include & cin/cout",
      "desc": "Fluxuri standard iostream, namespaces, funcția main() și compilatorul GCC.",
      "readTime": "5 MIN",
      "tag": "BAZELE C++",
      "icon": Icons.code,
      "color": AppColors.forest,
    },
    {
      "id": "cpp-vars",
      "track": "C++",
      "grade": "9",
      "title": "Tipuri de date primitive & Operatori C++",
      "desc": "Modificatori de tip, codul ASCII pentru char, împărțirea întreagă și operatorul modulo (%).",
      "readTime": "6 MIN",
      "tag": "TIPURI & OPERATORI",
      "icon": Icons.calculate,
      "color": AppColors.sky,
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredArticles {
    return _articles.where((a) => a['track'] == _selectedTrack).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

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
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 20 : 36),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Banner
                            RetroBlock(
                              bgColor: AppColors.mustard,
                              padding: isMobile ? 18 : 28,
                              shadowOffset: isMobile ? 3.5 : 5.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    color: AppColors.ink,
                                    child: Text(
                                      "THE GUILD CODEX // DOCUMENTAȚIE",
                                      style: TextStyle(
                                        color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                  Text(
                                    "LECȚII TEORETICE & GHIDURI",
                                    style: TextStyle(
                                      fontSize: isMobile ? 24 : 36,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Materiale de studiu sintetizate pentru programa școlară de liceu. Fără tabele inutile, axat pe explicații vizuale și exemple directe de cod.",
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isMobile ? 20 : 28),

                            // Track Switcher (Python vs C++)
                            Row(
                              children: [
                                _buildTrackButton("PYTHON (CLASA A 9-A)", "PYTHON", Icons.terminal, AppColors.forest, isMobile),
                                SizedBox(width: isMobile ? 10 : 16),
                                _buildTrackButton("C++ (CLASA A 9-A)", "C++", Icons.code, AppColors.sky, isMobile),
                              ],
                            ),
                            SizedBox(height: isMobile ? 20 : 28),

                            // Articles Grid
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _filteredArticles.map((article) {
                                return _buildArticleCard(article, isMobile);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTrackButton(String label, String trackKey, IconData icon, Color activeColor, bool isMobile) {
    final isSelected = _selectedTrack == trackKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTrack = trackKey),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isSelected ? const Offset(1.5, 1.5) : Offset(isMobile ? 3 : 4, isMobile ? 3 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 18 : 22,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 12 : 14,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, bool isMobile) {
    final Color tagColor = article['color'] as Color;

    return GestureDetector(
      onTap: () => context.go('/resurse/${article['id']}'),
      child: Container(
        width: isMobile ? double.infinity : 540,
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
        padding: EdgeInsets.all(isMobile ? 16 : 22),
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
                    article['tag'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      article['readTime'],
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article['title'],
              style: TextStyle(
                fontSize: isMobile ? 17 : 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article['desc'],
              style: TextStyle(
                fontSize: isMobile ? 12.5 : 14,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  "DESCHIDE LECȚIA",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.8),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 14, color: AppColors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}