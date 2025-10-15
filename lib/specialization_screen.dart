import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Pentru BackdropFilter

// ⚠️ Asigură-te că toate aceste ecrane există și sunt în calea corectă:
import 'user_dashboard.dart';
import 'login_screen.dart';
import 'teachers_dashboard.dart';
import 'teacher_list_screen.dart';
import 'teacher_profile_screen.dart';
import 'user_profile_screen.dart';
import 'home_screen.dart';
import 'exercises_screen.dart';

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({super.key});

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  final List<Map<String, dynamic>> specializations = [
    {'name': 'Matematică', 'teachers': []},
    {'name': 'Fizică', 'teachers': []},
    {'name': 'Chimie', 'teachers': []},
    {'name': 'Informatică', 'teachers': []},
    {'name': 'Limba Română', 'teachers': []},
    {'name': 'Engleză', 'teachers': []},
    {'name': 'Franceză', 'teachers': []},
    {'name': 'Istorie', 'teachers': []},
    {'name': 'Geografie', 'teachers': []},
  ];

  String searchQuery = '';
  bool _loadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final snapshot = await FirebaseFirestore.instance.collection('teachers')
        .where('active', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final subject = data['subject'] ?? '';
      if (subject.isNotEmpty) {
        final index = specializations.indexWhere((s) => s['name'] == subject);
        if (index != -1) {
          specializations[index]['teachers'].add({
            'uid': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'image': data['image'] ?? '',
            'experience': data['experience'] ?? 0,
            'contact': data['contact'] ?? '',
          });
        }
      }
    }

    setState(() {
      _loadingTeachers = false;
    });
  }

  // --------------------------------------------------------------------------
  // 🔨 WIDGETS NECESARE PENTRU NAVBAR
  // --------------------------------------------------------------------------

  // 1. Buton de Navigare Text
  Widget _navText(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937)),
        ),
      ),
    );
  }

  // 2. Buton de Sign In (Login)
  Widget _signInBtn(BuildContext ctx) => TextButton(
    onPressed: () => Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    ),
    child: Text('Login', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
  );

  // 3. Acțiunile Utilizatorului Logat
  Widget _actionRow({required bool isTeacher, required String userId}) {
    final String dashboardText = isTeacher ? 'Dashboard' : 'Contul Meu';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dashboard
        TextButton(
          onPressed: () {
            if (isTeacher) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TeachersDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserDashboard()),
              );
            }
          },
          child: Text(
            dashboardText,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 16),
          ),
        ),

        // Profil
        IconButton(
          icon: const Icon(Icons.person, color: Colors.blueAccent),
          tooltip: 'Profilul meu',
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            if (isTeacher) {
              final teacherDoc = FirebaseFirestore.instance.collection('teachers').doc(user.uid);
              final docSnapshot = await teacherDoc.get();

              if (!docSnapshot.exists) {
                final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                final data = userData.data() ?? {};
                await teacherDoc.set({
                  'name': data['name'] ?? '',
                  'email': user.email ?? '',
                  'subject': data['subject'] ?? '',
                  'contact': data['contact'] ?? '',
                  'experience': 0,
                  'image': data['image'] ?? '',
                  'hasAccount': true,
                  'active': true,
                });
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherProfileScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            }
          },
        ),

        // Logout
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            }
          },
          child: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.blueAccent, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // 4. Glassmorphism Navbar
  Widget _glassNavBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 800;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: Colors.white.withOpacity(0.65),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ----------------------------------------------------
                // STÂNGA: Logo și Link-uri (Logică de Comutare)
                // ----------------------------------------------------
                Row(
                  children: [
                    // Logo Gradient și Text (ÎNCAPSULAT ÎN GESTUREDETECTOR)
                    GestureDetector( // 🎯 NOU: Adăugat GestureDetector
                      onTap: () {
                        // 🚀 MODIFICARE: Navigare la HomeScreen (fără const)
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                            ),
                            child: const Icon(Icons.school, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text('iMeditatii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                        ],
                      ),
                    ),

                    if (isWide) const SizedBox(width: 30),

                    // Logica de comutare a link-urilor (Vizitator vs. Logat)
                    if (isWide)
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, snap) {
                          final user = snap.data;

                          // Logat (Afișează Profesori & Exerciții)
                          if (user != null) {
                            return Row(
                              children: [
                                _navText('Profesori', () {
                                  // Rămâne pe SpecializationScreen (folosim replace ca să nu se adune paginile)
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SpecializationScreen()));
                                }),
                                _navText('Exerciții', () {
                                  // 🚀 MODIFICARE: Folosim PUSH, nu PUSHREPLACEMENT, pentru a putea folosi POP pe ExercisesScreen
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisesScreen()));
                                }),
                              ],
                            );
                          }

                          // Neautentificat (Afișează link-urile de marketing)
                          return Row(
                            children: [
                              _navText('Proiecte', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()))),
                              _navText('Profesori', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SpecializationScreen()))),
                              _navText('De ce iMeditatii', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()))),
                              _navText('Prețuri', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()))),
                            ],
                          );
                        },
                      ),
                  ],
                ),

                // ----------------------------------------------------
                // DREAPTA: LOGICĂ DE AUTENTIFICARE DINAMICĂ
                // ----------------------------------------------------
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 80,
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)))),
                      );
                    }

                    final user = snap.data;

                    // CAZ 1: Utilizatorul NU este autentificat (Afișăm Login + Contact)
                    if (user == null) {
                      return Row(
                        children: [
                          _signInBtn(context),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: const Text('Contact'),
                          ),
                        ],
                      );
                    }

                    // CAZ 2: Utilizatorul ESTE autentificat (Afișăm acțiunile dinamice)
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get(),
                      builder: (context, userDoc) {
                        if (userDoc.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 80,
                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)))),
                          );
                        }
                        String? role;
                        if (userDoc.hasData && userDoc.data!.exists) {
                          role = (userDoc.data!.data() as Map<String, dynamic>)['role'] as String?;
                        }
                        return _actionRow(
                          isTeacher: role == 'teacher',
                          userId: user.uid,
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🎯 BUILD METHOD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = searchQuery.isEmpty
        ? specializations
        : specializations
        .where((s) => s['name']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Conținutul principal (Lista de Specializări)
          SafeArea(
            child: Padding(
              // ⚠️ MODIFICARE: Am ajustat padding-ul pentru a evita eroarea EdgeInsets.only
              padding: const EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 16),
              child: _loadingTeachers
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  // Păstrat: TextField pentru căutare
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintText: 'Caută profesor...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Păstrat: Lista de specializări
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final spec = filtered[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 400),
                                pageBuilder: (_, __, ___) =>
                                    TeacherListScreen(specialization: spec),
                                transitionsBuilder: (_, animation, __, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  spreadRadius: 1,
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
                                  child: const Icon(
                                    Icons.school,
                                    color: Colors.blueAccent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spec['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (spec['teachers'].isNotEmpty)
                                        Text(
                                          '${spec['teachers'].length} profesori disponibili',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navbar-ul suprapus (Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _glassNavBar(context),
          ),
        ],
      ),
    );
  }
}