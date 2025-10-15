import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'all_reviews_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({Key? key}) : super(key: key);

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
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
          'Profil Profesor',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        // Mutăm butonul de editare în AppBar
        actions: [
          IconButton(
            onPressed: () => _openEditDialog(uid),
            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 28),
            tooltip: 'Editează profilul',
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Am eliminat FloatingActionButton-ul
      body: StreamBuilder<DocumentSnapshot>(
        stream: _fire.collection('teachers').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text('Profil inexistent.',
                  style: TextStyle(fontSize: 18, color: Colors.black54)),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final image = data['image'] ?? '';
          final name = data['name'] ?? 'Nume Profesor';
          final email = data['email'] ?? 'N/A';
          final subject = data['subject'] ?? 'N/A';
          final experience = data['experience']?.toString() ?? '0';
          final contact = data['contact'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Secțiunea 1: Poza de profil și Nume
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                            backgroundImage: image.isEmpty
                                ? const AssetImage('assets/avatar_placeholder.png') as ImageProvider // Asigură-te că ai un placeholder
                                : CachedNetworkImageProvider(image),
                            child: image.isEmpty
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
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                              onPressed: _uploading ? null : () => _changePhoto(uid),
                            ),
                          ),
                        ],
                      ),
                      if (_uploading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(color: Colors.blueAccent),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Secțiunea 2: Informații de Bază
                const Text(
                  'Informații Profesor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),
                _styledInfoCard('Materie Predată', subject, Icons.menu_book),
                _styledInfoCard('Experiență', '$experience ani', Icons.timelapse),
                _styledInfoCard('Contact', contact, Icons.phone_android_outlined),
                const SizedBox(height: 30),

                // Secțiunea 3: Rating și Recenzii
                const Text(
                  'Rating & Recenzii',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(color: Colors.grey),
                _ratingSection(uid),
                const SizedBox(height: 10),

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
                    onPressed: () async {
                      await _auth.sendPasswordResetEmail(email: email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email de resetare a parolei trimis!')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET: Card de informații stilizat
  Widget _styledInfoCard(String label, String value, IconData icon) {
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
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // LOGICĂ: Schimbare poza de profil (păstrată)
  Future<void> _changePhoto(String uid) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final ref = _storage.ref('teacher_pics/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _fire.collection('teachers').doc(uid).update({'image': url});
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

  // LOGICĂ: Dialog pentru editarea profilului (UI actualizat)
  Future<void> _openEditDialog(String uid) async {
    final doc = await _fire.collection('teachers').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;

    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final subjectCtrl = TextEditingController(text: data['subject'] ?? '');
    final expCtrl = TextEditingController(text: '${data['experience'] ?? ''}');
    final contactCtrl = TextEditingController(text: data['contact'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editează informațiile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _styledInput(nameCtrl, 'Nume'),
              _styledInput(subjectCtrl, 'Materie'),
              _styledInput(expCtrl, 'Experiență (ani)', type: TextInputType.number),
              _styledInput(contactCtrl, 'Contact'),
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
            onPressed: () async {
              await _fire.collection('teachers').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                'contact': contactCtrl.text.trim(),
              });
              await _fire.collection('users').doc(uid).set({
                'name': nameCtrl.text.trim(),
              }, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvează', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // WIDGET: Input field personalizat pentru dialog (STILIZAT)
  Widget _styledInput(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  // WIDGET: Secțiunea de rating și recenzii (STILIZAT)
  Widget _ratingSection(String uid) {
    final reviewsRef = _fire
        .collection('teachers')
        .doc(uid)
        .collection('reviews')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: reviewsRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.active || !snap.hasData) return const SizedBox.shrink();

        final docs = snap.data!.docs;
        final limitedDocs = docs.take(3).toList();

        double avg = 0;
        if (docs.isNotEmpty) {
          avg = docs
              .map((d) => (d['rating'] as num).toDouble())
              .reduce((a, b) => a + b) / docs.length;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medie Rating: ${avg.toStringAsFixed(1)} / 5',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87),
                  ),
                  Text(
                    '(${docs.length} recenzii)',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              if (docs.isEmpty)
                Text(
                  'Nu există recenzii încă.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                ...limitedDocs.map((d) {
                  final rData = d.data() as Map<String, dynamic>;
                  final rating = rData['rating'] ?? 0;
                  final comment = rData['comment'] ?? '';
                  final stars = List.generate(5, (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  ));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: stars),
                        const SizedBox(height: 5),
                        Text(
                          comment,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              if (docs.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.reviews, color: Colors.blueAccent),
                      label: const Text(
                        'Vezi toate recenziile',
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        // Atenție: clasa `AllReviewsScreen` necesită un `lawyerId`, pe care îl vom presupune ca fiind `teacherId`
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllReviewsScreen(lawyerId: uid),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}