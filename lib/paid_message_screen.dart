import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:go_router/go_router.dart'; // 🚀 Import obligatoriu pentru navigare

class PaidMessageScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const PaidMessageScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<PaidMessageScreen> createState() => _PaidMessageScreenState();
}

class _PaidMessageScreenState extends State<PaidMessageScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  int? _initialPrice;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    // Generăm un preț inițial random pentru mesajul plătit
    _initialPrice = 20 + Random().nextInt(30); // ex: 20-50 RON
  }

  Future<void> _sendPaidMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _msgCtrl.text.trim().isEmpty) return;

    setState(() => _isPaying = true);

    // Simulare plată
    await Future.delayed(const Duration(seconds: 2));

    final chatRef = FirebaseFirestore.instance.collection('chats').doc();

    await chatRef.set({
      'userId': user.uid,
      'teacherId': widget.teacherId,
      'lastMessage': _msgCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isInitialPaid': true,
      'pricePerMessage': _initialPrice,
      'messagesCount': 1,
    });

    await chatRef.collection('messages').doc().set({
      'senderId': user.uid,
      'text': _msgCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isPaid': true,
      'price': _initialPrice,
    });

    if (!mounted) return;

    // 🚀 Am înlocuit Navigator.pushReplacement cu GoRouter
    // Folosim pushReplacement ca userul să nu se poată întoarce la ecranul de plată cu butonul de Back
    context.pushReplacement(
      '/chat/${chatRef.id}',
      extra: widget.teacherName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Trimite mesaj către ${widget.teacherName}',
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Preț inițial: $_initialPrice RON',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _msgCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Scrie mesajul tău către profesor...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isPaying ? null : _sendPaidMessage,
              icon: const Icon(Icons.payment, size: 22),
              label: Text(
                _isPaying ? 'Se procesează plata...' : 'Plătește și trimite',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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