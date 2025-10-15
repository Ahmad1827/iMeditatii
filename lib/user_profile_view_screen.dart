import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends StatelessWidget {
  final String userId;

  const UserProfileViewScreen({super.key, required this.userId});

  // 🔹 Preia datele utilizatorului din Firestore
  Future<Map<String, dynamic>?> _getUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  // 🔹 Creează sau redeschide un chat între utilizatorul curent și userId
  Future<String> _openOrCreateChat(BuildContext context, String otherUserId, String otherName) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUid = currentUser.uid;
    final firestore = FirebaseFirestore.instance;

    // 🔹 Citește rolurile ambilor utilizatori
    final currentUserDoc = await firestore.collection('users').doc(currentUid).get();
    final otherUserDoc = await firestore.collection('users').doc(otherUserId).get();

    final currentRole = currentUserDoc.data()?['role'] ?? 'student';
    final otherRole = otherUserDoc.data()?['role'] ?? 'teacher';

    // 🔹 Stabilim cine e profesorul și cine e elevul
    String teacherId, teacherName, studentId, studentName;

    if (currentRole == 'teacher') {
      teacherId = currentUid;
      teacherName = currentUserDoc.data()?['name'] ?? '';
      studentId = otherUserId;
      studentName = otherUserDoc.data()?['name'] ?? otherName;
    } else {
      teacherId = otherUserId;
      teacherName = otherUserDoc.data()?['name'] ?? otherName;
      studentId = currentUid;
      studentName = currentUserDoc.data()?['name'] ?? '';
    }

    // 🔹 Caută un chat existent între acești doi
    final existingChats = await firestore
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    // 🔹 Creează un chat nou
    final newChat = await firestore.collection('chats').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': studentId,
      'studentName': studentName,
      'isEnded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Profil utilizator",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Profilul nu a fost găsit."));
          }

          final data = snapshot.data!;
          final image = data['image'];
          final name = data['name'] ?? 'Nume necunoscut';
          final bio = data['bio'] ?? 'Fără descriere';
          final contact = data['contact'] ?? 'Nespecificat';
          final email = data['email'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // imaginea de profil
                CircleAvatar(
                  radius: 60,
                  backgroundImage: image != null ? NetworkImage(image) : null,
                  backgroundColor: Colors.grey[300],
                  child: image == null ? const Icon(Icons.person, size: 60) : null,
                ),
                const SizedBox(height: 16),

                // numele
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // bio-ul
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(height: 24),

                // email & telefon
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(email),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(contact),
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Buton: deschide / creează chat
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Deschide conversație"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final chatId = await _openOrCreateChat(context, userId, name);
                    // Navighează direct în chat
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId,
                          teacherName: name,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
