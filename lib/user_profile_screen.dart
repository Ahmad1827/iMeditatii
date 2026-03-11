import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart'; // 🚀 Import obligatoriu pentru navigare curată
import 'custom_navbar.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

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

  // LOGICĂ: Calculează progresul
  Future<Map<String, int>> _getProgressPerSubject() async {
    final prefs = await SharedPreferences.getInstance();
    final subjects = ['Matematică', 'Informatică', 'Fizică', 'Limba Română', 'Chimie', 'Engleză'];

    Map<String, int> progress = {};
    for (var subject in subjects) {
      int count = 0;
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith(subject) && (prefs.getBool(key) ?? false)) {
          count++;
        }
      }
      if (count > 0) {
        progress[subject] = count;
      }
    }
    return progress;
  }

  // LOGICĂ: Încarcă profilul
  Future<void> _loadUserProfile() async {
    setState(() => _loading = true);
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _name = data['name'] ?? 'Utilizator';
      _bio = data['bio'] ?? 'Fără descriere.';
      _contact = data['contact'] ?? 'N/A';
      _imageUrl = data['image'];
    }

    if (widget.userId == _auth.currentUser?.uid) {
      _email = _auth.currentUser?.email ?? 'N/A';
    } else {
      _email ??= doc.data()?['email'] ?? 'N/A';
    }

    setState(() => _loading = false);
  }

  // 🚀 REPARAT: Compatibilitate cu Web pentru încărcarea pozei
  Future<void> _pickImage() async {
    if (widget.userId != _auth.currentUser?.uid) return;

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploading = true);
    final uid = _auth.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('profile_pics/$uid.jpg'); // Schimbat puțin folderul pentru a evita confuzii

    try {
      final bytes = await file.readAsBytes(); // Citim datele brute, merge pe Web!
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg')); // Folosim putData
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).set({'image': url}, SetOptions(merge: true));

      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
      setState(() => _uploading = false);
    }
  }

  // LOGICĂ: Salvează profil (doar pt currentUser)
  Future<void> _saveProfile({String? newName, String? newBio, String? newContact}) async {
    if (widget.userId != _auth.currentUser?.uid) return;
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'name': newName ?? _name,
      'bio': newBio ?? _bio,
      'contact': newContact ?? _contact,
    }, SetOptions(merge: true));

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil salvat cu succes!')));
    _loadUserProfile();
  }

  // LOGICĂ: Schimbă parola
  Future<void> _changePassword() async {
    if (widget.userId != _auth.currentUser?.uid) return;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Schimbă Parola', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl, obscureText: true,
                decoration: InputDecoration(labelText: 'Parolă Curentă', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                validator: (v) => v!.isEmpty ? 'Obligatoriu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl, obscureText: true,
                decoration: InputDecoration(labelText: 'Parolă Nouă', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                validator: (v) => v!.length < 6 ? 'Minim 6 caractere' : null,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Anulează', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            onPressed: () { if (formKey.currentState!.validate()) context.pop(true); },
            child: const Text('Confirmă'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentCtrl.text.trim());
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parola a fost actualizată!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    }
  }

  Widget _buildHeroCard(bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  image: _imageUrl != null && _imageUrl!.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(_imageUrl!), fit: BoxFit.cover) : null,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: _imageUrl == null || _imageUrl!.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.blueAccent) : null,
              ),
              if (isCurrentUser)
                GestureDetector(
                  onTap: _uploading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                    child: _uploading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text("Elev / Utilizator", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                Text(_name ?? 'Nume Utilizator', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                const SizedBox(height: 4),
                Text(_email ?? 'N/A', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (isCurrentUser)
            ElevatedButton.icon(
              onPressed: _openEditDialog,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Editează"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: const Color(0xFF0F172A), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )
        ],
      ),
    );
  }

  Widget _buildBentoInfoGrid() {
    return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            children: [
              Expanded(flex: isMobile ? 0 : 1, child: _bentoBox(Icons.info_outline_rounded, "Despre", _bio ?? 'Fără descriere')),
              SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
              Expanded(flex: isMobile ? 0 : 1, child: _bentoBox(Icons.phone_iphone_rounded, "Contact", _contact ?? 'N/A')),
            ],
          );
        }
    );
  }

  Widget _bentoBox(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 28),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Progresul Tău (Exerciții)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("Aici sunt salvate toate exercițiile pe care le-ai rezolvat cu succes.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, int>>(
            future: _getProgressPerSubject(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.rocket_launch, color: Colors.blueAccent), const SizedBox(width: 16), Expanded(child: Text("Încă nu ai rezolvat exerciții. Mergi la secțiunea de teste pentru a începe!", style: TextStyle(color: Colors.grey.shade700)))]));

              final progress = snapshot.data!;
              return Column(
                children: progress.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 12), Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)))]),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text("${e.value} rezolvate", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Securitate cont", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text("Actualizează parola pentru a-ți păstra datele în siguranță.", style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _changePassword, icon: const Icon(Icons.lock_reset), label: const Text("Schimbă parola"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  // DIALOG EDITARE
  Future<void> _openEditDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    final contactCtrl = TextEditingController(text: _contact);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Editează Profilul', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledInput(nameCtrl, 'Numele complet'),
                _styledInput(bioCtrl, 'Despre mine (Bio)', maxLines: 3),
                _styledInput(contactCtrl, 'Număr contact'),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Anulează', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            onPressed: () {
              _saveProfile(newName: nameCtrl.text.trim(), newBio: bioCtrl.text.trim(), newContact: contactCtrl.text.trim());
              context.pop();
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Widget _styledInput(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c, maxLines: maxLines,
        decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.userId == _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800), // Păstrează lățimea clean pe desktop
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(isCurrentUser),
                      const SizedBox(height: 24),
                      _buildBentoInfoGrid(),
                      const SizedBox(height: 24),
                      _buildProgressSection(),
                      if (isCurrentUser) const SizedBox(height: 24),
                      if (isCurrentUser) _buildSettingsSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}