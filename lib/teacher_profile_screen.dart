import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky;
import 'sticky_footer.dart';
import 'ui_components.dart'
    show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer, PbAlert, PbAlertType;

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

  // Cached, refreshed explicitly after edits (instead of refetching on every rebuild).
  late Future<DocumentSnapshot> _teacherFuture = _fire.collection('teachers').doc(widget.teacherId).get();

  // ---- clean state
  bool _cHidden = false;
  bool _cOpening = false;
  final GlobalKey _cMainKey = GlobalKey();
  final GlobalKey _cFootKey = GlobalKey();

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

  void _reloadTeacher() {
    if (!mounted) return;
    setState(() => _teacherFuture = _fire.collection('teachers').doc(widget.teacherId).get());
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
      _reloadTeacher();
      if (mounted) _showToast('Poza a fost actualizată.');
    } catch (e) {
      if (mounted) _showToast('Eroare încărcare: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _approveTeacher(String uid) async {
    try {
      await _fire.collection('teachers').doc(uid).update({'active': true});
      if (uid == widget.teacherId) _reloadTeacher();
      if (mounted) _showToast("PROFESOR APROBAT.", friendly: 'Profesorul a fost aprobat.');
    } catch (e) {
      if (mounted) _showToast("Eroare: $e", isError: true);
    }
  }

  Future<void> _rejectTeacher(String uid) async {
    try {
      await _fire.collection('teachers').doc(uid).delete();
      await _fire.collection('users').doc(uid).update({'role': 'student'});
      if (mounted) _showToast("PROFESOR RESPINS.", isError: true, friendly: 'Profesorul a fost respins.');
    } catch (e) {
      if (mounted) _showToast("Eroare: $e", isError: true);
    }
  }

  void _showToast(String msg, {bool isError = false, String? friendly}) {
    if (AppStyle.current.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(friendly ?? AppStyle.sentence(msg), style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: isError ? const Color(0xFFB4232A) : const Color(0xFF212529),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: Pb.radius),
        ),
      );
      return;
    }
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

  Future<void> _saveProfile(String uid, Map<String, TextEditingController> c) async {
    await _fire.collection('teachers').doc(uid).set({
      'name': c['name']!.text.trim(),
      'subject': c['subject']!.text.trim(),
      'experience': int.tryParse(c['exp']!.text.trim()) ?? 0,
      'contact': c['contact']!.text.trim(),
      'price': int.tryParse(c['price']!.text.trim()) ?? 50,
      'bio': c['bio']!.text.trim(),
    }, SetOptions(merge: true));
    await _fire.collection('users').doc(uid).set({'name': c['name']!.text.trim()}, SetOptions(merge: true));
    _reloadTeacher();
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) => s.isClean
          ? _buildClean(MediaQuery.of(context).size.width < 960)
          : _buildRetro(MediaQuery.of(context).size.width < 960),
    );
  }

  // ===========================================================================
  // CLEAN — cover banner profile, stat tiles, rating distribution, Stripe card
  // ===========================================================================
  static const Color _cGreen = Color(0xFF10B981);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cRose = Color(0xFFE5484D);
  static const Color _cBlue = Color(0xFF3B82F6);

  Color _subjectColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('matemat')) return _cRose;
    if (l.contains('info')) return Pb.primary;
    if (l.contains('fizic')) return const Color(0xFF8B5CF6);
    if (l.contains('chim')) return const Color(0xFF14B8A6);
    if (l.contains('bio')) return const Color(0xFF22A06B);
    if (l.contains('român')) return _cBlue;
    if (l.contains('englez')) return _cAmber;
    if (l.contains('francez')) return const Color(0xFF6366F1);
    if (l.contains('istorie')) return const Color(0xFFD97706);
    if (l.contains('geograf')) return const Color(0xFF0EA5E9);
    return Pb.primary;
  }

  BoxDecoration _deco({double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  Widget _cardTitle(IconData i, String t, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(i, size: 19, color: Pb.muted),
            const SizedBox(width: 9),
            Expanded(child: Text(t, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text))),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _buildClean(bool isMobile) {
    final currentUserId = _auth.currentUser?.uid;
    final bool isMyProfile = currentUserId == widget.teacherId;

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              blockers: [_cMainKey, _cFootKey],
              cardsHidden: _cHidden,
              onToggleCards: () => setState(() => _cHidden = !_cHidden),
              hideLabel: 'Ascunde profilul',
              showLabel: 'Arată profilul',
              child: StreamBuilder<DocumentSnapshot>(
                stream: _fire.collection('users').doc(widget.teacherId).snapshots(),
                builder: (context, userSnap) {
                  Widget body;
                  if (!userSnap.hasData) {
                    body = const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: Pb.primary)));
                  } else if (!userSnap.data!.exists) {
                    body = Container(
                      padding: const EdgeInsets.all(30),
                      decoration: _deco(r: 14),
                      child: Column(
                        children: [
                          Icon(Icons.person_off_outlined, size: 36, color: Pb.muted),
                          const SizedBox(height: 10),
                          Text('Profilul nu a fost găsit.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Pb.text)),
                          const SizedBox(height: 16),
                          PbButton(
                            text: 'Înapoi la profesori',
                            variant: PbVariant.outlineSecondary,
                            size: PbSize.sm,
                            onPressed: () => context.go('/materii'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final userData = userSnap.data!.data() as Map<String, dynamic>;
                    body = FutureBuilder<DocumentSnapshot>(
                      future: _teacherFuture,
                      builder: (context, teacherSnap) {
                        final t = (teacherSnap.data?.data() as Map<String, dynamic>?) ?? {};
                        return _cContent(userData, t, isMyProfile, currentUserId ?? '', isMobile);
                      },
                    );
                  }
                  return StickyFooterScroll(
                    controller: _scrollController,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1140),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 36, isMobile ? 12 : 24, 0),
                          child: KeyedSubtree(key: _cMainKey, child: _PrReveal(child: body)),
                        ),
                      ),
                    ),
                    footer: KeyedSubtree(key: _cFootKey, child: _cFooter(isMobile)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cContent(Map<String, dynamic> userData, Map<String, dynamic> t, bool isMyProfile, String uid, bool isMobile) {
    final bool hasStripeId = userData['stripeAccountId'] != null && userData['stripeAccountId'].toString().isNotEmpty;
    final bool isStripeReady = userData['isStripeActive'] == true;
    final image = '${t['image'] ?? userData['image'] ?? ''}';
    final name = '${t['name'] ?? userData['name'] ?? 'Profesor'}';
    final email = '${t['email'] ?? userData['email'] ?? ''}';
    final subject = '${t['subject'] ?? 'General'}';
    final experience = '${t['experience'] ?? 0}';
    final contact = '${t['contact'] ?? ''}';
    final price = '${t['price'] ?? 50}';
    final bio = '${t['bio'] ?? ''}'.trim().isEmpty
        ? 'Mentor dedicat pregătirii interactive și aprofundate. Sesiuni 1 la 1 personalizate, cu tablă interactivă live.'
        : '${t['bio']}'.trim();
    final bool isApproved = t['active'] == true;
    final c = _subjectColor(subject);

    final right = <Widget>[
      _cStats(price, experience, c, isMobile),
      const SizedBox(height: 16),
      _cAbout(bio, c),
      const SizedBox(height: 16),
      if (isMyProfile) ...[
        _cStripe(hasStripeId, isStripeReady, email, isMobile),
        const SizedBox(height: 16),
      ],
      _cReviews(c),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOwner) _cAdmin(),
        if (isMyProfile && !isApproved)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: PbAlert(
              type: PbAlertType.warning,
              icon: Icons.hourglass_top_rounded,
              child: Text(
                'Profilul tău așteaptă aprobarea unui administrator. Până atunci nu apare în lista publică de profesori.',
                style: TextStyle(fontSize: 14.5),
              ),
            ),
          ),
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: _cIdentity(name, email, image, subject, contact, isApproved, isMyProfile, uid, c, isMobile)),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
            ],
          )
        else ...[
          _cIdentity(name, email, image, subject, contact, isApproved, isMyProfile, uid, c, isMobile),
          const SizedBox(height: 16),
          ...right,
        ],
      ],
    );
  }

  Widget _cIdentity(String name, String email, String image, String subject, String contact, bool isApproved, bool isMyProfile,
      String uid, Color c, bool isMobile) {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final initials = parts.isEmpty ? '?' : parts.map((w) => w[0].toUpperCase()).join();
    const avatar = 108.0;

    Widget chip(String label, Color col, {IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 13, color: col), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: col)),
            ],
          ),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _deco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 104,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.withOpacity(0.85), Color.lerp(c, _cBlue, 0.45)!.withOpacity(0.7)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(_getSubjectIcon(subject), size: 26, color: Colors.white.withOpacity(0.7)),
                  ),
                ),
              ),
              Positioned(
                bottom: -avatar / 2,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: avatar,
                      height: avatar,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Pb.surface, shape: BoxShape.circle),
                      child: CircleAvatar(
                        backgroundColor: c.withOpacity(0.15),
                        backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
                        child: image.isEmpty
                            ? Text(initials, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: c))
                            : null,
                      ),
                    ),
                    if (isMyProfile)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _uploading ? null : () => _changePhoto(uid),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Pb.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Pb.surface, width: 3),
                            ),
                            child: _uploading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: avatar / 2 + 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Text(name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(email, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    chip(subject, c),
                    isApproved
                        ? chip('Verificat', _cGreen, icon: Icons.verified)
                        : chip('În așteptare', _cAmber, icon: Icons.hourglass_top_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 18, color: Pb.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contact.isEmpty || contact == 'N/A' ? 'Telefon nespecificat' : contact,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text),
                        ),
                      ),
                      if (contact.isNotEmpty && contact != 'N/A')
                        IconButton(
                          tooltip: 'Copiază',
                          splashRadius: 18,
                          icon: Icon(Icons.copy_rounded, size: 17, color: Pb.muted),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: contact));
                            _showToast('Copiat.', friendly: 'Numărul a fost copiat.');
                          },
                        )
                      else
                        const SizedBox(height: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isMyProfile)
                  PbButton(
                    text: 'Editează profilul',
                    icon: Icons.edit_outlined,
                    variant: PbVariant.outlineSecondary,
                    fullWidth: true,
                    onPressed: () => _openEditDialog(uid, isMobile),
                  )
                else
                  PbButton(
                    text: 'Scrie un mesaj',
                    icon: Icons.chat_bubble_outline,
                    fullWidth: true,
                    loading: _cOpening,
                    onPressed: _cOpening
                        ? null
                        : () async {
                            setState(() => _cOpening = true);
                            try {
                              final chatId = await _openOrCreateChat(context, widget.teacherId, name);
                              if (mounted && chatId.isNotEmpty) context.push('/chat/$chatId', extra: name);
                            } finally {
                              if (mounted) setState(() => _cOpening = false);
                            }
                          },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cStats(String price, String exp, Color c, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').doc(widget.teacherId).collection('reviews').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final ratings = docs.map((d) => ((d.data() as Map)['rating'] as num?)?.toDouble() ?? 0).toList();
        final avg = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
        final expN = int.tryParse(exp) ?? 0;

        Widget tile(IconData i, String label, String value, String sub, Color col) => Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: _deco(r: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                        child: Icon(i, size: 16, color: col),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 17 : 21, fontWeight: FontWeight.w700, color: Pb.text)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.muted)),
                ],
              ),
            );

        return Row(
          children: [
            Expanded(child: tile(Icons.payments_outlined, 'Tarif', '$price RON', 'pe oră', Pb.primary)),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(child: tile(Icons.military_tech_outlined, 'Experiență', expN == 0 ? 'Nou' : '$expN ${expN == 1 ? 'an' : 'ani'}', 'de predare', _cAmber)),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: tile(
                Icons.star_rounded,
                'Rating',
                ratings.isEmpty ? '–' : avg.toStringAsFixed(1),
                ratings.isEmpty ? 'fără recenzii' : '${ratings.length} ${ratings.length == 1 ? 'recenzie' : 'recenzii'}',
                _cRose,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cAbout(String bio, Color c) {
    final features = [
      (Icons.draw_outlined, 'Tablă interactivă live', _cBlue),
      (Icons.school_outlined, 'Pregătire pentru Bac', Pb.primary),
      (Icons.quiz_outlined, 'Teme și probleme', _cAmber),
      (Icons.forum_outlined, 'Feedback 1 la 1', _cRose),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _deco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.person_outline, 'Despre'),
          Text(bio, style: TextStyle(fontSize: 15, color: Pb.text, height: 1.65)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in features)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: f.$3.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.$1, size: 16, color: f.$3),
                      const SizedBox(width: 7),
                      Text(f.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Pb.text)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cStripe(bool hasStripeId, bool isStripeReady, String email, bool isMobile) {
    final action = !hasStripeId
        ? PbButton(text: 'Configurează plățile', icon: Icons.account_balance_wallet_outlined, loading: _isLoadingStripe, onPressed: _isLoadingStripe ? null : _setupStripeAccount)
        : (!isStripeReady
            ? PbButton(text: 'Finalizează configurarea', icon: Icons.arrow_forward, loading: _isLoadingStripe, onPressed: _isLoadingStripe ? null : _setupStripeAccount)
            : PbButton(
                text: 'Deschide panoul Stripe',
                icon: Icons.open_in_new,
                variant: PbVariant.success,
                loading: _isLoadingStripe,
                onPressed: _isLoadingStripe ? null : _openStripeDashboard,
              ));

    final reset = PbLink(
      text: 'Resetează parola',
      fontSize: 13.5,
      onTap: () async {
        await _auth.sendPasswordResetEmail(email: email);
        _showToast('RESET LOG TRANSMITTED.', friendly: 'Ți-am trimis un email pentru resetarea parolei.');
      },
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _deco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle(
            Icons.account_balance_wallet_outlined,
            'Plăți',
            trailing: _isCheckingStatus
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary))
                : Text('prin Stripe', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
          ),
          PbAlert(
            type: isStripeReady ? PbAlertType.success : PbAlertType.warning,
            icon: isStripeReady ? Icons.verified_outlined : Icons.info_outline,
            child: Text(
              isStripeReady
                  ? 'Contul de plăți e activ. Poți primi bani pentru lecții.'
                  : (hasStripeId
                      ? 'Configurarea nu e completă. Termină pașii din Stripe ca să poți primi plăți.'
                      : 'Nu ai încă un cont de plăți. Configurează-l ca elevii să-ți poată plăti lecțiile.'),
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
          const SizedBox(height: 14),
          if (isMobile) ...[
            action,
            const SizedBox(height: 10),
            Center(child: reset),
          ] else
            Row(children: [action, const Spacer(), reset]),
        ],
      ),
    );
  }

  Widget _cReviews(Color c) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').doc(widget.teacherId).collection('reviews').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final ratings = docs.map((d) => (((d.data() as Map)['rating'] as num?) ?? 0).round().clamp(0, 5).toInt()).toList();
        final avg = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
        final counts = List<int>.generate(6, (i) => ratings.where((r) => r == i).length);

        Widget stars(num v, {double size = 16}) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  v >= i + 1 ? Icons.star_rounded : (v >= i + 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
                  size: size,
                  color: _cAmber,
                ),
              ),
            );

        final summary = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(ratings.isEmpty ? '–' : avg.toStringAsFixed(1),
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: Pb.text, height: 1)),
                const SizedBox(height: 6),
                stars(avg),
                const SizedBox(height: 4),
                Text('${ratings.length} ${ratings.length == 1 ? 'recenzie' : 'recenzii'}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  for (var s = 5; s >= 1; s--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          SizedBox(width: 14, child: Text('$s', style: TextStyle(fontSize: 12.5, color: Pb.muted))),
                          const Icon(Icons.star_rounded, size: 13, color: _cAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: ratings.isEmpty ? 0 : counts[s] / ratings.length),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 7, color: _cAmber, backgroundColor: Pb.gray),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: Text('${counts[s]}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _deco(r: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardTitle(
                Icons.reviews_outlined,
                'Recenzii',
                trailing: docs.length > 3
                    ? PbLink(text: 'Toate (${docs.length})', fontSize: 13.5, onTap: () => context.push('/toate-recenziile/${widget.teacherId}'))
                    : null,
              ),
              if (!snap.hasData)
                const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)))
              else if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.star_outline_rounded, size: 22, color: Pb.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Încă nu există recenzii. După prima lecție, elevii pot lăsa o părere aici.',
                            style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.4)),
                      ),
                    ],
                  ),
                )
              else ...[
                summary,
                const SizedBox(height: 16),
                Container(height: 1, color: Pb.border),
                for (final d in docs.take(3))
                  Builder(builder: (context) {
                    final r = d.data() as Map<String, dynamic>;
                    final ts = r['createdAt'];
                    final dt = ts is Timestamp ? ts.toDate() : null;
                    final author = '${r['studentName'] ?? r['author'] ?? r['name'] ?? 'Elev'}';
                    return Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Pb.border))),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: c.withOpacity(0.14),
                            child: Text(author.isEmpty ? '?' : author[0].toUpperCase(),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(author, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                                    ),
                                    if (dt != null)
                                      Text(
                                        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
                                        style: TextStyle(fontSize: 12, color: Pb.muted),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                stars((r['rating'] as num?) ?? 0, size: 14),
                                if ('${r['comment'] ?? ''}'.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('${r['comment']}', style: TextStyle(fontSize: 14, color: Pb.text, height: 1.5)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cAdmin() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fire.collection('teachers').where('active', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        final pending = snapshot.data?.docs ?? [];
        if (pending.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: _deco(r: 16).copyWith(border: Border.all(color: _cBlue.withOpacity(0.45))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardTitle(
                Icons.admin_panel_settings_outlined,
                'Profesori în așteptare',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(color: _cBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('${pending.length}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _cBlue)),
                ),
              ),
              for (final doc in pending)
                Builder(builder: (context) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${d['name'] ?? 'Fără nume'}', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text)),
                              Text('${d['subject'] ?? ''}  ${d['email'] ?? ''}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                            ],
                          ),
                        ),
                        PbButton(text: 'Aprobă', icon: Icons.check, variant: PbVariant.success, size: PbSize.sm, onPressed: () => _approveTeacher(doc.id)),
                        const SizedBox(width: 6),
                        PbButton(text: 'Respinge', variant: PbVariant.outlineDanger, size: PbSize.sm, onPressed: () => _rejectTeacher(doc.id)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cEditDialog(String uid, Map<String, dynamic> data) async {
    final c = {
      'name': TextEditingController(text: data['name'] ?? ''),
      'subject': TextEditingController(text: data['subject'] ?? ''),
      'exp': TextEditingController(text: '${data['experience'] ?? ''}'),
      'contact': TextEditingController(text: data['contact'] ?? ''),
      'price': TextEditingController(text: '${data['price'] ?? 50}'),
      'bio': TextEditingController(text: data['bio'] ?? ''),
    };
    var saving = false;

    Widget field(String key, String label, IconData icon, {TextInputType? type, int lines = 1, String? suffix}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
              const SizedBox(height: 5),
              TextField(
                controller: c[key],
                keyboardType: type,
                maxLines: lines,
                style: TextStyle(fontSize: 15, color: Pb.text),
                cursorColor: Pb.primary,
                decoration: Pb.input().copyWith(
                  prefixIcon: lines == 1 ? Icon(icon, size: 18, color: Pb.muted) : null,
                  suffixText: suffix,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ],
          ),
        );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Pb.surface,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Pb.border)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(child: Text('Editează profilul', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Pb.text))),
                      IconButton(icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                ),
                Container(height: 1, color: Pb.border),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Column(
                      children: [
                        field('name', 'Nume complet', Icons.person_outline),
                        field('subject', 'Materia', Icons.auto_stories_outlined),
                        Row(
                          children: [
                            Expanded(child: field('exp', 'Experiență', Icons.military_tech_outlined, type: TextInputType.number, suffix: 'ani')),
                            const SizedBox(width: 12),
                            Expanded(child: field('price', 'Tarif', Icons.payments_outlined, type: TextInputType.number, suffix: 'RON/oră')),
                          ],
                        ),
                        field('contact', 'Telefon', Icons.phone_outlined, type: TextInputType.phone),
                        field('bio', 'Despre tine', Icons.notes, lines: 4),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: Pb.border),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
                      const SizedBox(width: 8),
                      PbButton(
                        text: 'Salvează',
                        icon: Icons.check,
                        loading: saving,
                        onPressed: saving
                            ? null
                            : () async {
                                setLocal(() => saving = true);
                                try {
                                  await _saveProfile(uid, c);
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  _showToast('Saved.', friendly: 'Profilul a fost actualizat.');
                                } catch (e) {
                                  setLocal(() => saving = false);
                                  _showToast('Eroare: $e', isError: true);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cFooter(bool isMobile) {
    final links = [
      PbLink(text: 'Termeni și condiții', fontSize: 14, onTap: () => context.go('/termeni-si-conditii')),
      PbLink(text: 'Politica de confidențialitate', fontSize: 14, onTap: () => context.go('/politica-confidentialitate')),
    ];
    final copy = Text('© 2026 iMeditații', style: TextStyle(color: Pb.muted, fontSize: 14));
    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: PbContainer(
        child: isMobile
            ? Column(children: [
                copy,
                const SizedBox(height: 10),
                Wrap(spacing: 18, runSpacing: 8, alignment: WrapAlignment.center, children: links),
              ])
            : Row(children: [copy, const Spacer(), ...links.expand((l) => [const SizedBox(width: 22), l])]),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(bool isMobile) {
    final currentUserId = _auth.currentUser?.uid;
    final bool isMyProfile = currentUserId == widget.teacherId;

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
                if (!userSnap.data!.exists) {
                  return Center(
                      child: Text('LOG ERROR: PROFILE NOT FOUND.', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)));
                }

                final userData = userSnap.data!.data() as Map<String, dynamic>;
                final bool hasStripeId = userData.containsKey('stripeAccountId') &&
                    userData['stripeAccountId'] != null &&
                    userData['stripeAccountId'].toString().isNotEmpty;
                final bool isStripeReady = userData['isStripeActive'] == true;

                return FutureBuilder<DocumentSnapshot>(
                  future: _teacherFuture,
                  builder: (context, teacherSnap) {
                    final teacherData = (teacherSnap.data?.data() as Map<String, dynamic>?) ?? {};
                    final image = teacherData['image'] ?? userData['image'] ?? '';
                    final name = teacherData['name'] ?? userData['name'] ?? 'MASTER UNKNOWN';
                    final email = teacherData['email'] ?? userData['email'] ?? 'N/A';
                    final subject = teacherData['subject'] ?? 'GENERAL';
                    final experience = teacherData['experience']?.toString() ?? '0';
                    final contact = teacherData['contact'] ?? 'N/A';
                    final price = teacherData['price']?.toString() ?? '50';
                    final bio = teacherData['bio'] ??
                        'Mentor dedicat pregătirii interactive și aprofundate. Sesiuni 1-la-1 personalizate cu tablă interactivă live.';
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
                                        child: _buildIdentityCard(
                                            name, email, image, subject, contact, isMyProfile, currentUserId ?? '', isMobile),
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
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, letterSpacing: 0.5),
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
                Icon(isStripeReady ? Icons.check_circle : Icons.warning,
                    color: isStripeReady ? const Color(0xFF55EFC4) : AppColors.mustard, size: 22),
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
                  RetroButton(
                      text: "INITIALIZE WALLET",
                      isFullWidth: true,
                      bgColor: AppColors.sky,
                      textColor: Colors.white,
                      onPressed: _setupStripeAccount,
                      isLoading: _isLoadingStripe)
                else if (hasStripeId && !isStripeReady)
                  RetroButton(
                      text: "COMPLETE SETUP",
                      isFullWidth: true,
                      bgColor: AppColors.sky,
                      textColor: Colors.white,
                      onPressed: _setupStripeAccount,
                      isLoading: _isLoadingStripe)
                else
                  RetroButton(
                      text: "OPEN DASHBOARD",
                      isFullWidth: true,
                      bgColor: AppColors.forest,
                      textColor: Colors.white,
                      onPressed: _openStripeDashboard,
                      isLoading: _isLoadingStripe),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _auth.sendPasswordResetEmail(email: email);
                      _showToast("RESET LOG TRANSMITTED.");
                    },
                    child: const Text("RESET ACCESS KEY",
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                if (!hasStripeId)
                  RetroButton(
                      text: "INITIALIZE WALLET", bgColor: AppColors.sky, textColor: Colors.white, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                else if (hasStripeId && !isStripeReady)
                  RetroButton(
                      text: "COMPLETE SETUP", bgColor: AppColors.sky, textColor: Colors.white, onPressed: _setupStripeAccount, isLoading: _isLoadingStripe)
                else
                  RetroButton(
                      text: "OPEN DASHBOARD", bgColor: AppColors.forest, textColor: Colors.white, onPressed: _openStripeDashboard, isLoading: _isLoadingStripe),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await _auth.sendPasswordResetEmail(email: email);
                    _showToast("RESET LOG TRANSMITTED.");
                  },
                  child: const Text("RESET KEY",
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
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
                    child: Text("NO REVIEWS LOGGED IN SYSTEM YET.",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMuted)),
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
                      Row(
                          children: List.generate(
                              5, (i) => Icon(i < (rData['rating'] ?? 0) ? Icons.star : Icons.star_border, color: AppColors.sunset, size: 16))),
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
                    child: Text("ACCESS ALL REVIEWS (${docs.length}) →",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.sky)),
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
    if (!mounted) return;

    if (AppStyle.current.isClean) {
      await _cEditDialog(uid, data);
      return;
    }

    final c = {
      'name': TextEditingController(text: data['name'] ?? ''),
      'subject': TextEditingController(text: data['subject'] ?? ''),
      'exp': TextEditingController(text: '${data['experience'] ?? ''}'),
      'contact': TextEditingController(text: data['contact'] ?? ''),
      'price': TextEditingController(text: '${data['price'] ?? 50}'),
      'bio': TextEditingController(text: data['bio'] ?? ''),
    };

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
        title: Text('UPDATE MASTER DATA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.ink)),
        content: SizedBox(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledInput(c['name']!, 'FULL NAME'),
                _styledInput(c['subject']!, 'DISCIPLINE'),
                _styledInput(c['exp']!, 'EXP YEARS', type: TextInputType.number),
                _styledInput(c['contact']!, 'CONTACT LINK / PHONE'),
                _styledInput(c['price']!, 'HOURLY RATE (RON)', type: TextInputType.number),
                _styledInput(c['bio']!, 'DESPRE MENTOR / BIO', maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))),
          RetroButton(
            text: 'SAVE DATA',
            bgColor: AppColors.sunset,
            textColor: Colors.white,
            onPressed: () async {
              await _saveProfile(uid, c);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
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

class _PrReveal extends StatefulWidget {
  final Widget child;
  const _PrReveal({required this.child});

  @override
  State<_PrReveal> createState() => _PrRevealState();
}

class _PrRevealState extends State<_PrReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a), child: widget.child),
    );
  }
}