import 'package:flutter/gestures.dart';
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
  final bool isLoading;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.isLoading = false,
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : Text(
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

class SignupScreen extends StatefulWidget {
  final bool googleUser;
  final String? initialEmail;
  final String? initialName;

  const SignupScreen({
    this.googleUser = false,
    this.initialEmail,
    this.initialName,
    super.key,
  });

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  String role = 'student';
  String? selectedSubject;
  bool loading = false;

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  final List<String> subjects = [
    "Matematică",
    "Informatică",
    "Fizică",
    "Chimie",
    "Biologie",
    "Istorie",
    "Geografie",
    "Limba Română",
    "Engleză",
    "Franceză",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.googleUser) {
      emailCtrl.text = widget.initialEmail ?? '';
      nameCtrl.text = widget.initialName ?? '';
    }
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms || !_acceptedPrivacy) {
      _showSnackbar('ACCEPTANCE OF TERMS & PRIVACY REQUIRED.', isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      String uid;

      if (widget.googleUser) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("GOOGLE USER NOT AUTHENTICATED.");
        }
        uid = user.uid;
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        uid = cred.user!.uid;
      }

      final data = {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'profileCompleted': true,
        'acceptedTerms': true,
        'acceptedPrivacy': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'teacher') {
        data['subject'] = selectedSubject ?? '';
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(data);

      if (role == 'teacher') {
        await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
          'name': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'subject': selectedSubject ?? '',
          'image': '',
          'active': false,
          'hasAccount': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSnackbar('ACCOUNT CREATED. AWAITING ADMIN APPROVAL.');
        }
      }

      if (mounted) {
        if (role == 'teacher') {
          context.go('/profesor/$uid');
        } else {
          context.go('/materii');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? 'REGISTRATION FAILED.', isError: true);
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
      cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        prefixIcon: Icon(prefixIcon, color: AppColors.ink),
        filled: true,
        fillColor: readOnly ? AppColors.cloud : AppColors.inputBg,
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
      onTap: () => setState(() => role = value),
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
              onPressed: () => context.go('/login'),
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
                            widget.googleUser ? 'FINALIZE GOOGLE REGISTRATION' : 'INITIALIZE NEW ACCOUNT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
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
                        const SizedBox(height: 48),

                        _buildTextField(
                          controller: nameCtrl,
                          labelText: 'Full Name',
                          prefixIcon: Icons.person,
                          validator: (v) => v!.isEmpty ? 'REQUIRED FIELD' : null,
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: emailCtrl,
                          labelText: 'Email Address',
                          prefixIcon: Icons.email,
                          readOnly: widget.googleUser,
                          validator: (v) => v!.contains('@') && v.contains('.') ? null : 'INVALID EMAIL FORMAT',
                        ),
                        const SizedBox(height: 24),

                        if (!widget.googleUser) ...[
                          _buildTextField(
                            controller: passCtrl,
                            labelText: 'Password',
                            prefixIcon: Icons.lock,
                            obscureText: true,
                            validator: (v) => v!.length < 6 ? 'MINIMUM 6 CHARACTERS REQUIRED' : null,
                          ),
                          const SizedBox(height: 24),
                        ],

                        _buildTextField(
                          controller: phoneCtrl,
                          labelText: 'Phone Number (Optional)',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) => null,
                        ),
                        const SizedBox(height: 48),

                        Text(
                          'ASSIGN CLASS / ROLE:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(child: _buildRoleSelector('Player\n(Student)', 'student', Icons.gamepad)),
                            Expanded(child: _buildRoleSelector('Master\n(Teacher)', 'teacher', Icons.admin_panel_settings)),
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
                            items: subjects.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink))
                            )).toList(),
                            value: selectedSubject,
                            onChanged: (val) => setState(() => selectedSubject = val),
                            validator: (v) => v == null || v.isEmpty ? 'REQUIRED FIELD' : null,
                          ),
                          const SizedBox(height: 40),
                        ],

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.border, width: 3),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    activeColor: AppColors.ink,
                                    checkColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                    side: BorderSide(color: AppColors.border, width: 2),
                                    onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I ACKNOWLEDGE THE ',
                                        style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(
                                            text: 'TERMS OF SERVICE',
                                            style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()..onTap = () => context.go('/termeni-si-conditii'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptedPrivacy,
                                    activeColor: AppColors.ink,
                                    checkColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                    side: BorderSide(color: AppColors.border, width: 2),
                                    onChanged: (val) => setState(() => _acceptedPrivacy = val ?? false),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I AGREE TO THE ',
                                        style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(
                                            text: 'PRIVACY POLICY',
                                            style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()..onTap = () => context.go('/politica-confidentialitate'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        RetroButton(
                          text: 'INITIALIZE ACCOUNT',
                          bgColor: AppColors.forest,
                          textColor: Colors.white,
                          isFullWidth: true,
                          isLoading: loading,
                          onPressed: _signup,
                        ),
                        const SizedBox(height: 32),

                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            "ALREADY REGISTERED? LOG IN.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                              decorationThickness: 2,
                            ),
                          ),
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