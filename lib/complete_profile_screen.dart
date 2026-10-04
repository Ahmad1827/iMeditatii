import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbAlert, PbAlertType;

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

  // ---- clean state
  String? _error;
  bool _tried = false;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      nameCtrl.text = user.displayName!;
    }
    nameCtrl.addListener(() => setState(() {}));
    phoneCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  bool get _nameOk => nameCtrl.text.trim().split(RegExp(r'\s+')).where((w) => w.length > 1).length >= 2;
  bool get _phoneOk => RegExp(r'^\+?\d{9,13}$').hasMatch(phoneCtrl.text.replaceAll(RegExp(r'[\s\-().]'), ''));
  bool get _subjectOk => role != 'teacher' || selectedSubject != null;

  Future<void> _saveProfile() async {
    final clean = AppStyle.current.isClean;
    if (clean) {
      setState(() => _tried = true);
      if (!_nameOk || !_phoneOk || !_subjectOk) {
        setState(() => _error = !_nameOk
            ? 'Scrie numele complet (prenume și nume).'
            : (!_phoneOk ? 'Numărul de telefon nu pare corect.' : 'Alege materia pe care o predai.'));
        return;
      }
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    setState(() {
      loading = true;
      _error = null;
    });
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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));

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
          clean
              ? const SnackBar(
                  content: Text('Profil completat. Bine ai venit!', style: TextStyle(color: Colors.white)),
                  backgroundColor: Color(0xFF212529),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: Pb.radius),
                )
              : SnackBar(
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
      if (!mounted) return;
      if (clean) {
        setState(() => _error = 'Nu am putut salva profilul. Verifică internetul și încearcă din nou.');
      } else {
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

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — checklist with a live completion ring that fills as you type,
  // role tiles, subject chips. Dragon scene (same as login / signup).
  // ===========================================================================
  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 820;
    final checks = <(String, bool)>[
      ('Numele complet', _nameOk),
      ('Telefon', _phoneOk),
      ('Rolul ales', true),
      if (role == 'teacher') ('Materia predată', selectedSubject != null),
    ];
    final done = checks.where((c) => c.$2).length;
    final pct = done / checks.length;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
        );

    Widget input(TextEditingController c, String hint, IconData icon, bool ok, {TextInputType? type}) => TextField(
          controller: c,
          keyboardType: type,
          enabled: !loading,
          style: TextStyle(fontSize: 15, color: Pb.text),
          cursorColor: Pb.primary,
          decoration: Pb.input(hint: hint).copyWith(
            prefixIcon: Icon(icon, size: 19, color: Pb.muted),
            suffixIcon: c.text.isEmpty
                ? null
                : Icon(ok ? Icons.check_circle : Icons.error_outline, size: 19, color: ok ? Pb.primary : (_tried ? const Color(0xFFE5484D) : Pb.muted)),
            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          ),
        );

    Widget roleTile(String value, String title, String sub, IconData icon, Color c) {
      final sel = role == value;
      return Expanded(
        child: CkHover(
          onTap: loading
              ? null
              : () => setState(() {
                    role = value;
                    if (value == 'user') selectedSubject = null;
                  }),
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? c.withOpacity(0.08) : (h ? Pb.hoverBg : Colors.transparent),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? c : Pb.border, width: sel ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 19, color: c),
                    ),
                    const Spacer(),
                    Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 19, color: sel ? c : Pb.border),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.35)),
              ],
            ),
          ),
        ),
      );
    }

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ultimul pas', style: TextStyle(fontSize: 14, color: Pb.muted)),
        const SizedBox(height: 2),
        Text('Completează-ți profilul', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Text('Avem nevoie de câteva detalii ca profesorii și elevii să te poată contacta.', style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.5)),
        const SizedBox(height: 22),
        label('Nume complet'),
        input(nameCtrl, 'Ex.: Andrei Popescu', Icons.person_outline, _nameOk),
        const SizedBox(height: 14),
        label('Telefon'),
        input(phoneCtrl, 'Ex.: 0722 123 456', Icons.phone_outlined, _phoneOk, type: TextInputType.phone),
        const SizedBox(height: 18),
        label('Cum folosești iMeditații?'),
        Row(
          children: [
            roleTile('user', 'Elev', 'Învăț, exersez și caut profesori.', Icons.backpack_outlined, Pb.primary),
            const SizedBox(width: 10),
            roleTile('teacher', 'Profesor', 'Predau și primesc elevi.', Icons.school_outlined, const Color(0xFF3B82F6)),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: role != 'teacher'
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label('Ce materie predai?'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in subjects)
                            CkHover(
                              onTap: loading ? null : () => setState(() => selectedSubject = s),
                              builder: (h) {
                                final sel = selectedSubject == s;
                                final c = ckSubjectColor(s);
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: sel ? c.withOpacity(0.12) : (h ? Pb.hoverBg : Colors.transparent),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: sel ? c : Pb.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(ckSubjectIcon(s), size: 14, color: sel ? c : Pb.muted),
                                      const SizedBox(width: 5),
                                      Text(s, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? c : Pb.text)),
                                    ],
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
        if (_error != null) ...[
          const SizedBox(height: 14),
          PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14))),
        ],
        const SizedBox(height: 20),
        PbButton(
          text: role == 'teacher' ? 'Salvează și mergi la panou' : 'Salvează și începe',
          icon: Icons.arrow_forward,
          fullWidth: true,
          loading: loading,
          onPressed: loading ? null : _saveProfile,
        ),
      ],
    );

    final meter = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Pb.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pb.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Pb.gray,
                      color: pct == 1 ? Pb.primary : const Color(0xFF3B82F6),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Pb.text, height: 1)),
                        Text('completat', style: TextStyle(fontSize: 11.5, color: Pb.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                    child: Icon(
                      c.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                      key: ValueKey('${c.$1}${c.$2}'),
                      size: 18,
                      color: c.$2 ? Pb.primary : Pb.border,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(c.$1, style: TextStyle(fontSize: 13.5, color: c.$2 ? Pb.text : Pb.muted, decoration: c.$2 ? TextDecoration.lineThrough : null)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            pct == 1 ? 'Gata! Poți salva.' : 'Mai ai ${checks.length - done} ${checks.length - done == 1 ? 'pas' : 'pași'}.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pct == 1 ? Pb.link : Pb.muted),
          ),
        ],
      ),
    );

    final card = Container(
      key: _cardKey,
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      decoration: ckDeco(r: 20),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [meter, const SizedBox(height: 20), form])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: 28), SizedBox(width: 250, child: meter)]),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: HomeSky(
        scene: HomeScene.fantasy,
        blockers: [_cardKey],
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 24 : 48),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: CkReveal(child: card)),
          ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sunset, width: 3)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sunset, width: 3)),
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
        transform: Matrix4.translationValues(isSelected ? 4.0 : 0.0, isSelected ? 4.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sky : AppColors.cardBg,
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, offset: isSelected ? const Offset(0, 0) : const Offset(6, 6), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, size: 48),
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

  Widget _buildRetro(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text('USER REGISTRATION', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
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
                          style: TextStyle(fontSize: 18, color: AppColors.textMuted, fontWeight: FontWeight.bold),
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
                            Expanded(child: _buildRoleSelector('Player\n(Student)', 'user', Icons.gamepad)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sunset, width: 3)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sunset, width: 3)),
                            ),
                            iconEnabledColor: AppColors.ink,
                            dropdownColor: AppColors.cardBg,
                            items: subjects
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink))))
                                .toList(),
                            value: selectedSubject,
                            onChanged: (val) => setState(() => selectedSubject = val),
                            validator: (v) {
                              if (role == 'teacher' && (v == null || v.isEmpty)) return 'REQUIRED FIELD';
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