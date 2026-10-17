import 'browser_python_stub.dart' if (dart.library.js_interop) 'browser_python_web.dart' as impl;
import 'judge0.dart' show RunResult;

/// Python run in the student's own browser (Pyodide, see web/py_runner.js):
/// free and without limits. Off the web, or when Python can't load there,
/// [run] gives null and the caller runs the code on the server instead.
class BrowserPython {
  static const Duration timeLimit = Duration(seconds: 10);

  /// Start loading Python now, so the first run doesn't wait for it.
  static void warm() => impl.warm();

  /// Python is loaded and the next run starts right away.
  static bool get ready => impl.ready();

  static Future<RunResult?> run(String code, String stdin) => impl.run(code, stdin, timeLimit);
}
