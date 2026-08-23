import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    final effectiveText = widget.textColor ?? Colors.white;

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
              color: effectiveText,
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

class GoogleRetroButton extends StatefulWidget {
  final VoidCallback onPressed;

  const GoogleRetroButton({super.key, required this.onPressed});

  @override
  State<GoogleRetroButton> createState() => _GoogleRetroButtonState();
}

class _GoogleRetroButtonState extends State<GoogleRetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
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
          width: double.infinity,
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                height: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'CONTINUE WITH GOOGLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleSigningIn = false;
  bool _showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.sunset,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
      ),
    );
  }

  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists || !doc.data()!.containsKey('role')) {
      if (mounted) context.go('/completare-profil');
    } else {
      final role = doc.data()!['role'];
      if (mounted) {
        if (role == 'teacher') {
          context.go('/panou-profesor');
        } else {
          context.go('/materii');
        }
      }
    }
  }

  Future<void> _login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showError('BOTH FIELDS ARE REQUIRED.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _checkUserProfile();
    } catch (e) {
      _showError('AUTHENTICATION FAILED: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isGoogleSigningIn = true);

    try {
      final GoogleAuthProvider authProvider = GoogleAuthProvider();
      authProvider.addScope('email');
      authProvider.addScope('profile');

      final userCred = await FirebaseAuth.instance.signInWithPopup(authProvider);

      if (userCred.user == null) {
        setState(() => isGoogleSigningIn = false);
        return;
      }

      final uid = userCred.user!.uid;
      final email = userCred.user!.email ?? '';
      final name = userCred.user!.displayName ?? '';

      if (userCred.additionalUserInfo?.isNewUser ?? false) {
        if (mounted) {
          context.go('/inregistrare', extra: {
            'googleUser': true,
            'initialEmail': email,
            'initialName': name,
          });
        }
        return;
      }

      final usersRef = FirebaseFirestore.instance.collection('users');
      final userDoc = await usersRef.doc(uid).get();

      if (!userDoc.exists || userDoc.data()?['profileCompleted'] != true) {
        if (mounted) context.go('/completare-profil');
        return;
      }

      final data = userDoc.data();
      if (mounted) {
        if (data?['role'] == 'teacher') {
          context.go('/panou-profesor');
        } else {
          context.go('/materii');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('GOOGLE AUTHENTICATION FAILED: $e');
        setState(() => isGoogleSigningIn = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
      cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.ink) : null,
        suffixIcon: suffixIcon,
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
              'SYSTEM LOGIN',
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
              onPressed: () => context.go('/'),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: RetroBlock(
                  bgColor: AppColors.cloud,
                  padding: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        color: AppColors.mustard,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Text(
                          'AUTHORIZATION REQUIRED',
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
                        'AUTHENTICATE TO CONTINUE LEARNING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 48),

                      _buildTextField(
                        controller: emailController,
                        labelText: 'Email Address',
                        prefixIcon: Icons.email,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.ink,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 48),

                      isLoading
                          ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
                          : RetroButton(
                              text: 'INITIATE LOGIN',
                              bgColor: AppColors.forest,
                              textColor: Colors.white,
                              isFullWidth: true,
                              onPressed: _login,
                            ),
                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(child: Container(height: 3, color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ),
                          Expanded(child: Container(height: 3, color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      isGoogleSigningIn
                          ? Center(child: CircularProgressIndicator(color: AppColors.sky))
                          : GoogleRetroButton(onPressed: _signInWithGoogle),
                      const SizedBox(height: 32),

                      GestureDetector(
                        onTap: () => context.go('/inregistrare'),
                        child: Text(
                          "NO ACCOUNT? INITIATE REGISTRATION",
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
        );
      },
    );
  }
}