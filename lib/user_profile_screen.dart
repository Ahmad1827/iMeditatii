import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  bool _uploading = false;
  bool _loading = false;

  String? _name = '';
  String? _email = '';
  String? _bio = '';
  String? _contact = '';
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // LOGICĂ: Calculează progresul (păstrată)
  Future<Map<String, int>> _getProgressPerSubject() async {
    final prefs = await SharedPreferences.getInstance();
    // TODO: Înlocuiește cu lista reală de materii și exerciții tale
    final subjects = ['Matematică', 'Informatică', 'Fizică'];

    Map<String, int> progress = {};

    for (var subject in subjects) {
      int count = 0;
      final keys = prefs.getKeys(); // toate cheile salvate
      for (var key in keys) {
        if (key.startsWith(subject) && (prefs.getBool(key) ?? false)) {
          count++;
        }
      }
      progress[subject] = count;
    }

    return progress;
  }

  // LOGICĂ: Încarcă profilul (păstrată)
  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _name = data['name'] ?? 'N/A';
      _bio = data['bio'] ?? 'Fără descriere.';
      _contact = data['contact'] ?? 'N/A';
      _email = user.email ?? 'N/A';
      _imageUrl = data['image'];
    }
    setState(() => _loading = false);
  }

  // LOGICĂ: Alege și încarcă imaginea (păstrată)
  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploading = true);
    final uid = _auth.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('profile_pictures/$uid.jpg');

    try {
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(uid)
          .set({'image': url}, SetOptions(merge: true));

      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare la încărcarea imaginii: $e')));
      setState(() => _uploading = false);
    }
  }

  // LOGICĂ: Salvează profilul (păstrată)
  Future<void> _saveProfile({String? newName, String? newBio, String? newContact}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'name': newName ?? _name,
      'bio': newBio ?? _bio,
      'contact': newContact ?? _contact,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profil salvat cu succes!')));
    // Reîncărcăm datele pentru a actualiza UI-ul
    _loadUserProfile();
  }

  // LOGICĂ: Schimbă parola (păstrată)
  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Schimbă Parola'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parolă Curentă',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                validator: (v) => v!.isEmpty ? 'Obligatoriu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parolă Nouă',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                validator: (v) => v!.length < 6 ? 'Minim 6 caractere' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anulează', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Schimbă', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentCtrl.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newCtrl.text.trim());

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Parola a fost actualizată!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare la schimbarea parolei: $e')));
    }
  }

  // WIDGET: Card de progres (STILIZAT)
  Widget _progressCard(String subject, int done) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$done',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'rezolvate',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Card de informații (STILIZAT)
  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Input stilizat pentru dialog (STILIZAT)
  Widget _input(TextEditingController c, String label, {int maxLines = 1}) =>
      TextFormField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // LOGICĂ: Deschide dialogul de editare (păstrată, cu UI actualizat)
  Future<void> _openEditDialog() async {
    final nameCtrl = TextEditingController(text: _name == 'N/A' ? '' : _name);
    final bioCtrl = TextEditingController(text: _bio == 'Fără descriere.' ? '' : _bio);
    final contactCtrl = TextEditingController(text: _contact == 'N/A' ? '' : _contact);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editează Profilul'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(nameCtrl, 'Nume complet'),
              const SizedBox(height: 15),
              _input(bioCtrl, 'Despre mine', maxLines: 3),
              const SizedBox(height: 15),
              _input(contactCtrl, 'Informații contact'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              _saveProfile(
                newName: nameCtrl.text.trim(),
                newBio: bioCtrl.text.trim(),
                newContact: contactCtrl.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Salvează', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        title: const Text(
          'Profilul meu',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // Butonul de editare mutat în AppBar (acțiune principală)
          IconButton(
            onPressed: _openEditDialog,
            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 28),
            tooltip: 'Editează profilul',
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Am eliminat FloatingActionButton-ul original.
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Secțiunea 1: Poza de profil și numele
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        backgroundImage: _imageUrl != null
                            ? NetworkImage(_imageUrl!) as ImageProvider
                            : null,
                        child: _imageUrl == null
                            ? const Icon(Icons.person_outline, size: 60, color: Colors.blueAccent)
                            : null,
                      ),
                      Material(
                        shape: const CircleBorder(),
                        color: Colors.blueAccent,
                        child: IconButton(
                          icon: _uploading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                          onPressed: _uploading ? null : _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name ?? 'Utilizator',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _email ?? 'email@lipsa.com',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Secțiunea 2: Informații de bază
            const Text(
              'Detalii Cont',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            _infoCard('Email', _email ?? 'N/A', Icons.mail_outline),
            _infoCard('Contact', _contact ?? 'N/A', Icons.phone_android_outlined),
            _infoCard('Despre mine', _bio ?? 'Fără descriere.', Icons.info_outline),
            const SizedBox(height: 30),

            // Secțiunea 3: Progres
            const Text(
              'Progresul tău',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: _getProgressPerSubject(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nu ai înregistrat încă niciun progres.', style: TextStyle(color: Colors.grey));
                }
                final progress = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: progress.entries
                      .map((e) => _progressCard(e.key, e.value))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 30),

            // Secțiunea 4: Acțiuni (Schimbă Parola)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset, size: 20),
                label: const Text('Schimbă parola'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                onPressed: _changePassword,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}