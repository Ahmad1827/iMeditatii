import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';

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
  final bool isLoading;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
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
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => setState(() => isPressed = true),
        onTapUp: widget.isLoading ? null : (_) {
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
            color: widget.isLoading ? Colors.grey : widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
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
              color: widget.textColor,
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

  @override
  void initState() {
    super.initState();
    _initialPrice = 20 + Random().nextInt(30);
  }

  Future<void> _sendPaidMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _msgCtrl.text.trim().isEmpty) return;

    setState(() => _isPaying = true);

    await Future.delayed(const Duration(seconds: 2));

    final chatRef = FirebaseFirestore.instance.collection('chats').doc();

    await chatRef.set({
      'userId': user.uid,
      'teacherId': widget.teacherId,
      'lastMessage': _msgCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isInitialPaid': true,
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

    context.pushReplacement(
      '/chat/${chatRef.id}',
      extra: widget.teacherName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'DIRECT MESSAGE',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
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
                      border: Border.all(color: AppColors.ink, width: 3),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TRANSMISSION FEE REQUIRED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ESTIMATED COST: $_initialPrice RON',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'RECIPIENT:',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.teacherName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.sky,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 8,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ENTER MESSAGE LOG...',
                      hintStyle: TextStyle(
                        color: Colors.black38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.ink, width: 3),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.ink, width: 3),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.sky, width: 3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  RetroButton(
                    text: 'PAY $_initialPrice RON & TRANSMIT',
                    bgColor: AppColors.forest,
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
  }
}