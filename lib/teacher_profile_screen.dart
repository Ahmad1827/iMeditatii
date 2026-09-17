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

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final double padding;
  final double shadowOffset;
  final Color? borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = bgColor ?? AppColors.cardBg;
    final effectiveBorder = borderColor ?? AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(color: effectiveBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.bgColor ?? AppColors.sunset;
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => setState(() => isPressed = true),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                setState(() => isPressed = false);
                widget.onPressed();
              },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
          transform: Matrix4.translationValues(
            isPressed ? 3.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 3.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isLoading ? Colors.grey : effectiveBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: widget.padding,
          child: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: effectiveTextColor, size: widget.fontSize + 3),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class TeacherProfileScreen extends StatefulWidget {
  final String teacherId;
  const TeacherProfileScreen({super.key, required this.teacherId});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  bool _uploading = false;
  bool _isLoadingStripe = false;
  bool _isCheckingStatus = false;

  bool get isOwner => _auth.currentUser?.email == 'ahmadarnaoute1896@gmail.com';

  @override
  void initState() {
    super.initState();
    _checkRealStripeStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      debugPrint("Eroare status Stripe: $e");
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
      if (mounted) _showToast('Eroare: $e', isError: true);
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
      if (mounted) _showToast('Eroare: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingStripe = false);
    }
  }

  Future<void> _changePhoto(String uid) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final ref = _storage.ref('teacher_pics/$uid.jpg');
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await _fire.collection('teachers').doc(uid).update({'image': url});
      await _fire.collection('users').doc(uid).set({'image': url}, SetOptions(merge: true));
    } catch (e) {
      if (mounted) _showToast('Eroare încărcare: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _approveTeacher(String uid) async {
    try {
      await _fire.collection('teachers').doc(uid).update({'active': true});
      if (mounted) _showToast("PROFESOR APROBAT.");
    } catch (e) {
      if (mounted) _showToast("Eroare: $e", isError: true);
    }
  }

  Future<void> _rejectTeacher(String uid) async {
    try {
      await _fire.collection('teachers').doc(uid).delete();
      await _fire.collection('users').doc(uid).update({'role': 'student'});
      if (mounted) _showToast("PROFESOR RESPINS.", isError: true);
    } catch (e) {
      if (mounted) _showToast("Eroare: $e", isError: true);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? AppColors.sunset : AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('matemat')) return Icons.calculate;
    if (s.contains('info') || s.contains('programare')) return Icons.terminal;
    if (s.contains('fizic')) return Icons.bolt;
    if (s.contains('chim')) return Icons.science;
    if (s.contains('român') || s.contains('literat')) return Icons.menu_book;
    if (s.contains('englez') || s.contains('francez')) return Icons.language;
    if (s.contains('istorie')) return Icons.account_balance;
    if (s.contains('geograf')) return Icons.public;
    return Icons.school;
  }

  Future<String> _openOrCreateChat(BuildContext context, String teacherId, String teacherName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return '';
    }

    final currentUid = currentUser.uid;
    final currentUserDoc = await _fire.collection('users').doc(currentUid).get();
    final studentName = currentUserDoc.data()?['name'] ?? 'Elev';

    final existingChats = await _fire
        .collection('chats')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentId', isEqualTo: currentUid)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    final newChat = await _fire.collection('chats').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': currentUid,
      'studentName': studentName,
      'isEnded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final bool isMyProfile = currentUserId == widget.teacherId;
    final isMobile = MediaQuery.of(context).size.width < 960;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _fire.collection('users').doc(widget.teacherId).snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.sunset));
                    if (!userSnap.data!.exists) return Center(child: Text('LOG ERROR: PROFILE NOT FOUND.', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)));

                    final userData = userSnap.data!.data() as Map<String, dynamic>;
                    final bool hasStripeId = userData.containsKey('stripeAccountId') && userData['stripeAccountId'] != null && userData['stripeAccountId'].toString().isNotEmpty;
                    final bool isStripeReady = userData['isStripeActive'] == true;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _fire.collection('teachers').doc(widget.teacherId).get(),
                      builder: (context, teacherSnap) {
                        final teacherData = (teacherSnap.data?.data() as Map<String, dynamic>?) ?? {};
                        final image = teacherData['image'] ?? userData['image'] ?? '';
                        final name = teacherData['name'] ?? userData['name'] ?? 'MASTER UNKNOWN';
                        final email = teacherData['email'] ?? userData['email'] ?? 'N/A';
                        final subject = teacherData['subject'] ?? 'GENERAL';
                        final experience = teacherData['experience']?.toString() ?? '0';
                        final contact = teacherData['contact'] ?? 'N/A';
                        final price = teacherData['price']?.toString() ?? '50';
                        final bio = teacherData['bio'] ?? 'Mentor dedicat pregătirii interactive și aprofundate. Sesiuni 1-la-1 personalizate cu tablă interactivă live.';
                        final bool isApproved = teacherData['active'] == true;

                        return Scrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 20 : 36),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1140),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (isOwner) _buildAdminPanel(),
                                    if (isMyProfile && !isApproved) _buildPendingBanner(),

                                    if (!isMobile)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 360,
                                            child: _buildIdentityCard(name, email, image, subject, contact, isMyProfile, currentUserId ?? '', isMobile),
                                          ),
                                          const SizedBox(width: 28),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                _buildStatsGrid(subject, experience, price, isMobile),
                                                const SizedBox(height: 24),
                                                _buildLoreAndFeaturesBlock(bio, subject),
                                                const SizedBox(height: 24),
                                                if (isMyProfile) ...[
                                                  _buildFinancialDashboard(hasStripeId, isStripeReady, email, isMobile),
                                                  const SizedBox(height: 24),
                                                ],
                                                _ratingSection(widget.teacherId),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildIdentityCard(name, email, image, subject, contact, isMyProfile, currentUserId ?? '', isMobile),
                                          const SizedBox(height: 20),
                                          _buildStatsGrid(subject, experience, price, isMobile),
                                          const SizedBox(height: 20),
                                          _buildLoreAndFeaturesBlock(bio, subject),
                                          const SizedBox(height: 20),
                                          if (isMyProfile) ...[
                                            _buildFinancialDashboard(hasStripeId, isStripeReady, email, isMobile),
                                            const SizedBox(height: 20),
                                          ],
                                          _ratingSection(widget.teacherId),
                                        ],
                                      ),
                                    SizedBox(height: isMobile ? 32 : 60),
                                  ],
                                ),
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
      },
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: RetroBlock(
        bgColor: AppColors.mustard,
        padding: 18,
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, size: 28, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                "SYSTEM AUTHORIZATION PENDING. PROFILE HIDDEN FROM PUBLIC GUILD ROSTER.",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanel() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').where('active', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        final pendingDocs = snapshot.data?.docs ?? [];
        if (pendingDocs.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: RetroBlock(
            bgColor: AppColors.sky,
            padding: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      "ADMIN SECURITY QUEUE (${pendingDocs.length})",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...pendingDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${data['name']} [${data['subject']}]".toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check_circle, color: AppColors.forest, size: 26),
                          tooltip: "APPROVE",
                          onPressed: () => _approveTeacher(doc.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: AppColors.sunset, size: 26),
                          tooltip: "REJECT",
                          onPressed: () => _rejectTeacher(doc.id),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityCard(String name, String email, String image, String subject, String contact, bool isMyProfile, String uid, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 20 : 28,
      shadowOffset: isMobile ? 4 : 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: isMobile ? 110 : 130,
                height: isMobile ? 110 : 130,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 3.5),
                  boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
                  image: image.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(image), fit: BoxFit.cover) : null,
                ),
                child: image.isEmpty ? Icon(_getSubjectIcon(subject), size: isMobile ? 48 : 64, color: AppColors.ink) : null,
              ),
              if (isMyProfile)
                GestureDetector(
                  onTap: _uploading ? null : () => _changePhoto(uid),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: _uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(Icons.camera_alt, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Container(
                color: AppColors.sky,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  subject.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                  ),
                ),
              ),
              Container(
                color: AppColors.forest,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: const Text(
                  "VERIFIED GUILD MASTER",
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w900, height: 1.1, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 18, color: AppColors.ink),
                const SizedBox(width: 8),
                Text(
                  contact.toUpperCase(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isMyProfile)
            RetroButton(
              text: "EDIT PROFILE DATA",
              icon: Icons.edit,
              isFullWidth: true,
              bgColor: AppColors.cloud,
              textColor: AppColors.ink,
              onPressed: () => _openEditDialog(uid, isMobile),
            )
          else ...[
            RetroButton(
              text: "TRIMITE MESAJ / CHAT",
              icon: Icons.chat,
              isFullWidth: true,
              bgColor: AppColors.forest,
              textColor: Colors.white,
              onPressed: () async {
                final chatId = await _openOrCreateChat(context, widget.teacherId, name);
                if (context.mounted && chatId.isNotEmpty) {
                  context.push('/chat/$chatId', extra: name);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String subject, String exp, String price, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').doc(widget.teacherId).collection('reviews').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        double avg = 5.0;
        if (docs.isNotEmpty) {
          avg = docs.map((d) => (d['rating'] as num).toDouble()).reduce((a, b) => a + b) / docs.length;
        }

        return Row(
          children: [
            Expanded(child: _buildStatTile("RATE", "$price RON", Icons.payments, AppColors.forest, isMobile)),
            SizedBox(width: isMobile ? 8 : 14),
            Expanded(child: _buildStatTile("EXP", "$exp YRS", Icons.military_tech, AppColors.mustard, isMobile)),
            SizedBox(width: isMobile ? 8 : 14),
            Expanded(child: _buildStatTile("RATING", "${avg.toStringAsFixed(1)} ★", Icons.star, AppColors.sunset, isMobile)),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, bool isMobile) {
    final isMustard = color == AppColors.mustard;
    final textColor = isMustard && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 18, vertical: isMobile ? 12 : 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 2.5 : 3.5, isMobile ? 2.5 : 3.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 5 : 8),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Icon(icon, size: isMobile ? 16 : 20, color: isMustard && AppColors.isDark ? const Color(0xFF10161A) : Colors.white),
              ),
              SizedBox(width: isMobile ? 6 : 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: isMobile ? 9 : 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 14),
          Text(
            value.toUpperCase(),
            style: TextStyle(fontSize: isMobile ? 15 : 20, fontWeight: FontWeight.w900, color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoreAndFeaturesBlock(String bio, String subject) {
    final features = [
      {"label": "TABLĂ INTERACTIVĂ LIVE", "icon": Icons.draw, "color": AppColors.sky},
      {"label": "PREGĂTIRE BACALAUREAT", "icon": Icons.school, "color": AppColors.forest},
      {"label": "REZOLVARE TEME & QUESTS", "icon": Icons.quiz, "color": AppColors.mustard},
      {"label": "FEEDBACK 1-ON-1", "icon": Icons.verified, "color": AppColors.sunset},
    ];

    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu, size: 24, color: AppColors.sunset),
              const SizedBox(width: 10),
              Text(
                "DESPRE MENTOR & METODOLOGIE",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            bio,
            style: TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(height: 2, color: AppColors.border),
          const SizedBox(height: 18),
          Text(
            "CAPABILITĂȚI SESIUNE:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: features.map((f) {
              final col = f['color'] as Color;
              final isMustard = col == AppColors.mustard;
              final txtCol = isMustard && AppColors.isDark ? const Color(0xFF10161A) : Colors.white;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: col,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f['icon'] as IconData, size: 16, color: txtCol),
                    const SizedBox(width: 8),
                    Text(
                      f['label'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: txtCol, letterSpacing: 0.8),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDashboard(bool hasStripeId, bool isStripeReady, String email, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
      padding: isMobile ? 18 : 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "STRIPE FINANCIAL CORE",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              if (_isCheckingStatus) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(isStripeReady ? Icons.check_circle : Icons.warning, color: isStripeReady ? const Color(0xFF55EFC4) : AppColors.mustard, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isStripeReady ? "PAYMENT TUNNEL SECURE. READY FOR REVENUE." : "INCOMPLETE CONFIGURATION. REVENUE DISABLED.",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasStripeId)
                  RetroButton(text: "INITIALIZE WALLET", isFullWidth: true, bgColor: AppColors.sky, textColor: Colors.white, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                else if (hasStripeId && !isStripeReady)
                  RetroButton(text: "COMPLETE SETUP", isFullWidth: true, bgColor: AppColors.sky, textColor: Colors.white, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                else
                  RetroButton(text: "OPEN DASHBOARD", isFullWidth: true, bgColor: AppColors.forest, textColor: Colors.white, onPressed: _openStripeDashboard, isLoading: _isLoadingStripe),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _auth.sendPasswordResetEmail(email: email);
                      _showToast("RESET LOG TRANSMITTED.");
                    },
                    child: const Text("RESET ACCESS KEY", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                if (!hasStripeId)
                  RetroButton(text: "INITIALIZE WALLET", bgColor: AppColors.sky, textColor: Colors.white, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                else if (hasStripeId && !isStripeReady)
                  RetroButton(text: "COMPLETE SETUP", bgColor: AppColors.sky, textColor: Colors.white, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                else
                  RetroButton(text: "OPEN DASHBOARD", bgColor: AppColors.forest, textColor: Colors.white, onPressed: _openStripeDashboard, isLoading: _isLoadingStripe),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await _auth.sendPasswordResetEmail(email: email);
                    _showToast("RESET LOG TRANSMITTED.");
                  },
                  child: const Text("RESET KEY", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _ratingSection(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').doc(teacherId).collection('reviews').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;

        return RetroBlock(
          bgColor: AppColors.cardBg,
          padding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "PLAYER FEEDBACK & REVIEWS",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (docs.isNotEmpty)
                    Text(
                      "${docs.length} REVIEWS",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
                  child: Center(
                    child: Text("NO REVIEWS LOGGED IN SYSTEM YET.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMuted)),
                  ),
                ),
              ...docs.take(3).map((d) {
                final rData = d.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: List.generate(5, (i) => Icon(i < (rData['rating'] ?? 0) ? Icons.star : Icons.star_border, color: AppColors.sunset, size: 16))),
                      const SizedBox(height: 8),
                      Text(rData['comment'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
                    ],
                  ),
                );
              }),
              if (docs.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => context.push('/toate-recenziile/$teacherId'),
                    child: Text("ACCESS ALL REVIEWS (${docs.length}) →", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.sky)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditDialog(String uid, bool isMobile) async {
    final doc = await _fire.collection('teachers').doc(uid).get();
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final subjectCtrl = TextEditingController(text: data['subject'] ?? '');
    final expCtrl = TextEditingController(text: '${data['experience'] ?? ''}');
    final contactCtrl = TextEditingController(text: data['contact'] ?? '');
    final priceCtrl = TextEditingController(text: '${data['price'] ?? 50}');
    final bioCtrl = TextEditingController(text: data['bio'] ?? '');

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
        title: Text('UPDATE MASTER DATA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.ink)),
        content: SizedBox(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledInput(nameCtrl, 'FULL NAME'),
                _styledInput(subjectCtrl, 'DISCIPLINE'),
                _styledInput(expCtrl, 'EXP YEARS', type: TextInputType.number),
                _styledInput(contactCtrl, 'CONTACT LINK / PHONE'),
                _styledInput(priceCtrl, 'HOURLY RATE (RON)', type: TextInputType.number),
                _styledInput(bioCtrl, 'DESPRE MENTOR / BIO', maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))),
          RetroButton(
            text: 'SAVE DATA',
            bgColor: AppColors.sunset,
            textColor: Colors.white,
            onPressed: () async {
              await _fire.collection('teachers').doc(uid).set({
                'name': nameCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                'contact': contactCtrl.text.trim(),
                'price': int.tryParse(priceCtrl.text.trim()) ?? 50,
                'bio': bioCtrl.text.trim(),
              }, SetOptions(merge: true));
              await _fire.collection('users').doc(uid).set({'name': nameCtrl.text.trim()}, SetOptions(merge: true));
              if (mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _styledInput(TextEditingController c, String label, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12),
          filled: true,
          fillColor: AppColors.inputBg,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 2.5)),
        ),
      ),
    );
  }
}