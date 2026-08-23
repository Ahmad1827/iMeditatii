import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

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

  // Whiteboard properties
  List<DrawingPoint> _whiteboardPoints = [];
  Color _selectedDrawColor = const Color(0xFF55EFC4);
  double _strokeWidth = 3.5;

  @override
  void initState() {
    super.initState();
    initAgora();
    _listenToWhiteboard();
  }

  void _listenToWhiteboard() {
    FirebaseFirestore.instance
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
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.roomId)
        .collection('whiteboard')
        .doc('live');

    final mapped = newPoints.map((p) => p.toMap()).toList();
    await ref.set({'points': mapped}, SetOptions(merge: true));
  }

  Future<void> _clearWhiteboard() async {
    setState(() => _whiteboardPoints.clear());
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.roomId)
        .collection('whiteboard')
        .doc('live')
        .set({'points': []});
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
            setState(() => _localUserJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            setState(() => _remoteUid = null);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
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
        debugPrint("Cameră indisponibilă: $e");
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
      if (mounted) {
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
      debugPrint("Eroare la screen share: $e");
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
          body: Stack(
            children: [
              // Main Video Stream (Remote)
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

              // Interactive Whiteboard Overlay
              if (_isWhiteboardOpen)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xDD141A1F),
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onPanStart: (details) {
                                final x = details.localPosition.dx / constraints.maxWidth;
                                final y = details.localPosition.dy / constraints.maxHeight;
                                final point = DrawingPoint(x: x, y: y, colorValue: _selectedDrawColor.value, strokeWidth: _strokeWidth);
                                _whiteboardPoints.add(point);
                                _pushWhiteboardStroke(_whiteboardPoints);
                              },
                              onPanUpdate: (details) {
                                final x = details.localPosition.dx / constraints.maxWidth;
                                final y = details.localPosition.dy / constraints.maxHeight;
                                final point = DrawingPoint(x: x, y: y, colorValue: _selectedDrawColor.value, strokeWidth: _strokeWidth);
                                _whiteboardPoints.add(point);
                                _pushWhiteboardStroke(_whiteboardPoints);
                              },
                              onPanEnd: (_) {
                                _whiteboardPoints.add(DrawingPoint(x: 0, y: 0, colorValue: 0, strokeWidth: 0, isEndOfStroke: true));
                                _pushWhiteboardStroke(_whiteboardPoints);
                              },
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

              // Local User Picture-in-Picture Video
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
                        : Center(
                            child: Icon(Icons.videocam_off, color: AppColors.sunset, size: 48),
                          ),
                  ),
                ),

              // Bottom Action Buttons Toolbar
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
                      onPressed: () => context.pop(),
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