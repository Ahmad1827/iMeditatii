import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky;
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
    final effectiveText = widget.textColor ?? Colors.white;

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

class ReviewScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String chatId;

  const ReviewScreen({
    required this.teacherId,
    required this.teacherName,
    required this.chatId,
    super.key,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // ---- clean state
  int? _hoverStar;
  final Set<String> _tags = {};
  String? _error;
  final GlobalKey _cardKey = GlobalKey();

  static const _labels = ['Slab', 'Acceptabil', 'Bun', 'Foarte bun', 'Excelent'];
  static const _faces = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];
  static const _faceColors = [Color(0xFFE5484D), Color(0xFFEA7A2B), Color(0xFFF59E0B), Color(0xFF84CC16), Color(0xFF10B981)];
  static const _goodTags = ['Explică clar', 'Răbdător', 'Punctual', 'Materiale bune', 'Aș recomanda'];
  static const _badTags = ['Prea rapid', 'Greu de înțeles', 'A întârziat', 'Probleme tehnice'];

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false, String? friendly}) {
    if (AppStyle.current.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendly ?? AppStyle.sentence(message), style: const TextStyle(color: Colors.white)),
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

  Future<void> _submitReview() async {
    final clean = AppStyle.current.isClean;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (clean) {
        setState(() => _error = 'Trebuie să fii autentificat ca să lași o recenzie.');
      } else {
        _showSnackbar('AUTHENTICATION REQUIRED TO SUBMIT REVIEW.', isError: true);
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        if (mounted) setState(() => _isSubmitting = false);
        if (clean) {
          setState(() => _error = 'Nu am găsit profilul tău. Completează-ți profilul și încearcă din nou.');
        } else {
          _showSnackbar('ERROR: USER PROFILE NOT FOUND.', isError: true);
        }
        return;
      }

      final userName = userDoc.data()?['name'] ?? 'ANONYMOUS';

      final reviewData = {
        'userId': user.uid,
        'userName': userName,
        'studentName': userName,
        'rating': _rating.toDouble(),
        'comment': _commentController.text.trim(),
        'createdAt': Timestamp.now(),
        'chatId': widget.chatId,
        if (_tags.isNotEmpty) 'tags': _tags.toList(),
      };

      await FirebaseFirestore.instance.collection('teachers').doc(widget.teacherId).collection('reviews').add(reviewData);

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'reviewed': true});

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/chat/${widget.chatId}');
        }
        _showSnackbar('REVIEW LOGGED SUCCESSFULLY.', friendly: 'Mulțumim! Recenzia ta a fost publicată.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (clean) {
        setState(() => _error = 'Nu am putut trimite recenzia. Încearcă din nou.');
      } else {
        _showSnackbar('TRANSMISSION ERROR: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — star rating with a mood face and labels, quick tags, live preview
  // of how the review will look on the teacher's profile. Meadow scene.
  // ===========================================================================
  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;
    final shown = _hoverStar ?? _rating;
    final faceColor = _faceColors[shown - 1];

    final stars = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final on = i < shown;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoverStar = i + 1),
          onExit: (_) => setState(() => _hoverStar = null),
          child: GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: on && (_hoverStar == i + 1 || (_hoverStar == null && _rating == i + 1)) ? 1.18 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded, size: isMobile ? 42 : 50, color: on ? const Color(0xFFF59E0B) : Pb.border),
              ),
            ),
          ),
        );
      }),
    );

    final tags = (_rating >= 4 ? _goodTags : [..._badTags, ..._goodTags.take(2)]);

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Înapoi',
              icon: Icon(Icons.arrow_back, color: Pb.muted),
              onPressed: () => context.canPop() ? context.pop() : context.go('/chat/${widget.chatId}'),
            ),
            const SizedBox(width: 4),
            Text('Recenzie', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
          ],
        ),
        const SizedBox(height: 6),
        Center(child: CkAvatar(name: widget.teacherName, image: '', size: 56)),
        const SizedBox(height: 10),
        Text('Cum a fost lecția cu ${widget.teacherName}?',
            textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 21 : 24, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text('Părerea ta îi ajută pe alți elevi să aleagă profesorul potrivit.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted)),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(_faces[shown - 1], key: ValueKey(shown), size: 46, color: faceColor),
        ),
        const SizedBox(height: 8),
        stars,
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(_labels[shown - 1], key: ValueKey('l$shown'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: faceColor)),
        ),
        const SizedBox(height: 22),
        Text(_rating >= 4 ? 'Ce ți-a plăcut?' : 'Ce n-a mers bine?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in tags)
              CkHover(
                onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                builder: (h) {
                  final sel = _tags.contains(t);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? Pb.primary.withOpacity(0.12) : (h ? Pb.hoverBg : Colors.transparent),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: sel ? Pb.primary.withOpacity(0.6) : Pb.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sel) ...[Icon(Icons.check, size: 14, color: Pb.link), const SizedBox(width: 4)],
                        Text(t, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.link : Pb.text)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Comentariu', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(width: 6),
            Text('(opțional)', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            const Spacer(),
            Text('${_commentController.text.length}/500', style: TextStyle(fontSize: 12, color: Pb.muted)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 500,
          style: TextStyle(fontSize: 15, color: Pb.text, height: 1.5),
          cursorColor: Pb.primary,
          decoration: Pb.input(hint: 'Ce ar trebui să știe un alt elev despre lecție?').copyWith(counterText: '', contentPadding: const EdgeInsets.all(14)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14))),
        ],
        const SizedBox(height: 18),
        PbButton(
          text: 'Publică recenzia',
          icon: Icons.send_outlined,
          fullWidth: true,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submitReview,
        ),
      ],
    );

    // live preview of how it will show on the profile
    final preview = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: Pb.muted),
              const SizedBox(width: 6),
              Text('Așa va apărea pe profil', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 16, backgroundColor: Pb.primary.withOpacity(0.14), child: const Icon(Icons.person, size: 16, color: Pb.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                    const SizedBox(height: 2),
                    Row(children: List.generate(5, (i) => Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 15, color: const Color(0xFFF59E0B)))),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final t in _tags)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: Pb.border)),
                              child: Text(t, style: TextStyle(fontSize: 11.5, color: Pb.text)),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _commentController.text.trim().isEmpty ? 'Fără comentariu.' : _commentController.text.trim(),
                      style: TextStyle(fontSize: 13.5, color: _commentController.text.trim().isEmpty ? Pb.muted : Pb.text, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final card = Container(
      key: _cardKey,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: ckDeco(r: 20),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, const SizedBox(height: 18), preview])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: form), const SizedBox(width: 24), SizedBox(width: 280, child: Padding(padding: const EdgeInsets.only(top: 56), child: preview))],
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
            title: Text(
              'SESSION REVIEW',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0),
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
                          color: AppColors.sky,
                          border: Border.all(color: AppColors.border, width: 3),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'EVALUATE MENTOR:',
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
                              widget.teacherName.toUpperCase(),
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
                      const SizedBox(height: 48),
                      Text(
                        'RATE YOUR EXPERIENCE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _rating = index + 1),
                              child: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: AppColors.sunset,
                                size: 64,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _commentController,
                        maxLines: 6,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink, height: 1.5),
                        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                        decoration: InputDecoration(
                          hintText: 'ENTER OPTIONAL LOG DETAILS...',
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
                        text: 'TRANSMIT LOG',
                        bgColor: AppColors.forest,
                        textColor: Colors.white,
                        isFullWidth: true,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? () {} : _submitReview,
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