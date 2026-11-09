// =============================================================================
// PCLP / SD: C PROGRAMS ON TESTS
//   The student writes C (or repairs the program in the editor); it compiles
//   in the browser (Clang for WebAssembly) or, when that can't run, on the
//   server (gcc). "rulează testele" runs every test and shows what differs;
//   "rulează" runs it once on the student's own input.
// =============================================================================

import 'package:flutter/material.dart';

import '../../browser_run.dart';
import '../../judge0.dart';
import '../acs_data.dart';
import '../acs_kit.dart';
import 'ws_common.dart';

const _cKeywords = {
  'int', 'char', 'float', 'double', 'long', 'short', 'unsigned', 'signed', 'void', 'struct', 'union', 'enum', 'typedef', 'const', 'static',
  'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'default', 'break', 'continue', 'return', 'sizeof', 'goto', 'NULL', 'extern',
};

String _norm(String s) => s.replaceAll('\r', '').trim().split('\n').map((l) => l.trimRight()).join('\n');

String _preview(String s, [int lines = 6, int width = 90]) {
  final t = s.replaceAll('\r', '').trimRight();
  if (t.isEmpty) return '(nimic)';
  final ls = t.split('\n');
  final cut = [for (final l in ls.take(lines)) l.length > width ? '${l.substring(0, width)}…' : l];
  return ls.length > lines ? '${cut.join('\n')}\n… (${ls.length} linii)' : cut.join('\n');
}

class CWorkspace extends AcsWorkspace {
  const CWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<CWorkspace> createState() => _CWorkspaceState();
}

class _CWorkspaceState extends State<CWorkspace> {
  late final TextEditingController _code;
  final TextEditingController _stdin = TextEditingController();
  bool _busy = false;
  String _status = '';
  String? _compileError;
  List<Check>? _checks;
  String? _ownOut;

  List<Map> get _tests => (widget.problem.spec['tests'] as List).cast<Map>();

  @override
  void initState() {
    super.initState();
    _code = acsCodeController(widget.problem.spec['starter'] as String? ?? '', _cKeywords);
    if (_tests.isNotEmpty) _stdin.text = '${_tests.first['input']}';
    AcsProgress.draft(widget.problem).then((d) {
      if (d != null && d.trim().isNotEmpty && mounted) _code.text = d;
    });
    _code.addListener(() => AcsProgress.saveDraft(widget.problem, _code.text));
    BrowserRun.warm('c');
  }

  @override
  void dispose() {
    _code.dispose();
    _stdin.dispose();
    super.dispose();
  }

  bool _isCompileError(RunResult r) => r.status == 'Compilation Error' || (r.status.isEmpty && r.error.contains('error:'));

  Future<void> _runTests() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _compileError = null;
      _checks = null;
      _ownOut = null;
      _status = BrowserRun.ready('c') ? 'se compilează...' : 'se pregătește compilatorul (prima dată durează câteva secunde)...';
    });
    final out = <Check>[];
    var allOk = true;
    for (var k = 0; k < _tests.length; k++) {
      final t = _tests[k];
      if (!mounted) return;
      setState(() => _status = 'testul ${k + 1} din ${_tests.length}...');
      final r = await Judge0.run(code: _code.text, stdin: '${t['input']}', lang: 'c');
      if (r.failed) {
        setState(() {
          _busy = false;
          _status = r.error;
        });
        return;
      }
      if (_isCompileError(r)) {
        setState(() {
          _busy = false;
          _status = '';
          _compileError = r.error.trim();
        });
        widget.onVerdict(false);
        return;
      }
      final want = '${t['output']}';
      final ok = r.status != 'Time Limit Exceeded' && !r.status.startsWith('Runtime Error') && _norm(r.stdout) == _norm(want);
      allOk &= ok;
      final time = r.seconds == null ? '' : ' · ${r.seconds!.toStringAsFixed(2)} s';
      String detail = '';
      if (!ok) {
        if (r.status == 'Time Limit Exceeded') {
          detail = 'a depășit timpul (o buclă infinită, sau prea încet)';
        } else if (r.status.startsWith('Runtime Error') || r.status.contains('Signal')) {
          detail = 's-a oprit cu o eroare la rulare (${r.status})${r.error.trim().isEmpty ? '' : ':\n${_preview(r.error, 4)}'}';
        } else {
          detail = 'intrare:\n${_preview('${t['input']}', 4)}\nai afișat:\n${_preview(r.stdout)}\nse aștepta:\n${_preview(want)}';
        }
      }
      out.add(Check('testul ${k + 1}$time', ok, detail));
      setState(() => _checks = List.of(out));
    }
    setState(() {
      _busy = false;
      _status = '';
    });
    widget.onVerdict(allOk);
  }

  Future<void> _runOwn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _compileError = null;
      _ownOut = null;
      _status = BrowserRun.ready('c') ? 'rulează...' : 'se pregătește compilatorul...';
    });
    final r = await Judge0.run(code: _code.text, stdin: _stdin.text, lang: 'c');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = '';
      if (r.failed) {
        _status = r.error;
      } else if (_isCompileError(r)) {
        _compileError = r.error.trim();
      } else {
        _ownOut = '${r.stdout}${r.error.trim().isEmpty ? '' : '\n[stderr]\n${r.error}'}${r.status == 'Accepted' || r.status.isEmpty ? '' : '\n[${r.status}]'}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ink.terminal ? '// main.c — C11' : 'main.c (C11)', style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 6),
        AcsCodeEditor(ink, _code, minHeight: widget.narrow ? 320 : 420, keywords: _cKeywords, onRun: _runTests),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'rulează testele', _busy ? null : _runTests, primary: true, icon: Icons.play_arrow),
          AcsButton(ink, 'rulează cu intrarea mea', _busy ? null : _runOwn),
          AcsConfirmButton(ink, 'cod inițial', _busy ? null : () => setState(() => _code.text = widget.problem.spec['starter'] as String? ?? '')),
          acsKeysHint(ink, 'Ctrl+Enter rulează testele'),
        ], trailing: _busy ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ink.accent)) : null),
        if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status, style: ink.mono(13, color: ink.muted))),
        if (_compileError != null) ...[
          const SizedBox(height: 10),
          AcsBox(ink, title: 'eroare de compilare', color: ink.bg, child: SelectableText(_preview(_compileError!, 14, 140), style: ink.mono(13, color: ink.bad))),
        ],
        if (_checks != null) ...[const SizedBox(height: 12), ChecksView(ink, _checks!, title: _checks!.length < _tests.length ? 'teste: ${_checks!.length} din ${_tests.length}...' : null)],
        const SizedBox(height: 14),
        Text(ink.terminal ? '// intrarea ta (stdin)' : 'Intrarea ta', style: ink.mono(13, color: ink.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: _stdin,
          maxLines: 4,
          minLines: 2,
          style: ink.mono(13.5, color: ink.strong),
          cursorColor: ink.accent,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: ink.panel,
            border: OutlineInputBorder(borderSide: BorderSide(color: ink.line), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.line), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.accent), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
          ),
        ),
        if (_ownOut != null) ...[
          const SizedBox(height: 8),
          AcsBox(ink, title: 'ieșire', color: ink.bg, child: SelectableText(_ownOut!.isEmpty ? '(nimic)' : _preview(_ownOut!, 30, 140), style: ink.mono(13.5))),
        ],
      ],
    );
  }
}
