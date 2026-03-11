import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; // 🚀 Importul necesar pentru GoRouter

class ChooseRoleScreen extends StatelessWidget {
  final String uid;
  final String email;

  const ChooseRoleScreen({required this.uid, required this.email, super.key});

  Future<void> _setRole(BuildContext context, String role) async {
    // Salvăm rolul în baza de date
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'role': role,
    });

    // 🚀 Rutare folosind GoRouter
    if (context.mounted) {
      if (role == 'teacher') {
        context.go('/panou-profesor');
      } else {
        context.go('/materii'); // Trimitem elevul direct la lista de materii
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alege Rolul')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ești Profesor sau Elev?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _setRole(context, 'teacher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Sunt Profesor", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: () => _setRole(context, 'student'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.blueAccent),
                ),
                child: const Text("Sunt Elev", style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}