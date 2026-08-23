import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void dispose() {
    _commentController.dispose();
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

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('AUTHENTICATION REQUIRED TO SUBMIT REVIEW.', isError: true);
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      _showSnackbar('ERROR: USER PROFILE NOT FOUND.', isError: true);
      return;
    }

    final userName = userDoc.data()?['name'] ?? 'ANONYMOUS';

    final reviewData = {
      'userId': user.uid,
      'userName': userName,
      'rating': _rating.toDouble(),
      'comment': _commentController.text.trim(),
      'createdAt': Timestamp.now(),
      'chatId': widget.chatId,
    };

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherId)
          .collection('reviews')
          .add(reviewData);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'reviewed': true});

      if (mounted) {
        context.pop();
        _showSnackbar('REVIEW LOGGED SUCCESSFULLY.');
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      if (mounted) {
        _showSnackbar('TRANSMISSION ERROR: $e', isError: true);
      }
    }
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
              'SESSION REVIEW',
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
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: 1.0,
                        ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                        cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                        decoration: InputDecoration(
                          hintText: 'ENTER OPTIONAL LOG DETAILS...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          contentPadding: const EdgeInsets.all(24),
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