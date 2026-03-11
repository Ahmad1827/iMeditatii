import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart'; // 🚀 Import obligatoriu pentru navigare

class ReviewScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String chatId;

  const ReviewScreen({
    required this.teacherId,
    required this.teacherName,
    required this.chatId,
    Key? key,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 3;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trebuie să fii logat pentru a lăsa un review.')),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eroare: utilizatorul nu a fost găsit.')),
      );
      return;
    }

    final userName = userDoc.data()?['name'] ?? 'Anonim';

    final reviewData = {
      'userId': user.uid,
      'userName': userName,
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'createdAt': Timestamp.now(),
      'chatId': widget.chatId,
    };

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherId)
          .collection('reviews')
          .add(reviewData);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'reviewed': true});

      if (mounted) {
        // 🚀 Am înlocuit Navigator.pop cu GoRouter
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recenzia a fost trimisă cu succes!')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la trimitere: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Review ${widget.teacherName}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cum ai evalua experiența ta?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Slider(
              value: _rating,
              onChanged: (val) => setState(() => _rating = val),
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.toStringAsFixed(1),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.blueAccent.withOpacity(0.3),
            ),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Lasă un comentariu (opțional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: const Icon(Icons.check, size: 22),
              label: Text(
                _isSubmitting ? 'Se trimite...' : 'Trimite Recenzia',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}