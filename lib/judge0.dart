import 'dart:convert';

import 'package:http/http.dart' as http;

import 'browser_run.dart';

/// Result of one program run.
class RunResult {
  final String stdout;
  final String error; // compile output or stderr
  final String status; // "Accepted", "Compilation Error", "Time Limit Exceeded"...
  final double? seconds;
  final int? memoryKb;
  final bool failed; // request itself failed (network / quota)
  // a problem with files ([Judge0.run]'s `file`): [stdout] is what the program
  // wrote in <file>.out, [console] what it wrote on the screen (which doesn't count)
  final String console;
  final bool noFile; // it didn't create <file>.out

  const RunResult({
    this.stdout = '',
    this.console = '',
    this.noFile = false,
    this.error = '',
    this.status = '',
    this.seconds,
    this.memoryKb,
    this.failed = false,
  });

  bool get ok => !failed && status == 'Accepted';

  RunResult copyWith({String? stdout, String? console, bool? noFile}) => RunResult(
        stdout: stdout ?? this.stdout,
        console: console ?? this.console,
        noFile: noFile ?? this.noFile,
        error: error,
        status: status,
        seconds: seconds,
        memoryKb: memoryKb,
        failed: failed,
      );
}

/// A problem with files, like at the olympiad: the program reads `name.in`
/// and writes `name.out`; the keyboard gives it nothing and the screen doesn't count.
class FileIo {
  /// Between the screen and `name.out` in what [wrap]'s program prints.
  static const String marker = '\u0001IM-FILE-OUT\u0001';

  /// For a judge that only has the keyboard and the screen: [code] with a
  /// prelude that, before main, writes [input] to `name.in`, and after the
  /// program ends prints the screen's [marker] and `name.out` on the real
  /// screen (kept aside, so a freopen of stdout doesn't take it). `#line 1`
  /// keeps the compiler's line numbers those of the student's code.
  static String wrap(String code, String name, String input) {
    var tag = 'IMIN';
    while (input.contains(')$tag"')) {
      tag += 'X';
    }
    return '''#include <cstdio>
#include <unistd.h>
namespace im_file_io {
struct Io {
  int screen;
  Io() {
    std::FILE *f = std::fopen("$name.in", "w");
    if (f) { std::fputs(R"$tag($input)$tag", f); std::fclose(f); }
    std::remove("$name.out");
    screen = dup(1);
  }
  ~Io() {
    std::fflush(stdout);
    const char m[] = "\\001IM-FILE-OUT\\001"; // [marker]
    if (write(screen, m, sizeof m - 1) < 0) return;
    std::FILE *f = std::fopen("$name.out", "r");
    if (!f) return;
    if (write(screen, "+", 1) < 0) return;
    char b[65536];
    std::size_t n;
    while ((n = std::fread(b, 1, sizeof b, f)) > 0) {
      if (write(screen, b, n) < 0) break;
    }
    std::fclose(f);
  }
} io;
}
#line 1
$code''';
  }

  /// What [wrap]'s program printed, split: the screen, and `name.out` (null: not created).
  static (String screen, String? file) split(String printed) {
    final at = printed.lastIndexOf(marker);
    if (at < 0) return (printed, null);
    final rest = printed.substring(at + marker.length);
    return (printed.substring(0, at), rest.startsWith('+') ? rest.substring(1) : null);
  }
}

/// Thin wrapper over the Judge0 CE API used by the problem judge and the IDE.
/// The code goes to [BrowserRun] first.
class Judge0 {
  static const String apiKey = 'YOUR_API_KEY';
  static const String _host = 'judge0-ce.p.rapidapi.com';

  static const int cpp = 52;
  static const int python = 71;

  static int languageId(String lang) => lang == 'python' ? python : cpp;

  /// Public Judge0 CE instance: no key, used when the RapidAPI plan refuses us.
  static const String _publicHost = 'ce.judge0.com';
  static bool _usePublic = false;

  static Future<http.Response> _post(String host, Map<String, String> headers, String body) => http
      .post(
        Uri.parse('https://$host/submissions?base64_encoded=true&wait=true'),
        headers: {'Content-Type': 'application/json', ...headers},
        body: body,
      )
      .timeout(const Duration(seconds: 40));

  /// Runs [code] on [stdin]. With [file] (a problem with files), [stdin] goes
  /// in `file.in` instead, the keyboard is empty, and the result's stdout is
  /// what the program wrote in `file.out`.
  static Future<RunResult> run({required String code, String stdin = '', String lang = 'cpp', String? file}) async {
    // In the browser when it can: free, and no limit on runs.
    final local = await BrowserRun.run(lang, code, stdin, file: file);
    if (local != null) return local;
    if (file == null) return _server(code, stdin, lang);
    final r = await _server(FileIo.wrap(code, file, stdin), '', lang);
    if (r.failed || r.status == 'Compilation Error') return r;
    final (screen, out) = FileIo.split(r.stdout);
    return r.copyWith(stdout: out ?? '', console: screen, noFile: out == null);
  }

  static Future<RunResult> _server(String code, String stdin, String lang) async {
    try {
      final body = jsonEncode({
        'language_id': languageId(lang),
        'source_code': base64Encode(utf8.encode(code)),
        'stdin': base64Encode(utf8.encode(stdin)),
      });

      http.Response? res;
      if (!_usePublic) {
        res = await _post(_host, const {'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': _host}, body);
        // Not subscribed / key revoked / monthly quota used up: switch for the rest of the session.
        if (res.statusCode == 401 || res.statusCode == 403 || res.statusCode == 429) _usePublic = true;
      }
      if (_usePublic) res = await _post(_publicHost, const {}, body);

      if (res!.statusCode == 429) {
        return const RunResult(failed: true, error: 'Limita de rulări a fost atinsă. Încearcă din nou peste câteva minute.');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return RunResult(failed: true, error: 'Serviciul de rulare a răspuns cu eroarea ${res.statusCode}.');
      }

      final r = jsonDecode(res.body) as Map<String, dynamic>;
      String dec(dynamic v) {
        if (v == null) return '';
        try {
          return utf8.decode(base64Decode('$v'.replaceAll(RegExp(r'\s'), '')), allowMalformed: true);
        } catch (_) {
          return '$v';
        }
      }

      final compile = dec(r['compile_output']);
      final stderr = dec(r['stderr']);
      final message = dec(r['message']);
      return RunResult(
        stdout: dec(r['stdout']),
        error: [compile, stderr, if (compile.isEmpty && stderr.isEmpty) message].where((e) => e.trim().isNotEmpty).join('\n'),
        status: '${(r['status'] as Map?)?['description'] ?? ''}',
        seconds: double.tryParse('${r['time'] ?? ''}'),
        memoryKb: r['memory'] is num ? (r['memory'] as num).toInt() : null,
      );
    } catch (e) {
      return RunResult(failed: true, error: 'Nu am putut rula codul: $e');
    }
  }
}
