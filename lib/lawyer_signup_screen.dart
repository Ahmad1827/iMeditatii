// lawyer_signup_screen.dart  (FULL FILE – adăugat constructor pentru cont Google)
// Dacă vine deja autentificat (googleUid != null) NU mai creăm user în Auth,
// ci doar salvăm detaliile în colecțiile `lawyers` + `users`.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerSignupScreen extends StatefulWidget {
  const LawyerSignupScreen({
    super.key,
    this.googleUid,
    this.googleEmail,
    this.googleName,
  });

  final String? googleUid;     // ← NEW
  final String? googleEmail;   // ← NEW
  final String? googleName;    // ← NEW

  @override
  State<LawyerSignupScreen> createState() => _LawyerSignupScreenState();
}

class _LawyerSignupScreenState extends State<LawyerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _education = TextEditingController();
  final _experience = TextEditingController();
  final _contact = TextEditingController();
  final _imageUrl = TextEditingController();

  final List<String> _specializations = [
    'Family Law',
    'Criminal Defense',
    'Drept civil',
    'Drept penal',
    'Drept comercial / societar',
    'Dreptul muncii',
    'Dreptul familiei',
    'Drept administrativ',
    'Drept fiscal',
    'Drept imobiliar',
    'Dreptul consumatorului',
    'Drept IT / protecția datelor (GDPR)',
    'Proprietate intelectuală',
    'Drept maritim și transporturi',
  ];
  String _selectedSpec = 'Family Law';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.googleEmail != null) {
      _email.text = widget.googleEmail!;
      _name.text  = widget.googleName ?? '';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      String uid;

      if (widget.googleUid != null) {
        // ─── user deja autentificat cu Google ────────────────
        uid = widget.googleUid!;
      } else {
        // ─── creare cont email/parolă ───────────────────────
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
        uid = cred.user!.uid;
      }

      // salvează documentul în `lawyers`
      await _firestore.collection('lawyers').doc(uid).set({
        'uid'            : uid,
        'email'          : _email.text.trim(),
        'name'           : _name.text.trim(),
        'education'      : _education.text.trim(),
        'experience'     : int.parse(_experience.text.trim()),
        'specialization' : _selectedSpec,
        'specializationKey': _selectedSpec.toLowerCase(),
        'contact'        : _contact.text.trim(),
        'image'          : _imageUrl.text.trim(),
        'createdAt'      : FieldValue.serverTimestamp(),
      });

      // document‑oglindă în `users`
      await _firestore.collection('users').doc(uid).set({
        'role' : 'lawyer',
        'email': _email.text.trim(),
        'name' : _name.text.trim(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleMode = widget.googleUid != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawyer Sign‑Up'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(_name, 'Full Name'),
              _input(_email, 'Email',
                  type: TextInputType.emailAddress,
                  enabled: !googleMode),                     // e-mail fix în Google mode
              if (!googleMode)
                _input(_password, 'Password', isPassword: true),
              _input(_education, 'Education'),
              _input(_experience, 'Years of Experience',
                  type: TextInputType.number),
              DropdownButtonFormField<String>(
                value: _selectedSpec,
                items: _specializations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Specialization'),
                onChanged: (v) => setState(() => _selectedSpec = v!),
              ),
              _input(_contact, 'Contact Number'),
              _input(_imageUrl, 'Profile Image URL (optional)'),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                child: Text(googleMode ? 'Save' : 'Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {TextInputType type = TextInputType.text,
        bool isPassword = false,
        bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        enabled: enabled,
        obscureText: isPassword,
        decoration:
        InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) =>
        v == null || v.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
