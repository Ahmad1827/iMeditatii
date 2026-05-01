import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;
  final bool fillWidth;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor = Colors.white,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor = AppColors.ink,
    this.fillWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fillWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
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

class RetroDropdown extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final Function(String?) onChanged;
  final Color color;

  const RetroDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.color = AppColors.sky,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink, width: 3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.ink, size: 32),
          style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold),
          dropdownColor: Colors.white,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class ExerciseListScreen extends StatefulWidget {
  final String subject;
  final String? grade;

  const ExerciseListScreen({super.key, required this.subject, this.grade});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<Map<String, dynamic>> allExercises = [];
  List<Map<String, dynamic>> displayedExercises = [];

  String selectedGrade = "9";
  String selectedCategory = "Toate";

  List<String> availableGrades = [];
  List<String> availableCategories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.grade ?? "9";
    _loadExercisesFromFirebase();
  }

  Future<void> _loadExercisesFromFirebase() async {
    setState(() => isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('subject', isEqualTo: widget.subject)
          .get();

      List<Map<String, dynamic>> fetchedExercises = [];
      Set<String> tempGrades = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['grade'] = data['grade']?.toString() ?? "N/A";
        data['category'] = data['category'] ?? "General";
        data['title'] = data['title'] ?? "Fără titlu";
        data['difficulty'] = data['difficulty'] ?? "ușoară";

        fetchedExercises.add(data);
        tempGrades.add(data['grade']);
      }

      setState(() {
        allExercises = fetchedExercises;
        availableGrades = tempGrades.toList()..sort();

        if (!availableGrades.contains(selectedGrade) && availableGrades.isNotEmpty) {
          selectedGrade = availableGrades.first;
        }
        isLoading = false;
      });

      _updateCategoriesAndFilter();
    } catch (e) {
      debugPrint("Eroare la încărcarea din Firebase: $e");
      setState(() => isLoading = false);
    }
  }

  void _updateCategoriesAndFilter() {
    Set<String> tempCategories = {};
    List<Map<String, dynamic>> gradeFiltered = [];

    for (var ex in allExercises) {
      if (ex['grade'] == selectedGrade) {
        tempCategories.add(ex['category']);
        gradeFiltered.add(ex);
      }
    }

    setState(() {
      availableCategories = tempCategories.toList()..sort();

      if (selectedCategory != "Toate" && !availableCategories.contains(selectedCategory)) {
        selectedCategory = "Toate";
      }

      if (selectedCategory == "Toate") {
        displayedExercises = gradeFiltered;
      } else {
        displayedExercises = gradeFiltered.where((ex) => ex['category'] == selectedCategory).toList();
      }
    });
  }

  Future<bool> _isExerciseDone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${selectedGrade}_$id";
    return prefs.getBool(key) ?? false;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.ink, width: 3),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        fontSize: 32,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      "SOLVE QUESTS AND TRACK YOUR EXP",
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSidebar() {
    return RetroBlock(
      bgColor: AppColors.cloud,
      padding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 28, color: AppColors.ink),
              SizedBox(width: 12),
              Text("DATA FILTERS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 32),
          if (availableGrades.isEmpty)
            const Text("NO LEVELS AVAILABLE", style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.bold))
          else ...[
            const Text("LEVEL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            RetroDropdown(
              value: availableGrades.contains(selectedGrade) ? selectedGrade : null,
              items: availableGrades.map((g) => DropdownMenuItem(value: g, child: Text("LEVEL $g", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (val) {
                setState(() {
                  selectedGrade = val!;
                  _updateCategoriesAndFilter();
                });
              },
            ),
          ],
          const SizedBox(height: 32),
          const Text("CATEGORY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          RetroDropdown(
            value: ["Toate", ...availableCategories].contains(selectedCategory) ? selectedCategory : null,
            items: ["Toate", ...availableCategories].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (val) {
              setState(() {
                selectedCategory = val!;
                _updateCategoriesAndFilter();
              });
            },
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
        title: const Text('QUEST LOG', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
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
                      final isWide = constraints.maxWidth > 800;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: isWide
                            ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 320, child: _buildSidebar()),
                            const SizedBox(width: 40),
                            Expanded(child: _buildListSection()),
                          ],
                        )
                            : Column(
                          children: [
                            SizedBox(width: double.infinity, child: _buildSidebar()),
                            const SizedBox(height: 32),
                            Expanded(child: _buildListSection()),
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

  Widget _buildListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "AVAILABLE QUESTS",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.ink, border: Border.all(color: AppColors.ink, width: 3)),
              child: Text(
                "${displayedExercises.length} QUESTS",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (displayedExercises.isEmpty)
          Expanded(
            child: Center(
              child: RetroBlock(
                bgColor: AppColors.cloud,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.search_off, size: 64, color: AppColors.ink),
                    SizedBox(height: 24),
                    Text("NO QUESTS FOUND.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    SizedBox(height: 8),
                    Text("ADJUST FILTERS TO SEARCH AGAIN.", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: displayedExercises.length,
              itemBuilder: (context, index) {
                final ex = displayedExercises[index];
                return FutureBuilder<bool>(
                  future: _isExerciseDone(ex["id"]),
                  builder: (context, snapshot) {
                    final isDone = snapshot.data ?? false;
                    return ExerciseListItem(
                      exercise: ex,
                      isDone: isDone,
                      onTap: () async {
                        final encodedMaterie = Uri.encodeComponent(widget.subject);
                        final encodedClasa = Uri.encodeComponent(selectedGrade);
                        final exId = ex["id"];

                        await context.push('/exercitiu/$exId?materie=$encodedMaterie&clasa=$encodedClasa');
                        if (mounted) setState(() {});
                      },
                    );
                  },
                );
              },
            ),
          )
      ],
    );
  }
}

class ExerciseListItem extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final bool isDone;
  final VoidCallback onTap;

  const ExerciseListItem({super.key, required this.exercise, required this.isDone, required this.onTap});

  @override
  State<ExerciseListItem> createState() => _ExerciseListItemState();
}

class _ExerciseListItemState extends State<ExerciseListItem> {
  bool _isHovering = false;
  bool _isPressed = false;

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară": return AppColors.forest;
      case "medie": return AppColors.mustard;
      case "grea": return AppColors.sunset;
      default: return AppColors.sky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.exercise["title"] ?? "UNKNOWN TITLE";
    final category = widget.exercise["category"] ?? "";
    final diff = widget.exercise["difficulty"] ?? "ușoară";

    return MouseRegion(
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
          margin: const EdgeInsets.only(bottom: 24),
          transform: Matrix4.translationValues(
            _isPressed ? 4.0 : (_isHovering ? -2.0 : 0.0),
            _isPressed ? 4.0 : (_isHovering ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isDone ? AppColors.cloud : Colors.white,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: _isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              )
            ],
          ),
          // 🚀 FIX: Wrap the Row in IntrinsicHeight here!
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: widget.isDone ? AppColors.forest : AppColors.sky,
                    border: const Border(right: BorderSide(color: AppColors.ink, width: 3)),
                  ),
                  child: Center(
                    child: Icon(
                        widget.isDone ? Icons.check_circle : Icons.code,
                        color: widget.isDone ? Colors.white : AppColors.ink,
                        size: 40
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            title.toUpperCase(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)
                        ),
                        const SizedBox(height: 8),
                        Text(
                            category.toUpperCase(),
                            style: const TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.ink, width: 3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          diff.toUpperCase(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _difficultyColor(diff), letterSpacing: 1.5)
                      ),
                      const SizedBox(height: 12),
                      const Icon(Icons.arrow_forward_ios, size: 24, color: AppColors.ink),
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