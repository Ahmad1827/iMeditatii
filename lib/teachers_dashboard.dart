import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // 🚀 Import obligatoriu pentru GoRouter
import 'custom_navbar.dart';
class TeachersDashboard extends StatefulWidget {
  const TeachersDashboard({Key? key}) : super(key: key);

  @override
  State<TeachersDashboard> createState() => _TeachersDashboardState();
}

class _TeachersDashboardState extends State<TeachersDashboard> {
  // Helper pentru a extrage inițialele dintr-un nume
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }

  // --------------------------------------------------------------------------
  // NAVBAR UNIVERSAL
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'), // 🚀 Navigare către Home
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
          Row(
            children: [
              TextButton(
                  onPressed: () => context.go('/materii'), // 🚀 Navigare către Profesori
                  child: const Text("Profesori", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15))
              ),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: () => context.go('/exercitii'), // 🚀 Navigare către Exerciții
                  child: const Text("Exerciții", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15))
              ),
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
            onPressed: () => context.go('/login'), // 🚀 Navigare către Login
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
            // 1. BUTON DASHBOARD (Dezactivat vizual, deoarece deja suntem aici)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF3B82F6), size: 28), // Albastru ca să arate că e Activ
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
                      context.go('/profesor/${user.uid}'); // 🚀 Navigare către profilul propriu
                    } else {
                      context.go('/elev/${user.uid}');
                    }
                  }
                } catch (e) {
                  debugPrint("Eroare profil: $e");
                }
              },
              icon: const Icon(Icons.account_circle, color: Color(0xFF0F172A), size: 30),
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
                    context.go('/'); // 🚀 Navigare către Home după deconectare
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
  // BUILD PRINCIPAL
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final String teacherId = FirebaseAuth.instance.currentUser!.uid;
    final teacherFuture = FirebaseFirestore.instance.collection('teachers').doc(teacherId).get();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/adauga-exercitiu'), // 🚀 Navigare către AddExerciseScreen
        backgroundColor: const Color(0xFF0F172A),
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text("Exercițiu Nou", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800), // Lățime perfectă pentru desktop
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      FutureBuilder<DocumentSnapshot>(
                        future: teacherFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                          final teacherName = data['name'] ?? 'Profesor';
                          return _buildHeaderSection(teacherName, teacherId);
                        },
                      ),

                      const SizedBox(height: 40),

                      // --- TITLU SECȚIUNE ---
                      const Row(
                        children: [
                          Icon(Icons.forum_rounded, color: Color(0xFF3B82F6), size: 28),
                          SizedBox(width: 12),
                          Text(
                            "Mesaje de la elevi",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- LISTA CHATURI ---
                      _buildChatList(teacherId),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // COMPONENTE UI
  // --------------------------------------------------------------------------
  Widget _buildHeaderSection(String teacherName, String teacherId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Culoarea albastră principală a aplicației
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text("PANOU PROFESOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
              ),
              const SizedBox(height: 16),
              Text(
                "Salut, ${teacherName.split(' ')[0]}!",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Text(
                "Gestionează elevii și adaugă exerciții noi.",
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => context.go('/profesor/$teacherId'), // 🚀 Navigare către profilul propriu
            icon: const Icon(Icons.person),
            label: const Text("Profilul Meu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatList(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: List.generate(3, (index) => _chatCardSkeleton()));
        }
        if (snapshot.hasError) return Center(child: Text('Eroare la încărcare: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

        final chats = snapshot.data!.docs;

        return Column(
          children: chats.map((chatDoc) {
            final data = chatDoc.data()! as Map<String, dynamic>;
            final chatId = chatDoc.id;
            final studentId = data['studentId'] ?? '';
            if (studentId.isEmpty) return const SizedBox.shrink(); // Ignorăm doc eronate

            final lastMsg = data['lastMessage'] ?? '...';
            final timestamp = data['updatedAt'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return _chatCardSkeleton();
                if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();

                final userData = userSnap.data!.data() as Map<String, dynamic>;
                final userName = userData['name'] ?? 'Elev Necunoscut';
                final userAvatar = userData['image'] as String? ?? '';

                return _chatCard(
                  name: userName,
                  avatarUrl: userAvatar,
                  lastMessage: lastMsg,
                  timestamp: timestamp,
                  // 🚀 Navigare către Chat
                  onTap: () => context.go('/chat/$chatId', extra: userName),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _chatCard({required String name, required String avatarUrl, required String lastMessage, Timestamp? timestamp, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                  ),
                  child: avatarUrl.isEmpty ? Center(child: Text(_getInitials(name), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 18))) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(lastMessage, style: TextStyle(color: Colors.grey.shade600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (timestamp != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('HH:mm').format(timestamp.toDate()), style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200, width: 1, style: BorderStyle.solid)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_chat_unread_rounded, size: 64, color: Colors.blue.shade100),
          const SizedBox(height: 24),
          const Text("Inboxul tău este gol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("Când elevii te vor contacta, mesajele vor apărea aici.", style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}