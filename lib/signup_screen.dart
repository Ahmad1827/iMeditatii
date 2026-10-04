import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
  final bool isLoading;
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
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : Text(
                  widget.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: effectiveTextColor,
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

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
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

  // ---- clean state
  String? _error;
  bool _showPass = false;
  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

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

  /// Retro: snackbar. Clean: errors go inline (with a shake), success is a soft snackbar.
  void _showSnackbar(String message, {bool isError = false, String? friendly}) {
    if (!mounted) return;
    if (AppStyle.current.isClean) {
      if (isError) {
        setState(() => _error = friendly ?? message);
        _shake.forward(from: 0);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendly ?? message, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF212529),
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

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Există deja un cont cu acest email. Intră în cont în loc să creezi unul nou.';
      case 'invalid-email':
        return 'Adresa de email nu e validă.';
      case 'weak-password':
        return 'Parola e prea slabă. Folosește cel puțin 6 caractere.';
      case 'network-request-failed':
        return 'Nu există conexiune la internet.';
      case 'operation-not-allowed':
        return 'Înregistrarea cu email nu e activă momentan.';
    }
    return e.message ?? 'Nu am putut crea contul.';
  }

  Future<void> _signup() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      if (AppStyle.current.isClean) _shake.forward(from: 0);
      return;
    }

    if (role == 'teacher' && (selectedSubject ?? '').isEmpty) {
      _showSnackbar('SELECT A SPECIALIZATION.', isError: true, friendly: 'Alege materia pe care o predai.');
      return;
    }

    if (!_acceptedTerms || !_acceptedPrivacy) {
      _showSnackbar('ACCEPTANCE OF TERMS & PRIVACY REQUIRED.',
          isError: true, friendly: 'Bifează termenii și politica de confidențialitate ca să continui.');
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
          _showSnackbar('ACCOUNT CREATED. AWAITING ADMIN APPROVAL.',
              friendly: 'Cont creat. Profilul tău de profesor așteaptă aprobarea unui administrator.');
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
      _showSnackbar(e.message ?? 'REGISTRATION FAILED.', isError: true, friendly: _friendly(e));
    } catch (e) {
      final s = e.toString();
      _showSnackbar(
        s,
        isError: true,
        friendly: s.contains('GOOGLE USER')
            ? 'Sesiunea Google a expirat. Autentifică-te din nou cu Google.'
            : 'Nu am putut crea contul. Încearcă din nou.',
      );
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
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final w = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(w < 860) : _buildRetro(w < 700);
      },
    );
  }

  // ===========================================================================
  // CLEAN — role-aware split card: the side panel changes with the role
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cGreen = Color(0xFF10B981);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cRose = Color(0xFFE5484D);

  Color get _roleColor => role == 'teacher' ? _cBlue : Pb.primary;

  int get _strength {
    final p = passCtrl.text;
    var s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if ((RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    if (p.length < 6) s = math.min(s, 1);
    return s;
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix, bool readOnly = false}) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(borderRadius: Pb.radius, borderSide: BorderSide(color: c));
    return Pb.input(hint: hint).copyWith(
      prefixIcon: Icon(icon, size: 18, color: Pb.muted),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      suffixIcon: suffix,
      fillColor: readOnly ? Pb.hoverBg : Pb.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      errorBorder: b(Pb.danger),
      focusedErrorBorder: b(Pb.danger),
      errorStyle: const TextStyle(fontSize: 12.5),
    );
  }

  Widget _label(String t, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(t, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
            if (hint != null) ...[
              const SizedBox(width: 6),
              Text(hint, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ],
        ),
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
                          constraints: BoxConstraints(maxWidth: isMobile ? 520 : 1000),
                          child: KeyedSubtree(key: _cardKey, child: _SReveal(child: card)),
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
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: Pb.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Pb.border.withOpacity(0.7)),
          boxShadow: shadow,
        ),
        child: _cForm(true),
      );
    }
    const sideW = 360.0;
    return LayoutBuilder(builder: (context, b) {
      final f = (sideW / b.maxWidth).clamp(0.0, 1.0).toDouble();
      final tint = Color.alphaBlend(_roleColor.withOpacity(AppColors.isDark ? 0.11 : 0.06), Pb.surface);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(36, 32, 36, 30), child: _cForm(false))),
          ],
        ),
      );
    });
  }

  Widget _cSide() {
    final teacher = role == 'teacher';
    final c = _roleColor;

    Widget perk(IconData i, Color col, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(i, size: 17, color: col),
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

    final content = Column(
      key: ValueKey(role),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(teacher ? 'Cont de profesor' : 'Cont de elev',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c)),
        ),
        const SizedBox(height: 14),
        Text(
          teacher ? 'Predă pe iMeditații' : 'Începe să exersezi',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          teacher
              ? 'Îți faci un profil public și primești elevi pentru meditații 1 la 1.'
              : 'Probleme evaluate automat, lecții pe capitole și profesori verificați.',
          style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (teacher) ...[
          perk(Icons.badge_outlined, _cBlue, 'Profil public', 'Materia, experiența și recenziile tale, într-un singur loc.'),
          perk(Icons.forum_outlined, _cGreen, 'Mesaje și lecții video', 'Vorbești cu elevii și ții meditațiile direct din aplicație.'),
          perk(Icons.verified_user_outlined, _cAmber, 'Aprobare manuală',
              'Un administrator îți verifică profilul înainte să apară public.'),
        ] else ...[
          perk(Icons.code, Pb.primary, 'Probleme cu evaluare automată', 'Scrii codul în browser și vezi pe loc ce teste trec.'),
          perk(Icons.menu_book_outlined, _cBlue, 'Lecții pe capitole', 'Programa claselor IX–XII, cu exemple și capcane de Bac.'),
          perk(Icons.emoji_events_outlined, _cAmber, 'Clasament', 'Fiecare problemă rezolvată te urcă mai sus.'),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: child),
            ),
            layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, if (cur != null) cur]),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _roleTile(String value, String title, String desc, IconData icon, Color c) {
    final sel = role == value;
    return _SHover(
      onTap: () => setState(() {
        role = value;
        _error = null;
      }),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: sel ? c.withOpacity(0.08) : (h ? Pb.hoverBg : Pb.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? c : Pb.border, width: sel ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: sel ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Icon(Icons.check_circle, size: 20, color: c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cForm(bool isMobile) {
    final strength = _strength;
    const labels = ['Prea scurtă', 'Slabă', 'Acceptabilă', 'Bună', 'Foarte bună'];
    const colors = [_cRose, _cRose, _cAmber, _cGreen, _cGreen];

    final student = _roleTile('student', 'Elev', 'Rezolvi probleme și citești lecții.', Icons.school_outlined, Pb.primary);
    final teacher = _roleTile('teacher', 'Profesor', 'Îți faci profil și primești elevi.', Icons.co_present_outlined, _cBlue);

    Widget check(bool value, ValueChanged<bool> onChanged, String before, String link, String route) => Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: value,
                activeColor: Pb.primary,
                side: BorderSide(color: Pb.inputBorder, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => setState(() {
                  onChanged(v ?? false);
                  _error = null;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(before, style: TextStyle(fontSize: 14, color: Pb.text)),
                  PbLink(text: link, fontSize: 14, onTap: () => context.go(route)),
                ],
              ),
            ),
          ],
        );

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMobile) ...[Align(alignment: Alignment.centerLeft, child: _brand()), const SizedBox(height: 18)],
            Text(
              widget.googleUser ? 'Finalizează contul' : 'Creează cont',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Ai deja cont? ', style: TextStyle(fontSize: 14, color: Pb.muted)),
                PbLink(text: 'Intră în cont', fontSize: 14, onTap: () => context.go('/login')),
              ],
            ),
            if (widget.googleUser) ...[
              const SizedBox(height: 16),
              const PbAlert(
                type: PbAlertType.info,
                icon: Icons.verified_user_outlined,
                child: Text('Te-ai conectat cu Google. Mai avem nevoie doar de câteva detalii.', style: TextStyle(fontSize: 14.5)),
              ),
            ],
            const SizedBox(height: 20),
            _label('Cine ești?'),
            if (isMobile) ...[student, const SizedBox(height: 8), teacher]
            else
              Row(children: [Expanded(child: student), const SizedBox(width: 10), Expanded(child: teacher)]),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: role != 'teacher'
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Ce materie predai?'),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final s in subjects)
                                _SHover(
                                  onTap: () => setState(() {
                                    selectedSubject = s;
                                    _error = null;
                                  }),
                                  builder: (h) {
                                    final sel = selectedSubject == s;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sel ? _cBlue.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: sel ? _cBlue.withOpacity(0.6) : Pb.border),
                                      ),
                                      child: Text(
                                        s,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                                          color: sel ? _cBlue : Pb.text,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            _label('Nume complet'),
            TextFormField(
              controller: nameCtrl,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 15, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: _dec('Prenume Nume', Icons.person_outline),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Scrie-ți numele.' : null,
            ),
            const SizedBox(height: 14),
            _label('Email', hint: widget.googleUser ? '(de la Google)' : null),
            TextFormField(
              controller: emailCtrl,
              readOnly: widget.googleUser,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 15, color: widget.googleUser ? Pb.muted : Pb.text),
              cursorColor: Pb.primary,
              decoration: _dec('nume@exemplu.ro', Icons.mail_outline, readOnly: widget.googleUser),
              validator: (v) {
                final t = (v ?? '').trim();
                return t.contains('@') && t.contains('.') ? null : 'Adresa de email nu pare validă.';
              },
            ),
            if (!widget.googleUser) ...[
              const SizedBox(height: 14),
              _label('Parolă'),
              TextFormField(
                controller: passCtrl,
                obscureText: !_showPass,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 15, color: Pb.text),
                cursorColor: Pb.primary,
                decoration: _dec(
                  'Cel puțin 6 caractere',
                  Icons.lock_outline,
                  suffix: IconButton(
                    tooltip: _showPass ? 'Ascunde parola' : 'Arată parola',
                    splashRadius: 18,
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: Pb.muted),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) => (v ?? '').length < 6 ? 'Parola trebuie să aibă cel puțin 6 caractere.' : null,
              ),
              if (passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < strength ? colors[strength] : Pb.gray,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      if (i < 3) const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 10),
                    Text(labels[strength], style: TextStyle(fontSize: 12.5, color: colors[strength], fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 14),
            _label('Telefon', hint: '(opțional)'),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: 15, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: _dec('07xx xxx xxx', Icons.phone_outlined),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  check(_acceptedTerms, (v) => _acceptedTerms = v, 'Accept ', 'termenii și condițiile', '/termeni-si-conditii'),
                  check(_acceptedPrivacy, (v) => _acceptedPrivacy = v, 'Sunt de acord cu ', 'politica de confidențialitate',
                      '/politica-confidentialitate'),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: PbAlert(
                        type: PbAlertType.danger,
                        icon: Icons.error_outline,
                        child: Text(_error!, style: const TextStyle(fontSize: 14.5)),
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            PbButton(
              text: loading ? 'Se creează contul...' : (role == 'teacher' ? 'Creează cont de profesor' : 'Creează cont de elev'),
              icon: Icons.arrow_forward,
              size: PbSize.lg,
              fullWidth: true,
              loading: loading,
              variant: role == 'teacher' ? PbVariant.primary : PbVariant.success,
              onPressed: loading ? null : _signup,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required bool isMobile,
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
      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 18),
      cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
        prefixIcon: Icon(prefixIcon, color: AppColors.ink, size: isMobile ? 18 : 22),
        filled: true,
        fillColor: readOnly ? AppColors.cloud : AppColors.inputBg,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sunset, width: 2.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sunset, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(String title, String value, IconData icon, bool isMobile) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () => setState(() => role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 20, horizontal: isMobile ? 10 : 16),
        transform: Matrix4.translationValues(
          isSelected ? 3.0 : 0.0,
          isSelected ? 3.0 : 0.0,
          0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sky : AppColors.cardBg,
          border: Border.all(color: AppColors.border, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: isSelected ? const Offset(0, 0) : Offset(isMobile ? 3 : 5, isMobile ? 3 : 5),
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
              size: isMobile ? 34 : 48,
            ),
            SizedBox(height: isMobile ? 8 : 14),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetro(bool isMobile) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'USER REGISTRATION',
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
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 60),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: RetroBlock(
              bgColor: AppColors.cloud,
              padding: isMobile ? 18 : 40,
              shadowOffset: isMobile ? 4 : 6,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: AppColors.mustard,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12, horizontal: isMobile ? 12 : 16),
                      child: Text(
                        widget.googleUser ? 'FINALIZE GOOGLE SIGNUP' : 'INITIALIZE NEW ACCOUNT',
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
                      'Provide required credentials to enter the system.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 16,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 48),
                    _buildTextField(
                      controller: nameCtrl,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person,
                      isMobile: isMobile,
                      validator: (v) => v!.isEmpty ? 'REQUIRED FIELD' : null,
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildTextField(
                      controller: emailCtrl,
                      labelText: 'Email Address',
                      prefixIcon: Icons.email,
                      isMobile: isMobile,
                      readOnly: widget.googleUser,
                      validator: (v) => v!.contains('@') && v.contains('.') ? null : 'INVALID EMAIL FORMAT',
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    if (!widget.googleUser) ...[
                      _buildTextField(
                        controller: passCtrl,
                        labelText: 'Password',
                        prefixIcon: Icons.lock,
                        isMobile: isMobile,
                        obscureText: true,
                        validator: (v) => v!.length < 6 ? 'MINIMUM 6 CHARACTERS REQUIRED' : null,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                    ],
                    _buildTextField(
                      controller: phoneCtrl,
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: Icons.phone,
                      isMobile: isMobile,
                      keyboardType: TextInputType.phone,
                      validator: (v) => null,
                    ),
                    SizedBox(height: isMobile ? 24 : 48),
                    Text(
                      'ASSIGN CLASS / ROLE:',
                      style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
                    ),
                    SizedBox(height: isMobile ? 12 : 20),
                    Row(
                      children: [
                        Expanded(child: _buildRoleSelector('Player\n(Student)', 'student', Icons.gamepad, isMobile)),
                        Expanded(child: _buildRoleSelector('Master\n(Teacher)', 'teacher', Icons.admin_panel_settings, isMobile)),
                      ],
                    ),
                    SizedBox(height: isMobile ? 24 : 40),
                    if (role == 'teacher') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'SELECT SPECIALIZATION',
                          labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                          prefixIcon: Icon(Icons.book, color: AppColors.ink, size: isMobile ? 18 : 22),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18, horizontal: 16),
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: AppColors.sunset, width: 2.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: AppColors.sunset, width: 2.5),
                          ),
                        ),
                        iconEnabledColor: AppColors.ink,
                        dropdownColor: AppColors.cardBg,
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: isMobile ? 13 : 15))))
                            .toList(),
                        value: selectedSubject,
                        onChanged: (val) => setState(() => selectedSubject = val),
                        validator: (v) => v == null || v.isEmpty ? 'REQUIRED FIELD' : null,
                      ),
                      SizedBox(height: isMobile ? 24 : 40),
                    ],
                    Container(
                      padding: EdgeInsets.all(isMobile ? 14 : 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(color: AppColors.border, width: 2.5),
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
                                    style: TextStyle(color: AppColors.ink, fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold),
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
                          SizedBox(height: isMobile ? 8 : 12),
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
                                    style: TextStyle(color: AppColors.ink, fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold),
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
                    SizedBox(height: isMobile ? 24 : 48),
                    RetroButton(
                      text: 'INITIALIZE ACCOUNT',
                      bgColor: AppColors.forest,
                      textColor: Colors.white,
                      isFullWidth: true,
                      isLoading: loading,
                      fontSize: isMobile ? 15 : 18,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                      onPressed: _signup,
                    ),
                    SizedBox(height: isMobile ? 20 : 32),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        "ALREADY REGISTERED? LOG IN.",
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
      ),
    );
  }
}

// =============================================================================
// Clean helpers
// =============================================================================
class _SHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _SHover({required this.builder, this.onTap});

  @override
  State<_SHover> createState() => _SHoverState();
}

class _SHoverState extends State<_SHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(_hover),
      ),
    );
  }
}

class _SReveal extends StatefulWidget {
  final Widget child;
  const _SReveal({required this.child});

  @override
  State<_SReveal> createState() => _SRevealState();
}

class _SRevealState extends State<_SReveal> with SingleTickerProviderStateMixin {
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