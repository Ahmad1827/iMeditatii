import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'clean_kit.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'sticky_footer.dart';
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, PbAlert, PbAlertType;

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
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
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
                      Icon(widget.icon, color: effectiveTextColor, size: widget.fontSize + 2),
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

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  bool _uploading = false;
  bool _loading = false;

  String? _name = '';
  String? _email = '';
  String? _bio = '';
  String? _contact = '';
  String? _imageUrl;

  // ---- progress data (clean)
  List<String> _solvedIds = [];
  Set<String> _localSolved = {};
  String _role = 'student';
  bool _hidden = false;
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  static final RegExp _progressKey = RegExp(r'^(.+?)_(\d+)_(.+)$');

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false, String? friendly}) {
    if (AppStyle.current.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(friendly ?? AppStyle.sentence(message), style: const TextStyle(color: Colors.white))),
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
        content: Text(
          message.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        backgroundColor: isError ? AppColors.sunset : AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
    );
  }

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

  Future<void> _loadUserProfile() async {
    setState(() => _loading = true);
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _name = data['name'] ?? 'PLAYER';
      _bio = data['bio'] ?? 'Gata să cucerească quest-urile zilnice și să acumuleze EXP.';
      _contact = data['contact'] ?? 'N/A';
      _imageUrl = data['image'];
      _solvedIds = ((data['solvedIds'] as List?) ?? const []).map((e) => '$e').toList();
      _role = '${data['role'] ?? 'student'}';
    }

    if (widget.userId == _auth.currentUser?.uid) {
      _email = _auth.currentUser?.email ?? 'N/A';
      try {
        final prefs = await SharedPreferences.getInstance();
        _localSolved = prefs.getKeys().where((k) => _progressKey.hasMatch(k) && prefs.get(k) == true).toSet();
      } catch (_) {}
    } else {
      _email ??= doc.data()?['email'] ?? 'N/A';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    if (widget.userId != _auth.currentUser?.uid) return;

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploading = true);
    final uid = _auth.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('profile_pics/$uid.jpg');

    try {
      final bytes = await file.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).set({'image': url}, SetOptions(merge: true));

      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
      _showSnackbar('AVATAR UPDATED.', friendly: 'Poza a fost actualizată.');
    } catch (e) {
      _showSnackbar('ERROR UPLOADING: $e', isError: true, friendly: 'Nu am putut încărca poza. Încearcă din nou.');
      setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile({String? newName, String? newBio, String? newContact}) async {
    if (widget.userId != _auth.currentUser?.uid) return;
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'name': newName ?? _name,
      'bio': newBio ?? _bio,
      'contact': newContact ?? _contact,
    }, SetOptions(merge: true));

    _showSnackbar('PROFILE LOG UPDATED.', friendly: 'Profilul a fost actualizat.');
    _loadUserProfile();
  }

  Future<void> _applyPassword(String current, String next) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(email: user.email!, password: current);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(next);
  }

  Future<void> _changePassword() async {
    if (widget.userId != _auth.currentUser?.uid) return;
    if (AppStyle.current.isClean) return _cChangePassword();

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
        title: Text('UPDATE ACCESS KEY', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _styledInput(currentCtrl, 'CURRENT KEY', isPassword: true),
              _styledInput(newCtrl, 'NEW KEY', isPassword: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))),
          RetroButton(
            text: 'CONFIRM',
            bgColor: AppColors.sky,
            textColor: Colors.white,
            onPressed: () {
              if (formKey.currentState!.validate()) context.pop(true);
            },
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await _applyPassword(currentCtrl.text.trim(), newCtrl.text.trim());
      _showSnackbar('ACCESS KEY UPDATED SUCCESSFULLY.');
    } catch (e) {
      _showSnackbar('ERROR UPDATING KEY: $e', isError: true);
    }
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('matemat')) return Icons.functions;
    if (s.contains('info')) return Icons.data_object;
    if (s.contains('fizic')) return Icons.bolt;
    if (s.contains('chim')) return Icons.science;
    if (s.contains('român')) return Icons.menu_book;
    if (s.contains('englez')) return Icons.language;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final w = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(w < 900) : _buildRetro(w < 900);
      },
    );
  }

  // ===========================================================================
  // CLEAN — cover banner, stat tiles, ACHIEVEMENTS, progress per subject.
  // Works for your own profile and for other players. Dragon scene.
  // ===========================================================================
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cBlue = Color(0xFF3B82F6);

  Set<String> get _allSolved => {..._solvedIds, ..._localSolved};

  Map<String, int> get _bySubject {
    final map = <String, int>{};
    for (final id in _allSolved) {
      final m = _progressKey.firstMatch(id);
      if (m == null) continue;
      map[m.group(1)!] = (map[m.group(1)!] ?? 0) + 1;
    }
    return map;
  }

  Widget _buildClean(bool isMobile) {
    final isMe = widget.userId == _auth.currentUser?.uid;
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              scene: HomeScene.fantasy,
              blockers: [_mainKey, _footKey],
              cardsHidden: _hidden,
              onToggleCards: () => setState(() => _hidden = !_hidden),
              hideLabel: 'Ascunde profilul',
              showLabel: 'Arată profilul',
              child: StickyFooterScroll(
                controller: _scrollController,
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 36, isMobile ? 12 : 24, 0),
                      child: KeyedSubtree(
                        key: _mainKey,
                        child: _loading
                            ? const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: Pb.primary)))
                            : CkReveal(child: _cContent(isMe, isMobile)),
                      ),
                    ),
                  ),
                ),
                footer: KeyedSubtree(key: _footKey, child: CkFooter(isMobile: isMobile)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cContent(bool isMe, bool isMobile) {
    final by = _bySubject;
    final total = _allSolved.length;
    final level = total ~/ 5 + 1;
    final rank = total > 10 ? 'Avansat' : (total > 3 ? 'Intermediar' : 'Începător');
    final color = _role == 'teacher' ? _cBlue : Pb.primary;
    final badges = ckAchievements(total, by);
    final earned = badges.where((b) => b.earned).length;

    Widget tile(IconData i, String label, String value, String sub, Color col) => Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: ckDeco(r: 14),
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
                  Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted))),
                ],
              ),
              const SizedBox(height: 10),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isMobile ? 17 : 21, fontWeight: FontWeight.w700, color: Pb.text)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.muted)),
            ],
          ),
        );

    final stats = Row(
      children: [
        Expanded(child: tile(Icons.check_circle_outline, 'Rezolvate', '$total', total == 1 ? 'problemă' : 'probleme', Pb.primary)),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(child: tile(Icons.bolt, 'Experiență', '${total * 50} XP', 'nivelul $level', _cAmber)),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(child: tile(Icons.military_tech_outlined, 'Rang', rank, '$earned/${badges.length} realizări', _cBlue)),
      ],
    );

    final achievements = Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ckCardTitle(Icons.emoji_events_outlined, 'Realizări', trailing: Text('$earned din ${badges.length}', style: TextStyle(fontSize: 13, color: Pb.muted))),
          CkBadgeGrid(items: badges),
        ],
      ),
    );

    final entries = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final best = entries.isEmpty ? 1 : entries.first.value;
    final progress = Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ckCardTitle(
            Icons.trending_up,
            'Progres pe materii',
            trailing: isMe ? GestureDetector(onTap: () => context.go('/exercitii'), child: Text('Exersează', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.link))) : null,
          ),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
              child: Text(isMe ? 'Nu ai rezolvat nicio problemă încă. Prima apare aici.' : 'Încă nicio problemă rezolvată.',
                  style: TextStyle(fontSize: 14, color: Pb.muted)),
            )
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(ckSubjectIcon(e.key), size: 16, color: ckSubjectColor(e.key)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Pb.text))),
                        Text('${e.value}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Pb.text)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: e.value / best),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 7, color: ckSubjectColor(e.key), backgroundColor: Pb.gray),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );

    final about = Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ckCardTitle(Icons.person_outline, 'Despre'),
          Text(_bio == null || _bio!.trim().isEmpty ? 'Nicio descriere încă.' : _bio!, style: TextStyle(fontSize: 14.5, color: Pb.text, height: 1.6)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.phone_outlined, size: 18, color: Pb.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (_contact == null || _contact!.isEmpty || _contact == 'N/A') ? 'Telefon nespecificat' : _contact!,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final security = Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ckCardTitle(Icons.lock_outline, 'Securitate'),
          Text('Schimbă parola contului. Îți cerem parola curentă ca să confirmi că ești tu.', style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45)),
          const SizedBox(height: 14),
          PbButton(text: 'Schimbă parola', icon: Icons.lock_reset, variant: PbVariant.outlineSecondary, fullWidth: true, onPressed: _cChangePassword),
        ],
      ),
    );

    final cover = CkCover(
      color: color,
      name: _name ?? '',
      image: _imageUrl ?? '',
      isMobile: isMobile,
      topRight: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(999)),
        child: Text('Nivelul $level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
      ),
      avatarOverlay: isMe
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Pb.primary, shape: BoxShape.circle, border: Border.all(color: Pb.surface, width: 3)),
                  child: _uploading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_name ?? 'Elev', style: TextStyle(fontSize: isMobile ? 24 : 30, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(_role == 'teacher' ? 'Profesor' : 'Elev', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
              ),
              if ((_email ?? '').isNotEmpty && _email != 'N/A') Text(_email!, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
            ],
          ),
          if (isMe) ...[
            const SizedBox(height: 16),
            PbButton(text: 'Editează profilul', icon: Icons.edit_outlined, variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _cEditDialog),
          ],
        ],
      ),
    );

    final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [stats, const SizedBox(height: 14), achievements, const SizedBox(height: 14), progress]);
    final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [about, if (isMe) ...[const SizedBox(height: 14), security]]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cover,
        const SizedBox(height: 14),
        if (isMobile) ...[left, const SizedBox(height: 14), right] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 14), SizedBox(width: 320, child: right)]),
      ],
    );
  }

  Future<void> _cEditDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    final contactCtrl = TextEditingController(text: _contact == 'N/A' ? '' : _contact);

    Widget field(TextEditingController c, String label, IconData icon, {int lines = 1, TextInputType? type}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
              const SizedBox(height: 5),
              TextField(
                controller: c,
                maxLines: lines,
                keyboardType: type,
                style: TextStyle(fontSize: 15, color: Pb.text),
                cursorColor: Pb.primary,
                decoration: Pb.input().copyWith(
                  prefixIcon: lines == 1 ? Icon(icon, size: 18, color: Pb.muted) : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ],
          ),
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Pb.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Pb.border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                child: Row(
                  children: [
                    Expanded(child: Text('Editează profilul', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Pb.text))),
                    IconButton(icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(ctx).pop(false)),
                  ],
                ),
              ),
              Container(height: 1, color: Pb.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Column(
                    children: [
                      field(nameCtrl, 'Nume complet', Icons.person_outline),
                      field(contactCtrl, 'Telefon', Icons.phone_outlined, type: TextInputType.phone),
                      field(bioCtrl, 'Despre tine', Icons.notes, lines: 4),
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
                    PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
                    const SizedBox(width: 8),
                    PbButton(text: 'Salvează', icon: Icons.check, onPressed: () => Navigator.of(ctx).pop(true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      await _saveProfile(newName: nameCtrl.text.trim(), newBio: bioCtrl.text.trim(), newContact: contactCtrl.text.trim());
    }
  }

  Future<void> _cChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? error;
    var saving = false;
    var show = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Pb.surface,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Pb.border)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(child: Text('Schimbă parola', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Pb.text))),
                      IconButton(icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                ),
                Container(height: 1, color: Pb.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Parola curentă', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: currentCtrl,
                        obscureText: !show,
                        style: TextStyle(fontSize: 15, color: Pb.text),
                        cursorColor: Pb.primary,
                        decoration: Pb.input().copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
                      ),
                      const SizedBox(height: 12),
                      Text('Parola nouă', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: newCtrl,
                        obscureText: !show,
                        style: TextStyle(fontSize: 15, color: Pb.text),
                        cursorColor: Pb.primary,
                        decoration: Pb.input(hint: 'Cel puțin 6 caractere').copyWith(
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          suffixIcon: IconButton(
                            splashRadius: 18,
                            icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: Pb.muted),
                            onPressed: () => setLocal(() => show = !show),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(error!, style: const TextStyle(fontSize: 14))),
                      ],
                    ],
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
                        text: 'Schimbă parola',
                        icon: Icons.check,
                        loading: saving,
                        onPressed: saving
                            ? null
                            : () async {
                                if (currentCtrl.text.isEmpty) {
                                  setLocal(() => error = 'Scrie parola curentă.');
                                  return;
                                }
                                if (newCtrl.text.trim().length < 6) {
                                  setLocal(() => error = 'Parola nouă trebuie să aibă cel puțin 6 caractere.');
                                  return;
                                }
                                setLocal(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  await _applyPassword(currentCtrl.text.trim(), newCtrl.text.trim());
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  _showSnackbar('ACCESS KEY UPDATED.', friendly: 'Parola a fost schimbată.');
                                } on FirebaseAuthException catch (e) {
                                  setLocal(() {
                                    saving = false;
                                    error = (e.code == 'wrong-password' || e.code == 'invalid-credential')
                                        ? 'Parola curentă nu e corectă.'
                                        : (e.code == 'weak-password' ? 'Parola nouă e prea slabă.' : (e.message ?? 'Nu am putut schimba parola.'));
                                  });
                                } catch (e) {
                                  setLocal(() {
                                    saving = false;
                                    error = 'Nu am putut schimba parola. Încearcă din nou.';
                                  });
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

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(bool isMobile) {
    final isCurrentUser = widget.userId == _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
                : Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 20 : 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isMobile)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 330,
                                      child: _buildIdentityCard(isCurrentUser, isMobile),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildStatsHUD(isMobile),
                                          const SizedBox(height: 20),
                                          _buildProgressSection(),
                                          if (isCurrentUser) ...[
                                            const SizedBox(height: 20),
                                            _buildSettingsSection(isMobile),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildIdentityCard(isCurrentUser, isMobile),
                                    const SizedBox(height: 20),
                                    _buildStatsHUD(isMobile),
                                    const SizedBox(height: 20),
                                    _buildProgressSection(),
                                    if (isCurrentUser) ...[
                                      const SizedBox(height: 20),
                                      _buildSettingsSection(isMobile),
                                    ],
                                  ],
                                ),
                              SizedBox(height: isMobile ? 28 : 48),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(bool isCurrentUser, bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: isMobile ? 20 : 24,
      shadowOffset: isMobile ? 4 : 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: isMobile ? 96 : 110,
                height: isMobile ? 96 : 110,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
                  image: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? DecorationImage(image: CachedNetworkImageProvider(_imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageUrl == null || _imageUrl!.isEmpty ? Icon(Icons.person, size: isMobile ? 48 : 54, color: AppColors.ink) : null,
              ),
              if (isCurrentUser)
                GestureDetector(
                  onTap: _uploading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: _uploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(Icons.camera_alt, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Container(
                color: AppColors.forest,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: const Text("PLAYER ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
              ),
              Container(
                color: AppColors.mustard,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text("APPRENTICE", style: TextStyle(color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _name?.toUpperCase() ?? 'UNKNOWN PLAYER',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 22 : 24, fontWeight: FontWeight.w900, height: 1.1, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            _email ?? 'N/A',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("BIO & LORE:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                  _bio ?? 'NO BIO LOGGED.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.ink),
                const SizedBox(width: 8),
                Text(
                  _contact?.toUpperCase() ?? 'N/A',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isCurrentUser)
            RetroButton(
              text: "EDIT PROFILE DATA",
              icon: Icons.edit,
              isFullWidth: true,
              bgColor: AppColors.cloud,
              textColor: AppColors.ink,
              onPressed: () => _openEditDialog(isMobile),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsHUD(bool isMobile) {
    return FutureBuilder<Map<String, int>>(
      future: _getProgressPerSubject(),
      builder: (context, snapshot) {
        int totalCleared = 0;
        if (snapshot.hasData) {
          totalCleared = snapshot.data!.values.fold(0, (sum, count) => sum + count);
        }

        final expGained = totalCleared * 50;
        final rankTitle = totalCleared > 10 ? "GOLD VANGUARD" : (totalCleared > 3 ? "SILVER RANK" : "NOVICE APPRENTICE");

        if (isMobile) {
          return Row(
            children: [
              Expanded(child: _buildStatTile("CLEARED", "$totalCleared", Icons.check_circle, AppColors.forest, isMobile)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatTile("EXP", "$expGained XP", Icons.bolt, AppColors.sunset, isMobile)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatTile("RANK", totalCleared > 10 ? "GOLD" : (totalCleared > 3 ? "SILVER" : "NOVICE"), Icons.military_tech, AppColors.mustard, isMobile)),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildStatTile("QUESTS CLEARED", "$totalCleared SOLVED", Icons.check_circle, AppColors.forest, isMobile)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile("EXP ACCUMULATED", "$expGained XP", Icons.bolt, AppColors.sunset, isMobile)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile("GUILD RANK", rankTitle, Icons.military_tech, AppColors.mustard, isMobile)),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, bool isMobile) {
    final isMustard = color == AppColors.mustard;
    final textColor = isMustard && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 2.5 : 3, isMobile ? 2.5 : 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 4 : 6),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Icon(icon, size: isMobile ? 14 : 16, color: isMustard && AppColors.isDark ? const Color(0xFF10161A) : Colors.white),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: isMobile ? 9 : 10, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            value.toUpperCase(),
            style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SKILL & QUEST PROGRESSION",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.ink),
              ),
              GestureDetector(
                onTap: () => context.go('/exercitii'),
                child: Text(
                  "ENTER ARENA >",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.sunset, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<Map<String, int>>(
            future: _getProgressPerSubject(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.sunset));
              }

              final progress = snapshot.data ?? {};
              final defaultSubjects = ['Matematică', 'Informatică', 'Fizică', 'Chimie', 'Limba Română', 'Engleză'];

              return Column(
                children: defaultSubjects.map((subj) {
                  final cleared = progress[subj] ?? 0;
                  final icon = _getSubjectIcon(subj);
                  final progressPercent = (cleared / 10.0).clamp(0.0, 1.0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 18, color: AppColors.ink),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                subj.toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              color: cleared > 0 ? AppColors.forest : AppColors.border,
                              child: Text(
                                "$cleared / 10 SOLVED",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: AppColors.border.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(cleared > 0 ? AppColors.forest : AppColors.textMuted),
                            minHeight: 6,
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

  Widget _buildSettingsSection(bool isMobile) {
    if (isMobile) {
      return RetroBlock(
        bgColor: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        padding: 16,
        shadowOffset: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "SYSTEM SECURITY CONSOLE",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              "UPDATE YOUR SECRET ACCESS KEY TO SECURE REPUTATION.",
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            RetroButton(
              text: "CHANGE KEY",
              icon: Icons.lock_reset,
              bgColor: AppColors.cardBg,
              textColor: AppColors.ink,
              fontSize: 12,
              isFullWidth: true,
              padding: const EdgeInsets.symmetric(vertical: 10),
              onPressed: _changePassword,
            ),
          ],
        ),
      );
    }

    return RetroBlock(
      bgColor: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
      padding: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SYSTEM SECURITY CONSOLE",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                const Text(
                  "UPDATE YOUR SECRET ACCESS KEY TO SECURE REPUTATION.",
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          RetroButton(
            text: "CHANGE KEY",
            icon: Icons.lock_reset,
            bgColor: AppColors.cardBg,
            textColor: AppColors.ink,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onPressed: _changePassword,
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(bool isMobile) async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    final contactCtrl = TextEditingController(text: _contact);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
        title: Text('EDIT PROFILE DATA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.ink)),
        content: SizedBox(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledInput(nameCtrl, 'FULL NAME'),
                _styledInput(bioCtrl, 'BIO LORE', maxLines: 3),
                _styledInput(contactCtrl, 'COMMS PHONE'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))),
          RetroButton(
            text: 'SAVE',
            bgColor: AppColors.sky,
            textColor: Colors.white,
            onPressed: () {
              _saveProfile(newName: nameCtrl.text.trim(), newBio: bioCtrl.text.trim(), newContact: contactCtrl.text.trim());
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _styledInput(TextEditingController c, String label, {int maxLines = 1, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        obscureText: isPassword,
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 11),
          filled: true,
          fillColor: AppColors.inputBg,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 2.5)),
        ),
        validator: (v) => v!.isEmpty ? 'REQUIRED FIELD' : null,
      ),
    );
  }
}