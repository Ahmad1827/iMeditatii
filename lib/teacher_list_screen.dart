import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart'; // 🚀 Importul necesar pentru navigare
import 'custom_navbar.dart';

// ==========================================
// WIDGET MAGIC PENTRU EFECT DE HOVER
// ==========================================
class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: isHovered ? (Matrix4.identity()..translate(0.0, -6.0, 0.0)) : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
// ==========================================

class TeacherListScreen extends StatefulWidget {
  final Map<String, dynamic> specialization;

  const TeacherListScreen({required this.specialization, Key? key}) : super(key: key);

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {

  /// Gestionează click-ul pe Mesaj
  Future<void> _handleMessageTap(BuildContext context, String teacherId, String teacherName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trebuie să fii conectat pentru a trimite mesaje.')),
      );
      return;
    }

    // Împiedicăm profesorul să își dea mesaj singur
    if (currentUser.uid == teacherId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acesta este profilul tău!')),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    // Caută chat-ul existent între utilizator și profesor
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    String chatId;

    if (chatQuery.docs.isNotEmpty) {
      chatId = chatQuery.docs.first.id;
    } else {
      // Dacă nu există chat, crează unul nou
      final newChat = await FirebaseFirestore.instance.collection('chats').add({
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentId': currentUser.uid,
        'studentName': currentUser.displayName ?? 'Elev',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'isEnded': false,
        'isSessionPaid': false,
        'isStudentAccepted': false, // Logica nouă de acceptare
      });
      chatId = newChat.id;
    }

    if (mounted) {
      // 🚀 Navigăm către Chat cu GoRouter
      context.go('/chat/$chatId', extra: teacherName);
    }
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
              onTap: () => context.go('/'), // 🚀 Navigăm Home
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
                  onPressed: () => context.go('/materii'), // 🚀 Navigăm Profesori
                  child: const Text("Profesori", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15)) // Activ
              ),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: () => context.go('/exercitii'), // 🚀 Navigăm Exerciții
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
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
        final user = snapshot.data;

        if (user == null) {
          return ElevatedButton(
            onPressed: () => context.go('/login'), // 🚀 Navigăm Login
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
            child: const Text("Intră în cont", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/panou-profesor'); // 🚀 Navigăm Dashboard
                    } else {
                      context.go('/panou-elev');
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
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/profesor/${user.uid}'); // 🚀 Navigăm Profil
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
            Container(
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) context.go('/'); // 🚀 Deconectare
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
  // HEADER SECȚIUNE
  // --------------------------------------------------------------------------
  Widget _buildHeader(String specName, Color themeColor, IconData themeIcon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(themeIcon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Profesori disponibili", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(specName, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.pop(), // 🚀 Înapoi (GoRouter)
                icon: const Icon(Icons.close_rounded, size: 28),
                tooltip: "Înapoi",
              )
            ],
          ),
          const SizedBox(height: 16),
          Text("Alege profesorul potrivit și trimite-i un mesaj pentru a programa prima ședință.", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final specName = widget.specialization['name'] ?? 'Materie';
    final themeColor = widget.specialization['color'] as Color? ?? const Color(0xFF3B82F6);
    final themeIcon = widget.specialization['icon'] as IconData? ?? Icons.school_rounded;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildNavbar(), // Aici folosim navbar-ul generat mai sus
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000), // Perfect pe Desktop
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(specName, themeColor, themeIcon),
                      const SizedBox(height: 32),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('teachers')
                            .where('subject', isEqualTo: specName)
                            .where('active', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                          if (snapshot.hasError) return Center(child: Text('Eroare: ${snapshot.error}'));

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text("Niciun profesor disponibil momentan.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 8),
                                  Text("Încă nu avem profesori aprobați pentru această materie.", style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          // Grid Responsiv
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 450, // 🚀 Ajustat puțin pentru a încăpea perfect prețul
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data()! as Map<String, dynamic>;
                              final teacherId = docs[index].id;

                              // 🚀 Preluăm prețul din baza de date, setăm 50 RON default dacă nu a setat nimic
                              final price = data['price']?.toString() ?? '50';

                              return HoverCard(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Partea de sus a cardului
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 36,
                                                backgroundColor: themeColor.withOpacity(0.1),
                                                backgroundImage: data['image'] != null && data['image'] != '' ? NetworkImage(data['image']) : null,
                                                child: (data['image'] == null || data['image'] == '') ? Icon(Icons.person, size: 36, color: themeColor) : null,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(data['name'] ?? 'Fără Nume', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.military_tech_rounded, size: 16, color: Colors.grey.shade500),
                                                        const SizedBox(width: 4),
                                                        Text('${data['experience'] ?? '0'} ani experiență', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (data['education'] != null)
                                                      Row(
                                                        children: [
                                                          Icon(Icons.school_rounded, size: 16, color: Colors.grey.shade500),
                                                          const SizedBox(width: 4),
                                                          Expanded(child: Text(data['education'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              // 🚀 AICI AM ADĂUGAT PREȚUL ÎN COLȚUL DREAPTA-SUS
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text('$price RON', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                                                  Text('/ oră', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      Divider(height: 1, color: Colors.grey.shade100),

                                      // Butoanele de jos
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () => context.go('/profesor/$teacherId'), // 🚀 Navigăm Profil
                                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                                child: const Text("Vezi Profil", style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _handleMessageTap(context, teacherId, data['name'] ?? 'Profesor'),
                                                icon: const Icon(Icons.send_rounded, size: 16),
                                                label: const Text("Mesaj"),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: themeColor,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
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
}