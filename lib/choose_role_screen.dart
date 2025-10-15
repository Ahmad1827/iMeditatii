import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iMeditatii/teachers_dashboard.dart';

import 'teachers_dashboard.dart';
import 'specialization_screen.dart';

class ChooseRoleScreen extends StatelessWidget {
  final String uid;
  final String email;     // we’ll save this too

  const ChooseRoleScreen({required this.uid, required this.email, super.key});

  Future<void> _setRole(BuildContext context, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'role': role,
    });

    if (role == 'lawyer') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeachersDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SpecializationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Are you a Lawyer or a Client?', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _setRole(context, 'lawyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("I'm a Lawyer"),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: () => _setRole(context, 'user'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.blueAccent),
                ),
                child: const Text("I'm a Client", style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
