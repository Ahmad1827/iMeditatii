// =============================================================================
// MN: OCTAVE IN THE PAGE
//   The function file in the editor; under it an Octave console (>>) where
//   the student's function is already loaded, to try it on their own
//   matrices. "rulează testele" calls it on the hidden tests.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/octave.dart';
import '../engine/octave_task.dart';
import 'ws_common.dart';

const _octKeywords = {
  'function', 'end', 'endfunction', 'if', 'elseif', 'else', 'endif', 'for', 'endfor', 'while', 'endwhile', 'return', 'break', 'continue', 'switch', 'case', 'otherwise',
  'zeros', 'ones', 'eye', 'size', 'length', 'numel', 'rows', 'columns', 'norm', 'abs', 'sqrt', 'sum', 'max', 'min', 'disp', 'printf', 'fprintf', 'triu', 'tril', 'diag',
};

class OctaveWorkspace extends AcsWorkspace {
  const OctaveWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<OctaveWorkspace> createState() => _OctaveWorkspaceState();
}

class _OctaveWorkspaceState extends State<OctaveWorkspace> {
  late final TextEditingController _code;
  late final OctaveTask _task = OctaveTask.fromSpec(widget.problem.spec);
  List<OctResult>? _results;
  final TextEditingController _cmd = TextEditingController();
  final FocusNode _cmdFocus = FocusNode();
  final List<(String, bool)> _console = []; // text, is error
  final List<String> _history = [];
  int _hist = -1;
  Octave? _oct;
  String _loaded = '';
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _code = acsCodeController(widget.problem.spec['starter'] as String? ?? '', _octKeywords, comment: '%');
    AcsProgress.draft(widget.problem).then((d) {
      if (d != null && d.trim().isNotEmpty && mounted) _code.text = d;
    });
    _code.addListener(() => AcsProgress.saveDraft(widget.problem, _code.text));
    final first = _task.cases.isEmpty ? null : _task.cases.first;
    if (first != null) _cmd.text = '${_task.nout > 1 ? '[${[for (var k = 1; k <= _task.nout; k++) 'o$k'].join(', ')}] = ' : 'r = '}${_task.function}(${first.args.join(', ')})';
  }

  @override
  void dispose() {
    _code.dispose();
    _cmd.dispose();
    _cmdFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _runTests() {
    final r = _task.run(_code.text);
    setState(() => _results = r);
    widget.onVerdict(r.every((x) => x.ok));
  }

  /// The console keeps its variables; the file is loaded again when it changed.
  void _exec(String line) {
    if (line.trim().isEmpty) return;
    _history.add(line);
    _hist = -1;
    setState(() {
      _console.add(('>> $line', false));
      try {
        if (_oct == null || _loaded != _code.text) {
          final keep = _oct?.globals;
          _oct = Octave();
          if (keep != null) _oct!.globals.addAll(keep);
          _oct!.load(_code.text);
          _loaded = _code.text;
        }
        _oct!.steps = 0;
        final out = _oct!.eval(line);
        if (out.isNotEmpty) _console.add((out.trimRight(), false));
      } on OctError catch (e) {
        _console.add((e.toString(), true));
      } on StackOverflowError {
        _console.add(('error: recursivitate prea adâncă', true));
      }
      if (_console.length > 400) _console.removeRange(0, _console.length - 400);
      _cmd.clear();
    });
    _cmdFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (_history.isEmpty) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      _hist = _hist == -1 ? _history.length - 1 : (_hist - 1).clamp(0, _history.length - 1);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_hist == -1) return KeyEventResult.handled;
      _hist++;
      if (_hist >= _history.length) {
        _hist = -1;
        _cmd.clear();
        return KeyEventResult.handled;
      }
    } else {
      return KeyEventResult.ignored;
    }
    final t = _history[_hist];
    _cmd.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final spec = widget.problem.spec;
    final forbid = _task.forbid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('% ${spec['function']}.m${forbid.isEmpty ? '' : ' · interzis: ${forbid.map((f) => f == '\\' ? '\\ (backslash)' : f).join(', ')}'}', style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 6),
        AcsCodeEditor(ink, _code, minHeight: widget.narrow ? 280 : 340, keywords: _octKeywords, comment: '%', onRun: _runTests),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'rulează testele', _runTests, primary: true, icon: Icons.play_arrow),
          AcsButton(ink, 'cod inițial', () => setState(() => _code.text = spec['starter'] as String? ?? '')),
        ]),
        if (_results != null) ...[
          const SizedBox(height: 12),
          ChecksView(ink, [for (final r in _results!) Check(_task.describe(r.c), r.ok, r.message)],
              title: _results!.every((r) => r.ok) ? 'teste: toate trec' : 'teste: ${_results!.where((r) => r.ok).length} din ${_results!.length}'),
        ],
        const SizedBox(height: 14),
        Container(
          height: widget.narrow ? 220 : 260,
          decoration: BoxDecoration(color: ink.panel, border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(4)),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
              child: Text('consola Octave · funcția ta e încărcată', style: ink.mono(12, color: ink.muted)),
            ),
            Expanded(
              child: SelectionArea(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  children: [
                    for (final (t, err) in _console) Text(t, style: ink.mono(13, color: err ? ink.bad : (t.startsWith('>> ') ? ink.accent : ink.fg))),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: ink.line))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Text('>> ', style: ink.mono(13.5, color: ink.accent, weight: FontWeight.w700)),
                Expanded(
                  child: Focus(
                    onKeyEvent: _key,
                    skipTraversal: true,
                    child: TextField(
                      controller: _cmd,
                      focusNode: _cmdFocus,
                      style: ink.mono(13.5, color: ink.strong),
                      cursorColor: ink.accent,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: _exec,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }
}
