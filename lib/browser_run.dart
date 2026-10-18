import 'browser_run_stub.dart' if (dart.library.js_interop) 'browser_run_web.dart' as impl;
import 'judge0.dart' show RunResult;

/// Code run in the student's own browser: Python with Pyodide
/// (web/py_runner.js), C++ with Clang built for WebAssembly
/// (web/cpp_runner.js). Free and without limits. When it can't run there
/// (off the web, still loading, didn't load), [run] gives null and the
/// caller runs the code on the server instead.
class BrowserRun {
  static const Duration timeLimit = Duration(seconds: 10);

  /// Start loading [lang] now, so a run later doesn't wait for it.
  static void warm(String lang) => impl.warm(_runner(lang));

  /// [lang] is loaded and the next run starts right away.
  static bool ready(String lang) => impl.ready(_runner(lang));

  /// With [file] (C++ only), [stdin] goes in `file.in` and the result's
  /// stdout is `file.out`; see [Judge0.run].
  static Future<RunResult?> run(String lang, String code, String stdin, {String? file}) =>
      impl.run(_runner(lang), code, stdin, timeLimit, lang == 'python' ? null : file);

  static String _runner(String lang) => lang == 'python' ? 'imPython' : 'imCpp';
}
