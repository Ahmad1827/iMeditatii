import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.icon,
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
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            isPressed ? 3.0 : (isHovered ? -1.5 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String teacherName;

  const ChatScreen({required this.chatId, required this.teacherName, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  bool isChatEnded = false;
  String teacherId = '';
  String studentId = '';
  bool isSessionPaid = false;
  bool isStudentAccepted = false;
  bool _isLoadingPayment = false;
  bool _isUploadingImage = false;

  int _teacherPrice = 50;
  final String ownerEmail = 'ahmadarnaoute1896@gmail.com';

  bool get isOwner => currentUser?.email == ownerEmail;
  bool get isTeacher => currentUser?.uid == teacherId;

  final List<Map<String, dynamic>> _localSystemMessages = [];

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();

    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && mounted) {
        setState(() {
          isChatEnded = data['isEnded'] == true;
          teacherId = data['teacherId'] ?? '';
          studentId = data['studentId'] ?? '';
          isSessionPaid = data['isSessionPaid'] == true;
          isStudentAccepted = data['isStudentAccepted'] == true;
        });

        if (teacherId.isNotEmpty) {
          FirebaseFirestore.instance.collection('teachers').doc(teacherId).get().then((doc) {
            if (doc.exists && mounted) {
              setState(() => _teacherPrice = doc.data()?['price'] ?? 50);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void markMessagesAsRead() async {
    if (currentUser == null) return;
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final msgRef = chatRef.collection('messages');
    final unread = await msgRef.where('senderId', isNotEqualTo: currentUser!.uid).where('isRead', isEqualTo: false).get();

    for (var doc in unread.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> _acceptStudent() async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'isStudentAccepted': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('STUDENT ACCEPTED.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.forest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickAndSendImage() async {
    if (currentUser == null) return;
    if (!isTeacher && !isOwner && !isStudentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AWAIT MENTOR APPROVAL BEFORE TRANSMITTING FILES.")),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = FirebaseStorage.instance.ref().child('chat_images/${widget.chatId}/$fileName');

      final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      final msgRef = chatRef.collection('messages');

      await msgRef.add({
        'senderId': currentUser!.uid,
        'text': '',
        'imageUrl': downloadUrl,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });

      await chatRef.set({
        'lastMessage': '📷 [IMAGE ATTACHED]',
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IMAGE TRANSMISSION FAILED: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.border, width: 4),
                boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(8, 8))],
              ),
              padding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.sunset, border: Border.all(color: AppColors.border, width: 2)),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openPaymentPage() async {
    if (teacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ERROR: Mentor missing.')));
      return;
    }
    setState(() => _isLoadingPayment = true);

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');
      final amountInCents = _teacherPrice * 100;
      final result = await callable.call({'chatId': widget.chatId, 'teacherId': teacherId, 'amount': amountInCents});
      final String stripeUrl = result.data['url'];
      final Uri url = Uri.parse(stripeUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch payment gateway.';
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
            title: Text("PAYMENT ERROR", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset)),
            content: Text(e.toString(), style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            actions: [
              RetroButton(
                text: "CLOSE",
                bgColor: AppColors.cloud,
                textColor: AppColors.ink,
                onPressed: () => context.pop(),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPayment = false);
    }
  }

  Future<void> _unlockSessionByOwner() async {
    if (!isOwner) return;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'isSessionPaid': true,
      'isStudentAccepted': true,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('MANUAL OVERRIDE: SESSION UNLOCKED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.ink,
        ),
      );
    }
  }

  Future<void> _handleVideoCallPress() async {
    if (isSessionPaid || isOwner) {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      await chatRef.update({'activeCall': {'roomId': widget.chatId, 'startedBy': currentUser!.uid, 'startedAt': Timestamp.now()}});

      if (mounted) {
        await context.push('/video-call/${widget.chatId}');

        if (isTeacher || isOwner) {
          await chatRef.update({'activeCall': FieldValue.delete(), 'isSessionPaid': false});
        } else {
          _showReviewDialog();
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
          title: Text("SESSION LOCKED", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset)),
          content: Text("Payment required before initiating video feed.", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
          actions: [
            RetroButton(
              text: "ACKNOWLEDGE",
              bgColor: AppColors.sky,
              textColor: Colors.white,
              onPressed: () => context.pop(),
            )
          ],
        ),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    if (!isTeacher && !isOwner && !isStudentAccepted) {
      setState(() {
        _localSystemMessages.insert(0, {
          'text': "WARNING: Await mentor approval before transmitting.",
          'isSystem': true,
          'createdAt': Timestamp.now(),
        });
      });
      _messageController.clear();
      return;
    }

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final msgRef = chatRef.collection('messages');

    await msgRef.add({'senderId': currentUser!.uid, 'text': text, 'createdAt': Timestamp.now(), 'isRead': false});
    await chatRef.set({'lastMessage': text, 'updatedAt': Timestamp.now()}, SetOptions(merge: true));

    _messageController.clear();
  }

  Future<void> _showReviewDialog() async {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
              title: Text('RATE SESSION', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 2.0)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('EVALUATE MENTOR PERFORMANCE:', style: TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => rating = index + 1),
                        child: Icon(index < rating ? Icons.star : Icons.star_border, color: AppColors.sunset, size: 44),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                    decoration: InputDecoration(
                      hintText: 'LEAVE LOG (OPTIONAL)...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        text: 'SKIP',
                        bgColor: AppColors.cloud,
                        textColor: AppColors.ink,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: RetroButton(
                        text: isSubmitting ? '...' : 'SUBMIT',
                        bgColor: AppColors.ink,
                        textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                        onPressed: isSubmitting
                            ? () {}
                            : () async {
                                setDialogState(() => isSubmitting = true);
                                try {
                                  await FirebaseFirestore.instance.collection('teachers').doc(teacherId).collection('reviews').add({
                                    'rating': rating,
                                    'comment': reviewController.text.trim(),
                                    'createdAt': Timestamp.now(),
                                    'studentId': currentUser!.uid,
                                  });
                                  if (mounted) context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LOG SUBMITTED.')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $e')));
                                  setDialogState(() => isSubmitting = false);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime _getDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  String _formatTime(dynamic timestamp) {
    final date = _getDateTime(timestamp);
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;

    if (checkDate == today) {
      return "ASTĂZI • $d.$m.$y";
    } else if (checkDate == yesterday) {
      return "IERI • $d.$m.$y";
    } else {
      return "$d.$m.$y";
    }
  }

  bool _isDifferentDay(DateTime d1, DateTime d2) {
    return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: const Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              _formatDateHeader(date).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
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
            backgroundColor: AppColors.bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: AppColors.ink),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(color: AppColors.border, height: 3)),
            title: GestureDetector(
              onTap: () {
                final currentUid = currentUser!.uid;
                final amITeacher = currentUid == teacherId && teacherId.isNotEmpty;
                final targetId = amITeacher ? (studentId.isNotEmpty ? studentId : null) : (teacherId.isNotEmpty ? teacherId : null);
                if (targetId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PROFILE NOT FOUND.")));
                  return;
                }
                if (amITeacher) {
                  context.go('/elev/$targetId');
                } else {
                  context.go('/profesor/$targetId');
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.mustard,
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2, 2))],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.teacherName.isNotEmpty ? widget.teacherName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teacherName.isNotEmpty ? widget.teacherName.toUpperCase() : 'COMM CHANNEL',
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSessionPaid ? AppColors.forest : AppColors.sunset,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSessionPaid ? "SECURE FEED ACTIVE" : (!isTeacher ? "SESSION LOCKED" : "ONLINE"),
                              style: TextStyle(
                                color: isSessionPaid ? AppColors.forest : AppColors.sunset,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isTeacher || isOwner)
                IconButton(
                  icon: Icon(
                    isSessionPaid ? Icons.lock_open : Icons.lock,
                    color: isSessionPaid ? AppColors.forest : (isOwner ? AppColors.sky : AppColors.sunset),
                    size: 26,
                  ),
                  tooltip: isSessionPaid ? "UNLOCKED" : (isOwner ? "OVERRIDE" : "AWAITING PAYMENT"),
                  onPressed: (!isSessionPaid && isOwner) ? _unlockSessionByOwner : null,
                ),
              Container(
                margin: const EdgeInsets.only(right: 16, left: 6),
                decoration: BoxDecoration(
                  color: isSessionPaid || isOwner ? AppColors.sky : AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.videocam,
                    color: isSessionPaid || isOwner ? (AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink) : AppColors.textMuted,
                    size: 22,
                  ),
                  tooltip: "INITIATE VIDEO FEED",
                  onPressed: _handleVideoCallPress,
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6), blurRadius: 0),
                  ],
                ),
                child: Column(
                  children: [
                    if (isTeacher && !isStudentAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cloud,
                          border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: AppColors.ink, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "NEW QUEST REQUEST. ACCEPT STUDENT?",
                                style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            RetroButton(
                              text: "ACCEPT",
                              bgColor: AppColors.sky,
                              textColor: Colors.white,
                              onPressed: _acceptStudent,
                            ),
                          ],
                        ),
                      ),

                    if (!isTeacher && !isStudentAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.mustard,
                          border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_empty, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "AWAITING MENTOR APPROVAL TO UNLOCK TRANSMISSION.",
                                style: TextStyle(
                                  color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!isTeacher && isStudentAccepted && !isSessionPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 26),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "REQUEST APPROVED. UNLOCK VIDEO FEED.",
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            RetroButton(
                              text: _isLoadingPayment ? "..." : "PAY $_teacherPrice RON",
                              bgColor: AppColors.sunset,
                              textColor: Colors.white,
                              onPressed: _isLoadingPayment ? () {} : openPaymentPage,
                            ),
                          ],
                        ),
                      ),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final hasActiveCall = data?['activeCall'] != null;

                        if (hasActiveCall) {
                          final roomId = (data!['activeCall'] as Map<String, dynamic>)['roomId'];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.sky,
                              border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                                  child: Icon(Icons.videocam, color: AppColors.ink, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "LIVE FEED TRANSMITTING!",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                RetroButton(
                                  text: "JOIN",
                                  bgColor: AppColors.cardBg,
                                  textColor: AppColors.ink,
                                  onPressed: () async {
                                    await context.push('/video-call/$roomId');

                                    if (isTeacher || isOwner) {
                                      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'activeCall': FieldValue.delete(), 'isSessionPaid': false});
                                    } else {
                                      _showReviewDialog();
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('createdAt', descending: true).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: AppColors.sunset));

                          var firebaseMessages = snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            data['isSystem'] = false;
                            return data;
                          }).toList();

                          var allMessages = [..._localSystemMessages, ...firebaseMessages];

                          allMessages.sort((a, b) {
                            Timestamp timeA = a['createdAt'] is Timestamp ? a['createdAt'] as Timestamp : Timestamp.now();
                            Timestamp timeB = b['createdAt'] is Timestamp ? b['createdAt'] as Timestamp : Timestamp.now();
                            return timeB.compareTo(timeA);
                          });

                          if (allMessages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted),
                                  const SizedBox(height: 14),
                                  Text(
                                    "TRANSMISSION LOG EMPTY.",
                                    style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Send your first message or attach homework below.",
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                            reverse: true,
                            itemCount: allMessages.length,
                            itemBuilder: (context, index) {
                              final msg = allMessages[index];
                              final currentDate = _getDateTime(msg['createdAt']);

                              bool showDateHeader = false;
                              if (index == allMessages.length - 1) {
                                showDateHeader = true;
                              } else {
                                final olderMsg = allMessages[index + 1];
                                final olderDate = _getDateTime(olderMsg['createdAt']);
                                if (_isDifferentDay(currentDate, olderDate)) {
                                  showDateHeader = true;
                                }
                              }

                              if (msg['isSystem'] == true) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showDateHeader) _buildDateSeparator(currentDate),
                                    Center(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.sunset,
                                          border: Border.all(color: AppColors.border, width: 2),
                                        ),
                                        child: Text(
                                          msg['text'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final isMe = msg['senderId'] == currentUser!.uid;
                              final hasImage = msg['imageUrl'] != null && msg['imageUrl'].toString().isNotEmpty;
                              final timeStr = _formatTime(msg['createdAt']);

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showDateHeader) _buildDateSeparator(currentDate),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Row(
                                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe) ...[
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.sky,
                                              border: Border.all(color: AppColors.border, width: 2),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              widget.teacherName.isNotEmpty ? widget.teacherName[0].toUpperCase() : 'M',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62),
                                            decoration: BoxDecoration(
                                              color: isMe ? AppColors.cloud : AppColors.inputBg,
                                              border: Border.all(color: AppColors.border, width: 2.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.shadow,
                                                  offset: isMe ? const Offset(3.5, 3.5) : const Offset(-3.5, 3.5),
                                                  blurRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isMe ? AppColors.ink : AppColors.border,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        isMe ? "[PLAYER] YOU" : "[MASTER] ${widget.teacherName.toUpperCase()}",
                                                        style: TextStyle(
                                                          color: isMe ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white) : (AppColors.isDark ? Colors.white : AppColors.cloud),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w900,
                                                          letterSpacing: 1.0,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        timeStr,
                                                        style: TextStyle(
                                                          color: isMe ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white70) : (AppColors.isDark ? Colors.white70 : AppColors.cloud),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'monospace',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                                    children: [
                                                      if (hasImage) ...[
                                                        GestureDetector(
                                                          onTap: () => _showImageDialog(msg['imageUrl']),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              border: Border.all(color: AppColors.border, width: 2),
                                                            ),
                                                            child: ClipRRect(
                                                              child: Image.network(
                                                                msg['imageUrl'],
                                                                fit: BoxFit.cover,
                                                                loadingBuilder: (context, child, progress) {
                                                                  if (progress == null) return child;
                                                                  return Container(
                                                                    height: 180,
                                                                    width: 220,
                                                                    color: AppColors.inputBg,
                                                                    child: Center(
                                                                      child: CircularProgressIndicator(color: AppColors.sunset),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      if (msg['text'] != null && msg['text'].toString().isNotEmpty) ...[
                                                        if (hasImage) const SizedBox(height: 8),
                                                        Text(
                                                          msg['text'],
                                                          style: TextStyle(
                                                            color: AppColors.ink,
                                                            fontSize: 17,
                                                            fontWeight: FontWeight.w700,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.mustard,
                                              border: Border.all(color: AppColors.border, width: 2),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "P",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        border: Border(top: BorderSide(color: AppColors.border, width: 3)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _pickAndSendImage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                border: Border.all(color: AppColors.border, width: 2),
                                boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2, 2))],
                              ),
                              child: _isUploadingImage
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sunset))
                                  : Icon(Icons.add_photo_alternate, color: AppColors.ink, size: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onSubmitted: (_) => sendMessage(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.ink),
                              cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                              decoration: InputDecoration(
                                hintText: '> ENTER COMMAND...',
                                hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                filled: true,
                                fillColor: AppColors.inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2.5)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2.5)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 2.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: sendMessage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                border: Border.all(color: AppColors.border, width: 2.5),
                                boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    "SEND",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 14),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.send, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}