import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllReviewsScreen extends StatelessWidget {
  final String teacherId;

  const AllReviewsScreen({Key? key, required this.teacherId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reviewsRef = FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacherId)
        .collection('reviews')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toate recenziile'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewsRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Nicio recenzie momentan.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final rating = data['rating'] ?? 0;
              final comment = data['comment'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    '★' * rating,
                    style: const TextStyle(color: Colors.amber),
                  ),
                  subtitle: Text(comment),
                ),
              );
            },
          );
        },
      ),
    );
  }
}