import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart'; // 🚀 Importul necesar pentru navigare

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
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? const Center(child: Text("Nu există categorii pentru această clasă."))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent),
              onTap: () {
                // 🚀 SCHIMBAREA AICI: Navigăm folosind GoRouter.
                // Trimitem numele categoriei prin parametrul 'extra' în caz că ecranul următor are nevoie de ea.
                context.go(
                  '/exercitii/${widget.subject}/${widget.grade}',
                  extra: category,
                );
              },
            ),
          );
        },
      ),
    );
  }
}