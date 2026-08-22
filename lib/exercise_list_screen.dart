import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class AppColors {
  static const Color bg = Color(0xFFF4F1EA);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE5E0D4);
  static const Color sky = Color(0xFF5BA8B5);
  static const Color purple = Color(0xFF8854D0);
  static const Color orange = Color(0xFFFA8231);
}

class ExerciseListScreen extends StatefulWidget {
  final String subject;
  final String? grade;

  const ExerciseListScreen({super.key, required this.subject, this.grade});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> allExercises = [];
  List<Map<String, dynamic>> displayedExercises = [];

  String selectedGrade = "9";
  String selectedCategory = "Toate";
  String searchQuery = "";

  List<String> availableGrades = [];
  List<String> availableCategories = [];

  bool isLoading = true;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.grade ?? "9";
    _loadAllExercises();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllExercises() async {
    setState(() => isLoading = true);

    List<Map<String, dynamic>> fetched = [];
    Set<String> tempGrades = {};

    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final data = json.decode(response);

      final subjectData = data[widget.subject];
      if (subjectData != null) {
        (subjectData as Map<String, dynamic>).forEach((gradeKey, categoriesMap) {
          tempGrades.add(gradeKey);
          (categoriesMap as Map<String, dynamic>).forEach((categoryName, exercisesList) {
            for (var ex in (exercisesList as List<dynamic>)) {
              fetched.add({
                'id': ex['id'],
                'grade': gradeKey,
                'category': categoryName,
                'title': ex['title'] ?? "Fără titlu",
                'difficulty': ex['difficulty'] ?? "ușoară",
                'source': 'json',
              });
            }
          });
        });
      }
    } catch (e) {
      debugPrint("Eroare JSON: $e");
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('subject', isEqualTo: widget.subject)
          .where('approved', isEqualTo: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final gradeStr = data['grade']?.toString() ?? "N/A";

        fetched.add({
          'id': doc.id,
          'grade': gradeStr,
          'category': data['category'] ?? "General",
          'title': data['title'] ?? "Fără titlu",
          'difficulty': data['difficulty'] ?? "ușoară",
          'source': 'firebase',
        });
        tempGrades.add(gradeStr);
      }
    } catch (e) {
      debugPrint("Eroare Firestore: $e");
    }

    if (mounted) {
      setState(() {
        allExercises = fetched;
        availableGrades = tempGrades.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        if (!availableGrades.contains(selectedGrade) && availableGrades.isNotEmpty) {
          selectedGrade = availableGrades.first;
        }
        isLoading = false;
      });

      _updateCategoriesAndFilter();
    }
  }

  void _updateCategoriesAndFilter() async {
    Set<String> tempCategories = {};
    List<Map<String, dynamic>> gradeFiltered = [];

    for (var ex in allExercises) {
      if (ex['grade'] == selectedGrade) {
        tempCategories.add(ex['category']);
        gradeFiltered.add(ex);
      }
    }

    int done = 0;
    final prefs = await SharedPreferences.getInstance();
    for (var ex in gradeFiltered) {
      final key = "${widget.subject}_${selectedGrade}_${ex['id']}";
      if (prefs.getBool(key) ?? false) done++;
    }

    setState(() {
      completedCount = done;
      availableCategories = tempCategories.toList()..sort();

      if (selectedCategory != "Toate" && !availableCategories.contains(selectedCategory)) {
        selectedCategory = "Toate";
      }

      var filtered = gradeFiltered;
      if (selectedCategory != "Toate") {
        filtered = filtered.where((ex) => ex['category'] == selectedCategory).toList();
      }

      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((ex) {
          final t = (ex['title'] as String).toLowerCase();
          final c = (ex['category'] as String).toLowerCase();
          return t.contains(searchQuery.toLowerCase()) || c.contains(searchQuery.toLowerCase());
        }).toList();
      }

      displayedExercises = filtered;
    });
  }

  Future<bool> _isExerciseDone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${selectedGrade}_$id";
    return prefs.getBool(key) ?? false;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.mustard,
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/exercitii'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(3, 3))],
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subject.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      fontSize: 24,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    "RESOLVE PROBLEMS • EARN XP",
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Butoane Nivel
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.ink, width: 2.5),
                  boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(3, 3))],
                ),
                child: Row(
                  children: availableGrades.map((g) {
                    final isSel = g == selectedGrade;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedGrade = g);
                        _updateCategoriesAndFilter();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.ink : Colors.transparent,
                        ),
                        child: Text(
                          "CLASA $g",
                          style: TextStyle(
                            color: isSel ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final totalInGrade = allExercises.where((e) => e['grade'] == selectedGrade).length;
    final progressPercent = totalInGrade > 0 ? (completedCount / totalInGrade) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panou Progres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "QUEST PROGRESS",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink, letterSpacing: 0.5),
                    ),
                    Text(
                      "$completedCount / $totalInGrade",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.forest),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.cloud,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forest),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Căutare
          const Text(
            "SEARCH QUEST",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: "Caută exercițiu...",
                hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.ink),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
              onChanged: (val) {
                searchQuery = val;
                _updateCategoriesAndFilter();
              },
            ),
          ),
          const SizedBox(height: 22),

          // Categorii
          const Text(
            "CATEGORIES",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          ...["Toate", ...availableCategories].map((cat) {
            final isSelected = cat == selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() => selectedCategory = cat);
                  _updateCategoriesAndFilter();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ink : Colors.white,
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cat.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : AppColors.ink,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) const Icon(Icons.arrow_right, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Watermark Made by Ahmad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.code, size: 16, color: AppColors.sunset),
                SizedBox(width: 8),
                Text(
                  "MADE BY AHMAD",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'QUEST LOG',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 2.5, fontSize: 16),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.ink, height: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.sunset))
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 800;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                              child: isDesktop
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(width: 330, child: _buildSidebar()),
                                        const SizedBox(width: 28),
                                        Expanded(child: _buildSingleColumnList()),
                                      ],
                                    )
                                  : ListView(
                                      children: [
                                        _buildSidebar(),
                                        const SizedBox(height: 20),
                                        _buildSingleColumnList(),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleColumnList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "AVAILABLE QUESTS (${displayedExercises.length})",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.6),
            ),
            Text(
              "FILTRU: ${selectedCategory.toUpperCase()}",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (displayedExercises.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, size: 40, color: AppColors.ink),
                SizedBox(height: 12),
                Text("NICIUN EXERCIȚIU GĂSIT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ],
            ),
          )
        else
          Expanded(
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: Radius.zero,
              thumbColor: AppColors.ink,
              trackColor: AppColors.cloud,
              trackBorderColor: AppColors.ink,
              padding: const EdgeInsets.only(left: 6),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(right: 14, bottom: 24),
                itemCount: displayedExercises.length,
                itemBuilder: (context, index) {
                  final ex = displayedExercises[index];
                  return FutureBuilder<bool>(
                    future: _isExerciseDone(ex["id"]),
                    builder: (context, snapshot) {
                      final isDone = snapshot.data ?? false;
                      return SingleColumnQuestCard(
                        index: index,
                        exercise: ex,
                        isDone: isDone,
                        onTap: () async {
                          final encodedMaterie = Uri.encodeComponent(widget.subject);
                          final encodedClasa = Uri.encodeComponent(selectedGrade);
                          final exId = ex["id"];

                          await context.push('/exercitiu/$exId?materie=$encodedMaterie&clasa=$encodedClasa');
                          if (mounted) _updateCategoriesAndFilter();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class SingleColumnQuestCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> exercise;
  final bool isDone;
  final VoidCallback onTap;

  const SingleColumnQuestCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.isDone,
    required this.onTap,
  });

  @override
  State<SingleColumnQuestCard> createState() => _SingleColumnQuestCardState();
}

class _SingleColumnQuestCardState extends State<SingleColumnQuestCard> {
  bool _isHover = false;
  bool _isPressed = false;

  static const List<Color> _badgeColors = [
    AppColors.sky,
    AppColors.orange,
    AppColors.purple,
    AppColors.mustard,
    AppColors.sunset,
    Color(0xFF20BF6B),
  ];

  Color _getBadgeColor() {
    if (widget.isDone) return AppColors.forest;
    return _badgeColors[widget.index % _badgeColors.length];
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară":
        return AppColors.forest;
      case "medie":
        return AppColors.mustard;
      case "grea":
        return AppColors.sunset;
      default:
        return AppColors.sky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.exercise["title"] ?? "UNKNOWN";
    final category = widget.exercise["category"] ?? "";
    final diff = widget.exercise["difficulty"] ?? "ușoară";
    final id = widget.exercise["id"] ?? "";

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          margin: const EdgeInsets.only(bottom: 16),
          transform: Matrix4.translationValues(
            _isPressed ? 2.5 : (_isHover ? -2.0 : 0.0),
            _isPressed ? 2.5 : (_isHover ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isDone ? const Color(0xFFF0EFE9) : Colors.white,
            border: Border.all(color: AppColors.ink, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: _isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ecuson stânga cu culori dinamice
                Container(
                  width: 68,
                  decoration: BoxDecoration(
                    color: _getBadgeColor(),
                    border: const Border(right: BorderSide(color: AppColors.ink, width: 2.5)),
                  ),
                  child: Center(
                    child: Text(
                      widget.isDone ? "✓" : "#$id",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Conținut central (Titlu & Categorie cu spațiu generos pe verticală)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink.withOpacity(0.75),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge Dificultate & Săgeată
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.ink, width: 2.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _difficultyColor(diff).withOpacity(0.15),
                          border: Border.all(color: _difficultyColor(diff), width: 1.5),
                        ),
                        child: Text(
                          diff.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _difficultyColor(diff),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.ink),
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
}