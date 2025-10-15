// lawyer_profile_screen.dart
// REFACTOR pentru stil modern, consistent cu celelalte ecrane din aplicație

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'all_reviews_screen.dart';

class LawyerProfileScreen extends StatefulWidget {
  const LawyerProfileScreen({Key? key}) : super(key: key);

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditDialog(uid),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.edit),
        label: const Text('Editează'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _fire.collection('lawyers').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text('Profil inexistent.',
                  style: TextStyle(fontSize: 18, color: Colors.black54)),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final image = data['image'] ?? '';
          final name = data['name'] ?? '';
          final email = data['email'] ?? '';
          final edu = data['education'] ?? '';
          final exp = data['experience']?.toString() ?? '';
          final spec = data['specialization'] ?? '';
          final contact = data['contact'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: image.isEmpty
                            ? const AssetImage('assets/avatar_placeholder.png')
                        as ImageProvider
                            : CachedNetworkImageProvider(image),
                      ),
                      Material(
                        shape: const CircleBorder(),
                        color: Colors.blueAccent,
                        child: IconButton(
                          icon: const Icon(Icons.photo_camera, color: Colors.white),
                          onPressed: _uploading ? null : () => _changePhoto(uid),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 24),

                _infoCard('Nume', name),
                _infoCard('Email', email),
                _infoCard('Educație', edu),
                _infoCard('Experiență', '$exp ani'),
                _infoCard('Specializare', spec),
                _infoCard('Contact', contact),

                const SizedBox(height: 24),
                _ratingSection(uid),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Schimbă parola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      await _auth.sendPasswordResetEmail(email: email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email de resetare trimis!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto(String uid) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final ref = _storage.ref('profile_pics/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _fire.collection('lawyers').doc(uid).update({'image': url});
      await _fire.collection('users').doc(uid).set({'image': url},
          SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openEditDialog(String uid) async {
    final doc = await _fire.collection('lawyers').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;

    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final eduCtrl = TextEditingController(text: data['education'] ?? '');
    final expCtrl = TextEditingController(text: '${data['experience'] ?? ''}');
    final specCtrl = TextEditingController(text: data['specialization'] ?? '');
    final contactCtrl = TextEditingController(text: data['contact'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Editează informațiile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(nameCtrl, 'Nume'),
              _input(eduCtrl, 'Educație'),
              _input(expCtrl, 'Experiență (ani)', type: TextInputType.number),
              _input(specCtrl, 'Specializare'),
              _input(contactCtrl, 'Contact'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              await _fire.collection('lawyers').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'education': eduCtrl.text.trim(),
                'experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                'specialization': specCtrl.text.trim(),
                'contact': contactCtrl.text.trim(),
              });
              await _fire.collection('users').doc(uid).set({
                'name': nameCtrl.text.trim(),
              }, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _ratingSection(String uid) {
    final reviewsRef = _fire
        .collection('lawyers')
        .doc(uid)
        .collection('reviews')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: reviewsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final docs = snap.data!.docs;
        final limitedDocs = docs.take(3).toList();

        double avg = 0;
        if (docs.isNotEmpty) {
          avg = docs
              .map((d) => (d['rating'] as num).toDouble())
              .reduce((a, b) => a + b) /
              docs.length;
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating: ${avg.toStringAsFixed(1)} / 5 (${docs.length} recenzii)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                ...limitedDocs.map((d) {
                  final rData = d.data() as Map<String, dynamic>;
                  final rating = rData['rating'] ?? 0;
                  final comment = rData['comment'] ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ListTile(
                      title: Text(
                        '★' * rating,
                        style: const TextStyle(color: Colors.amber, fontSize: 16),
                      ),
                      subtitle: Text(comment),
                    ),
                  );
                }).toList(),
                if (docs.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.reviews),
                      label: const Text('Vezi toate recenziile'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllReviewsScreen(lawyerId: uid),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
