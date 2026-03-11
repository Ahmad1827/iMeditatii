import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              tooltip: 'Înapoi',
              onPressed: () => context.go('/exercitii'),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subject,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 24, letterSpacing: -0.5),
              ),
              Text("Rezolvă probleme și urmărește-ți progresul", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 20, color: Colors.black87),
              SizedBox(width: 8),
              Text("Filtrează", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 24),

          if (availableGrades.isEmpty)
            const Text("Nicio clasă disponibilă", style: TextStyle(color: Colors.redAccent))
          else ...[
            Text("Clasa", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
            const SizedBox(height: 8),
            _modernDropdown(
              value: availableGrades.contains(selectedGrade) ? selectedGrade : null,
              items: availableGrades.map((g) => DropdownMenuItem(value: g, child: Text("Clasa $g"))).toList(),
              onChanged: (val) {
                setState(() {
                  selectedGrade = val!;
                  _updateCategoriesAndFilter();
                });
              },
            ),
          ],

          const SizedBox(height: 24),
          Text("Categoria", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
          const SizedBox(height: 8),
          _modernDropdown(
            value: ["Toate", ...availableCategories].contains(selectedCategory) ? selectedCategory : null,
            items: ["Toate", ...availableCategories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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

  Widget _modernDropdown({required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: 30),
                      child: isWide
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSidebar(),
                          const SizedBox(width: 40),
                          Expanded(child: _buildListSection()),
                        ],
                      )
                          : Column(
                        children: [
                          SizedBox(width: double.infinity, child: _buildSidebar()),
                          const SizedBox(height: 24),
                          Expanded(child: _buildListSection()),
                        ],
                      ),
                    );
                  }
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
              "Probleme disponibile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
              child: Text("${displayedExercises.length} probleme", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (displayedExercises.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("Nu am găsit exerciții.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  Text("Încearcă să schimbi filtrele.", style: TextStyle(color: Colors.grey.shade500)),
                ],
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
                        // 🚀 URL securizat cu ID-ul în path și parametrii codificați
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

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară": return const Color(0xFF10B981);
      case "medie": return const Color(0xFFF59E0B);
      case "grea": return const Color(0xFFEF4444);
      default: return Colors.blueGrey;
    }
  }

  Color _difficultyBg(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară": return const Color(0xFF10B981).withOpacity(0.1);
      case "medie": return const Color(0xFFF59E0B).withOpacity(0.1);
      case "grea": return const Color(0xFFEF4444).withOpacity(0.1);
      default: return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.exercise["title"] ?? "Titlu necunoscut";
    final category = widget.exercise["category"] ?? "";
    final diff = widget.exercise["difficulty"] ?? "ușoară";

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovering ? Colors.blueAccent.withOpacity(0.5) : Colors.grey.shade200,
              width: _isHovering ? 2 : 1,
            ),
            boxShadow: _isHovering
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          transform: _isHovering ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDone ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.isDone ? Icons.check_circle : Icons.code, color: widget.isDone ? Colors.green : Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Text(category, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _difficultyBg(diff), borderRadius: BorderRadius.circular(20)),
                child: Text(diff.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _difficultyColor(diff), letterSpacing: 0.5)),
              ),
              const SizedBox(width: 16),
              Icon(Icons.arrow_forward_ios, size: 16, color: _isHovering ? Colors.blueAccent : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}