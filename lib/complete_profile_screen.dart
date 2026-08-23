import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

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

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
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
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String role = 'user';
  String? selectedSubject;

  final subjects = [
    'Matematică',
    'Fizică',
    'Chimie',
    'Informatică',
    'Limba Română',
    'Engleză',
    'Franceză',
    'Istorie',
    'Geografie',
  ];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      nameCtrl.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => loading = true);
    try {
      final userData = {
        'name': nameCtrl.text.trim(),
        'email': user.email,
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'subject': role == 'teacher' ? selectedSubject : null,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      if (role == 'teacher') {
        await FirebaseFirestore.instance.collection('teachers').doc(user.uid).set({
          'name': nameCtrl.text.trim(),
          'email': user.email,
          'subject': selectedSubject,
          'hasAccount': true,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PROFILE COMPLETED.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
          ),
        );

        if (role == 'teacher') {
          context.go('/panou-profesor');
        } else {
          context.go('/materii');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: $e', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.sunset,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
      cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        prefixIcon: Icon(prefixIcon, color: AppColors.ink),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border, width: 3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sky, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sunset, width: 3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sunset, width: 3),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(String title, String value, IconData icon) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          role = value;
          if (value == 'user') {
            selectedSubject = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        transform: Matrix4.translationValues(
          isSelected ? 4.0 : 0.0,
          isSelected ? 4.0 : 0.0,
          0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sky : AppColors.cardBg,
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: isSelected ? const Offset(0, 0) : const Offset(6, 6),
              blurRadius: 0,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              'USER REGISTRATION',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: RetroBlock(
                  bgColor: AppColors.cloud,
                  padding: 40,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: AppColors.mustard,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Text(
                            'COMPLETE YOUR PROFILE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Provide required credentials to enter the system.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildTextField(
                          controller: nameCtrl,
                          labelText: 'Full Name',
                          prefixIcon: Icons.person,
                          validator: (v) => v!.isEmpty ? 'REQUIRED FIELD' : null,
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: phoneCtrl,
                          labelText: 'Phone Number',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? 'REQUIRED FIELD' : null,
                        ),
                        const SizedBox(height: 40),

                        Text(
                          'ASSIGN CLASS / ROLE:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleSelector('Player\n(Student)', 'user', Icons.gamepad),
                            ),
                            Expanded(
                              child: _buildRoleSelector('Master\n(Teacher)', 'teacher', Icons.admin_panel_settings),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        if (role == 'teacher') ...[
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'SELECT SPECIALIZATION',
                              labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                              prefixIcon: Icon(Icons.book, color: AppColors.ink),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.border, width: 3),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.border, width: 3),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.sky, width: 3),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.sunset, width: 3),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.sunset, width: 3),
                              ),
                            ),
                            iconEnabledColor: AppColors.ink,
                            dropdownColor: AppColors.cardBg,
                            items: subjects
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink))))
                                .toList(),
                            value: selectedSubject,
                            onChanged: (val) {
                              setState(() => selectedSubject = val);
                            },
                            validator: (v) {
                              if (role == 'teacher' && (v == null || v.isEmpty)) {
                                return 'REQUIRED FIELD';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                        ],

                        loading
                            ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
                            : RetroButton(
                                text: 'SAVE CREDENTIALS',
                                bgColor: AppColors.forest,
                                textColor: Colors.white,
                                isFullWidth: true,
                                onPressed: _saveProfile,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}