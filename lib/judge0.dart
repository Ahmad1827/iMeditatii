import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of one program run.
class RunResult {
  final String stdout;
  final String error; // compile output or stderr
  final String status; // "Accepted", "Compilation Error", "Time Limit Exceeded"...
  final double? seconds;
  final int? memoryKb;
  final bool failed; // request itself failed (network / quota)

  const RunResult({
    this.stdout = '',
    this.error = '',
    this.status = '',
    this.seconds,
    this.memoryKb,
    this.failed = false,
  });

  bool get ok => !failed && status == 'Accepted';
}

/// Thin wrapper over the Judge0 CE API used by the problem judge and the IDE.
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

  static Future<RunResult> run({required String code, String stdin = '', String lang = 'cpp'}) async {
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
