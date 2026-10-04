import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky;
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbAlert, PbAlertType;

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

class PaidMessageScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const PaidMessageScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<PaidMessageScreen> createState() => _PaidMessageScreenState();
}

class _PaidMessageScreenState extends State<PaidMessageScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  int? _initialPrice;
  bool _isPaying = false;

  // ---- clean state
  int _step = 0; // 0 idle, 1 verifying, 2 paying, 3 sending
  String? _error;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialPrice = 20 + Random().nextInt(30);
    _msgCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendPaidMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }
    if (_msgCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Scrie mesajul înainte să plătești.');
      return;
    }

    setState(() {
      _isPaying = true;
      _error = null;
      _step = 1;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _step = 2);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _step = 3);

      final chatRef = FirebaseFirestore.instance.collection('chats').doc();

      await chatRef.set({
        'userId': user.uid,
        // 'studentId' + names so the chat shows up in both dashboards
        'studentId': user.uid,
        'teacherId': widget.teacherId,
        'teacherName': widget.teacherName,
        'lastMessage': _msgCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isInitialPaid': true,
        'isEnded': false,
        'pricePerMessage': _initialPrice,
        'messagesCount': 1,
      });

      await chatRef.collection('messages').doc().set({
        'senderId': user.uid,
        'text': _msgCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isPaid': true,
        'price': _initialPrice,
      });

      if (!mounted) return;

      context.pushReplacement('/chat/${chatRef.id}', extra: widget.teacherName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _step = 0;
        _error = 'Nu am putut trimite mesajul. Nu ți-am luat bani. Încearcă din nou.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — message composer + a receipt card that walks through the payment
  // steps while sending. Meadow scene.
  // ===========================================================================
  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;
    final price = _initialPrice ?? 0;
    final words = _msgCtrl.text.trim().isEmpty ? 0 : _msgCtrl.text.trim().split(RegExp(r'\s+')).length;

    final composer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Înapoi',
              icon: Icon(Icons.arrow_back, color: Pb.muted),
              onPressed: _isPaying ? null : () => context.canPop() ? context.pop() : context.go('/materii'),
            ),
            const SizedBox(width: 4),
            Text('Mesaj direct', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CkAvatar(name: widget.teacherName, image: '', size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Către', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  Text(widget.teacherName, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Pb.text)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Mesajul tău', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
            const Spacer(),
            Text('$words ${words == 1 ? 'cuvânt' : 'cuvinte'}', style: TextStyle(fontSize: 12, color: Pb.muted)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _msgCtrl,
          enabled: !_isPaying,
          maxLines: 7,
          style: TextStyle(fontSize: 15, color: Pb.text, height: 1.5),
          cursorColor: Pb.primary,
          decoration: Pb.input(hint: 'Salut! Aș avea nevoie de ajutor cu…\n\nSpune-i pe scurt ce vrei să lucrați, ce clasă ești și când ești disponibil.')
              .copyWith(contentPadding: const EdgeInsets.all(14)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in const ['Pregătire pentru Bac', 'Ajutor la temă', 'O lecție de recapitulare'])
              CkHover(
                onTap: _isPaying
                    ? null
                    : () {
                        final t = _msgCtrl.text.trim();
                        _msgCtrl.text = t.isEmpty ? 'Salut! Aș avea nevoie de: $s.' : '$t\n$s.';
                      },
                builder: (h) => AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: h ? Pb.hoverBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Pb.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: Pb.muted),
                      const SizedBox(width: 4),
                      Text(s, style: TextStyle(fontSize: 12.5, color: Pb.text)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14))),
        ],
      ],
    );

    Widget step(int n, String label) {
      final done = _step > n;
      final active = _step == n;
      final c = done ? Pb.primary : (active ? const Color(0xFF3B82F6) : Pb.muted);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: done
                  ? const Icon(Icons.check_circle, size: 18, color: Pb.primary)
                  : (active
                      ? const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))
                      : Icon(Icons.radio_button_unchecked, size: 18, color: Pb.border)),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: c)),
          ],
        ),
      );
    }

    Widget line(String a, String b, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: Text(a, style: TextStyle(fontSize: bold ? 15 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: bold ? Pb.text : Pb.muted))),
              Text(b, style: TextStyle(fontSize: bold ? 17 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: Pb.text)),
            ],
          ),
        );

    final receipt = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: Pb.muted),
              const SizedBox(width: 8),
              Text('Sumar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
            ],
          ),
          const SizedBox(height: 10),
          line('Primul mesaj', '$price RON'),
          line('Comision platformă', '0 RON'),
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _Dashes(color: Pb.border)),
          line('Total', '$price RON', bold: true),
          const SizedBox(height: 14),
          if (_isPaying) ...[
            step(1, 'Verificăm plata'),
            step(2, 'Confirmăm tranzacția'),
            step(3, 'Trimitem mesajul'),
          ] else ...[
            PbButton(
              text: 'Plătește $price RON și trimite',
              icon: Icons.lock_outline,
              fullWidth: true,
              onPressed: _sendPaidMessage,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 14, color: Pb.muted),
                const SizedBox(width: 5),
                Text('Plată securizată', style: TextStyle(fontSize: 12, color: Pb.muted)),
              ],
            ),
          ],
        ],
      ),
    );

    final card = Container(
      key: _cardKey,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: ckDeco(r: 20),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [composer, const SizedBox(height: 18), receipt])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: composer), const SizedBox(width: 24), SizedBox(width: 270, child: Padding(padding: const EdgeInsets.only(top: 56), child: receipt))],
            ),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: HomeSky(
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
  Widget _buildRetro(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text('DIRECT MESSAGE', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
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
              onPressed: () => context.pop(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.mustard,
                          border: Border.all(color: AppColors.border, width: 3),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TRANSMISSION FEE REQUIRED',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ESTIMATED COST: $_initialPrice RON',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('RECIPIENT:', style: TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        widget.teacherName.toUpperCase(),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.sky, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _msgCtrl,
                        maxLines: 8,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink, height: 1.5),
                        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                        decoration: InputDecoration(
                          hintText: 'ENTER MESSAGE LOG...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          contentPadding: const EdgeInsets.all(24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
                        ),
                      ),
                      const SizedBox(height: 48),
                      RetroButton(
                        text: 'PAY $_initialPrice RON & TRANSMIT',
                        bgColor: AppColors.forest,
                        textColor: Colors.white,
                        isFullWidth: true,
                        isLoading: _isPaying,
                        onPressed: _isPaying ? () {} : _sendPaidMessage,
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

class _Dashes extends StatelessWidget {
  final Color color;
  const _Dashes({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 8).floor();
        return Row(
          children: List.generate(n, (_) => Expanded(child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 2), color: color))),
        );
      },
    );
  }
}