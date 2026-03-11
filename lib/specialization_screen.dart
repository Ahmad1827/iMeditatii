import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'custom_navbar.dart';

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({super.key});

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  // Date îmbogățite pentru un aspect vizual premium
  final List<Map<String, dynamic>> specializations = [
    {'name': 'Matematică', 'icon': Icons.functions_rounded, 'color': const Color(0xFF3B82F6), 'desc': 'Algebră, Geometrie, Analiză și Bacalaureat.'},
    {'name': 'Fizică', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFF59E0B), 'desc': 'Mecanică, Termodinamică, Electricitate și Optică.'},
    {'name': 'Chimie', 'icon': Icons.science_rounded, 'color': const Color(0xFF10B981), 'desc': 'Chimie Organică, Anorganică și admitere Medicină.'},
    {'name': 'Informatică', 'icon': Icons.data_object_rounded, 'color': const Color(0xFF8B5CF6), 'desc': 'Algoritmi, C++, Python și pregătire olimpiade.'},
    {'name': 'Limba Română', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFFEF4444), 'desc': 'Eseuri, Gramatică, pregătire Evaluare și BAC.'},
    {'name': 'Engleză', 'icon': Icons.language_rounded, 'color': const Color(0xFF4F46E5), 'desc': 'Gramatică, Vocabular, Conversație și Cambridge.'},
    {'name': 'Franceză', 'icon': Icons.tour_rounded, 'color': const Color(0xFF06B6D4), 'desc': 'Nivel A1-C1, atestate DELF și conversație.'},
    {'name': 'Istorie', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFFD97706), 'desc': 'Istoria Românilor, Istorie Universală și BAC.'},
    {'name': 'Geografie', 'icon': Icons.public_rounded, 'color': const Color(0xFF84CC16), 'desc': 'Geografia Europei, României și cartografie.'},
  ];

  String searchQuery = '';
  bool _loadingTeachers = true;
  Map<String, int> teacherCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  // Optimizare: Încărcăm doar numărul de profesori, nu toate datele lor
  Future<void> _loadTeacherData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('teachers')
          .where('active', isEqualTo: true)
          .get();

      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final subject = doc.data()['subject'] ?? '';
        counts[subject] = (counts[subject] ?? 0) + 1;
      }

      setState(() {
        teacherCounts = counts;
        _loadingTeachers = false;
      });
    } catch (e) {
      debugPrint("Eroare: $e");
      if (mounted) setState(() => _loadingTeachers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = specializations.where((s) =>
        s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fundal neutru, modern
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeaderAndSearch(),
                  ),
                ),
                if (_loadingTeachers)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    sliver: _buildBentoGrid(filtered),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // NAVBAR (Standard și Curat)
  // --------------------------------------------------------------------------
  Widget _buildNavbar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'), // 🚀 Navigare către HomeScreen
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('iMeditatii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                ],
              ),
            ),
          ),
          // Linkuri & Auth
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text("Profesori", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15))),
              const SizedBox(width: 8),
              TextButton(onPressed: () => context.go('/exercitii'), // 🚀 Navigare către ExercisesScreen
                  child: const Text("Exerciții", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15))),
              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              _buildAuthActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthActions() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
        }

        final user = snapshot.data;

        // Când NU este logat
        if (user == null) {
          return ElevatedButton(
            onPressed: () => context.go('/login'), // 🚀 Navigare către LoginScreen
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
            ),
            child: const Text("Intră în cont", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        }

        // Când ESTE logat (Dashboard + Profil + LOGOUT)
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. BUTON DASHBOARD
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/panou-profesor'); // 🚀 Navigare TeachersDashboard
                    } else {
                      context.go('/panou-elev'); // 🚀 Navigare UserDashboard
                    }
                  }
                } catch (e) {
                  debugPrint("Eroare dashboard: $e");
                }
              },
              icon: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF0F172A), size: 28),
              tooltip: "Panou de control",
            ),

            const SizedBox(width: 4),

            // 2. BUTON PROFIL
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/profesor/${user.uid}'); // 🚀 Navigare TeacherProfile
                    } else {
                      context.go('/elev/${user.uid}'); // 🚀 Navigare UserProfile
                    }
                  }
                } catch (e) {
                  debugPrint("Eroare profil: $e");
                }
              },
              icon: const Icon(Icons.account_circle, color: Color(0xFF3B82F6), size: 30),
              tooltip: "Contul meu",
            ),

            const SizedBox(width: 4),

            // 3. BUTON LOGOUT
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    context.go('/'); // 🚀 Navigare Home după deconectare
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                tooltip: "Deconectare",
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // HEADER & SEARCH BAR
  // --------------------------------------------------------------------------
  Widget _buildHeaderAndSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Găsește materia dorită", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
        const SizedBox(height: 8),
        Text("Peste 100 de profesori te așteaptă să începeți pregătirea.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        Container(
          width: 500, // Lățime maximă pentru search bar ca să nu arate imens pe desktop
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: InputDecoration(
              hintText: "Ex: Matematică, Fizică, Informatică...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // GRID ADAPTIV (Aici se controlează dimensiunea cardurilor)
  // --------------------------------------------------------------------------
  Widget _buildBentoGrid(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text("Nu am găsit nicio materie.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16))),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.15, // Controlează raportul lățime/înălțime
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final spec = data[index];
          final count = teacherCounts[spec['name']] ?? 0;
          return AnimatedBentoCard(
            data: spec,
            count: count,
            onTap: () {
              // 🚀 Navigăm către lista de profesori din materia selectată
              context.go(
                '/materii/${spec['name']}',
                extra: spec, // Trimitem restul datelor (icon, descriere) ca `extra`
              );
            },
          );
        },
        childCount: data.length,
      ),
    );
  }
}

// --------------------------------------------------------------------------
// CARDUL ANIMAT (MODERN BENTO STYLE)
// --------------------------------------------------------------------------
class AnimatedBentoCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int count;
  final VoidCallback onTap;

  const AnimatedBentoCard({super.key, required this.data, required this.count, required this.onTap});

  @override
  State<AnimatedBentoCard> createState() => _AnimatedBentoCardState();
}

class _AnimatedBentoCardState extends State<AnimatedBentoCard> with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.data['color'];

    return MouseRegion(
      onEnter: (_) {
        setState(() => isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovered ? primaryColor.withOpacity(0.5) : Colors.grey.shade200,
                width: isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered ? primaryColor.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                  blurRadius: isHovered ? 20 : 10,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rândul de sus: Iconiță + Badge număr profesori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.data['icon'], color: primaryColor, size: 28),
                    ),
                    if (widget.count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text("${widget.count} Profi", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // Rândul de jos: Titlu, descriere și săgeată animată
                Text(widget.data['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.data['desc'],
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Săgeata care apare și glisează ușor spre dreapta la Hover
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isHovered ? 1 : 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.translationValues(isHovered ? 0 : -10, 0, 0),
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}