import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import 'teacher_detail_screen.dart';
import 'paid_message_screen.dart';

class TeacherListScreen extends StatelessWidget {
  final Map<String, dynamic> specialization;

  const TeacherListScreen({required this.specialization, Key? key}) : super(key: key);

  /// Gestionează click pe Message
  Future<void> _handleMessageTap(BuildContext context, String teacherId, String teacherName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages.')),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    // Caută chat-ul existent între utilizator și profesor
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: currentUserId) // presupunem că utilizatorul e student
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
        'studentName': currentUser.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'isEnded': false,
      });

      chatId = newChat.id;
    }

    // Navighează direct în ChatScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          teacherName: teacherName,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final specName = specialization['name'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          specName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teachers')
            .where('subject', isEqualTo: specName) // 🔹 folosește câmpul 'subject'
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
                'No teachers found in this specialization.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data()! as Map<String, dynamic>;
              final teacherId = docs[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherDetailScreen(teacherId: teacherId),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: data['image'] != null && data['image'] != ''
                            ? NetworkImage(data['image'])
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: (data['image'] == null || data['image'] == '')
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (data['education'] != null)
                              Text(
                                data['education'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Experience: ${data['experience'] ?? 'N/A'} years',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                        ),
                        icon: const Icon(Icons.message),
                        label: const Text('Message'),
                        onPressed: () {
                          _handleMessageTap(context, teacherId, data['name'] ?? 'Teacher');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
