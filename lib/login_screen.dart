import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, PbLink, PbAlert, PbAlertType;

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
  final double fontSize;
  final EdgeInsets padding;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.fontSize = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          padding: widget.padding,
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveText,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleRetroButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isMobile;

  const GoogleRetroButton({super.key, required this.onPressed, this.isMobile = false});

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
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 18 : 32, vertical: widget.isMobile ? 13 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(_googleLogo, height: widget.isMobile ? 20 : 24),
              SizedBox(width: widget.isMobile ? 10 : 16),
              Text(
                'CONTINUE WITH GOOGLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: widget.isMobile ? 15 : 18,
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

const String _googleLogo =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleSigningIn = false;
  bool _showPassword = false;

  // ---- clean state
  String? _error;
  String? _info;
  final FocusNode _passFocus = FocusNode();
  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _passFocus.dispose();
    _shake.dispose();
    super.dispose();
  }

  /// Retro: snackbar. Clean: inline alert inside the card + a little shake.
  void _showError(String message, {String? friendly}) {
    if (!mounted) return;
    if (AppStyle.current.isClean) {
      setState(() {
        _error = friendly ?? message;
        _info = null;
      });
      _shake.forward(from: 0);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.sunset,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
      ),
    );
  }

  String _friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Adresa de email nu e validă.';
        case 'user-disabled':
          return 'Contul acesta a fost dezactivat.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Emailul sau parola nu sunt corecte.';
        case 'too-many-requests':
          return 'Prea multe încercări. Așteaptă puțin și încearcă din nou.';
        case 'network-request-failed':
          return 'Nu există conexiune la internet.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Fereastra Google a fost închisă înainte de autentificare.';
        case 'popup-blocked':
          return 'Browserul a blocat fereastra Google. Permite pop-up-urile pentru acest site.';
      }
      return e.message ?? 'Autentificarea a eșuat.';
    }
    return 'Autentificarea a eșuat. Încearcă din nou.';
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
      _showError('BOTH FIELDS ARE REQUIRED.', friendly: 'Completează emailul și parola.');
      return;
    }

    setState(() {
      isLoading = true;
      _error = null;
      _info = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _checkUserProfile();
    } catch (e) {
      _showError('AUTHENTICATION FAILED: $e', friendly: _friendly(e));
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('ENTER YOUR EMAIL FIRST.', friendly: 'Scrie adresa de email mai sus, apoi apasă din nou pe „Ai uitat parola?”.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _error = null;
          _info = 'Ți-am trimis un email cu un link pentru resetarea parolei. Verifică și folderul Spam.';
        });
      }
    } catch (e) {
      _showError('RESET FAILED: $e', friendly: _friendly(e));
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isGoogleSigningIn = true;
      _error = null;
      _info = null;
    });

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
        _showError('GOOGLE AUTHENTICATION FAILED: $e', friendly: _friendly(e));
        setState(() => isGoogleSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final w = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(w < 820) : _buildRetro(w < 700);
      },
    );
  }

  // ===========================================================================
  // CLEAN — "porțile castelului": split card over the fantasy scene
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);

  static const List<String> _facts = [
    'Algoritmul lui Euclid are peste 2.000 de ani și încă rulează în criptografia de azi.',
    'Primul „bug” documentat a fost o molie reală, găsită într-un calculator în 1947.',
    'Căutarea binară găsește un element printre un milion în cel mult 20 de pași.',
    'Python își ia numele de la Monty Python, nu de la șarpe.',
  ];

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) => Pb.input(hint: hint).copyWith(
        prefixIcon: Icon(icon, size: 18, color: Pb.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
      );

  Widget _brand() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Pb.primary, borderRadius: BorderRadius.circular(9)),
            child: const Text('iM', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text('iMeditații', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3)),
        ],
      );

  Widget _buildClean(bool isMobile) {
    final card = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        return Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 9 * (1 - t), 0), child: child);
      },
      child: _cCard(isMobile),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              scene: HomeScene.fantasy,
              blockers: [_cardKey],
              child: LayoutBuilder(
                builder: (context, vp) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: vp.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 20 : 40),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isMobile ? 460 : 940),
                          child: KeyedSubtree(key: _cardKey, child: _AReveal(child: card)),
                        ),
                      ),
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

  Widget _cCard(bool isMobile) {
    final shadow = [
      BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.35 : 0.08), blurRadius: 32, offset: const Offset(0, 12)),
    ];
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: Pb.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Pb.border.withOpacity(0.7)),
          boxShadow: shadow,
        ),
        child: _cForm(true),
      );
    }
    const sideW = 370.0;
    return LayoutBuilder(builder: (context, b) {
      final f = (sideW / b.maxWidth).clamp(0.0, 1.0).toDouble();
      final tint = Color.alphaBlend(Pb.primary.withOpacity(AppColors.isDark ? 0.10 : 0.05), Pb.surface);
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Pb.border.withOpacity(0.7)),
          boxShadow: shadow,
          gradient: LinearGradient(
            colors: [tint, tint, Pb.border, Pb.surface, Pb.surface],
            stops: [0, f, f, math.min(1.0, f + 0.0012), 1],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: sideW, child: _cSide()),
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(36, 34, 36, 30), child: _cForm(false))),
          ],
        ),
      );
    });
  }

  Widget _cSide() {
    Widget perk(IconData i, Color c, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(i, size: 17, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                    const SizedBox(height: 2),
                    Text(body, style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );

    final now = DateTime.now();
    final fact = _facts[now.difference(DateTime(now.year)).inDays % _facts.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 34, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(),
          const SizedBox(height: 30),
          Text('Bine ai revenit', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Intră în cont și continuă de unde ai rămas.', style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5)),
          const SizedBox(height: 26),
          perk(Icons.sync, Pb.primary, 'Progresul rămâne cu tine', 'Problemele rezolvate se salvează pe cont, pe orice dispozitiv.'),
          perk(Icons.emoji_events_outlined, _cAmber, 'Urci în clasament', 'Fiecare soluție acceptată contează.'),
          perk(Icons.school_outlined, _cBlue, 'Lecții și profesori', 'Teorie pe capitole și meditații 1 la 1.'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Pb.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Pb.border.withOpacity(0.7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 18, color: _cAmber),
                const SizedBox(width: 10),
                Expanded(child: Text(fact, style: TextStyle(fontSize: 13, color: Pb.text, height: 1.45))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cForm(bool isMobile) {
    final google = _GoogleButton(loading: isGoogleSigningIn, onTap: isGoogleSigningIn ? null : _signInWithGoogle);

    final divider = Row(
      children: [
        Expanded(child: Container(height: 1, color: Pb.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('sau cu email', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
        ),
        Expanded(child: Container(height: 1, color: Pb.border)),
      ],
    );

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMobile) ...[Align(alignment: Alignment.centerLeft, child: _brand()), const SizedBox(height: 18)],
          Text('Intră în cont', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Nu ai cont? ', style: TextStyle(fontSize: 14, color: Pb.muted)),
              PbLink(text: 'Creează unul gratuit', fontSize: 14, onTap: () => context.go('/inregistrare')),
            ],
          ),
          const SizedBox(height: 22),
          google,
          const SizedBox(height: 18),
          divider,
          const SizedBox(height: 18),
          _label('Email'),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passFocus.requestFocus(),
            style: TextStyle(fontSize: 15, color: Pb.text),
            cursorColor: Pb.primary,
            decoration: _dec('nume@exemplu.ro', Icons.mail_outline),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _label('Parolă')),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PbLink(text: 'Ai uitat parola?', fontSize: 13, onTap: _resetPassword),
              ),
            ],
          ),
          TextField(
            controller: passwordController,
            focusNode: _passFocus,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            style: TextStyle(fontSize: 15, color: Pb.text),
            cursorColor: Pb.primary,
            decoration: _dec(
              'Parola ta',
              Icons.lock_outline,
              suffix: IconButton(
                tooltip: _showPassword ? 'Ascunde parola' : 'Arată parola',
                splashRadius: 18,
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: Pb.muted),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14.5))),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 14),
                  PbAlert(type: PbAlertType.success, icon: Icons.mark_email_read_outlined, child: Text(_info!, style: const TextStyle(fontSize: 14.5))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          PbButton(
            text: isLoading ? 'Se verifică...' : 'Intră în cont',
            icon: Icons.login,
            size: PbSize.lg,
            fullWidth: true,
            loading: isLoading,
            onPressed: isLoading ? null : _login,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Continuând, ești de acord cu ', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              PbLink(text: 'termenii', fontSize: 12.5, onTap: () => context.go('/termeni-si-conditii')),
              Text(' și ', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              PbLink(text: 'politica de confidențialitate', fontSize: 12.5, onTap: () => context.go('/politica-confidentialitate')),
              Text('.', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isMobile,
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
      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 18),
      cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.ink, size: isMobile ? 18 : 22) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 20, horizontal: isMobile ? 14 : 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border, width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sky, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildRetro(bool isMobile) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'SYSTEM LOGIN',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: isMobile ? 18 : 22,
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
          icon: Icon(Icons.arrow_back, color: AppColors.ink, size: isMobile ? 26 : 32),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 60),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RetroBlock(
              bgColor: AppColors.cloud,
              padding: isMobile ? 20 : 40,
              shadowOffset: isMobile ? 4 : 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: AppColors.mustard,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12, horizontal: isMobile ? 12 : 16),
                    child: Text(
                      'AUTHORIZATION REQUIRED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 10 : 16),
                  Text(
                    'AUTHENTICATE TO CONTINUE LEARNING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 16,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isMobile ? 28 : 48),
                  _buildTextField(
                    controller: emailController,
                    labelText: 'Email Address',
                    prefixIcon: Icons.email,
                    isMobile: isMobile,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildTextField(
                    controller: passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock,
                    isMobile: isMobile,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.ink,
                        size: isMobile ? 20 : 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: isMobile ? 28 : 48),
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
                      : RetroButton(
                          text: 'INITIATE LOGIN',
                          bgColor: AppColors.forest,
                          textColor: Colors.white,
                          isFullWidth: true,
                          fontSize: isMobile ? 15 : 18,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                          onPressed: _login,
                        ),
                  SizedBox(height: isMobile ? 20 : 32),
                  Row(
                    children: [
                      Expanded(child: Container(height: 2.5, color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR',
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: isMobile ? 15 : 18),
                        ),
                      ),
                      Expanded(child: Container(height: 2.5, color: AppColors.border)),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 32),
                  isGoogleSigningIn
                      ? Center(child: CircularProgressIndicator(color: AppColors.sky))
                      : GoogleRetroButton(onPressed: _signInWithGoogle, isMobile: isMobile),
                  SizedBox(height: isMobile ? 20 : 32),
                  GestureDetector(
                    onTap: () => context.go('/inregistrare'),
                    child: Text(
                      "NO ACCOUNT? INITIATE REGISTRATION",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: isMobile ? 13 : 16,
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
  }
}

// =============================================================================
// Clean helpers
// =============================================================================
class _GoogleButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  final String label;

  const _GoogleButton({required this.loading, required this.onTap, this.label = 'Continuă cu Google'});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: _hover ? Pb.hoverBg : Pb.surface,
            borderRadius: Pb.radius,
            border: Border.all(color: _hover ? Pb.inputBorder : Pb.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary))
              else
                Image.network(_googleLogo, height: 18, errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, color: Pb.text)),
              const SizedBox(width: 10),
              Text(widget.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Pb.text)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AReveal extends StatefulWidget {
  final Widget child;
  const _AReveal({required this.child});

  @override
  State<_AReveal> createState() => _ARevealState();
}

class _ARevealState extends State<_AReveal> with SingleTickerProviderStateMixin {
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
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}