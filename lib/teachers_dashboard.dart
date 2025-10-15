// teachers_dashboard.dart
// Versiune adaptată din lawyer_dashboard.dart pentru colecția "teachers"

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import 'specialization_screen.dart';
import 'teacher_profile_screen.dart'; // ← Trebuie să creezi ecranul de profil pentru profesori

class TeachersDashboard extends StatelessWidget {
  const TeachersDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String teacherId = FirebaseAuth.instance.currentUser!.uid;

    return WillPopScope(
      onWillPop: () async {
        _goHome(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Teachers Dashboard',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goHome(context),
          ),
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER cu "Profilul meu"
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherProfileScreen(),
                  ),
                ),
                icon: const Icon(Icons.person, size: 22),
                label: const Text(
                  'Profilul meu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            // TITLU LISTĂ
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Conversațiile mele',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // LISTA CHATURI
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('teacherId', isEqualTo: teacherId)
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nu ai conversații încă.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }

                  final chats = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final data = chats[index].data()! as Map<String, dynamic>;
                      final chatId = chats[index].id;

                      final studentId = data['studentId'] ?? '';
                      if (studentId.isEmpty) return _chatCardError('⚠️ studentId lipsă în chat');
                      final lastMsg = data['lastMessage'] ?? '';

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(studentId)
                            .get(),
                        builder: (context, userSnap) {
                          if (userSnap.connectionState ==
                              ConnectionState.waiting) {
                            return _chatCardSkeleton();
                          }

                          if (!userSnap.hasData || !userSnap.data!.exists) {
                            return _chatCardError('⚠️ Document user inexistent');
                          }

                          final rawData = userSnap.data!.data();
                          if (rawData == null) {
                            return _chatCardError('⚠️ Date user lipsă');
                          }

                          final userData = rawData as Map<String, dynamic>;
                          final userName = userData['name'] ?? '⚠️ Nume lipsă';

                          return _chatCard(
                            context: context,
                            name: userName,
                            lastMessage: lastMsg,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chatId,
                                    teacherName: userName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatCard({
    required BuildContext context,
    required String name,
    required String lastMessage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Colors.blueAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _chatCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _chatCardError(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }

  void _goHome(BuildContext ctx) => Navigator.pushAndRemoveUntil(
    ctx,
    MaterialPageRoute(builder: (_) => SpecializationScreen()),
        (route) => false,
  );
}
