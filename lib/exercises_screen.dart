import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'custom_navbar.dart';
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



  Widget _heroSection() {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      padding: EdgeInsets.all(isWide ? 60 : 30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage("https://i.imgur.com/Wvoh2pk.png"),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ZONĂ DE STUDIU', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Exersează inteligent.\nDevino mai bun zilnic.",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Alege materia la care vrei să excelezi. Platforma îți salvează progresul și îți evaluează răspunsurile în timp real.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // 🚀 FOLOSIM GO PENTRU WEB (Actualizare URL garantată)
                    final encodedSubj = Uri.encodeComponent("Matematică");
                    context.go('/lista-exercitii?materie=$encodedSubj');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Începe cu Matematica", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 60),
            Expanded(
              flex: 2,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.rocket_launch, size: 120, color: Colors.blueAccent),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CATEGORII", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _materiiSection() {
    final List<Map<String, dynamic>> materii = [
      {"icon": Icons.functions_rounded, "title": "Matematică", "color": "0xFF10B981"},
      {"icon": Icons.menu_book_rounded, "title": "Limba Română", "color": "0xFF3B82F6"},
      {"icon": Icons.language_rounded, "title": "Engleză", "color": "0xFFF59E0B"},
      {"icon": Icons.data_object_rounded, "title": "Informatică", "color": "0xFF8B5CF6"},
      {"icon": Icons.bolt_rounded, "title": "Fizică", "color": "0xFFEF4444"},
      {"icon": Icons.science_rounded, "title": "Chimie", "color": "0xFF14B8A6"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: materii.map((m) {
          final cardColor = Color(int.parse(m["color"]!));
          return _MaterieCard(
            title: m["title"] as String,
            icon: m["icon"] as IconData,
            color: cardColor,
            onTap: () {
              // 🚀 FOLOSIM GO PENTRU WEB (Actualizare URL garantată)
              final encodedSubj = Uri.encodeComponent(m["title"] as String);
              context.go('/lista-exercitii?materie=$encodedSubj');
            },
          );
        }).toList(),
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
            const CustomNavbar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _pageScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroSection(),
                    _sectionTitle("Alege materia"),
                    _materiiSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterieCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MaterieCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MaterieCard> createState() => _MaterieCardState();
}

class _MaterieCardState extends State<_MaterieCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovering ? widget.color.withOpacity(0.5) : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: _hovering
                ? [
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          transform: _hovering ? (Matrix4.identity()..translate(0.0, -8.0)) : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, size: 32, color: widget.color),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text("Exersează acum", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.color)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: widget.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}