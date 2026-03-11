import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 🚀 Importul necesar pentru GoRouter

class ClassSelectionScreen extends StatelessWidget {
  final String subject;
  const ClassSelectionScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final List<int> clase = [5, 6, 7, 8, 9, 10, 11, 12];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () {
            // 🚀 Înlocuit Navigator.pop(context)
            context.pop();
          },
        ),
        title: Text(
          subject,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: clase.length,
        itemBuilder: (context, i) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('Clasa a ${clase[i]}-a', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 🚀 Înlocuit Navigator.push
                // Navigăm folosind URL-ul logic creat în main.dart
                context.go('/exercitii/$subject/${clase[i]}');
              },
            ),
          );
        },
      ),
    );
  }
}