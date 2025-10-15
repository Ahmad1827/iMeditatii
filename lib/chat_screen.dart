import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_screen.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'video_call_screen.dart';
import 'user_profile_view_screen.dart';
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String teacherName;

  const ChatScreen({required this.chatId, required this.teacherName, Key? key})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  bool isChatEnded = false;
  String teacherId = '';
  String studentId = '';

  final String stripePaymentLink =
      'https://buy.stripe.com/test_14A9AV8ZX7bKfYpeyf5ZC00'; // Link Stripe

  void markMessagesAsRead() async {
    final chatRef =
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final msgRef = chatRef.collection('messages');

    final unread = await msgRef
        .where('senderId', isNotEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();

    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get().then((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        setState(() {
          isChatEnded = data['isEnded'] == true;
          teacherId = data['teacherId'] ?? '';
          studentId = data['studentId'] ?? '';
        });
      }
    });
  }


  Future<void> openPaymentPage() async {
    final Uri url = Uri.parse(stripePaymentLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu se poate deschide pagina de plată')),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final chatRef =
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final msgRef = chatRef.collection('messages');

    // adaugă mesaj
    await msgRef.add({
      'senderId': currentUser!.uid,
      'text': text,
      'createdAt': Timestamp.now(),
      'isRead': false,
    });

    // actualizează ultimul mesaj
    await chatRef.set({
      'lastMessage': text,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  final JitsiMeet jitsiMeet = JitsiMeet();
  Future<void> _startVideoCall(BuildContext context, String roomId) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // scrie în Firestore că apelul e activ
    await chatRef.set({
      'activeCall': {
        'roomId': roomId,
        'startedBy': currentUser!.uid,
        'startedAt': Timestamp.now(),
      }
    }, SetOptions(merge: true));

    // deschide ecranul de apel pentru cel care a pornit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(roomId: roomId),
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
    jitsiMeet.hangUp();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: GestureDetector(
          onTap: () {
            final currentUid = currentUser!.uid;
            // dacă utilizatorul curent este teacher => arătăm profilul studentului, altfel arătăm profilul teacherului
            final isTeacher = currentUid == teacherId && teacherId.isNotEmpty;
            final targetId = isTeacher
                ? (studentId.isNotEmpty ? studentId : null)
                : (teacherId.isNotEmpty ? teacherId : null);

            if (targetId == null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Profil indisponibil.")));
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileViewScreen(userId: targetId)),
            );

          },
          child: Text(
            widget.teacherName.isNotEmpty ? 'Chat cu ${widget.teacherName}' : 'Chat',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.blueAccent),
            tooltip: "Pornește apelul video",
            onPressed: () async {
              final chatRef =
              FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

              await chatRef.set({
                'activeCall': {
                  'roomId': widget.chatId,
                  'startedBy': currentUser!.uid,
                  'startedAt': Timestamp.now(),
                }
              }, SetOptions(merge: true));

              // pornește apelul pentru cel care l-a inițiat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen(roomId: widget.chatId),
                ),
              );
            },

          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null || data['activeCall'] == null) {
                return const SizedBox.shrink();
              }

              final callData = data['activeCall'] as Map<String, dynamic>;
              final roomId = callData['roomId'];

              return Container(
                color: Colors.green[50],
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Apel video activ!"),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_call),
                      label: const Text("Join"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoCallScreen(roomId: roomId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          if (isChatEnded)
            Container(
              color: Colors.yellow[100],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: const [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Această conversație s-a încheiat.'))
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                // 🔥 Banner pentru apel activ
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final hasActiveCall = data?['activeCall'] == true;

                    if (hasActiveCall) {
                      return Container(
                        color: Colors.green[100],
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(Icons.video_call, color: Colors.green),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text("Un apel video este activ acum"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VideoCallScreen(roomId: widget.chatId),
                                  ),
                                );
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

                // 🔥 Chat-ul propriu-zis
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId'] == currentUser!.uid;

                          return Align(
                            alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blueAccent : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  if (!isMe)
                                    BoxShadow(
                                      color: Colors.black12.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                ],
                              ),
                              child: Text(
                                msg['text'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Scrie un mesaj către profesor...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
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
