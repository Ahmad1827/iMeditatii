import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky;
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, showPbModal;

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
  bool isStudentAccepted = false;
  bool _isLoadingPayment = false;
  bool _isUploadingImage = false;

  Map<String, dynamic>? activeSession;
  int _teacherPrice = 50;
  final String ownerEmail = 'ahmadarnaoute1896@gmail.com';

  bool get isOwner => currentUser?.email == ownerEmail;
  bool get isTeacher => currentUser?.uid == teacherId;
  bool get isSessionPaid => activeSession != null && activeSession!['isPaid'] == true && activeSession!['status'] == 'active';

  final List<Map<String, dynamic>> _localSystemMessages = [];

  // listener + streams created once
  StreamSubscription? _chatSub;
  bool _priceLoaded = false;
  late final Stream<QuerySnapshot> _messages = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots();
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPaymentReturn();
    });

    _chatSub = FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && mounted) {
        setState(() {
          isChatEnded = data['isEnded'] == true;
          teacherId = data['teacherId'] ?? '';
          studentId = data['studentId'] ?? data['userId'] ?? '';
          isStudentAccepted = data['isStudentAccepted'] == true;
          activeSession = data['activeSession'] as Map<String, dynamic>?;
        });

        if (teacherId.isNotEmpty && !_priceLoaded) {
          _priceLoaded = true;
          FirebaseFirestore.instance.collection('teachers').doc(teacherId).get().then((doc) {
            if (doc.exists && mounted) {
              final p = doc.data()?['price'];
              setState(() => _teacherPrice = p is num ? p.toInt() : (int.tryParse('$p') ?? 50));
            }
          });
        }
      }
    });
  }

  bool get _clean => AppStyle.current.isClean;

  void _toast(String retro, {String? clean, bool error = false}) {
    if (!mounted) return;
    if (_clean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(clean ?? AppStyle.sentence(retro), style: const TextStyle(color: Colors.white)),
          backgroundColor: error ? const Color(0xFFB4232A) : const Color(0xFF212529),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: Pb.radius),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(retro, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: error ? AppColors.sunset : AppColors.forest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
        ),
      );
    }
  }

  void _checkPaymentReturn() async {
    final uri = Uri.base;
    final paymentStatus = uri.queryParameters['payment'];
    final sessionId = uri.queryParameters['sessionId'];

    if (paymentStatus == 'success' && sessionId != null) {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'activeSession': {
          'sessionId': sessionId,
          'isPaid': true,
          'status': 'active',
          'paidAt': FieldValue.serverTimestamp(),
          'paidBy': currentUser?.uid,
        },
        'isSessionPaid': true,
      }, SetOptions(merge: true));

      if (kIsWeb) {
        final cleanUrl = uri.path;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(cleanUrl);
          context.push('/video-call/${widget.chatId}');
        });
      }
    } else if (paymentStatus == 'cancelled') {
      _toast('PAYMENT CANCELLED. ACCESS RESTRICTED.', clean: 'Plata a fost anulată. Nu ți-am luat bani.', error: true);
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void markMessagesAsRead() async {
    if (currentUser == null) return;
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      final msgRef = chatRef.collection('messages');
      final unread = await msgRef.where('senderId', isNotEqualTo: currentUser!.uid).where('isRead', isEqualTo: false).get();

      for (var doc in unread.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('markMessagesAsRead: $e');
    }
  }

  Future<void> _acceptStudent() async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'isStudentAccepted': true});
      _toast('STUDENT ACCEPTED.', clean: 'Ai acceptat elevul. Acum vă puteți scrie.');
    } catch (e) {
      _toast('Error: $e', clean: 'Nu am putut accepta cererea. Încearcă din nou.', error: true);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (currentUser == null) return;
    if (!isTeacher && !isOwner && !isStudentAccepted) {
      _toast('AWAIT MENTOR APPROVAL BEFORE TRANSMITTING FILES.', clean: 'Poți trimite poze după ce profesorul îți acceptă cererea.', error: true);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);

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
        'lastMessage': '📷 Imagine',
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      _toast('IMAGE TRANSMISSION FAILED: $e', clean: 'Nu am putut trimite imaginea.', error: true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageDialog(String imageUrl) {
    if (_clean) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: InteractiveViewer(maxScale: 5, child: Image.network(imageUrl, fit: BoxFit.contain)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
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
              child: InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain)),
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

  Future<void> _startOrJoinCall() async {
    if (teacherId.isEmpty) return;

    if (isTeacher || isOwner) {
      final existingSessionId = activeSession?['sessionId'];
      final sessionId = existingSessionId ?? 'sess_${DateTime.now().millisecondsSinceEpoch}';

      if (existingSessionId == null) {
        await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
          'activeSession': {
            'sessionId': sessionId,
            'status': 'active',
            'isPaid': false,
            'createdAt': FieldValue.serverTimestamp(),
          },
          'activeCall': {'roomId': widget.chatId, 'startedBy': currentUser!.uid, 'startedAt': Timestamp.now()}
        }, SetOptions(merge: true));
      }

      if (mounted) {
        await context.push('/video-call/${widget.chatId}');
      }
      return;
    }

    if (isSessionPaid) {
      await context.push('/video-call/${widget.chatId}');
      return;
    }

    setState(() => _isLoadingPayment = true);

    try {
      final amountInCents = _teacherPrice * 100;

      final response = await http.post(
        Uri.parse('https://us-central1-imeditatii.cloudfunctions.net/createPaymentIntent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chatId': widget.chatId,
          'teacherId': teacherId,
          'studentId': currentUser?.uid ?? '',
          'amount': amountInCents,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['error'] != null) {
        throw data['error'] ?? 'Eroare necunoscută la inițializarea plății.';
      }

      final clientSecret = data['clientSecret'];
      final publishableKey = data['publishableKey'];
      final sessionId = data['sessionId'];

      final piperUrl = Uri.parse('/piper/index.html'
          '?pk=$publishableKey'
          '&client_secret=$clientSecret'
          '&chatId=${widget.chatId}'
          '&sessionId=$sessionId'
          '&amount=${_teacherPrice.toStringAsFixed(2)}+RON'
          '&item=${Uri.encodeComponent("SESIUNE: ${widget.teacherName}")}');

      await launchUrl(piperUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      final rawMessage = e.toString();
      final stripeMissing = rawMessage.contains("No such destination") ||
          rawMessage.contains("stripeAccountId") ||
          rawMessage.contains("nu are contul Stripe") ||
          rawMessage.contains("destination");

      if (!mounted) return;
      if (_clean) {
        showPbModal<void>(
          context,
          title: stripeMissing ? 'Profesorul nu poate primi plăți încă' : 'Plata nu a pornit',
          body: Text(stripeMissing
              ? '${widget.teacherName} nu și-a configurat încă contul de plăți. Scrie-i în chat să-l configureze din profilul său, apoi încearcă din nou.'
              : 'Nu am putut porni plata. Verifică internetul și încearcă din nou.\n\nDetalii: $rawMessage'),
          actions: (ctx) => [PbButton(text: 'Am înțeles', onPressed: () => Navigator.of(ctx).pop())],
        );
      } else {
        final friendlyMessage = stripeMissing
            ? "TEACHER SETUP REQUIRED:\nPlease ask ${widget.teacherName} to set up their Stripe bank account in their profile before initiating paid sessions."
            : rawMessage;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
            title: Text("PAYMENT NOTICE", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset)),
            content: Text(friendlyMessage, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.4)),
            actions: [
              RetroButton(text: "UNDERSTOOD", bgColor: AppColors.ink, textColor: Colors.white, onPressed: () => context.pop()),
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
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'activeSession': {
        'sessionId': 'override_${DateTime.now().millisecondsSinceEpoch}',
        'isPaid': true,
        'status': 'active',
        'paidAt': FieldValue.serverTimestamp(),
      },
      'isSessionPaid': true,
      'isStudentAccepted': true,
    }, SetOptions(merge: true));

    _toast('MANUAL OVERRIDE: SESSION UNLOCKED', clean: 'Sesiune deblocată manual (admin).');
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    if (!isTeacher && !isOwner && !isStudentAccepted) {
      setState(() {
        _localSystemMessages.insert(0, {
          'text': _clean
              ? 'Poți scrie după ce profesorul îți acceptă cererea.'
              : "WARNING: Await mentor approval before transmitting.",
          'isSystem': true,
          'createdAt': Timestamp.now(),
        });
      });
      _messageController.clear();
      return;
    }

    _messageController.clear();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final msgRef = chatRef.collection('messages');

    await msgRef.add({'senderId': currentUser!.uid, 'text': text, 'createdAt': Timestamp.now(), 'isRead': false});
    await chatRef.set({'lastMessage': text, 'updatedAt': Timestamp.now()}, SetOptions(merge: true));
  }

  void _openOtherProfile() {
    if (currentUser == null) return;
    final amITeacher = currentUser!.uid == teacherId && teacherId.isNotEmpty;
    final targetId = amITeacher ? (studentId.isNotEmpty ? studentId : null) : (teacherId.isNotEmpty ? teacherId : null);
    if (targetId == null) {
      _toast('PROFILE NOT FOUND.', clean: 'Nu am găsit profilul.', error: true);
      return;
    }
    context.go(amITeacher ? '/elev/$targetId' : '/profesor/$targetId');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(isTeacher ? '/panou-profesor' : '/panou-elev');
    }
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

  List<Map<String, dynamic>> _mergeMessages(QuerySnapshot snap) {
    final firebaseMessages = snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['isSystem'] = false;
      return data;
    }).toList();

    final all = [..._localSystemMessages, ...firebaseMessages];
    all.sort((a, b) {
      final ta = a['createdAt'] is Timestamp ? a['createdAt'] as Timestamp : Timestamp.now();
      final tb = b['createdAt'] is Timestamp ? b['createdAt'] as Timestamp : Timestamp.now();
      return tb.compareTo(ta);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — messenger layout: grouped bubbles with read receipts, date chips,
  // status cards for the lesson flow, and smart quick replies. Meadow scene.
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);

  List<String> get _quickReplies => isTeacher
      ? const ['Bună! Te pot ajuta cu asta.', 'Când ești disponibil pentru o lecție?', 'Trimite-mi o poză cu exercițiul.', 'Pornesc apelul în câteva minute.']
      : const ['Bună ziua! Am nevoie de ajutor la…', 'Când sunteți disponibil?', 'Cât durează o lecție?', 'Mulțumesc mult!'];

  Widget _cBanner({required Color color, required IconData icon, required String text, Widget? action}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), border: Border(bottom: BorderSide(color: Pb.border))),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.35))),
          if (action != null) ...[const SizedBox(width: 10), action],
        ],
      ),
    );
  }

  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final canCall = isSessionPaid || isTeacher || isOwner;
    final statusColor = isSessionPaid ? Pb.primary : (isStudentAccepted || isTeacher ? _cBlue : _cAmber);
    final statusText = isSessionPaid
        ? 'Lecție plătită, poți intra în apel'
        : (isTeacher ? (isStudentAccepted ? 'Elev acceptat' : 'Cerere nouă') : (isStudentAccepted ? 'Cerere acceptată' : 'Așteaptă acceptarea'));

    final header = Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Pb.border))),
      child: Row(
        children: [
          IconButton(tooltip: 'Înapoi', icon: Icon(Icons.arrow_back, color: Pb.muted), onPressed: _goBack),
          Expanded(
            child: CkHover(
              onTap: _openOtherProfile,
              builder: (h) => Row(
                children: [
                  CkAvatar(name: widget.teacherName, image: '', size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teacherName.isNotEmpty ? widget.teacherName : 'Conversație',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: h ? Pb.link : Pb.text),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(statusText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwner && !isSessionPaid)
            IconButton(
              tooltip: 'Deblochează sesiunea (admin)',
              icon: const Icon(Icons.lock_open_outlined, color: _cBlue),
              onPressed: _unlockSessionByOwner,
            ),
          const SizedBox(width: 4),
          Tooltip(
            message: canCall ? 'Pornește apelul video' : 'Plătește lecția ca să intri în apel',
            child: PbButton(
              text: isMobile ? '' : (canCall ? 'Apel video' : 'Plătește $_teacherPrice RON'),
              icon: Icons.videocam_outlined,
              size: PbSize.sm,
              variant: canCall ? PbVariant.primary : PbVariant.outlinePrimary,
              loading: _isLoadingPayment,
              onPressed: _isLoadingPayment ? null : _startOrJoinCall,
            ),
          ),
        ],
      ),
    );

    final banners = <Widget>[
      if (isTeacher && !isStudentAccepted)
        _cBanner(
          color: _cBlue,
          icon: Icons.person_add_alt_1_outlined,
          text: 'Cerere nouă de la un elev. După ce o accepți, vă puteți scrie liber.',
          action: PbButton(text: 'Acceptă', icon: Icons.check, size: PbSize.sm, onPressed: _acceptStudent),
        ),
      if (!isTeacher && !isOwner && !isStudentAccepted)
        _cBanner(
          color: _cAmber,
          icon: Icons.hourglass_top_rounded,
          text: 'Profesorul nu ți-a acceptat încă cererea. Vei putea scrie imediat ce o acceptă.',
        ),
      if (!isTeacher && isStudentAccepted && !isSessionPaid)
        _cBanner(
          color: Pb.primary,
          icon: Icons.check_circle_outline,
          text: 'Cererea a fost acceptată. Plătește lecția ca să intri în apelul video.',
          action: PbButton(
            text: 'Plătește $_teacherPrice RON',
            size: PbSize.sm,
            loading: _isLoadingPayment,
            onPressed: _isLoadingPayment ? null : _startOrJoinCall,
          ),
        ),
      if (activeSession != null && activeSession!['status'] == 'active')
        _cBanner(
          color: _cBlue,
          icon: Icons.videocam_outlined,
          text: isSessionPaid ? 'Lecția e în desfășurare. Poți intra oricând în apel.' : 'Profesorul a pornit o lecție. Plătește ca să intri.',
          action: PbButton(
            text: canCall ? 'Intră' : 'Plătește și intră',
            size: PbSize.sm,
            variant: PbVariant.outlinePrimary,
            onPressed: _startOrJoinCall,
          ),
        ),
    ];

    final list = StreamBuilder<QuerySnapshot>(
      stream: _messages,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary));
        final all = _mergeMessages(snapshot.data!);

        if (all.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Pb.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.waving_hand_outlined, size: 30, color: Pb.primary),
                  ),
                  const SizedBox(height: 12),
                  Text('Începe conversația', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Pb.text)),
                  const SizedBox(height: 4),
                  Text('Scrie un mesaj sau trimite o poză cu tema.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _chatScrollController,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
          reverse: true,
          itemCount: all.length,
          itemBuilder: (context, index) {
            final msg = all[index];
            final date = _getDateTime(msg['createdAt']);
            final older = index + 1 < all.length ? all[index + 1] : null;
            final newer = index > 0 ? all[index - 1] : null;
            final showDate = older == null || _isDifferentDay(date, _getDateTime(older['createdAt']));

            Widget dateChip() => Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(999)),
                    child: Text(_cDateLabel(date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pb.muted)),
                  ),
                );

            if (msg['isSystem'] == true) {
              return Column(
                children: [
                  if (showDate) dateChip(),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: _cAmber.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 15, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Flexible(child: Text('${msg['text']}', style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)))),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final isMe = msg['senderId'] == currentUser?.uid;
            // group consecutive messages from the same sender (within 3 min)
            bool sameAs(Map<String, dynamic>? o) =>
                o != null &&
                o['isSystem'] != true &&
                o['senderId'] == msg['senderId'] &&
                _getDateTime(o['createdAt']).difference(date).inMinutes.abs() < 3 &&
                !_isDifferentDay(_getDateTime(o['createdAt']), date);
            final firstOfGroup = !sameAs(older) || showDate;
            final lastOfGroup = !sameAs(newer);

            return Column(
              children: [
                if (showDate) dateChip(),
                _CBubble(
                  isMe: isMe,
                  name: widget.teacherName,
                  text: '${msg['text'] ?? ''}',
                  imageUrl: '${msg['imageUrl'] ?? ''}',
                  time: _formatTime(msg['createdAt']),
                  isRead: msg['isRead'] == true,
                  firstOfGroup: firstOfGroup,
                  lastOfGroup: lastOfGroup,
                  onImage: _showImageDialog,
                ),
              ],
            );
          },
        );
      },
    );

    final canWrite = isTeacher || isOwner || isStudentAccepted;
    final quick = _messageController.text.isEmpty && canWrite && !isChatEnded
        ? SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) => CkHover(
                onTap: () {
                  final t = _quickReplies[i];
                  _messageController.text = t;
                  _messageController.selection = TextSelection.collapsed(offset: t.length);
                },
                builder: (h) => AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: h ? Pb.primary.withOpacity(0.08) : Pb.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: h ? Pb.primary.withOpacity(0.5) : Pb.border),
                  ),
                  child: Text(_quickReplies[i], style: TextStyle(fontSize: 12.5, color: h ? Pb.link : Pb.text)),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final hasText = _messageController.text.trim().isNotEmpty;
    final composer = Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
      child: isChatEnded
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Conversația a fost încheiată.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted)),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Trimite o poză',
                  icon: _isUploadingImage
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary))
                      : Icon(Icons.add_photo_alternate_outlined, color: Pb.muted),
                  onPressed: _isUploadingImage ? null : _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => sendMessage(),
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(fontSize: 15, color: Pb.text),
                    cursorColor: Pb.primary,
                    decoration: InputDecoration(
                      hintText: canWrite ? 'Scrie un mesaj…' : 'Aștepți acceptarea profesorului…',
                      hintStyle: TextStyle(color: Pb.muted),
                      filled: true,
                      fillColor: Pb.hoverBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: hasText ? 1 : 0.9,
                  child: Material(
                    color: hasText ? Pb.primary : Pb.gray,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: hasText ? sendMessage : null,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.send_rounded, size: 20, color: hasText ? Colors.white : Pb.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );

    final card = Container(
      key: _cardKey,
      clipBehavior: Clip.antiAlias,
      decoration: ckDeco(r: isMobile ? 0 : 18),
      child: Column(
        children: [
          header,
          ...banners,
          Expanded(child: list),
          quick,
          composer,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: HomeSky(
        blockers: [_cardKey],
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: isMobile ? EdgeInsets.zero : const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _cDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Astăzi';
    if (d == today.subtract(const Duration(days: 1))) return 'Ieri';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2.5, 2.5), blurRadius: 0)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              _formatDateHeader(date).toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.2, fontFamily: 'monospace'),
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
            backgroundColor: AppColors.bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: AppColors.ink),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
            leadingWidth: 54,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 10.0, bottom: 10.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(2, 2))],
                    ),
                    child: Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
                  ),
                ),
              ),
            ),
            title: GestureDetector(
              onTap: _openOtherProfile,
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
                      style: TextStyle(color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 20),
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
                              decoration: BoxDecoration(color: isSessionPaid ? AppColors.forest : AppColors.sunset, shape: BoxShape.circle),
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
                  icon: Icon(isSessionPaid ? Icons.lock_open : Icons.lock,
                      color: isSessionPaid ? AppColors.forest : (isOwner ? AppColors.sky : AppColors.sunset), size: 26),
                  tooltip: isSessionPaid ? "UNLOCKED" : (isOwner ? "OVERRIDE" : "AWAITING PAYMENT"),
                  onPressed: (!isSessionPaid && isOwner) ? _unlockSessionByOwner : null,
                ),
              Container(
                margin: const EdgeInsets.only(right: 16, left: 6),
                decoration: BoxDecoration(
                  color: isSessionPaid || isTeacher || isOwner ? AppColors.sky : AppColors.cloud,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: IconButton(
                  icon: _isLoadingPayment
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(
                          Icons.videocam,
                          color: (isSessionPaid || isTeacher || isOwner) ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white) : AppColors.textMuted,
                          size: 22,
                        ),
                  tooltip: "INITIATE VIDEO FEED",
                  onPressed: _isLoadingPayment ? null : _startOrJoinCall,
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
                  boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6), blurRadius: 0)],
                ),
                child: Column(
                  children: [
                    if (isTeacher && !isStudentAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: AppColors.cloud, border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5))),
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
                            RetroButton(text: "ACCEPT", bgColor: AppColors.sky, textColor: Colors.white, onPressed: _acceptStudent),
                          ],
                        ),
                      ),
                    if (!isTeacher && !isStudentAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: AppColors.mustard, border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5))),
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
                        decoration: BoxDecoration(color: AppColors.forest, border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5))),
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
                              onPressed: _isLoadingPayment ? () {} : _startOrJoinCall,
                            ),
                          ],
                        ),
                      ),
                    if (activeSession != null && activeSession!['status'] == 'active')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.sky, border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5))),
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
                                isSessionPaid ? "SESSION ACTIVE (PAID) // RECONNECT READY" : "SESSION ACTIVE // PAYMENT REQUIRED",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            RetroButton(
                              text: isSessionPaid || isTeacher || isOwner ? "JOIN" : "PAY & JOIN",
                              bgColor: AppColors.cardBg,
                              textColor: AppColors.ink,
                              onPressed: _startOrJoinCall,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _messages,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: AppColors.sunset));

                          final allMessages = _mergeMessages(snapshot.data!);

                          if (allMessages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted),
                                  const SizedBox(height: 14),
                                  Text("TRANSMISSION LOG EMPTY.",
                                      style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                  const SizedBox(height: 6),
                                  Text("Send your first message or attach homework below.",
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
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
                                final olderDate = _getDateTime(allMessages[index + 1]['createdAt']);
                                if (_isDifferentDay(currentDate, olderDate)) showDateHeader = true;
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
                                        decoration: BoxDecoration(color: AppColors.sunset, border: Border.all(color: AppColors.border, width: 2)),
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

                              final isMe = msg['senderId'] == currentUser?.uid;
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
                                            decoration: BoxDecoration(color: AppColors.sky, border: Border.all(color: AppColors.border, width: 2)),
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
                                                  decoration: BoxDecoration(color: isMe ? AppColors.ink : AppColors.border),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        isMe ? "[PLAYER] YOU" : "[MASTER] ${widget.teacherName.toUpperCase()}",
                                                        style: TextStyle(
                                                          color: isMe
                                                              ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)
                                                              : (AppColors.isDark ? Colors.white : AppColors.cloud),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w900,
                                                          letterSpacing: 1.0,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        timeStr,
                                                        style: TextStyle(
                                                          color: isMe
                                                              ? (AppColors.isDark ? const Color(0xFF10161A) : Colors.white70)
                                                              : (AppColors.isDark ? Colors.white70 : AppColors.cloud),
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
                                                      if (hasImage)
                                                        GestureDetector(
                                                          onTap: () => _showImageDialog(msg['imageUrl']),
                                                          child: Container(
                                                            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
                                                            child: Image.network(
                                                              msg['imageUrl'],
                                                              fit: BoxFit.cover,
                                                              loadingBuilder: (context, child, progress) {
                                                                if (progress == null) return child;
                                                                return Container(
                                                                  height: 180,
                                                                  width: 220,
                                                                  color: AppColors.inputBg,
                                                                  child: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      if (msg['text'] != null && msg['text'].toString().isNotEmpty) ...[
                                                        if (hasImage) const SizedBox(height: 8),
                                                        Text(
                                                          msg['text'],
                                                          style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w700, height: 1.4),
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
                                            decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
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
                      decoration: BoxDecoration(color: AppColors.cloud, border: Border(top: BorderSide(color: AppColors.border, width: 3))),
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
                                  Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 14)),
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

// =============================================================================
// Clean message bubble
// =============================================================================
class _CBubble extends StatelessWidget {
  final bool isMe;
  final String name;
  final String text;
  final String imageUrl;
  final String time;
  final bool isRead;
  final bool firstOfGroup;
  final bool lastOfGroup;
  final void Function(String url) onImage;

  const _CBubble({
    required this.isMe,
    required this.name,
    required this.text,
    required this.imageUrl,
    required this.time,
    required this.isRead,
    required this.firstOfGroup,
    required this.lastOfGroup,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width < 700 ? 0.74 : 0.5);
    const r = Radius.circular(18);
    const tight = Radius.circular(5);
    final radius = BorderRadius.only(
      topLeft: !isMe && !firstOfGroup ? tight : r,
      bottomLeft: !isMe && !lastOfGroup ? tight : r,
      topRight: isMe && !firstOfGroup ? tight : r,
      bottomRight: isMe && !lastOfGroup ? tight : r,
    );
    final bg = isMe ? Pb.primary : Pb.hoverBg;
    final fg = isMe ? Colors.white : Pb.text;
    final meta = isMe ? Colors.white70 : Pb.muted;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: EdgeInsets.all(imageUrl.isNotEmpty ? 4 : 0),
      decoration: BoxDecoration(color: bg, borderRadius: radius, border: isMe ? null : Border.all(color: Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => onImage(imageUrl),
              child: MouseRegion(
                cursor: SystemMouseCursors.zoomIn,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    width: 240,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, p) => p == null
                        ? child
                        : Container(
                            width: 240,
                            height: 180,
                            color: Pb.gray,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Pb.primary),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      width: 240,
                      height: 120,
                      color: Pb.gray,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined, color: Pb.muted),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, imageUrl.isNotEmpty ? 6 : 9, 12, 7),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                if (text.isNotEmpty) Text(text, style: TextStyle(fontSize: 15, color: fg, height: 1.4)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: TextStyle(fontSize: 11, color: meta)),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.done_all, size: 14, color: isRead ? const Color(0xFFBFDBFE) : Colors.white60),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: firstOfGroup ? 8 : 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            SizedBox(width: 30, child: lastOfGroup ? CkAvatar(name: name, image: '', size: 28) : null),
            const SizedBox(width: 6),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}