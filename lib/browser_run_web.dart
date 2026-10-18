import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'judge0.dart' show RunResult;

extension type _Runner._(JSObject _) implements JSObject {
  external void warm();
  external JSBoolean isReady();
  external JSPromise<_Result> run(JSString code, JSString stdin, JSNumber timeoutMs, JSString? file);
}

extension type _Result._(JSObject _) implements JSObject {
  external JSString? get stdout;
  external JSString? get console; // a problem with files: what went on the screen
  external JSBoolean? get noFile;
  external JSString? get stderr;
  external JSString? get status;
  external JSNumber? get seconds;
  external JSBoolean? get failed;
  external JSBoolean? get notReady;
}

/// window.imPython or window.imCpp, if the page loaded it.
_Runner? _get(String name) => globalContext.has(name) ? globalContext.getProperty<JSObject>(name.toJS) as _Runner : null;

void warm(String runner) => _get(runner)?.warm();

bool ready(String runner) => _get(runner)?.isReady().toDart ?? false;

Future<RunResult?> run(String runner, String code, String stdin, Duration limit, String? file) async {
  final r0 = _get(runner);
  if (r0 == null) return null;
  try {
    final r = await r0.run(code.toJS, stdin.toJS, limit.inMilliseconds.toJS, file?.toJS).toDart;
    if ((r.failed?.toDart ?? false) || (r.notReady?.toDart ?? false)) return null; // let the server run it
    return RunResult(
      stdout: r.stdout?.toDart ?? '',
      console: r.console?.toDart ?? '',
      noFile: r.noFile?.toDart ?? false,
      error: r.stderr?.toDart ?? '',
      status: r.status?.toDart ?? '',
      seconds: r.seconds?.toDartDouble,
    );
  } catch (_) {
    return null;
  }
}
