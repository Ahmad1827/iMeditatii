import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import 'specialization_screen.dart';
import 'user_profile_screen.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SpecializationScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final String userId = user.uid;

    return WillPopScope(
      onWillPop: () async {
        _goHome(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Conversațiile mele',
            style: TextStyle(color: Colors.blueAccent),
          ),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
            onPressed: () => _goHome(context),
          ),
          elevation: 4,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.blueAccent),
              tooltip: "Profilul meu",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              ),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('studentId', isEqualTo: userId)
              .orderBy('updatedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Eroare: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nu ai conversații încă.'));
            }

            final chats = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chatDoc = chats[index];
                final data = chatDoc.data() as Map<String, dynamic>;
                final chatId = chatDoc.id;
                final teacherId = data['teacherId'] ?? '';
                final lastMsg = data['lastMessage'] ?? '';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('teachers')
                      .doc(teacherId)
                      .get(),
                  builder: (context, teacherSnap) {
                    if (!teacherSnap.hasData) {
                      return const ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Se încarcă profesor...'),
                      );
                    }

                    final teacher =
                        teacherSnap.data!.data() as Map<String, dynamic>? ?? {};
                    final teacherName = teacher['name'] ?? 'Profesor';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: const Icon(Icons.chat_bubble,
                              color: Colors.blueAccent),
                        ),
                        title: Text(
                          teacherName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.blueAccent),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatId,
                                teacherName: teacherName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _goHome(BuildContext ctx) => Navigator.pushAndRemoveUntil(
    ctx,
    MaterialPageRoute(builder: (_) => SpecializationScreen()),
        (route) => false,
  );
}
