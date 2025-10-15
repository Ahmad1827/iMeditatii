// edit_lawyer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditLawyerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditLawyerProfileScreen({super.key, required this.data});

  @override
  State<EditLawyerProfileScreen> createState() => _EditLawyerProfileScreenState();
}

class _EditLawyerProfileScreenState extends State<EditLawyerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController specializationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name']);
    specializationController = TextEditingController(text: widget.data['specialization']);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('lawyers').doc(uid).update({
      'name': nameController.text.trim(),
      'specialization': specializationController.text.trim(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editează profilul")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nume complet'),
                validator: (value) => value!.isEmpty ? 'Completează numele' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: specializationController,
                decoration: const InputDecoration(labelText: 'Specializare'),
                validator: (value) => value!.isEmpty ? 'Completează specializarea' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                child: const Text("Salvează"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
