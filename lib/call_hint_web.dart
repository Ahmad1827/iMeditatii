import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamTrack, MediaStreamTrackWeb;

/// Tells the browser the shared screen is text: when the network is busy it
/// drops frames instead of resolution, so code stays sharp.
void preferDetail(MediaStreamTrack track) {
  if (track is! MediaStreamTrackWeb) return;
  (track.jsTrack as JSObject).setProperty('contentHint'.toJS, 'detail'.toJS);
}
