import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'custom_navbar.dart';

class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor = Colors.white,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
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
  final Color bgColor;
  final Color textColor;
  final bool isFullWidth;
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
    this.isFullWidth = false,
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
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
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
            color: widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        backgroundColor: isError ? AppColors.sunset : AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 3),
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
      _bio = data['bio'] ?? 'NO BIO PROVIDED.';
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.ink, width: 4)),
        title: const Text('UPDATE ACCESS KEY', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5)),
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
          TextButton(onPressed: () => context.pop(false), child: const Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))),
          RetroButton(
            text: 'CONFIRM',
            bgColor: AppColors.sky,
            textColor: AppColors.ink,
            onPressed: () { if (formKey.currentState!.validate()) context.pop(true); },
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

  Widget _buildHeroCard(bool isCurrentUser, bool isMobile) {
    return RetroBlock(
      bgColor: Colors.white,
      padding: isMobile ? 24 : 32,
      child: isMobile
          ? Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.ink, width: 3),
                  image: _imageUrl != null && _imageUrl!.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(_imageUrl!), fit: BoxFit.cover) : null,
                ),
                child: _imageUrl == null || _imageUrl!.isEmpty ? const Icon(Icons.person, size: 60, color: AppColors.ink) : null,
              ),
              if (isCurrentUser)
                GestureDetector(
                  onTap: _uploading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.ink, border: Border.all(color: Colors.white, width: 2)),
                    child: _uploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                color: AppColors.forest,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: const Text("PLAYER ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),
              Text(_name?.toUpperCase() ?? 'UNKNOWN PLAYER', textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(_email?.toUpperCase() ?? 'N/A', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          if (isCurrentUser)
            RetroButton(
              text: "EDIT DATA",
              icon: Icons.edit,
              bgColor: AppColors.cloud,
              textColor: AppColors.ink,
              isFullWidth: true,
              onPressed: _openEditDialog,
            )
        ],
      )
          : Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  border: Border.all(color: AppColors.ink, width: 3),
                  image: _imageUrl != null && _imageUrl!.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(_imageUrl!), fit: BoxFit.cover) : null,
                ),
                child: _imageUrl == null || _imageUrl!.isEmpty ? const Icon(Icons.person, size: 60, color: AppColors.ink) : null,
              ),
              if (isCurrentUser)
                GestureDetector(
                  onTap: _uploading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.ink, border: Border.all(color: Colors.white, width: 2)),
                    child: _uploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
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
                  color: AppColors.forest,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: const Text("PLAYER ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                Text(_name?.toUpperCase() ?? 'UNKNOWN PLAYER', textAlign: TextAlign.left, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(_email?.toUpperCase() ?? 'N/A', textAlign: TextAlign.left, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isCurrentUser)
            RetroButton(
              text: "EDIT DATA",
              icon: Icons.edit,
              bgColor: AppColors.cloud,
              textColor: AppColors.ink,
              isFullWidth: false,
              onPressed: _openEditDialog,
            )
        ],
      ),
    );
  }

  Widget _buildBentoInfoGrid(bool isMobile) {
    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bentoBox(Icons.info, "BIO DATA", _bio ?? 'NO BIO LOGGED', AppColors.mustard),
        const SizedBox(height: 16),
        _bentoBox(Icons.phone, "COMMS", _contact ?? 'N/A', AppColors.sky),
      ],
    )
        : Row(
      children: [
        Expanded(child: _bentoBox(Icons.info, "BIO DATA", _bio ?? 'NO BIO LOGGED', AppColors.mustard)),
        const SizedBox(width: 16),
        Expanded(child: _bentoBox(Icons.phone, "COMMS", _contact ?? 'N/A', AppColors.sky)),
      ],
    );
  }

  Widget _bentoBox(IconData icon, String title, String value, Color color) {
    return RetroBlock(
      bgColor: color,
      padding: 24,
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 28),
              const SizedBox(width: 12),
              Text(title.toUpperCase(), style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value.toUpperCase(), style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return RetroBlock(
      bgColor: Colors.white,
      padding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("QUEST PROGRESSION", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          const Text("TRACK YOUR COMPLETED CHALLENGES HERE.", style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, int>>(
            future: _getProgressPerSubject(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.sunset));
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.ink, width: 2)),
                    child: Row(
                        children: const [
                          Icon(Icons.warning, color: AppColors.ink),
                          SizedBox(width: 16),
                          Expanded(
                              child: Text("NO COMPLETED QUESTS YET. ACCESS THE DAILY QUESTS MENU.", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))
                          )
                        ]
                    )
                );
              }

              final progress = snapshot.data!;
              return Column(
                children: progress.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                      color: AppColors.cloud,
                      border: Border.all(color: AppColors.ink, width: 2)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.forest),
                            const SizedBox(width: 12),
                            Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink))
                          ]
                      ),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: AppColors.ink,
                          child: Text("${e.value} CLEARED", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      ),
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

  Widget _buildSettingsSection(bool isMobile) {
    return RetroBlock(
      bgColor: AppColors.ink,
      padding: 32,
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("SYSTEM SECURITY", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              SizedBox(height: 8),
              Text("UPDATE YOUR ACCESS KEY TO SECURE ACCOUNT DATA.", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          RetroButton(
            text: "CHANGE KEY",
            icon: Icons.lock_reset,
            bgColor: Colors.white,
            textColor: AppColors.ink,
            isFullWidth: true,
            onPressed: _changePassword,
          ),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("SYSTEM SECURITY", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 8),
                Text("UPDATE YOUR ACCESS KEY TO SECURE ACCOUNT DATA.", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          RetroButton(
            text: "CHANGE KEY",
            icon: Icons.lock_reset,
            bgColor: Colors.white,
            textColor: AppColors.ink,
            isFullWidth: false,
            onPressed: _changePassword,
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    final contactCtrl = TextEditingController(text: _contact);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.ink, width: 4)),
        title: const Text('EDIT PROFILE DATA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledInput(nameCtrl, 'FULL NAME'),
                _styledInput(bioCtrl, 'BIO DATA', maxLines: 3),
                _styledInput(contactCtrl, 'COMMS NUMBER'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))),
          RetroButton(
            text: 'SAVE',
            bgColor: AppColors.sky,
            textColor: AppColors.ink,
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
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        obscureText: isPassword,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12),
          filled: true, fillColor: Colors.white,
          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink, width: 2)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
        ),
        validator: (v) => v!.isEmpty ? 'REQUIRED FIELD' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.userId == _auth.currentUser?.uid;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.sunset))
                : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(isCurrentUser, isMobile),
                      const SizedBox(height: 32),
                      _buildBentoInfoGrid(isMobile),
                      const SizedBox(height: 32),
                      _buildProgressSection(),
                      if (isCurrentUser) const SizedBox(height: 32),
                      if (isCurrentUser) _buildSettingsSection(isMobile),
                      const SizedBox(height: 60),
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