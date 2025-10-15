import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exercise_list_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String subject;
  final int grade;

  const CategoryScreen({super.key, required this.subject, required this.grade});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<String> categories = [];
  bool isLoading = true;
  Map<String, dynamic> classData = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final data = json.decode(response);

      // Ia materia
      final subjectData = data[widget.subject];
      if (subjectData != null) {
        final gradeData = subjectData[widget.grade.toString()];
        if (gradeData != null) {
          setState(() {
            categories = gradeData.keys.toList(); // doar ce e in JSON
            classData = gradeData;
            isLoading = false;
          });
          return;
        }
      }

      // fallback dacă nu există date
      setState(() {
        categories = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        categories = [];
        isLoading = false;
      });
      debugPrint("Eroare la încărcarea categoriilor: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} - Clasa ${widget.grade}"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? const Center(child: Text("Nu există categorii pentru această clasă."))
          : ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseListScreen(
                      subject: widget.subject,
                      //exercises: classData[category], // lista exactă din JSON
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
