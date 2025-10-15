import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exercise_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseListScreen extends StatefulWidget {
  final String subject;
  final String? grade;

  const ExerciseListScreen({super.key, required this.subject, this.grade});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  Map<String, dynamic> exercisesJson = {};
  List<Map<String, dynamic>> exercises = [];

  String selectedGrade = "9";
  String selectedCategory = "Toate";

  List<String> availableGrades = [];
  List<String> availableCategories = [];

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.grade ?? "9";
    _loadExercises();
  }
  Future<bool> _isExerciseDone(String grade, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${grade}_$id"; // ❌ asigura-te că folosești parametrul grade corect
    return prefs.getBool(key) ?? false;
  }

  Future<void> _loadExercises() async {
    final String response = await rootBundle.loadString('assets/data/exercises.json');
    final data = json.decode(response);

    setState(() {
      exercisesJson = data;
      availableGrades = exercisesJson[widget.subject]?.keys.cast<String>().toList() ?? [];

      // ✅ dacă materia are clasa 9, o alegem automat
      if (availableGrades.contains("9")) {
        selectedGrade = "9";
      } else if (availableGrades.isNotEmpty) {
        // altfel o alegem pe prima disponibilă
        selectedGrade = availableGrades.first;
      }

      selectedCategory = "Toate";
    });

    _filterExercises();
  }


  void _filterExercises() {
    if (exercisesJson.isEmpty) return;

    final subjectData = exercisesJson[widget.subject];
    if (subjectData == null) return;

    final gradeData = subjectData[selectedGrade];
    if (gradeData == null) {
      setState(() => exercises = []);
      return;
    }

    availableCategories = gradeData.keys.toList();

    List<Map<String, dynamic>> filtered = [];

    if (selectedCategory == "Toate") {
      for (var cat in gradeData.keys) {
        final List list = gradeData[cat];
        filtered.addAll(list.map((e) => {
          "id": e["id"],
          "title": e["title"],
          "difficulty": e["difficulty"],
          "category": cat,
        }));
      }
    } else {
      final List list = gradeData[selectedCategory];
      filtered.addAll(list.map((e) => {
        "id": e["id"],
        "title": e["title"],
        "difficulty": e["difficulty"],
        "category": selectedCategory,
      }));
    }

    setState(() => exercises = filtered);
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară":
        return Colors.green.shade700;
      case "medie":
        return Colors.orange.shade700;
      case "grea":
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Color _difficultyBg(String diff) {
    switch (diff.toLowerCase()) {
      case "ușoară":
        return Colors.green.shade50;
      case "medie":
        return Colors.orange.shade50;
      case "grea":
        return Colors.red.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'iMeditatii',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
            fontSize: 22,
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILTRU STÂNGA
            Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filtrează problemele",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Clasa:"),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: availableGrades.contains(selectedGrade) ? selectedGrade : null,
                    items: availableGrades
                        .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text("Clasa $g"),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedGrade = val!;
                        selectedCategory = "Toate";
                        _filterExercises();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Categoria:"),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: ["Toate", ...availableCategories].contains(selectedCategory)
                        ? selectedCategory
                        : null,
                    items: ["Toate", ...availableCategories]
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCategory = val!;
                        _filterExercises();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // LISTA DREAPTA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lista de probleme (${widget.subject})",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${exercises.length} probleme",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final diff = ex["difficulty"] ?? "necunoscută";

                        return FutureBuilder<bool>(
                          future: _isExerciseDone(selectedGrade, ex["id"]),
                          builder: (context, snapshot) {
                            final isDone = snapshot.data ?? false;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExerciseDetailScreen(
                                      subject: widget.subject,
                                      grade: selectedGrade,
                                      id: ex["id"],
                                    ),
                                  ),
                                ).then((_) {
                                  setState(() {}); // Rebuild pentru a actualiza statusul după ce utilizatorul rezolvă
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isDone ? Icons.check_circle : Icons.task_alt,
                                        color: isDone ? Colors.green : Colors.blueAccent,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ex["title"] ?? "Titlu necunoscut",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            ex["category"] ?? "",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _difficultyBg(diff),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "Dificultate: $diff",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _difficultyColor(diff),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
