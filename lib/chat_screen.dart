import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
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

  bool isChatEnded = false;
  String teacherId = '';
  String studentId = '';
  bool isSessionPaid = false;
  bool isStudentAccepted = false;
  bool _isLoadingPayment = false;

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
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
      'isStudentAccepted': true
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('MANUAL OVERRIDE: SESSION UNLOCKED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.ink,
        )
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
                        onPressed: isSubmitting ? () {} : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await FirebaseFirestore.instance.collection('teachers').doc(teacherId).collection('reviews').add({
                              'rating': rating, 'comment': reviewController.text.trim(), 'createdAt': Timestamp.now(), 'studentId': currentUser!.uid,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Text(
                      widget.teacherName.isNotEmpty ? widget.teacherName[0].toUpperCase() : '?',
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teacherName.isNotEmpty ? widget.teacherName.toUpperCase() : 'CHAT',
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isSessionPaid && !isTeacher) Text("COMM_LOCKED", style: TextStyle(color: AppColors.sunset, fontSize: 14, fontWeight: FontWeight.bold)),
                        if (isSessionPaid) Text("COMM_SECURE", style: TextStyle(color: AppColors.forest, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isTeacher || isOwner)
                IconButton(
                  icon: Icon(isSessionPaid ? Icons.lock_open : Icons.lock, color: isSessionPaid ? AppColors.forest : (isOwner ? AppColors.sky : AppColors.sunset), size: 28),
                  tooltip: isSessionPaid ? "UNLOCKED" : (isOwner ? "OVERRIDE" : "AWAITING PAYMENT"),
                  onPressed: (!isSessionPaid && isOwner) ? _unlockSessionByOwner : null,
                ),
              Container(
                margin: const EdgeInsets.only(right: 16, left: 8),
                decoration: BoxDecoration(
                  color: isSessionPaid || isOwner ? AppColors.sky : AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: IconButton(
                  icon: Icon(Icons.videocam, color: isSessionPaid || isOwner ? (AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink) : AppColors.textMuted),
                  tooltip: "INITIATE FEED",
                  onPressed: _handleVideoCallPress,
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  if (isTeacher && !isStudentAccepted)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 3)),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: AppColors.ink, size: 32),
                          const SizedBox(width: 16),
                          Expanded(child: Text("NEW QUEST REQUEST. ACCEPT STUDENT?", style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                          const SizedBox(width: 16),
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
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 3)),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "AWAITING MENTOR APPROVAL TO UNLOCK SESSION PAYMENT.",
                              style: TextStyle(
                                color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!isTeacher && isStudentAccepted && !isSessionPaid)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.forest, border: Border.all(color: AppColors.border, width: 3)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 32),
                          const SizedBox(width: 16),
                          const Expanded(child: Text("REQUEST APPROVED. PAY TO UNLOCK VIDEO FEED.", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                          const SizedBox(width: 16),
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
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.sky, border: Border.all(color: AppColors.border, width: 3)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                                child: Icon(Icons.videocam, color: AppColors.ink, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "VIDEO FEED ACTIVE!",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                    fontSize: 18,
                                    letterSpacing: 1.5,
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
                          Timestamp timeA = a['createdAt'] as Timestamp;
                          Timestamp timeB = b['createdAt'] as Timestamp;
                          return timeB.compareTo(timeA);
                        });

                        if (allMessages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.terminal, size: 80, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text("AWAITING INITIAL LOG.", style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                              ],
                            ),
                          );
                        }

                        return Scrollbar(
                          controller: _chatScrollController,
                          child: ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            reverse: true,
                            itemCount: allMessages.length,
                            itemBuilder: (context, index) {
                              final msg = allMessages[index];

                              if (msg['isSystem'] == true) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.sunset,
                                        border: Border.all(color: AppColors.border, width: 3),
                                      ),
                                      child: Text(
                                        msg['text'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final isMe = msg['senderId'] == currentUser!.uid;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: RetroBlock(
                                  bgColor: isMe ? AppColors.cloud : AppColors.cardBg,
                                  padding: 16,
                                  shadowOffset: 4,
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                                    child: Text(
                                      msg['text'],
                                      style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, max(24, MediaQuery.of(context).padding.bottom)),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      border: Border(top: BorderSide(color: AppColors.border, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            onSubmitted: (_) => sendMessage(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink),
                            cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                            decoration: InputDecoration(
                              hintText: 'ENTER COMMAND...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 3)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: sendMessage,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                border: Border.all(color: AppColors.border, width: 3),
                                boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4), blurRadius: 0)],
                              ),
                              child: Icon(Icons.send, color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}