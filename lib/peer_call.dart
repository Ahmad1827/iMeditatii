import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_hint_stub.dart' if (dart.library.js_interop) 'call_hint_web.dart' as hint;

enum CallLink { starting, waiting, connecting, connected, reconnecting, failed }

enum CallSignal { good, weak, bad }

/// A 1-on-1 call straight between the two devices (WebRTC), no media server.
///
/// Firestore only carries the offer and the answer, in chats/{room}/call/signal.
/// Video, sound and whiteboard messages go peer to peer. The teacher makes the
/// offers; the student answers them and, when it (re)joins, writes `want` to ask
/// for a fresh one. Candidates travel inside the SDP (gathered before sending),
/// so the whole handshake is two writes.
class PeerCall extends ChangeNotifier {
  PeerCall({
    required this.roomId,
    required this.isOfferer,
    required this.myName,
    required this.onMessage,
    required this.onChannelOpen,
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final String roomId;
  final bool isOfferer;
  final String myName;
  final void Function(Map<String, dynamic> msg) onMessage;
  final VoidCallback onChannelOpen;
  final FirebaseFirestore _db;

  static const Map<String, dynamic> _config = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };
  static const _camBitrate = 1500000;
  static const _screenBitrate = 2500000;
  static const _audioBitrate = 64000;

  final localView = RTCVideoRenderer();
  final remoteView = RTCVideoRenderer();

  CallLink link = CallLink.starting;
  CallSignal? signal;
  bool hasCamera = false;
  bool hasMic = false;
  bool micOff = false;
  bool camOff = false;
  bool sharing = false;
  String? remoteName;
  bool remoteMicOff = false;
  bool remoteCamOff = false;
  bool remoteSharing = false;

  MediaStream? _local;
  MediaStream? _screenStream;
  MediaStreamTrack? _cam;
  MediaStreamTrack? _mic;
  MediaStreamTrack? _screen;

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  MediaStream? _remote;
  RTCRtpSender? _audioSender;
  RTCRtpSender? _videoSender;

  StreamSubscription? _sub;
  Timer? _statsTimer;
  Future<void> _queue = Future.value();
  bool _closed = false;

  // offerer
  bool _firstSnap = true;
  String? _seenWant;
  String? _offerId;
  bool _answered = false;
  int _retries = 0;
  // answerer
  String? _handledOffer;
  bool _firstOffer = true;
  bool _staleOffer = false;
  int _freshFailures = 0;
  DateTime? _lastWant;

  int _lostBefore = 0;
  int _recvBefore = 0;

  bool get peerHere => link == CallLink.connected || link == CallLink.reconnecting;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('chats').doc(roomId).collection('call').doc('signal');

  static String _nonce() => '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 30)}';

  /// Runs signalling steps one after another, never interleaved.
  void _serial(Future<void> Function() step) {
    _queue = _queue.then((_) => _closed ? null : step()).catchError((Object e) => debugPrint('call: $e'));
  }

  void _set(VoidCallback f) {
    if (_closed) return;
    f();
    notifyListeners();
  }

  Future<void> start() async {
    await localView.initialize();
    await remoteView.initialize();
    await _openMedia();
    if (_closed) return;
    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}
    }
    _set(() => link = CallLink.waiting);
    _sub = _doc.snapshots().listen((s) => _serial(() => _onSignal(s.data() ?? const {})));
    if (!isOfferer) await _askForOffer();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readStats());
  }

  Future<void> _openMedia() async {
    const audio = {'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true};
    try {
      _local = await navigator.mediaDevices.getUserMedia({
        'audio': audio,
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 30},
          'facingMode': 'user',
        },
      });
    } catch (_) {
      try {
        _local = await navigator.mediaDevices.getUserMedia({'audio': audio, 'video': false});
      } catch (e) {
        debugPrint('call: no microphone: $e');
      }
    }
    final s = _local;
    if (s == null) return;
    _mic = s.getAudioTracks().firstOrNull;
    _cam = s.getVideoTracks().firstOrNull;
    hasMic = _mic != null;
    hasCamera = _cam != null;
    localView.srcObject = s;
  }

  // ---------------------------------------------------------------------------
  // signalling
  // ---------------------------------------------------------------------------
  Future<void> _onSignal(Map<String, dynamic> data) async {
    if (isOfferer) {
      final want = data['want'] as String?;
      if (_firstSnap) {
        _firstSnap = false;
        _seenWant = want;
        await _offer();
        return;
      }
      if (want != null && want != _seenWant) {
        _seenWant = want;
        final busy = _answered && (link == CallLink.connecting || link == CallLink.connected);
        if (!busy) await _offer();
      }
      final answer = data['answer'] as Map<String, dynamic>?;
      final pc = _pc;
      if (answer != null && answer['id'] == _offerId && !_answered && pc != null) {
        _answered = true;
        _set(() => link = CallLink.connecting);
        await pc.setRemoteDescription(RTCSessionDescription(answer['sdp'] as String, 'answer'));
        await _tune();
      }
    } else {
      final offer = data['offer'] as Map<String, dynamic>?;
      final id = offer?['id'] as String?;
      // the offer already there when we arrive may be from a teacher who left
      _staleOffer = _firstOffer;
      _firstOffer = false;
      if (id != null && id != _handledOffer) {
        _handledOffer = id;
        try {
          await _answer(id, offer!['sdp'] as String);
        } catch (e) {
          debugPrint('call: bad offer: $e');
          await _closePeer();
          _set(() => link = CallLink.waiting);
        }
      }
    }
  }

  Future<void> _askForOffer() async {
    _lastWant = DateTime.now();
    await _doc.set({'want': _nonce()}, SetOptions(merge: true));
  }

  Future<RTCPeerConnection> _newPeer() async {
    await _closePeer();
    final pc = await createPeerConnection(_config);
    _pc = pc;
    _remote = null;

    pc.onTrack = (e) async {
      if (pc != _pc || _closed) return;
      if (e.streams.isNotEmpty) {
        _remote = e.streams.first;
      } else {
        _remote ??= await createLocalMediaStream('remote');
        await _remote!.addTrack(e.track);
      }
      remoteView.srcObject = _remote;
      _set(() {});
    };

    pc.onConnectionState = (s) {
      if (pc != _pc) return;
      switch (s) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _retries = 0;
          _freshFailures = 0;
          _set(() => link = CallLink.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          if (link == CallLink.connected) _set(() => link = CallLink.reconnecting);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _serial(_onFailed);
          break;
        default:
          break;
      }
    };

    // negotiated: both sides open the same channel, no extra round trip
    final dc = await pc.createDataChannel('room', RTCDataChannelInit()
      ..negotiated = true
      ..id = 0);
    _dc = dc;
    dc.onDataChannelState = (s) {
      if (pc != _pc) return;
      if (s == RTCDataChannelState.RTCDataChannelOpen) {
        _sendMe();
        onChannelOpen();
      } else if (s == RTCDataChannelState.RTCDataChannelClosed) {
        _serial(() => _peerLeft(said: false));
      }
    };
    dc.onMessage = (m) {
      if (pc != _pc || m.isBinary) return;
      final Map<String, dynamic> j;
      try {
        j = jsonDecode(m.text) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
      switch (j['t']) {
        case 'me':
          _set(() {
            remoteName = j['name'] as String?;
            remoteMicOff = j['mic'] == true;
            remoteCamOff = j['cam'] == true;
            remoteSharing = j['screen'] == true;
          });
          break;
        case 'bye':
          _serial(() => _peerLeft(said: true));
          break;
        default:
          onMessage(j);
      }
    };
    return pc;
  }

  Future<void> _offer() async {
    final pc = await _newPeer();
    final streams = [if (_local != null) _local!];
    // a line for video even without a camera, so a screen can be shared later
    Future<RTCRtpTransceiver> line(MediaStreamTrack? track, RTCRtpMediaType kind) {
      final init = RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv, streams: streams);
      return track != null ? pc.addTransceiver(track: track, kind: kind, init: init) : pc.addTransceiver(kind: kind, init: init);
    }

    final a = await line(_mic, RTCRtpMediaType.RTCRtpMediaTypeAudio);
    final v = await line(sharing ? _screen : _cam, RTCRtpMediaType.RTCRtpMediaTypeVideo);
    _audioSender = a.sender;
    _videoSender = v.sender;
    await pc.setLocalDescription(await pc.createOffer());
    final sdp = await _gathered(pc);
    if (pc != _pc || sdp == null) return;
    _offerId = _nonce();
    _answered = false;
    _set(() => link = CallLink.waiting);
    await _doc.set({
      'offer': {'id': _offerId, 'sdp': sdp},
      'answer': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> _answer(String offerId, String offerSdp) async {
    final pc = await _newPeer();
    _set(() => link = CallLink.connecting);
    await pc.setRemoteDescription(RTCSessionDescription(offerSdp, 'offer'));
    for (final t in await pc.getTransceivers()) {
      final kind = t.receiver.track?.kind;
      if (kind != 'audio' && kind != 'video') continue;
      await t.setDirection(TransceiverDirection.SendRecv);
      final track = kind == 'audio' ? _mic : (sharing ? _screen : _cam);
      if (track != null) await t.sender.replaceTrack(track);
      if (kind == 'audio') {
        _audioSender = t.sender;
      } else {
        _videoSender = t.sender;
      }
    }
    await pc.setLocalDescription(await pc.createAnswer());
    final sdp = await _gathered(pc);
    if (pc != _pc || sdp == null) return;
    await _doc.set({
      'answer': {'id': offerId, 'sdp': sdp},
    }, SetOptions(merge: true));
    await _tune();
  }

  /// Waits for the candidates (at most 3 s) so they ride inside the SDP.
  Future<String?> _gathered(RTCPeerConnection pc) async {
    final until = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(until)) {
      if (pc != _pc) return null;
      if (pc.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return (await pc.getLocalDescription())?.sdp;
  }

  Future<void> _onFailed() async {
    if (isOfferer) {
      if (_retries < 2) {
        _retries++;
        await _offer();
      } else {
        await _closePeer();
        _set(() => link = CallLink.failed);
      }
      return;
    }
    // an old offer from a teacher who already left fails too: only offers that
    // came while we were here count as real failures
    if (!_staleOffer) _freshFailures++;
    await _closePeer();
    if (_freshFailures >= 3) {
      _set(() => link = CallLink.failed);
      return;
    }
    _set(() => link = CallLink.waiting);
    if (_lastWant == null || DateTime.now().difference(_lastWant!) > const Duration(seconds: 8)) {
      await _askForOffer();
    }
  }

  /// The other side hung up (`said`) or its connection closed.
  Future<void> _peerLeft({required bool said}) async {
    if (_pc == null) return;
    await _closePeer();
    _set(() {
      link = CallLink.waiting;
      signal = null;
      remoteName = null;
      remoteMicOff = remoteCamOff = remoteSharing = false;
    });
    // a closed link without a goodbye may be a network blip: the teacher offers
    // again right away, the student waits for that offer
    if (isOfferer && !said) await _offer();
  }

  /// Tries again after a failed connection.
  void retry() {
    _retries = 0;
    _freshFailures = 0;
    _set(() => link = CallLink.waiting);
    _serial(() => isOfferer ? _offer() : _askForOffer());
  }

  Future<void> _closePeer() async {
    final pc = _pc;
    _pc = null;
    _dc = null;
    _audioSender = null;
    _videoSender = null;
    _remote = null;
    remoteView.srcObject = null;
    await pc?.close();
  }

  // ---------------------------------------------------------------------------
  // quality
  // ---------------------------------------------------------------------------
  Future<void> _tune() async {
    await _cap(_audioSender, _audioBitrate);
    await _cap(_videoSender, sharing ? _screenBitrate : _camBitrate);
  }

  Future<void> _cap(RTCRtpSender? s, int bps) async {
    if (s == null) return;
    try {
      final p = s.parameters;
      final e = p.encodings;
      if (e == null || e.isEmpty) {
        p.encodings = [RTCRtpEncoding(maxBitrate: bps)];
      } else {
        e.first.maxBitrate = bps;
      }
      await s.setParameters(p);
    } catch (e) {
      debugPrint('call: bitrate: $e');
    }
  }

  Future<void> _readStats() async {
    final pc = _pc;
    if (pc == null || !peerHere) return;
    try {
      double? rtt;
      var lost = 0, recv = 0;
      for (final r in await pc.getStats()) {
        final v = r.values;
        if (r.type == 'candidate-pair' && v['state'] == 'succeeded' && v['nominated'] == true) {
          rtt = (v['currentRoundTripTime'] as num?)?.toDouble() ?? rtt;
        } else if (r.type == 'inbound-rtp' && v['kind'] == 'audio') {
          lost += (v['packetsLost'] as num?)?.toInt() ?? 0;
          recv += (v['packetsReceived'] as num?)?.toInt() ?? 0;
        }
      }
      final dLost = max(0, lost - _lostBefore), dRecv = max(0, recv - _recvBefore);
      _lostBefore = lost;
      _recvBefore = recv;
      final loss = dLost + dRecv == 0 ? 0.0 : dLost / (dLost + dRecv);
      final r = rtt ?? 0;
      final next = (r > 0.6 || loss > 0.08)
          ? CallSignal.bad
          : (r > 0.3 || loss > 0.03)
              ? CallSignal.weak
              : CallSignal.good;
      if (next != signal) _set(() => signal = next);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // controls
  // ---------------------------------------------------------------------------
  void send(Map<String, dynamic> msg) {
    final dc = _dc;
    if (dc == null || dc.state != RTCDataChannelState.RTCDataChannelOpen) return;
    try {
      dc.send(RTCDataChannelMessage(jsonEncode(msg)));
    } catch (_) {}
  }

  void _sendMe() => send({'t': 'me', 'name': myName, 'mic': micOff || !hasMic, 'cam': camOff || !hasCamera, 'screen': sharing});

  void toggleMic() {
    if (_mic == null) return;
    _set(() => micOff = !micOff);
    _mic!.enabled = !micOff;
    _sendMe();
  }

  void toggleCam() {
    if (_cam == null) return;
    _set(() => camOff = !camOff);
    _cam!.enabled = !camOff;
    _sendMe();
  }

  /// Starts or stops sharing the screen. Returns a message when it could not.
  Future<String?> toggleShare() async {
    if (sharing) {
      await _stopShare();
      return null;
    }
    final MediaStream s;
    try {
      s = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'frameRate': {'ideal': 30, 'max': 30},
        },
        'audio': false,
      });
    } catch (e) {
      final text = '$e';
      if (text.contains('NotAllowed') || text.contains('Permission') || text.contains('AbortError')) return null;
      return kIsWeb ? 'Nu am putut partaja ecranul.' : 'Partajarea ecranului merge din browser, pe calculator.';
    }
    final track = s.getVideoTracks().firstOrNull;
    if (track == null) return null;
    hint.preferDetail(track);
    // the browser's own "Stop sharing" button
    track.onEnded = () => _serial(_stopShare);
    _screenStream = s;
    _screen = track;
    await _videoSender?.replaceTrack(track);
    _set(() => sharing = true);
    localView.srcObject = s;
    await _cap(_videoSender, _screenBitrate);
    _sendMe();
    return null;
  }

  Future<void> _stopShare() async {
    if (!sharing) return;
    final s = _screenStream;
    _screen = null;
    _screenStream = null;
    await _videoSender?.replaceTrack(_cam);
    for (final t in s?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    _set(() => sharing = false);
    localView.srcObject = _local;
    await _cap(_videoSender, _camBitrate);
    _sendMe();
  }

  /// Hangs up: says goodbye to the other side and frees camera and mic.
  Future<void> leave() async {
    if (_closed) return;
    send({'t': 'bye'});
    _closed = true;
    _statsTimer?.cancel();
    await _sub?.cancel();
    await Future.delayed(const Duration(milliseconds: 150)); // let the goodbye out
    await _closePeer();
    for (final t in [...?_local?.getTracks(), ...?_screenStream?.getTracks()]) {
      await t.stop();
    }
    localView.srcObject = null;
    await localView.dispose();
    await remoteView.dispose();
  }
}
