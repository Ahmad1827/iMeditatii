import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void _showSnackbar(String message, {bool isError = false}) {
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
    }

    if (widget.userId == _auth.currentUser?.uid) {
      _email = _auth.currentUser?.email ?? 'N/A';
    } else {
      _email ??= doc.data()?['email'] ?? 'N/A';
    }

    setState(() => _loading = false);
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
      _showSnackbar('AVATAR UPDATED.');
    } catch (e) {
      _showSnackbar('ERROR UPLOADING: $e', isError: true);
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

    _showSnackbar('PROFILE LOG UPDATED.');
    _loadUserProfile();
  }

  Future<void> _changePassword() async {
    if (widget.userId != _auth.currentUser?.uid) return;
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
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentCtrl.text.trim());
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newCtrl.text.trim());
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
    final isCurrentUser = widget.userId == _auth.currentUser?.uid;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
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
                                        // Left Column: Player Identity Card
                                        SizedBox(
                                          width: 330,
                                          child: _buildIdentityCard(isCurrentUser, isMobile),
                                        ),
                                        const SizedBox(width: 24),
                                        // Right Column: Progression & Security
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
      },
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
          // Avatar
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
          // Badges
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
          // Bio Section
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
          // Comms Contact
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