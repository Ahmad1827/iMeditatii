import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDetailScreen extends StatelessWidget {
  final String teacherId;

  const TeacherDetailScreen({required this.teacherId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('teachers').doc(teacherId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Teacher not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(data['image'] ?? ''),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  data['specialization'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const Divider(height: 32),

                _infoTile('Email', data['email']),
                _infoTile('Contact', data['contact']),
                _infoTile('Education', data['education']),
                _infoTile('Experience', '${data['experience']} years'),
                _infoTile('UID', teacherId),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Contact Teacher'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Phone: ${data['contact']}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String? value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? '-', style: const TextStyle(fontSize: 16)),
    );
  }
}
