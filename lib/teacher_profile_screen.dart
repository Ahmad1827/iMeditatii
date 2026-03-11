import 'dart:io';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'custom_navbar.dart'; // 🚀 Import obligatoriu pentru navigare curată

class TeacherProfileScreen extends StatefulWidget {
  final String teacherId;

  const TeacherProfileScreen({Key? key, required this.teacherId}) : super(key: key);

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  bool _uploading = false;
  bool _isLoadingStripe = false;
  bool _isCheckingStatus = false;

  // Verificare dacă utilizatorul curent este administratorul
  bool get isOwner => _auth.currentUser?.email == 'ahmadarnaoute1896@gmail.com';

  @override
  void initState() {
    super.initState();
    _checkRealStripeStatus();
  }

  Future<void> _checkRealStripeStatus() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId != widget.teacherId) return;

    setState(() => _isCheckingStatus = true);
    try {
      await http.post(
        Uri.parse('https://us-central1-imeditatii.cloudfunctions.net/verifyStripeStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': currentUserId}),
      );
    } catch (e) {
      debugPrint("Eroare la verificarea statusului Stripe: $e");
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _setupStripeAccount() async {
    setState(() => _isLoadingStripe = true);
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-imeditatii.cloudfunctions.net/createStripeAccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': _auth.currentUser!.uid}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await launchUrl(Uri.parse(data['url']), mode: LaunchMode.externalApplication);
      } else {
        throw data['error'] ?? "Eroare necunoscută.";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingStripe = false);
    }
  }

  Future<void> _openStripeDashboard() async {
    setState(() => _isLoadingStripe = true);
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-imeditatii.cloudfunctions.net/createStripeDashboardLink'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': _auth.currentUser!.uid}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await launchUrl(Uri.parse(data['url']), mode: LaunchMode.externalApplication);
      } else {
        throw data['error'] ?? "Eroare necunoscută.";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingStripe = false);
    }
  }

  // 🚀 REPARAT: Funcționează perfect și pe Web și pe Telefon
  Future<void> _changePhoto(String uid) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final ref = _storage.ref('teacher_pics/$uid.jpg');

      // Citim fișierul ca Bytes (suportat de Web)
      final bytes = await picked.readAsBytes();

      // Folosim putData în loc de putFile
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final url = await ref.getDownloadURL();
      await _fire.collection('teachers').doc(uid).update({'image': url});
      await _fire.collection('users').doc(uid).set({'image': url}, SetOptions(merge: true));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare la încărcare: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // --------------------------------------------------------------------------
  // LOGICĂ ADMIN (PENTRU FONDATOR)
  // --------------------------------------------------------------------------
  Future<void> _approveTeacher(String uid) async {
    try {
      await _fire.collection('teachers').doc(uid).update({'active': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profesor aprobat cu succes!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare la aprobare: $e")));
      }
    }
  }

  Future<void> _rejectTeacher(String uid) async {
    try {
      await _fire.collection('teachers').doc(uid).delete();
      await _fire.collection('users').doc(uid).update({'role': 'student'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profesor respins și șters."), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare la respingere: $e")));
      }
    }
  }

  // --------------------------------------------------------------------------
  // NAVBAR
  // --------------------------------------------------------------------------
  Widget _buildNavbar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('iMeditatii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              TextButton(
                  onPressed: () => context.go('/materii'),
                  child: const Text("Profesori", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15))
              ),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: () => context.go('/exercitii'),
                  child: const Text("Exerciții", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15))
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              _buildAuthActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthActions() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
        }

        final user = snapshot.data;

        if (user == null) {
          return ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
            ),
            child: const Text("Intră în cont", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/panou-profesor');
                    } else {
                      context.go('/panou-elev');
                    }
                  }
                } catch (e) {
                  debugPrint("Eroare dashboard: $e");
                }
              },
              icon: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF0F172A), size: 28),
              tooltip: "Panou de control",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                if (user.uid != widget.teacherId) {
                  context.go('/profesor/${user.uid}');
                }
              },
              icon: Icon(
                  Icons.account_circle,
                  color: user.uid == widget.teacherId ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
                  size: 30
              ),
              tooltip: "Contul meu",
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                tooltip: "Deconectare",
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final bool isMyProfile = currentUserId == widget.teacherId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildNavbar(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _fire.collection('users').doc(widget.teacherId).snapshots(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                if (!userSnap.hasData || !userSnap.data!.exists) return const Center(child: Text('Profil inexistent.', style: TextStyle(fontSize: 18, color: Colors.black54)));

                final userData = userSnap.data!.data() as Map<String, dynamic>;
                final bool hasStripeId = userData.containsKey('stripeAccountId') && userData['stripeAccountId'] != null && userData['stripeAccountId'].toString().isNotEmpty;
                final bool isStripeReady = userData['isStripeActive'] == true;

                return FutureBuilder<DocumentSnapshot>(
                  future: _fire.collection('teachers').doc(widget.teacherId).get(),
                  builder: (context, teacherSnap) {
                    if (teacherSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final teacherData = (teacherSnap.data?.data() as Map<String, dynamic>?) ?? {};
                    final image = teacherData['image'] ?? userData['image'] ?? '';
                    final name = teacherData['name'] ?? userData['name'] ?? 'Nume Profesor';
                    final email = teacherData['email'] ?? userData['email'] ?? 'N/A';
                    final subject = teacherData['subject'] ?? 'N/A';
                    final experience = teacherData['experience']?.toString() ?? '0';
                    final contact = teacherData['contact'] ?? 'N/A';

                    // 🚀 NOU: Extragem prețul (Default 50 dacă nu a setat încă)
                    final price = teacherData['price']?.toString() ?? '50';

                    final bool isApproved = teacherData['active'] == true;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isOwner) _buildAdminPanel(),
                              if (isMyProfile && !isApproved) _buildPendingApprovalBanner(),

                              _buildHeroCard(name, email, image, subject, isMyProfile, currentUserId!),
                              const SizedBox(height: 24),

                              // 🚀 NOU: Trimitem și prețul către grila de informații
                              _buildInfoGrid(subject, experience, contact, price),

                              const SizedBox(height: 24),
                              if (isMyProfile) _buildFinancialDashboard(hasStripeId, isStripeReady, email),
                              if (isMyProfile) const SizedBox(height: 24),
                              _ratingSection(widget.teacherId),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // COMPONENTE UI MODERNE
  // --------------------------------------------------------------------------

  Widget _buildPendingApprovalBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.orange.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Contul tău este în așteptare", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade900)),
                const SizedBox(height: 4),
                Text("Administratorii noștri îți analizează profilul. Până la aprobare, nu vei apărea în lista publică de profesori.", style: TextStyle(fontSize: 14, color: Colors.orange.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.amber.shade800, size: 32),
              const SizedBox(width: 12),
              Text("Panou Administrator", style: TextStyle(color: Colors.amber.shade900, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Aici vezi și aprobi profesorii noi care și-au făcut cont.", style: TextStyle(color: Colors.amber.shade800, fontSize: 15)),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: _fire.collection('teachers').where('active', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade400),
                      const SizedBox(width: 12),
                      const Text("Nu există niciun profesor în așteptare momentan.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Icon(Icons.person, color: Colors.amber.shade800),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? 'Fără nume', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text("${data['subject']} • ${data['email']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.check_rounded, color: Colors.green, size: 24),
                            onPressed: () => _approveTeacher(doc.id),
                            tooltip: "Aprobă Profesor",
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 24),
                            onPressed: () => _rejectTeacher(doc.id),
                            tooltip: "Respinge și Șterge",
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String name, String email, String image, String subject, bool isMyProfile, String currentUserId) {
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
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  image: image.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(image), fit: BoxFit.cover) : null,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: image.isEmpty ? const Icon(Icons.person_outline, size: 50, color: Colors.blueAccent) : null,
              ),
              if (isMyProfile)
                GestureDetector(
                  onTap: _uploading ? null : () => _changePhoto(currentUserId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                    child: _uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(subject.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (isMyProfile)
            ElevatedButton.icon(
              onPressed: () => _openEditDialog(currentUserId),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Editează"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
        ],
      ),
    );
  }

  // 🚀 NOU: Am restructurat pe două rânduri ca să încapă frumos prețul
  Widget _buildInfoGrid(String subject, String exp, String contact, String price) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Column(
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(flex: isMobile ? 0 : 1, child: _bentoBox(Icons.menu_book_rounded, "Materie", subject)),
                  SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                  Expanded(flex: isMobile ? 0 : 1, child: _bentoBox(Icons.military_tech_rounded, "Experiență", "$exp ani")),
                ],
              ),
              const SizedBox(height: 16),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(flex: isMobile ? 0 : 1, child: _bentoBox(Icons.phone_rounded, "Contact", contact)),
                  SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                  Expanded(flex: isMobile ? 0 : 1, child: _bentoBox(Icons.payments_rounded, "Preț Setat", "$price RON / oră")), // 🚀 Căsuța pentru preț
                ],
              ),
            ],
          );
        }
    );
  }

  Widget _bentoBox(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 28),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinancialDashboard(bool hasStripeId, bool isStripeReady, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Panou Financiar (Stripe)", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (_isCheckingStatus) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(
              children: [
                Icon(isStripeReady ? Icons.check_circle_rounded : (hasStripeId ? Icons.info_outline : Icons.warning_amber_rounded), color: isStripeReady ? Colors.greenAccent : (hasStripeId ? Colors.blueAccent : Colors.orangeAccent)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isStripeReady ? "Contul tău este activ. Ești gata să primești plăți." : (hasStripeId ? "Contul a fost creat. Finalizează configurarea datelor bancare." : "Adaugă un cont bancar pentru a putea fi plătit de elevi."),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_isLoadingStripe)
                const CircularProgressIndicator(color: Colors.white)
              else if (!hasStripeId)
                ElevatedButton.icon(
                  onPressed: _setupStripeAccount, icon: const Icon(Icons.account_balance), label: const Text("Setează încasările"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )
              else if (hasStripeId && !isStripeReady)
                  ElevatedButton.icon(
                    onPressed: _setupStripeAccount, icon: const Icon(Icons.arrow_forward_ios, size: 16), label: const Text("Continuă configurarea"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _openStripeDashboard, icon: const Icon(Icons.dashboard), label: const Text("Deschide portofelul Stripe"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),

              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await _auth.sendPasswordResetEmail(email: email);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email de resetare trimis!')));
                },
                icon: const Icon(Icons.lock_reset, color: Colors.white54),
                label: const Text("Schimbă parola", style: TextStyle(color: Colors.white54)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _ratingSection(String teacherId) {
    final reviewsRef = _fire.collection('teachers').doc(teacherId).collection('reviews').orderBy('createdAt', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: reviewsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        final limitedDocs = docs.take(3).toList();
        double avg = 0;
        if (docs.isNotEmpty) avg = docs.map((d) => (d['rating'] as num).toDouble()).reduce((a, b) => a + b) / docs.length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recenzii", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(docs.isEmpty ? "Fără recenzii" : "${docs.length} păreri de la elevi", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                  if (docs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (docs.isEmpty) Text('Încă nu ai primit nicio recenzie.', style: TextStyle(color: Colors.grey.shade600)),
              ...limitedDocs.map((d) {
                final rData = d.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: List.generate(5, (i) => Icon(i < (rData['rating'] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 18))),
                      const SizedBox(height: 8),
                      Text(rData['comment'] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.4)),
                    ],
                  ),
                );
              }).toList(),
              if (docs.length > 3)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.go('/toate-recenziile/$teacherId'),
                    child: const Text("Vezi toate recenziile →", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // DIALOG DE EDITARE (Adăugat Câmpul PREȚ)
  // --------------------------------------------------------------------------
  Future<void> _openEditDialog(String uid) async {
    final doc = await _fire.collection('teachers').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;

    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final subjectCtrl = TextEditingController(text: data['subject'] ?? '');
    final expCtrl = TextEditingController(text: '${data['experience'] ?? ''}');
    final contactCtrl = TextEditingController(text: data['contact'] ?? '');

    // 🚀 NOU: Controler pentru preț
    final priceCtrl = TextEditingController(text: '${data['price'] ?? 50}');

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
                _styledInput(nameCtrl, 'Numele tău complet'),
                _styledInput(subjectCtrl, 'Materia predată'),
                _styledInput(expCtrl, 'Ani de experiență', type: TextInputType.number),
                _styledInput(contactCtrl, 'Număr de contact'),

                // 🚀 NOU: Input pentru preț în UI
                _styledInput(priceCtrl, 'Preț pe oră (RON)', type: TextInputType.number),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Anulează', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            onPressed: () async {
              await _fire.collection('teachers').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                'contact': contactCtrl.text.trim(),
                // 🚀 NOU: Salvăm prețul introdus în Firebase
                'price': int.tryParse(priceCtrl.text.trim()) ?? 50
              });
              await _fire.collection('users').doc(uid).set({'name': nameCtrl.text.trim()}, SetOptions(merge: true));
              if (mounted) context.pop();
            },
            child: const Text('Salvează modificările'),
          ),
        ],
      ),
    );
  }

  Widget _styledInput(TextEditingController c, String label, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c, keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
        ),
      ),
    );
  }
}