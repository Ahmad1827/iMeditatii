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

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
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
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isLoading ? Colors.grey : effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: widget.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[Icon(widget.icon, color: effectiveTextColor, size: 20), const SizedBox(width: 8)],
                    Text(
                      widget.text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: effectiveTextColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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

  bool _uploading = false;
  bool _isLoadingStripe = false;
  bool _isCheckingStatus = false;

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
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final bool isMyProfile = currentUserId == widget.teacherId;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text('MASTER PROFILE', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(color: AppColors.border, height: 3)),
            leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.ink, size: 28), onPressed: () => context.go('/')),
          ),
          body: StreamBuilder<DocumentSnapshot>(
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
                  final subject = teacherData['subject'] ?? 'N/A';
                  final experience = teacherData['experience']?.toString() ?? '0';
                  final contact = teacherData['contact'] ?? 'N/A';
                  final price = teacherData['price']?.toString() ?? '50';
                  final bool isApproved = teacherData['active'] == true;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          children: [
                            if (isOwner) _buildAdminPanel(isMobile),
                            if (isMyProfile && !isApproved) _buildPendingBanner(),
                            _buildHeroCard(name, email, image, subject, isMyProfile, currentUserId ?? '', isMobile),
                            const SizedBox(height: 32),
                            _buildInfoGrid(subject, experience, contact, price, isMobile),
                            const SizedBox(height: 32),
                            if (isMyProfile) _buildFinancialDashboard(hasStripeId, isStripeReady, email, isMobile),
                            const SizedBox(height: 32),
                            _ratingSection(widget.teacherId, isMobile),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: RetroBlock(
        bgColor: AppColors.mustard,
        padding: 20,
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, size: 32, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "SYSTEM AUTHORIZATION PENDING. PROFILE HIDDEN FROM PUBLIC REGISTRY.",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanel(bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: RetroBlock(
        bgColor: AppColors.sky,
        padding: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, size: 32),
                const SizedBox(width: 12),
                Text(
                  "ADMIN TERMINAL",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: _fire.collection('teachers').where('active', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(
                    "NO PENDING AUTHORIZATIONS.",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                      padding: const EdgeInsets.all(12),
                      child: isMobile
                          ? Column(
                              children: [
                                Text(
                                  "${data['name']} [${data['subject']}]".toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(icon: Icon(Icons.check_circle, color: AppColors.forest), onPressed: () => _approveTeacher(doc.id)),
                                    IconButton(icon: Icon(Icons.cancel, color: AppColors.sunset), onPressed: () => _rejectTeacher(doc.id)),
                                  ],
                                )
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${data['name']} [${data['subject']}]".toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(icon: Icon(Icons.check_circle, color: AppColors.forest), onPressed: () => _approveTeacher(doc.id)),
                                    IconButton(icon: Icon(Icons.cancel, color: AppColors.sunset), onPressed: () => _rejectTeacher(doc.id)),
                                  ],
                                )
                              ],
                            ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(String name, String email, String image, String subject, bool isMyProfile, String uid, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 24 : 32,
      child: isMobile
          ? Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        border: Border.all(color: AppColors.border, width: 3),
                        image: image.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(image), fit: BoxFit.cover) : null,
                      ),
                      child: image.isEmpty ? Icon(Icons.person, size: 60, color: AppColors.ink) : null,
                    ),
                    if (isMyProfile)
                      GestureDetector(
                        onTap: _uploading ? null : () => _changePhoto(uid),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.ink, border: Border.all(color: AppColors.border, width: 2)),
                          child: _uploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(Icons.camera_alt, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      color: AppColors.sky,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        subject.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.0, color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    Text(email, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 24),
                if (isMyProfile)
                  RetroButton(text: "EDIT", icon: Icons.edit, isFullWidth: true, bgColor: AppColors.cloud, textColor: AppColors.ink, onPressed: () => _openEditDialog(uid)),
              ],
            )
          : Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        border: Border.all(color: AppColors.border, width: 3),
                        image: image.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(image), fit: BoxFit.cover) : null,
                      ),
                      child: image.isEmpty ? Icon(Icons.person, size: 60, color: AppColors.ink) : null,
                    ),
                    if (isMyProfile)
                      GestureDetector(
                        onTap: _uploading ? null : () => _changePhoto(uid),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.ink, border: Border.all(color: AppColors.border, width: 2)),
                          child: _uploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(Icons.camera_alt, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 14),
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
                        color: AppColors.sky,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          subject.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(name.toUpperCase(), textAlign: TextAlign.left, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.0, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      Text(email, textAlign: TextAlign.left, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (isMyProfile)
                  RetroButton(text: "EDIT", icon: Icons.edit, isFullWidth: false, bgColor: AppColors.cloud, textColor: AppColors.ink, onPressed: () => _openEditDialog(uid)),
              ],
            ),
    );
  }

  Widget _buildInfoGrid(String subject, String exp, String contact, String price, bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: isMobile ? 3.5 : 2.2,
      children: [
        _bentoBox(Icons.menu_book, "DISCIPLINE", subject, AppColors.cloud),
        _bentoBox(Icons.military_tech, "EXP LEVEL", "$exp YEARS", AppColors.mustard),
        _bentoBox(Icons.phone, "COMMS", contact, AppColors.cloud),
        _bentoBox(Icons.payments, "RATE", "$price RON / HR", AppColors.sky),
      ],
    );
  }

  Widget _bentoBox(IconData icon, String title, String value, Color color) {
    return RetroBlock(
      bgColor: color,
      padding: 16,
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.isDark && color == AppColors.mustard ? const Color(0xFF10161A) : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.isDark && color == AppColors.mustard ? const Color(0xFF10161A) : AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDashboard(bool hasStripeId, bool isStripeReady, String email, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
      padding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text("FINANCIAL CORE (STRIPE)", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              if (_isCheckingStatus) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white24, width: 2)),
            child: Row(
              children: [
                Icon(isStripeReady ? Icons.check_circle : Icons.warning, color: isStripeReady ? Colors.greenAccent : AppColors.mustard),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isStripeReady ? "PAYMENT TUNNEL SECURE. READY FOR TRANSACTIONS." : "INCOMPLETE CONFIGURATION. REVENUE STREAMS DISABLED.",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasStripeId)
                      RetroButton(text: "INITIALIZE WALLET", bgColor: AppColors.sky, textColor: Colors.white, isFullWidth: true, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                    else if (hasStripeId && !isStripeReady)
                      RetroButton(text: "COMPLETE SETUP", bgColor: AppColors.sky, textColor: Colors.white, isFullWidth: true, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                    else
                      RetroButton(text: "OPEN DASHBOARD", bgColor: AppColors.forest, textColor: Colors.white, isFullWidth: true, onPressed: _openStripeDashboard, isLoading: _isLoadingStripe),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        await _auth.sendPasswordResetEmail(email: email);
                        _showToast("RESET LOG TRANSMITTED.");
                      },
                      child: const Text("RESET ACCESS KEY", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    )
                  ],
                )
              : Row(
                  children: [
                    if (!hasStripeId)
                      RetroButton(text: "INITIALIZE WALLET", bgColor: AppColors.sky, textColor: Colors.white, isFullWidth: false, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                    else if (hasStripeId && !isStripeReady)
                      RetroButton(text: "COMPLETE SETUP", bgColor: AppColors.sky, textColor: Colors.white, isFullWidth: false, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                    else
                      RetroButton(text: "OPEN DASHBOARD", bgColor: AppColors.forest, textColor: Colors.white, isFullWidth: false, onPressed: _openStripeDashboard, isLoading: _isLoadingStripe),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await _auth.sendPasswordResetEmail(email: email);
                        _showToast("RESET LOG TRANSMITTED.");
                      },
                      child: const Text("RESET ACCESS KEY", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    )
                  ],
                )
        ],
      ),
    );
  }

  Widget _ratingSection(String teacherId, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').doc(teacherId).collection('reviews').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        double avg = 0;
        if (docs.isNotEmpty) avg = docs.map((d) => (d['rating'] as num).toDouble()).reduce((a, b) => a + b) / docs.length;

        return RetroBlock(
          bgColor: AppColors.cardBg,
          padding: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PLAYER REVIEWS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.ink)),
                        const SizedBox(height: 12),
                        if (docs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
                            child: Text(
                              "AVG: ${avg.toStringAsFixed(1)} ★",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
                            ),
                          ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("PLAYER REVIEWS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.ink)),
                        if (docs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
                            child: Text(
                              "AVG: ${avg.toStringAsFixed(1)} ★",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
                            ),
                          ),
                      ],
                    ),
              const SizedBox(height: 24),
              if (docs.isEmpty) Text("NO REVIEWS LOGGED IN SYSTEM.", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              ...docs.take(2).map((d) {
                final rData = d.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
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
              if (docs.length > 2)
                TextButton(onPressed: () => context.go('/toate-recenziile/$teacherId'), child: Text("ACCESS FULL REVIEW LOG →", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.sky))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditDialog(String uid) async {
    final doc = await _fire.collection('teachers').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final subjectCtrl = TextEditingController(text: data['subject'] ?? '');
    final expCtrl = TextEditingController(text: '${data['experience'] ?? ''}');
    final contactCtrl = TextEditingController(text: data['contact'] ?? '');
    final priceCtrl = TextEditingController(text: '${data['price'] ?? 50}');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
        title: Text('UPDATE SYSTEM DATA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.ink)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledInput(nameCtrl, 'FULL NAME'),
                _styledInput(subjectCtrl, 'DISCIPLINE'),
                _styledInput(expCtrl, 'EXP YEARS', type: TextInputType.number),
                _styledInput(contactCtrl, 'CONTACT LINK'),
                _styledInput(priceCtrl, 'HOURLY RATE (RON)', type: TextInputType.number),
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
              await _fire.collection('teachers').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                'contact': contactCtrl.text.trim(),
                'price': int.tryParse(priceCtrl.text.trim()) ?? 50
              });
              await _fire.collection('users').doc(uid).set({'name': nameCtrl.text.trim()}, SetOptions(merge: true));
              if (mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _styledInput(TextEditingController c, String label, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: c,
        keyboardType: type,
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12),
          filled: true,
          fillColor: AppColors.inputBg,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
        ),
      ),
    );
  }
}