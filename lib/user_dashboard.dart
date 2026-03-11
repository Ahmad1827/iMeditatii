import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'custom_navbar.dart'; // 🚀 Import obligatoriu pentru rutare

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  // Helper pentru inițiale
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
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/materii'); // 🚀 Fallback dacă nu e user logat
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String userId = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800), // Lățime perfectă pe Desktop
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER BANNER ---
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                          final userName = data['name'] ?? 'Elev';
                          return _buildHeaderSection(userName, userId);
                        },
                      ),

                      const SizedBox(height: 40),

                      // --- TITLU SECȚIUNE ---
                      const Row(
                        children: [
                          Icon(Icons.forum_rounded, color: Color(0xFF10B981), size: 28), // Emerald Green pt elevi
                          SizedBox(width: 12),
                          Text(
                            "Mesaje de la profesori",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- LISTA DE CHAT-URI ---
                      _buildChatList(userId),
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
  Widget _buildHeaderSection(String userName, String userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Emerald Green (diferit de albastrul profesorului)
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
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
                child: const Text("PANOU ELEV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
              ),
              const SizedBox(height: 16),
              Text(
                "Salut, ${userName.split(' ')[0]}!",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Text(
                "Aici vei găsi toate discuțiile cu profesorii tăi.",
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => context.go('/elev/$userId'), // 🚀 Navigăm Profil Elev
            icon: const Icon(Icons.person),
            label: const Text("Profilul Meu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10B981),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('studentId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: List.generate(3, (index) => _chatCardSkeleton()));
        }
        if (snapshot.hasError) return Center(child: Text('Eroare: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

        final chats = snapshot.data!.docs;

        return Column(
          children: chats.map((chatDoc) {
            final data = chatDoc.data()! as Map<String, dynamic>;
            final chatId = chatDoc.id;
            final teacherId = data['teacherId'] ?? '';
            final lastMsg = data['lastMessage'] ?? '...';
            final timestamp = data['updatedAt'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('teachers').doc(teacherId).get(),
              builder: (context, teacherSnap) {
                if (teacherSnap.connectionState == ConnectionState.waiting) return _chatCardSkeleton();
                if (!teacherSnap.hasData || !teacherSnap.data!.exists) return const SizedBox.shrink();

                final teacherData = teacherSnap.data!.data() as Map<String, dynamic>;
                final teacherName = teacherData['name'] ?? 'Profesor Necunoscut';
                final teacherAvatar = teacherData['image'] as String? ?? '';

                return _chatCard(
                  name: teacherName,
                  avatarUrl: teacherAvatar,
                  lastMessage: lastMsg,
                  timestamp: timestamp,
                  // 🚀 Navigare către chat cu profesorul
                  onTap: () => context.go('/chat/$chatId', extra: teacherName),
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                  ),
                  child: avatarUrl.isEmpty ? Center(child: Text(_getInitials(name), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 18))) : null,
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
          Icon(Icons.mark_chat_unread_rounded, size: 64, color: Colors.green.shade100),
          const SizedBox(height: 24),
          const Text("Inboxul tău este gol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("Mergi la 'Profesori' pentru a începe o discuție.", style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/materii'), // 🚀 Navigăm Caută Profesori
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Caută Profesori", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}