import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  const VideoCallScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isScreenShared = false;

  // 🚀 Adăugăm o variabilă pentru a ști dacă utilizatorul are o cameră funcțională
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

      // 🚀 ASIGURĂM FUNCȚIONAREA AUDIO
      await _engine.enableAudio();

      // 🚀 BLOC SEPARAT PENTRU CAMERĂ (Nu blochează apelul dacă lipsește!)
      try {
        await _engine.enableVideo();
        await _engine.startPreview(sourceType: VideoSourceType.videoSourceCamera);
        _hasCamera = true;
      } catch (e) {
        debugPrint("Cameră indisponibilă sau permisiune refuzată: $e");
        _hasCamera = false; // Marcăm că nu avem cameră

        // Opțional, îi putem arăta un mesaj informativ (nu un dialog care blochează ecranul)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nu s-a detectat nicio cameră. Te-ai conectat doar cu microfonul."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // 🚀 NE CONECTĂM LA CANAL ORICUM
      await _engine.joinChannel(
        token: '',
        channelId: widget.roomId,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          // Trimitem video doar dacă a pornit camera cu succes
          publishCameraTrack: _hasCamera,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      // Aici ajungem doar la o eroare critică (ex. App ID invalid, lipsă internet etc.)
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("🚨 Eroare de Conexiune"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("Închide"),
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
          // Publicăm camera la loc DOAR dacă persoana chiar are cameră
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
          publishCameraTrack: false, // Oprim camera (dacă exista) ca să dăm share screen
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 📺 Ecranul persoanei cu care vorbești
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.roomId),
              ),
            )
                : const Text(
              'Așteptăm ca cealaltă\npersoană să se conecteze...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),

          // 🧑‍💻 Miniatura ta (dreapta-jos)
          if (_localUserJoined)
            Positioned(
              bottom: 100,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isScreenShared ? 200 : 120,
                height: _isScreenShared ? 130 : 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black, // Fundal negru în caz că nu e cameră
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  // Dacă avem cameră SAU dăm share screen, afișăm componenta video.
                  // Altfel, afișăm o iconiță cu camera tăiată.
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
                      Icons.videocam_off_rounded,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

          // 🎛️ Bara de butoane
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "screenShare",
                  backgroundColor: _isScreenShared ? Colors.blue : Colors.grey[800],
                  onPressed: _toggleScreenShare,
                  child: Icon(
                    _isScreenShared ? Icons.stop_screen_share : Icons.screen_share,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 30),
                FloatingActionButton(
                  heroTag: "endCall",
                  backgroundColor: Colors.red,
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}