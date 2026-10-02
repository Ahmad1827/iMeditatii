import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';
import 'ui_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _completedQuests = 0;
  bool _isLoadingStats = true;
  String _academicGrade = "9"; // 9, 10, 11, 12

  @override
  void initState() {
    super.initState();
    _loadPlayerStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int completed = 0;
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (prefs.getBool(key) == true) {
          completed++;
        }
      }
      setState(() {
        _completedQuests = completed;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint("Error loading stats: $e");
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _startDailyQuest() {
    const exerciseId = '1';
    final encodedMaterie = Uri.encodeComponent('Informatică');
    final encodedClasa = Uri.encodeComponent('9');
    context.go('/exercitiu/$exerciseId?materie=$encodedMaterie&clasa=$encodedClasa');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;

    return ValueListenableBuilder<AppStyleMode>(
      valueListenable: ThemeManager.styleNotifier,
      builder: (context, currentStyle, _) {
        final isClean = currentStyle == AppStyleMode.clean;

        return Scaffold(
          backgroundColor: isClean
              ? (AppColors.isDark ? const Color(0xFF141A1F) : const Color(0xFFF8F9FA))
              : AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: isClean
                        ? _buildAcademicDirectoryView(isMobile)
                        : _buildRetroArcadeView(isMobile),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // VIEW 1: AUTHENTIC PBINFO-STYLE ACADEMIC DIRECTORY (CLEAN MODE)
  // =========================================================================
  Widget _buildAcademicDirectoryView(bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1140),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 20 : 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Breadcrumb & Notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? const Color(0xFF1E252B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, size: 20, color: Color(0xFF20BF6B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Portal educațional de informatică și matematică conform programei școlare naționale 2026.",
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grade Tabs (Clasa a IX-a – Clasa a XII-a)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _academicGradeTab("9", "Clasa a IX-a (Python & C++)"),
                    const SizedBox(width: 8),
                    _academicGradeTab("10", "Clasa a X-a (Recursivitate & Matrice)"),
                    const SizedBox(width: 8),
                    _academicGradeTab("11", "Clasa a XI-a (Grafuri & Dinamică)"),
                    const SizedBox(width: 8),
                    _academicGradeTab("12", "Clasa a XII-a (OOP, SQL & Bacalaureat)"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Academic Curriculum Grid
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCurriculumColumnA()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCurriculumColumnB()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildCurriculumColumnA(),
                    const SizedBox(height: 18),
                    _buildCurriculumColumnB(),
                  ],
                ),

              const SizedBox(height: 36),

              // Clean Quick Practice Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? const Color(0xFF1E252B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Vrei să exersezi direct în arenă?",
                            style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rezolvă probleme cu evaluator automat C++ și teste live.",
                            style: TextStyle(fontSize: isMobile ? 12.5 : 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20BF6B),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      onPressed: () => context.go('/exercitii'),
                      child: const Text("Deschide Probleme", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              _buildAcademicFooter(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _academicGradeTab(String grade, String title) {
    final isSelected = _academicGrade == grade;
    return InkWell(
      onTap: () => setState(() => _academicGrade = grade),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF20BF6B)
              : (AppColors.isDark ? const Color(0xFF1E252B) : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.transparent : (AppColors.isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCurriculumColumnA() {
    if (_academicGrade == "9") {
      return Column(
        children: [
          _academicDirectoryCard(
            title: "Elemente de bază ale limbajului Python",
            badge: "NOU ÎN PROGRAMĂ",
            badgeColor: const Color(0xFF20BF6B),
            topics: [
              {"title": "Introducere în Python & Scurt Istoric", "route": "/resurse/py-9-intro"},
              {"title": "Variabile, Tipuri Primitive & input()", "route": "/resurse/py-9-vars"},
              {"title": "Operatori Aritmetici & Logici", "route": "/resurse/py-9-operators"},
            ],
          ),
          const SizedBox(height: 18),
          _academicDirectoryCard(
            title: "Structuri de control Python",
            badge: "PYTHON 3",
            badgeColor: const Color(0xFF45AAF2),
            topics: [
              {"title": "Instrucțiunea Decizională: if, elif, else", "route": "/resurse/py-9-if"},
              {"title": "Structuri Repetitive: while & for range()", "route": "/resurse/py-9-loops"},
            ],
          ),
        ],
      );
    } else if (_academicGrade == "10") {
      return _academicDirectoryCard(
        title: "Tablouri Bidimensionale (Matrice)",
        badge: "C++",
        badgeColor: const Color(0xFF45AAF2),
        topics: [
          {"title": "Matrice în C++: Declarare & Parcurgere", "route": "/resurse/cpp-10-matrix-basics"},
          {"title": "Diagonala Principală & Secundară", "route": "/resurse/cpp-10-matrix-diagonals"},
        ],
      );
    } else if (_academicGrade == "11") {
      return _academicDirectoryCard(
        title: "Tehnica Backtracking",
        badge: "ALGORITMICĂ",
        badgeColor: const Color(0xFF8854D0),
        topics: [
          {"title": "Backtracking: Căutare cu Revenire", "route": "/resurse/cpp-11-backtracking-intro"},
          {"title": "Generarea Permutărilor", "route": "/resurse/cpp-11-backtracking-perm"},
          {"title": "Generarea Combinărilor & Aranjamentelor", "route": "/resurse/cpp-11-backtracking-comb"},
        ],
      );
    } else {
      return _academicDirectoryCard(
        title: "Programare Orientată pe Obiecte (OOP)",
        badge: "C++",
        badgeColor: const Color(0xFF45AAF2),
        topics: [
          {"title": "Clase, Obiecte & Modificatori de Acces", "route": "/resurse/cpp-12-oop-classes"},
          {"title": "Constructori & Destructori", "route": "/resurse/cpp-12-oop-constructors"},
          {"title": "Moștenire & Polimorfism", "route": "/resurse/cpp-12-oop-inheritance"},
        ],
      );
    }
  }

  Widget _buildCurriculumColumnB() {
    if (_academicGrade == "9") {
      return Column(
        children: [
          _academicDirectoryCard(
            title: "Elemente de bază ale limbajului C++",
            badge: "CURRICULUM",
            badgeColor: const Color(0xFFFA8231),
            topics: [
              {"title": "Directiva #include, iostream & cin/cout", "route": "/resurse/cpp-9-intro"},
              {"title": "Tipuri de Date, Operatori & Codul ASCII", "route": "/resurse/cpp-9-types"},
              {"title": "Buclele while, do-while și for", "route": "/resurse/cpp-9-loops"},
            ],
          ),
          const SizedBox(height: 18),
          _academicDirectoryCard(
            title: "Algoritmi Elementari & Vectori",
            badge: "OLIMPIADĂ & BAC",
            badgeColor: const Color(0xFF20BF6B),
            topics: [
              {"title": "Prelucrarea Cifrelor unui Număr", "route": "/resurse/alg-9-digits"},
              {"title": "Divizibilitate, Numere Prime & Descompunere", "route": "/resurse/alg-9-divisors"},
              {"title": "Vectori în C++: Declarare & Parcurgere", "route": "/resurse/cpp-9-vectors-basic"},
            ],
          ),
        ],
      );
    } else if (_academicGrade == "10") {
      return _academicDirectoryCard(
        title: "Recursivitate & Divide et Impera",
        badge: "ALGORITMICĂ",
        badgeColor: const Color(0xFF20BF6B),
        topics: [
          {"title": "Recursivitate: Stiva de apeluri", "route": "/resurse/cpp-10-recursion-intro"},
          {"title": "Divide et Impera & Căutarea Binară", "route": "/resurse/cpp-10-d&i-intro"},
          {"title": "MergeSort & QuickSort", "route": "/resurse/cpp-10-d&i-mergesort"},
        ],
      );
    } else if (_academicGrade == "11") {
      return _academicDirectoryCard(
        title: "Grafuri Neorientate & Dinamică",
        badge: "CLASA A XI-A",
        badgeColor: const Color(0xFF20BF6B),
        topics: [
          {"title": "Matricea de Adiacență & Conexitate", "route": "/resurse/cpp-11-graphs-matrix"},
          {"title": "Parcurgerile BFS și DFS", "route": "/resurse/cpp-11-graphs-bfs"},
          {"title": "Programare Dinamică: Recurență & LIS", "route": "/resurse/cpp-11-dp-subseq"},
        ],
      );
    } else {
      return _academicDirectoryCard(
        title: "Pregătire Bacalaureat Informatică",
        badge: "EXAMEN BAC",
        badgeColor: const Color(0xFFE75A41),
        topics: [
          {"title": "Strategii pentru Subiectul I (Grile)", "route": "/resurse/bac-12-info-sub1"},
          {"title": "Rezolvarea Subiectului II (Șiruri & Struct)", "route": "/resurse/bac-12-info-sub2"},
          {"title": "Subiectul III.3: Algoritmi Eficienți O(N) și O(1)", "route": "/resurse/bac-12-info-sub3"},
        ],
      );
    }
  }

  Widget _academicDirectoryCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required List<Map<String, String>> topics,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF1E252B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          const SizedBox(height: 12),
          ...topics.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => context.go(t['route']!),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 18, color: Color(0xFF20BF6B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        t['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAcademicFooter(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black.withOpacity(0.08))),
      ),
      child: Center(
        child: Text(
          "iMeditatii • Platformă educațională deschisă • Conform programei Ministerului Educației",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 2: ORIGINAL 8-BIT RETRO GAMING VIEW
  // =========================================================================
  Widget _buildRetroArcadeView(bool isMobile) {
    return Column(
      children: [
        _buildHeroSection(isMobile),
        _buildPathsSection(isMobile),
        _buildMastersSection(isMobile),
        SizedBox(height: isMobile ? 14 : 28),
        _buildRetroFooter(isMobile),
      ],
    );
  }

  Widget _buildConstrainedSection({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    final leftContent = RetroBlock(
      bgColor: AppColors.mustard,
      padding: isMobile ? 18 : 36,
      shadowOffset: isMobile ? 3.5 : 6.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM OPERATIONAL',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: isMobile ? 11 : 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: AppColors.sunset,
                    child: const Text(
                      "SEASON 1",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 14 : 20),
              Text(
                "LEVEL UP YOUR\nKNOWLEDGE.",
                style: TextStyle(
                  fontSize: isMobile ? 26 : 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                  height: 1.1,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Text(
                "Alege o materie. Găsește un mentor verificat și rezolvă quest-uri interactive pentru a avansa în nivel.",
                style: TextStyle(
                  fontSize: isMobile ? 14 : 17,
                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 28),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RetroButton(
                  text: "FIND A MASTER",
                  icon: Icons.search,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  bgColor: AppColors.forest,
                  isFullWidth: true,
                  onPressed: () => context.go('/materii'),
                ),
                const SizedBox(height: 10),
                RetroButton(
                  text: "DAILY QUESTS",
                  icon: Icons.track_changes,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  isFullWidth: true,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            )
          else
            Row(
              children: [
                RetroButton(
                  text: "FIND A MASTER",
                  icon: Icons.search,
                  bgColor: AppColors.forest,
                  onPressed: () => context.go('/materii'),
                ),
                const SizedBox(width: 16),
                RetroButton(
                  text: "DAILY QUESTS",
                  icon: Icons.track_changes,
                  bgColor: AppColors.cardBg,
                  textColor: AppColors.ink,
                  onPressed: () => context.go('/exercitii'),
                ),
              ],
            ),
        ],
      ),
    );

    final rightContent = RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 18 : 32,
      shadowOffset: isMobile ? 3.5 : 6.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "YOUR PROGRESS",
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 14 : 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.sky, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(
                      _completedQuests > 10 ? "GOLD GUILD" : (_completedQuests > 3 ? "SILVER RANK" : "NOVICE"),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("QUESTS CLEARED", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12)),
                        _isLoadingStats
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text("$_completedQuests SOLVED", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      child: LinearProgressIndicator(
                        value: (_completedQuests % 5) / 5.0 == 0 && _completedQuests > 0 ? 1.0 : (_completedQuests % 5) / 5.0,
                        backgroundColor: AppColors.border.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("DAILY BOUNTY", style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                  Icon(Icons.star, color: AppColors.mustard, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "INFORMATICĂ // CLASA A 9-A",
                style: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(
                "RECOMPENSĂ: +50 EXP // AUTO-CHECK",
                style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          RetroButton(
            text: "ACCEPT BOUNTY",
            icon: Icons.play_arrow,
            bgColor: AppColors.sunset,
            isFullWidth: true,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: _startDailyQuest,
          ),
        ],
      ),
    );

    return _buildConstrainedSection(
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, isMobile ? 16 : 36, isMobile ? 14 : 24, isMobile ? 16 : 28),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftContent,
                const SizedBox(height: 14),
                rightContent,
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: leftContent),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: rightContent),
                ],
              ),
            ),
    );
  }

  Widget _buildPathsSection(bool isMobile) {
    final List<Map<String, dynamic>> paths = [
      {"icon": Icons.functions, "title": "MATEMATICĂ", "color": AppColors.sunset, "desc": "ALGEBRĂ & GEOMETRIE", "route": "Matematică"},
      {"icon": Icons.data_object, "title": "INFORMATICĂ", "color": AppColors.forest, "desc": "ALGORITMI & C++", "route": "Informatică"},
      {"icon": Icons.language, "title": "LIMBI STRĂINE", "color": AppColors.sky, "desc": "ENGLEZĂ & ROMÂNĂ", "route": "Engleză"},
    ];

    final List<Widget> pathCards = paths.map((path) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: isMobile && path != paths.last ? 12 : 0,
          right: !isMobile && path != paths.last ? 20 : 0,
        ),
        child: GestureDetector(
          onTap: () {
            final encoded = Uri.encodeComponent(path["route"] as String);
            context.go('/lista-exercitii?materie=$encoded');
          },
          child: RetroBlock(
            bgColor: AppColors.cardBg,
            padding: isMobile ? 16 : 24,
            shadowOffset: isMobile ? 3.5 : 6.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 18),
                  decoration: BoxDecoration(
                    color: path["color"],
                    border: Border.all(color: AppColors.border, width: 2.5),
                    boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
                  ),
                  child: Icon(path["icon"], size: isMobile ? 26 : 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  path["title"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path["desc"],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 28, horizontal: isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "CHOOSE YOUR PATH",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 22 : 34,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "SELECTEAZĂ O DISCIPLINĂ PENTRU ANTRENAMENT.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 11 : 15, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: pathCards)
              : Row(children: pathCards.map((card) => Expanded(child: card)).toList()),
        ],
      ),
    );
  }

  Widget _buildMastersSection(bool isMobile) {
    final leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.isDark ? AppColors.sunset : AppColors.ink,
          child: const Text(
            "GUILD ROSTER",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isMobile ? "MEET THE MASTERS." : "MEET THE\nMASTERS.",
          style: TextStyle(
            fontSize: isMobile ? 24 : 40,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            height: 1.1,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Mentori verificați gata să te ghideze 1-la-1 cu tablă interactivă live și conexiune securizată.",
          style: TextStyle(
            fontSize: isMobile ? 13 : 16,
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            height: 1.45,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 22),
        RetroButton(
          text: "EXPLOREAZĂ PROFESORII",
          icon: Icons.groups,
          bgColor: AppColors.sunset,
          isFullWidth: isMobile,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onPressed: () => context.go('/materii'),
        ),
      ],
    );

    final rightContent = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isMobile ? 1.25 : 1.1,
      children: [
        _buildMasterAvatar(Icons.calculate, "MATH", AppColors.sky),
        _buildMasterAvatar(Icons.terminal, "CODE", AppColors.mustard),
        _buildMasterAvatar(Icons.bolt, "PHYSICS", AppColors.forest),
        _buildMasterAvatar(Icons.science, "CHEM", AppColors.sunset),
      ],
    );

    return _buildConstrainedSection(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 36, horizontal: isMobile ? 14 : 24),
      child: RetroBlock(
        bgColor: AppColors.cloud,
        padding: isMobile ? 16 : 36,
        shadowOffset: isMobile ? 3.5 : 6.0,
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftContent,
                  const SizedBox(height: 20),
                  rightContent,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: leftContent),
                  const SizedBox(width: 36),
                  Expanded(child: rightContent),
                ],
              ),
      ),
    );
  }

  Widget _buildMasterAvatar(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: AppColors.isDark && color == AppColors.mustard ? const Color(0xFF10161A) : Colors.white),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: AppColors.ink,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 26 : 44),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'IMEDITATII // GUILD',
              style: TextStyle(
                fontSize: isMobile ? 22 : 32,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SYSTEM LOG: LEVEL UP YOUR LEARNING IN 2026.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}