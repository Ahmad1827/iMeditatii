import 'dart:js_interop';

import 'judge0.dart' show RunResult;

@JS('imPython')
external _Py? get _py;

extension type _Py._(JSObject _) implements JSObject {
  external void warm();
  external JSBoolean isReady();
  external JSPromise<_Result> run(JSString code, JSString stdin, JSNumber timeoutMs);
}

extension type _Result._(JSObject _) implements JSObject {
  external JSString? get stdout;
  external JSString? get stderr;
  external JSString? get status;
  external JSNumber? get seconds;
  external JSBoolean? get failed;
}

void warm() => _py?.warm();

bool ready() => _py?.isReady().toDart ?? false;

Future<RunResult?> run(String code, String stdin, Duration limit) async {
  final py = _py;
  if (py == null) return null;
  try {
    final r = await py.run(code.toJS, stdin.toJS, limit.inMilliseconds.toJS).toDart;
    if (r.failed?.toDart ?? false) return null; // Python didn't load here: let the server run it
    return RunResult(
      stdout: r.stdout?.toDart ?? '',
      error: r.stderr?.toDart ?? '',
      status: r.status?.toDart ?? '',
      seconds: r.seconds?.toDartDouble,
    );
  } catch (_) {
    return null;
  }
}
