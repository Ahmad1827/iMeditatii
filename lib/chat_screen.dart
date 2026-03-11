import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String teacherName;

  const ChatScreen({required this.chatId, required this.teacherName, Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController(); // 🚀 Adăugat pentru scroll web fluid
  final currentUser = FirebaseAuth.instance.currentUser;

  bool isChatEnded = false;
  String teacherId = '';
  String studentId = '';
  bool isSessionPaid = false;
  bool isStudentAccepted = false;
  bool _isLoadingPayment = false;

  // 🚀 Variabilă nouă pentru a reține prețul profesorului
  int _teacherPrice = 50;

  final String ownerEmail = 'ahmadarnaoute1896@gmail.com';

  bool get isOwner => currentUser?.email == ownerEmail;
  bool get isTeacher => currentUser?.uid == teacherId;

  // Lista pentru mesajele locale (eroare) care nu se duc în Firebase
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

        // 🚀 Căutăm dinamic prețul profesorului din contul său
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elev acceptat! Acum acesta poate plăti ședința.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    }
  }

  Future<void> openPaymentPage() async {
    if (teacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eroare: Nu am putut identifica profesorul.')));
      return;
    }
    setState(() => _isLoadingPayment = true);

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');

      // 🚀 Transformăm prețul în cenți/bani (ex: 80 RON devin 8000 pentru Stripe)
      final amountInCents = _teacherPrice * 100;

      final result = await callable.call({'chatId': widget.chatId, 'teacherId': teacherId, 'amount': amountInCents});

      final String stripeUrl = result.data['url'];
      final Uri url = Uri.parse(stripeUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Nu pot deschide browserul pentru plată.';
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Eroare la procesarea plății", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => context.pop(), child: const Text("Închide", style: TextStyle(color: Color(0xFF0F172A))))],
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesiune deblocată manual!'), backgroundColor: Color(0xFF0F172A)));
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Sesiune neplătită", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Sesiunea trebuie achitată înainte de a începe apelul video.", style: TextStyle(color: Colors.black87)),
          actions: [TextButton(onPressed: () => context.pop(), child: const Text("Am înțeles", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)))],
        ),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    // Interceptăm mesajul dacă e elev și nu e acceptat
    if (!isTeacher && !isOwner && !isStudentAccepted) {
      setState(() {
        _localSystemMessages.insert(0, {
          'text': "⚠️ Așteaptă ca profesorul să accepte cererea ta înainte de a trimite alte mesaje.",
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
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Cum a fost ședința?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Evaluează profesorul:', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => rating = index + 1),
                        child: Icon(index < rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 44),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Lasă un comentariu (opțional)...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => context.pop(), child: const Text('Omite', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: isSubmitting ? null : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await FirebaseFirestore.instance.collection('teachers').doc(teacherId).collection('reviews').add({
                              'rating': rating, 'comment': reviewController.text.trim(), 'createdAt': Timestamp.now(), 'studentId': currentUser!.uid,
                            });
                            if (mounted) context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recenzie trimisă! Îți mulțumim!')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
                            setState(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Trimite', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.shade200, height: 1)),
        title: GestureDetector(
          onTap: () {
            final currentUid = currentUser!.uid;
            final amITeacher = currentUid == teacherId && teacherId.isNotEmpty;
            final targetId = amITeacher ? (studentId.isNotEmpty ? studentId : null) : (teacherId.isNotEmpty ? teacherId : null);
            if (targetId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil indisponibil.")));
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
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                child: Text(widget.teacherName.isNotEmpty ? widget.teacherName[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.teacherName.isNotEmpty ? widget.teacherName : 'Chat', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!isSessionPaid && !isTeacher) const Text("Apel blocat", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                    if (isSessionPaid) const Text("Sesiune deblocată", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isTeacher || isOwner)
            IconButton(
              icon: Icon(isSessionPaid ? Icons.lock_open_rounded : Icons.lock_outline_rounded, color: isSessionPaid ? Colors.green : (isOwner ? const Color(0xFF8B5CF6) : Colors.orange)),
              tooltip: isSessionPaid ? "Sesiune plătită" : (isOwner ? "Deblochează manual" : "Așteaptă plata..."),
              onPressed: (!isSessionPaid && isOwner) ? _unlockSessionByOwner : null,
            ),
          Container(
            margin: const EdgeInsets.only(right: 12, left: 8),
            decoration: BoxDecoration(color: isSessionPaid || isOwner ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(Icons.videocam_rounded, color: isSessionPaid || isOwner ? const Color(0xFF3B82F6) : Colors.grey.shade400),
              tooltip: "Pornește apelul video",
              onPressed: _handleVideoCallPress,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BANNER ALBASTRU (Profesor)
          if (isTeacher && !isStudentAccepted)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Acest elev dorește meditații. Ești de acord să îl preiei?", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _acceptStudent,
                    child: const Text("Acceptă", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // 2. BANNER PORTOCALIU (Elev în așteptare)
          if (!isTeacher && !isStudentAccepted)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(child: Text("Poți discuta cu profesorul. Așteaptă ca acesta să îți accepte cererea pentru a putea plăti ședința video.", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4))),
                ],
              ),
            ),

          // 3. BANNER VERDE (Plată) - 🚀 Acum afișează prețul dinamic!
          if (!isTeacher && isStudentAccepted && !isSessionPaid)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Profesorul a acceptat! Plătește contravaloarea ședinței pentru a debloca apelul video.", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _isLoadingPayment ? null : openPaymentPage,
                    child: _isLoadingPayment
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Plătește $_teacherPrice RON"), // 🚀 Text Dinamic
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
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.videocam_rounded, color: Colors.green, size: 20)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text("Un apel video este în curs!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () async {
                          await context.push('/video-call/$roomId');

                          if (isTeacher || isOwner) {
                            await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'activeCall': FieldValue.delete(), 'isSessionPaid': false});
                          } else {
                            _showReviewDialog();
                          }
                        },
                        child: const Text("Alătură-te"),
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                        Icon(Icons.forum_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Scrie un mesaj pentru a începe discuția.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // 🚀 Am adăugat Scrollbar-ul pentru mesaje!
                return Scrollbar(
                  controller: _chatScrollController,
                  child: ListView.builder(
                    controller: _chatScrollController, // 🚀 Conectat
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    reverse: true,
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      final msg = allMessages[index];

                      if (msg['isSystem'] == true) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                msg['text'],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }

                      final isMe = msg['senderId'] == currentUser!.uid;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF3B82F6) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                            ),
                            boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            border: isMe ? null : Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : const Color(0xFF0F172A), fontSize: 15, height: 1.3)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, max(12, MediaQuery.of(context).padding.bottom)),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => sendMessage(), // Permite trimiterea cu Enter
                    decoration: InputDecoration(
                      hintText: 'Scrie un mesaj...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}