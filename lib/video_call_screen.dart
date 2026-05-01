import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
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

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;
  final bool isFullWidth;
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
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
    return MouseRegion(
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
            color: widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
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
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor,
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
  final Color bgColor;
  final Color iconColor;

  const RetroIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.bgColor = AppColors.cloud,
    this.iconColor = AppColors.ink,
  });

  @override
  State<RetroIconButton> createState() => _RetroIconButtonState();
}

class _RetroIconButtonState extends State<RetroIconButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
            color: widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Icon(widget.icon, color: widget.iconColor, size: 32),
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

  bool _hasCamera = true;

  final String appId = "de8d7a237d93419b8f7b22ea3a167307";

  @override
  void initState() {
    super.initState();
    initAgora();
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
            setState(() { _localUserJoined = true; });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() { _remoteUid = remoteUid; });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            setState(() { _remoteUid = null; });
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
        debugPrint("Cameră indisponibilă sau permisiune refuzată: $e");
        _hasCamera = false;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "CAMERA MODULE OFFLINE. AUDIO ONLY.",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)
              ),
              backgroundColor: AppColors.sunset,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: AppColors.ink, width: 3)
              ),
            ),
          );
        }
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
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.ink, width: 4)
            ),
            title: const Text(
                "CONNECTION ERROR",
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5)
            ),
            content: Text(
                e.toString().toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)
            ),
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

        await _engine.updateChannelMediaOptions(ChannelMediaOptions(
          publishScreenTrack: false,
          publishCameraTrack: _hasCamera,
        ));

        await _engine.stopPreview(sourceType: VideoSourceType.videoSourceScreen);

        if (_hasCamera) {
          await _engine.startPreview(sourceType: VideoSourceType.videoSourceCamera);
        }

      } else {
        await _engine.startScreenCapture(const ScreenCaptureParameters2(
          captureAudio: true,
          captureVideo: true,
        ));

        await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
          publishCameraTrack: false,
          publishScreenTrack: true,
        ));

        if (_hasCamera) {
          await _engine.stopPreview(sourceType: VideoSourceType.videoSourceCamera);
        }
        await _engine.startPreview(sourceType: VideoSourceType.videoSourceScreen);
      }

      setState(() {
        _isScreenShared = !_isScreenShared;
      });
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
    return Scaffold(
      backgroundColor: AppColors.ink,
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
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.satellite_alt, size: 64, color: AppColors.sky),
                SizedBox(height: 24),
                Text(
                  'AWAITING REMOTE CONNECTION...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.cloud,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0
                  ),
                ),
              ],
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
                  color: AppColors.ink,
                  border: Border.all(color: AppColors.sky, width: 4),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(6, 6))
                  ],
                ),
                child: (_isScreenShared || _hasCamera)
                    ? AgoraVideoView(
                  key: ValueKey(_isScreenShared),
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(
                      uid: 0,
                      sourceType: _isScreenShared
                          ? VideoSourceType.videoSourceScreen
                          : VideoSourceType.videoSourceCamera,
                    ),
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: AppColors.sunset,
                    size: 48,
                  ),
                ),
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
                const SizedBox(width: 32),
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
  }
}