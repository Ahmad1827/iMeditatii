import 'package:flutter/material.dart';
import 'home_screen.dart';
// Asigură-te că aceste importuri sunt valabile:
import 'class_selection_screen.dart';
import 'exercise_list_screen.dart';
import 'specialization_screen.dart'; // Import necesar dacă ne întoarcem aici

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // 🔨 WIDGETS AJUTĂTOARE
  // --------------------------------------------------------------------------

  // Header-ul simplificat, înlocuind AppBar-ul
  Widget _simpleHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 10, right: 20),
      child: Row(
        children: [
          // Butonul Săgeată Înapoi
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
            onPressed: () {
              // Logica de navigare corectă (pop cu fallback la SpecializationScreen)
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SpecializationScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          // Titlul Secțiunii
          const Text(
            "Exerciții",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Secțiune cu exerciții pentru fiecare materie (MODIFICATĂ COMPLET)
  Widget _materiiSection() {
    final List<Map<String, String>> materii = [
      {
        "icon": "3135715.png", // Am schimbat în nume de fișier pentru simplitate vizuală
        "title": "Matematică",
        "color": "0xFF4CAF50" // Green
      },
      {
        "icon": "3075977.png",
        "title": "Limba Română",
        "color": "0xFF2196F3" // Blue
      },
      {
        "icon": "2942924.png",
        "title": "Engleză",
        "color": "0xFFFFC107" // Amber
      },
      {
        "icon": "616408.png",
        "title": "Informatică",
        "color": "0xFF9C27B0" // Purple
      },
      {
        "icon": "1828884.png",
        "title": "Fizică",
        "color": "0xFFFF5722" // Deep Orange
      },
      {
        "icon": "1239525.png",
        "title": "Chimie",
        "color": "0xFF795548" // Brown
      },
    ];

    // Calculăm înălțimea pentru a se potrivi noilor carduri (am redus-o)
    const double cardHeight = 180;

    return SizedBox(
      height: cardHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: materii.map((m) {
            final cardColor = Color(int.parse(m["color"]!));
            final imageUrl = "https://cdn-icons-png.flaticon.com/512/${m["icon"]}";

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseListScreen(subject: m["title"]!),
                  ),
                );
              },
              child: Container(
                width: 150, // Am redus lățimea pentru a încăpea mai multe
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardColor.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Iconiță (Încadrată într-un cerc colorat)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        imageUrl,
                        height: 40,
                        color: cardColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Titlu
                    Text(
                      m["title"]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Text Ajutător Subtil
                    Text(
                      "Exersează acum!",
                      style: TextStyle(
                        fontSize: 12,
                        color: cardColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 🔹 Titlu secțiune
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // 🚀 HERO SECTION CU DESIGN ACTUALIZAT
  Widget _heroSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(0.05), Colors.lightBlue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Iconiță mare
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          // Titlu
          const Text(
            'Exersează pentru a deveni mai bun!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Subtitlu
          Text(
            'Alege materia dorită și începe să rezolvi exerciții interactive.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  // --------------------------------------------------------------------------
  // 🎯 BUILD METHOD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Am setat un fundal ușor gri
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _pageScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER-UL SIMPLIFICAT
              _simpleHeader(),

              // HERO SECTION
              _heroSection(),

              // SECȚIUNE MATERII
              _sectionTitle("Exerciții disponibile"),
              _materiiSection(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}