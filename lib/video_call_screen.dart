import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, showPbModal;

class DrawingPoint {
  final double x;
  final double y;
  final int colorValue;
  final double strokeWidth;
  final bool isEndOfStroke;

  DrawingPoint({
    required this.x,
    required this.y,
    required this.colorValue,
    required this.strokeWidth,
    this.isEndOfStroke = false,
  });

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'c': colorValue,
        'w': strokeWidth,
        'e': isEndOfStroke,
      };

  factory DrawingPoint.fromMap(Map<String, dynamic> map) => DrawingPoint(
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        colorValue: map['c'] as int,
        strokeWidth: (map['w'] as num).toDouble(),
        isEndOfStroke: map['e'] as bool? ?? false,
      );
}

class WhiteboardPainter extends CustomPainter {
  final List<DrawingPoint> points;
  WhiteboardPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].isEndOfStroke) continue;
      if (points[i + 1].isEndOfStroke) continue;

      final paint = Paint()
        ..color = Color(points[i].colorValue)
        ..strokeWidth = points[i].strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final p1 = Offset(points[i].x * size.width, points[i].y * size.height);
      final p2 = Offset(points[i + 1].x * size.width, points[i + 1].y * size.height);

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

class RetroIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? iconColor;

  const RetroIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.bgColor,
    this.iconColor,
  });

  @override
  State<RetroIconButton> createState() => _RetroIconButtonState();
}

class _RetroIconButtonState extends State<RetroIconButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.bgColor ?? AppColors.cloud;
    final effectiveIconColor = widget.iconColor ?? AppColors.ink;

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
          padding: const EdgeInsets.all(16),
          child: Icon(widget.icon, color: effectiveIconColor, size: 32),
        ),
      ),
    );
  }
}

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  const VideoCallScreen({super.key, required this.roomId});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isScreenShared = false;
  bool _isWhiteboardOpen = false;

  bool _hasCamera = true;
  final String appId = dotenv.env['AGORA_APP_ID'] ?? '';

  List<DrawingPoint> _whiteboardPoints = [];
  Color _selectedDrawColor = const Color(0xFF55EFC4);
  double _strokeWidth = 3.5;

  bool _isAuthorized = false;
  bool _isTeacher = false;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // listeners + call timer (cancelled in dispose)
  StreamSubscription? _sessionSub;
  StreamSubscription? _boardSub;
  Timer? _clock;
  DateTime? _joinedAt;
  bool _micOff = false;
  bool _camOff = false;

  @override
  void initState() {
    super.initState();
    _verifyAccessAndInit();
    _listenToWhiteboard();
    _listenToSessionStatus();
  }

  void _listenToSessionStatus() {
    _sessionSub = FirebaseFirestore.instance.collection('chats').doc(widget.roomId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final session = data['activeSession'] as Map<String, dynamic>?;
      if (session != null && session['status'] == 'ended' && mounted) {
        context.go('/chat/${widget.roomId}');
      }
    });
  }

  Future<void> _verifyAccessAndInit() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.roomId).get();
    if (!chatDoc.exists) {
      if (mounted) context.go('/chat/${widget.roomId}');
      return;
    }

    final data = chatDoc.data() ?? {};
    final teacherId = data['teacherId'];
    final session = data['activeSession'] as Map<String, dynamic>?;

    _isTeacher = currentUserId == teacherId;
    final isOwner = FirebaseAuth.instance.currentUser?.email == 'ahmadarnaoute1896@gmail.com';
    final isPaid = session != null && session['isPaid'] == true && session['status'] == 'active';

    if (!_isTeacher && !isOwner && !isPaid) {
      if (mounted) {
        context.go('/chat/${widget.roomId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStyle.current.isClean
                ? 'Sesiunea nu este plătită. Plătește lecția din chat ca să intri în apel.'
                : "ACCESS DENIED: SESSION UNPAID."),
            backgroundColor: AppStyle.current.isClean ? const Color(0xFFB4232A) : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isAuthorized = true);
    initAgora();
  }

  void _listenToWhiteboard() {
    _boardSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.roomId)
        .collection('whiteboard')
        .doc('live')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final list = doc.data()!['points'] as List<dynamic>?;
        if (list != null && mounted) {
          setState(() {
            _whiteboardPoints = list.map((item) => DrawingPoint.fromMap(item as Map<String, dynamic>)).toList();
          });
        }
      }
    });
  }

  Future<void> _pushWhiteboardStroke(List<DrawingPoint> newPoints) async {
    final ref = FirebaseFirestore.instance.collection('chats').doc(widget.roomId).collection('whiteboard').doc('live');

    final mapped = newPoints.map((p) => p.toMap()).toList();
    await ref.set({'points': mapped}, SetOptions(merge: true));
  }

  Future<void> _clearWhiteboard() async {
    setState(() => _whiteboardPoints.clear());
    await FirebaseFirestore.instance.collection('chats').doc(widget.roomId).collection('whiteboard').doc('live').set({'points': []});
  }

  /// Removes the last stroke.
  void _undoStroke() {
    if (_whiteboardPoints.isEmpty) return;
    var i = _whiteboardPoints.length - 1;
    if (_whiteboardPoints[i].isEndOfStroke) i--;
    while (i >= 0 && !_whiteboardPoints[i].isEndOfStroke) {
      i--;
    }
    setState(() => _whiteboardPoints = _whiteboardPoints.sublist(0, i + 1));
    _pushWhiteboardStroke(_whiteboardPoints);
  }

  void _startClock() {
    _joinedAt ??= DateTime.now();
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> initAgora() async {
    try {
      if (!kIsWeb) {
        await [Permission.microphone, Permission.camera].request();
      }

      _engine = createAgoraRtcEngine();

      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() => _localUserJoined = true);
            _startClock();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (mounted) setState(() => _remoteUid = null);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            if (!mounted) return;
            setState(() {
              _localUserJoined = false;
              _remoteUid = null;
            });
          },
        ),
      );

      await _engine.enableAudio();

      try {
        await _engine.enableVideo();
        await _engine.startPreview(sourceType: VideoSourceType.videoSourceCamera);
        _hasCamera = true;
      } catch (e) {
        _hasCamera = false;
      }

      await _engine.joinChannel(
        token: '',
        channelId: widget.roomId,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: _hasCamera,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (AppStyle.current.isClean) {
        showPbModal<void>(
          context,
          title: 'Nu ne-am putut conecta',
          body: Text('Verifică conexiunea la internet și permisiunile pentru cameră și microfon, apoi încearcă din nou.\n\nDetalii: $e'),
          actions: (ctx) => [PbButton(text: 'Închide', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop())],
        );
        return;
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 4)),
          title: Text("CONNECTION ERROR", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5)),
          content: Text(e.toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
          actions: [
            RetroButton(
              text: "CLOSE",
              bgColor: AppColors.cloud,
              textColor: AppColors.ink,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _toggleScreenShare() async {
    try {
      if (_isScreenShared) {
        await _engine.stopScreenCapture();
        await _engine.updateChannelMediaOptions(ChannelMediaOptions(publishScreenTrack: false, publishCameraTrack: _hasCamera));
        await _engine.stopPreview(sourceType: VideoSourceType.videoSourceScreen);
        if (_hasCamera) await _engine.startPreview(sourceType: VideoSourceType.videoSourceCamera);
      } else {
        await _engine.startScreenCapture(const ScreenCaptureParameters2(captureAudio: true, captureVideo: true));
        await _engine.updateChannelMediaOptions(const ChannelMediaOptions(publishCameraTrack: false, publishScreenTrack: true));
        if (_hasCamera) await _engine.stopPreview(sourceType: VideoSourceType.videoSourceCamera);
        await _engine.startPreview(sourceType: VideoSourceType.videoSourceScreen);
      }
      setState(() => _isScreenShared = !_isScreenShared);
    } catch (e) {
      debugPrint("Screen share error: $e");
    }
  }

  Future<void> _toggleMic() async {
    if (!_localUserJoined) return;
    final next = !_micOff;
    try {
      await _engine.muteLocalAudioStream(next);
      setState(() => _micOff = next);
    } catch (e) {
      debugPrint('Mic toggle: $e');
    }
  }

  Future<void> _toggleCam() async {
    if (!_localUserJoined || !_hasCamera) return;
    final next = !_camOff;
    try {
      await _engine.muteLocalVideoStream(next);
      setState(() => _camOff = next);
    } catch (e) {
      debugPrint('Camera toggle: $e');
    }
  }

  Future<void> _handleHangup() async {
    if (_isTeacher) {
      bool? shouldEndSession;
      if (AppStyle.current.isClean) {
        shouldEndSession = await showPbModal<bool>(
          context,
          title: 'Închei lecția?',
          body: const Text('Poți ieși doar temporar din apel sau poți încheia sesiunea plătită de tot.'),
          actions: (ctx) => [
            PbButton(text: 'Doar ies', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
            PbButton(text: 'Închei sesiunea', variant: PbVariant.danger, onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        );
      } else {
        shouldEndSession = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
            title: Text("TERMINATE SESSION?", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
            content: Text(
              "Do you want to close this paid session completely, or just leave temporarily?",
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
            ),
            actions: [
              RetroButton(
                text: "LEAVE ONLY",
                bgColor: AppColors.cloud,
                textColor: AppColors.ink,
                onPressed: () => ctx.pop(false),
              ),
              RetroButton(
                text: "END SESSION",
                bgColor: AppColors.sunset,
                textColor: Colors.white,
                onPressed: () => ctx.pop(true),
              ),
            ],
          ),
        );
      }

      if (shouldEndSession == null) return; // dialog dismissed: stay in the call
      if (shouldEndSession == true) {
        await FirebaseFirestore.instance.collection('chats').doc(widget.roomId).update({
          'activeSession.status': 'ended',
        });
      }
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chat/${widget.roomId}');
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _boardSub?.cancel();
    _clock?.cancel();
    if (_isAuthorized) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  // whiteboard gestures shared by both styles
  void _boardPoint(Offset p, BoxConstraints c, {bool end = false}) {
    if (end) {
      _whiteboardPoints.add(DrawingPoint(x: 0, y: 0, colorValue: 0, strokeWidth: 0, isEndOfStroke: true));
    } else {
      _whiteboardPoints.add(DrawingPoint(
        x: p.dx / c.maxWidth,
        y: p.dy / c.maxHeight,
        colorValue: _selectedDrawColor.value,
        strokeWidth: _strokeWidth,
      ));
    }
    setState(() {});
    _pushWhiteboardStroke(_whiteboardPoints);
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — dark call room: live timer, mic/camera toggles, labelled dock,
  // whiteboard with pen sizes + undo.
  // ===========================================================================
  static const Color _vBg = Color(0xFF0F1113);
  static const Color _vPanel = Color(0xFF1C1F23);
  static const Color _vLine = Color(0x22FFFFFF);
  static const Color _vRed = Color(0xFFE5484D);
  static const Color _vGreen = Color(0xFF22C55E);

  String get _elapsed {
    if (_joinedAt == null) return '00:00';
    final d = DateTime.now().difference(_joinedAt!);
    String two(int n) => n.toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}' : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  Widget _pill(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: _vPanel.withOpacity(0.85), borderRadius: BorderRadius.circular(999), border: Border.all(color: _vLine)),
        child: child,
      );

  Widget _buildClean(BuildContext context) {
    if (!_isAuthorized) {
      return const Scaffold(
        backgroundColor: _vBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Pb.primary),
              SizedBox(height: 16),
              Text('Pregătim sala de lecție…', style: TextStyle(color: Colors.white70, fontSize: 14.5)),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: _vBg,
      body: Stack(
        children: [
          // remote video / waiting room
          Positioned.fill(
            child: _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.roomId),
                    ),
                  )
                : const _WaitingRoom(),
          ),

          // whiteboard
          if (_isWhiteboardOpen)
            Positioned.fill(
              child: Container(
                color: const Color(0xEE15181B),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, c) => GestureDetector(
                        onPanStart: (d) => _boardPoint(d.localPosition, c),
                        onPanUpdate: (d) => _boardPoint(d.localPosition, c),
                        onPanEnd: (_) => _boardPoint(Offset.zero, c, end: true),
                        child: CustomPaint(painter: WhiteboardPainter(points: _whiteboardPoints), size: Size(c.maxWidth, c.maxHeight)),
                      ),
                    ),
                    Positioned(top: isMobile ? 64 : 76, left: 0, right: 0, child: Center(child: _cBoardTools())),
                  ],
                ),
              ),
            ),

          // top bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _pill(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _localUserJoined ? _vRed : Colors.white38, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(_localUserJoined ? 'Live' : 'Se conectează',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Text(_elapsed, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()])),
                    ],
                  )),
                  const Spacer(),
                  _pill(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_remoteUid != null ? Icons.people_alt_outlined : Icons.person_outline, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(_remoteUid != null ? '2 în apel' : 'Doar tu', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  )),
                ],
              ),
            ),
          ),

          // self view
          if (_localUserJoined)
            Positioned(
              bottom: isMobile ? 112 : 120,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isScreenShared ? (isMobile ? 180 : 260) : (isMobile ? 110 : 160),
                height: _isScreenShared ? (isMobile ? 112 : 160) : (isMobile ? 150 : 210),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _vPanel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _vLine),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((_isScreenShared || _hasCamera) && !(_camOff && !_isScreenShared))
                      AgoraVideoView(
                        key: ValueKey(_isScreenShared),
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: VideoCanvas(
                            uid: 0,
                            sourceType: _isScreenShared ? VideoSourceType.videoSourceScreen : VideoSourceType.videoSourceCamera,
                          ),
                        ),
                      )
                    else
                      const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 34)),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_micOff) ...[const Icon(Icons.mic_off, size: 12, color: _vRed), const SizedBox(width: 4)],
                            Text(_isScreenShared ? 'Ecranul tău' : 'Tu', style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // control dock
          Positioned(
            bottom: isMobile ? 20 : 28,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _vPanel.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _vLine),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DockButton(icon: _micOff ? Icons.mic_off : Icons.mic_none, label: _micOff ? 'Pornește' : 'Microfon', active: _micOff, activeColor: _vRed, onTap: _toggleMic, compact: isMobile),
                      _DockButton(
                        icon: _camOff || !_hasCamera ? Icons.videocam_off_outlined : Icons.videocam_outlined,
                        label: !_hasCamera ? 'Fără cameră' : (_camOff ? 'Pornește' : 'Cameră'),
                        active: _camOff || !_hasCamera,
                        activeColor: _vRed,
                        onTap: _toggleCam,
                        compact: isMobile,
                      ),
                      _DockButton(
                        icon: _isScreenShared ? Icons.stop_screen_share_outlined : Icons.screen_share_outlined,
                        label: _isScreenShared ? 'Oprește' : 'Ecran',
                        active: _isScreenShared,
                        activeColor: Pb.primary,
                        onTap: _toggleScreenShare,
                        compact: isMobile,
                      ),
                      _DockButton(
                        icon: Icons.draw_outlined,
                        label: 'Tablă',
                        active: _isWhiteboardOpen,
                        activeColor: const Color(0xFFF59E0B),
                        onTap: () => setState(() => _isWhiteboardOpen = !_isWhiteboardOpen),
                        compact: isMobile,
                      ),
                      const SizedBox(width: 6),
                      _DockButton(icon: Icons.call_end, label: 'Închide', filled: _vRed, onTap: _handleHangup, compact: isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cBoardTools() {
    const colors = [Color(0xFF55EFC4), Color(0xFFF9CA24), Color(0xFFFF7675), Color(0xFF74B9FF), Colors.white];
    const sizes = [2.5, 4.5, 8.0];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _vPanel, borderRadius: BorderRadius.circular(999), border: Border.all(color: _vLine)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in colors)
            GestureDetector(
              onTap: () => setState(() => _selectedDrawColor = c),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: _selectedDrawColor.value == c.value ? Colors.white : Colors.transparent, width: 2.5),
                  ),
                ),
              ),
            ),
          Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 8), color: _vLine),
          for (final s in sizes)
            Tooltip(
              message: 'Grosime',
              child: InkResponse(
                radius: 18,
                onTap: () => setState(() => _strokeWidth = s),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _strokeWidth == s ? Colors.white12 : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Container(width: s + 3, height: s + 3, decoration: BoxDecoration(color: _selectedDrawColor, shape: BoxShape.circle)),
                ),
              ),
            ),
          Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 8), color: _vLine),
          IconButton(
            tooltip: 'Anulează ultima linie',
            splashRadius: 18,
            icon: const Icon(Icons.undo, color: Colors.white, size: 20),
            onPressed: _undoStroke,
          ),
          IconButton(
            tooltip: 'Șterge tabla',
            splashRadius: 18,
            icon: const Icon(Icons.delete_outline, color: _vRed, size: 20),
            onPressed: () => showPbModal<void>(
              context,
              title: 'Ștergi toată tabla?',
              body: const Text('Desenul dispare pentru amândoi.'),
              actions: (ctx) => [
                PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
                PbButton(
                  text: 'Șterge',
                  variant: PbVariant.danger,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _clearWhiteboard();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
          body: Stack(
            children: [
              Center(
                child: _remoteUid != null
                    ? AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine,
                          canvas: VideoCanvas(uid: _remoteUid),
                          connection: RtcConnection(channelId: widget.roomId),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.satellite_alt, size: 64, color: AppColors.sky),
                          const SizedBox(height: 24),
                          Text(
                            'AWAITING REMOTE CONNECTION...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.cloud,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
              ),
              if (_isWhiteboardOpen)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xDD141A1F),
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onPanStart: (details) => _boardPoint(details.localPosition, constraints),
                              onPanUpdate: (details) => _boardPoint(details.localPosition, constraints),
                              onPanEnd: (_) => _boardPoint(Offset.zero, constraints, end: true),
                              child: CustomPaint(
                                painter: WhiteboardPainter(points: _whiteboardPoints),
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 24,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              border: Border.all(color: AppColors.border, width: 2.5),
                              boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
                            ),
                            child: Row(
                              children: [
                                _colorCircle(const Color(0xFF55EFC4)),
                                const SizedBox(width: 8),
                                _colorCircle(const Color(0xFFF9CA24)),
                                const SizedBox(width: 8),
                                _colorCircle(const Color(0xFFFF7675)),
                                const SizedBox(width: 8),
                                _colorCircle(const Color(0xFF74B9FF)),
                                const SizedBox(width: 8),
                                _colorCircle(Colors.white),
                                const SizedBox(width: 14),
                                Container(width: 2, height: 20, color: AppColors.border),
                                const SizedBox(width: 14),
                                IconButton(
                                  icon: Icon(Icons.delete, color: AppColors.sunset, size: 22),
                                  tooltip: "CLEAR BOARD",
                                  onPressed: _clearWhiteboard,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_localUserJoined)
                Positioned(
                  bottom: 120,
                  right: 24,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isScreenShared ? 240 : 140,
                    height: _isScreenShared ? 160 : 180,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border.all(color: AppColors.sky, width: 4),
                      boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6))],
                    ),
                    child: (_isScreenShared || _hasCamera)
                        ? AgoraVideoView(
                            key: ValueKey(_isScreenShared),
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: VideoCanvas(
                                uid: 0,
                                sourceType: _isScreenShared ? VideoSourceType.videoSourceScreen : VideoSourceType.videoSourceCamera,
                              ),
                            ),
                          )
                        : Center(child: Icon(Icons.videocam_off, color: AppColors.sunset, size: 48)),
                  ),
                ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RetroIconButton(
                      icon: _isScreenShared ? Icons.stop_screen_share : Icons.screen_share,
                      bgColor: _isScreenShared ? AppColors.sky : AppColors.cloud,
                      iconColor: AppColors.ink,
                      onPressed: _toggleScreenShare,
                    ),
                    const SizedBox(width: 20),
                    RetroIconButton(
                      icon: _isWhiteboardOpen ? Icons.brush : Icons.draw,
                      bgColor: _isWhiteboardOpen ? AppColors.mustard : AppColors.cloud,
                      iconColor: AppColors.ink,
                      onPressed: () => setState(() => _isWhiteboardOpen = !_isWhiteboardOpen),
                    ),
                    const SizedBox(width: 20),
                    RetroIconButton(
                      icon: Icons.call_end,
                      bgColor: AppColors.sunset,
                      iconColor: Colors.white,
                      onPressed: _handleHangup,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorCircle(Color c) {
    final isSelected = _selectedDrawColor.value == c.value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDrawColor = c),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.black45, width: isSelected ? 3 : 1),
        ),
      ),
    );
  }
}

// =============================================================================
// Clean helpers
// =============================================================================
class _DockButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;
  final Color? filled;
  final bool compact;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
    this.filled,
    this.compact = false,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled ?? (widget.active ? (widget.activeColor ?? Colors.white).withOpacity(0.22) : (_hover ? Colors.white12 : Colors.white.withOpacity(0.06)));
    final fg = widget.filled != null ? Colors.white : (widget.active ? (widget.activeColor ?? Colors.white) : Colors.white);
    final size = widget.compact ? 46.0 : 52.0;

    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.filled != null ? size + 14 : size,
                  height: size,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Icon(widget.icon, color: fg, size: 22),
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 4),
                  Text(widget.label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingRoom extends StatefulWidget {
  const _WaitingRoom();

  @override
  State<_WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<_WaitingRoom> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(painter: _PulsePainter(_c.value)),
              child: const Center(child: Icon(Icons.person_outline, color: Colors.white70, size: 40)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Așteptăm să intre și celălalt participant',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Poți porni tabla sau partaja ecranul între timp.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        34 + k * 36,
        Paint()
          ..color = const Color(0xFF22C55E).withOpacity(0.35 * (1 - k))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(c, 34, Paint()..color = const Color(0xFF2A2E33));
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.t != t;
}