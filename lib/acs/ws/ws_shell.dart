// =============================================================================
// USO: A TERMINAL ON THE PAGE
//   The student types commands into a real (in-memory) bash: history with the
//   arrows, Tab completes names, `nano file` opens an editor in place, Ctrl+L
//   clears. Verifică checks the files as they are now; Resetează starts over.
//   What was typed (and saved in the editor) is kept, and replayed on return.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/shell.dart';
import '../engine/shell_task.dart';
import '../engine/vfs.dart';
import 'ws_common.dart';

class ShellWorkspace extends AcsWorkspace {
  const ShellWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<ShellWorkspace> createState() => _ShellWorkspaceState();
}

class _Line {
  final String text;
  final int kind; // 0 output, 1 error, 2 prompt+command, 3 note
  final String dir;
  const _Line(this.text, this.kind, [this.dir = '']);
}

class _ShellWorkspaceState extends State<ShellWorkspace> with TypeToConsole {
  late ShellTask _task;
  late Shell _sh;
  final List<_Line> _lines = [];
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _journal = []; // what was done, to replay
  String _pending = ''; // the lines of a command not finished yet
  int _hist = -1;
  String _histDraft = '';
  List<TaskCheck>? _checks;

  // the editor (nano)
  String? _editing;
  TextEditingController? _editor;
  final FocusNode _editorFocus = FocusNode();

  @override
  FocusNode get consoleFocus => _focus;
  @override
  TextEditingController get consoleInput => _input;
  @override
  bool get consoleActive => _editing == null;

  @override
  void initState() {
    super.initState();
    _task = ShellTask(widget.problem.spec);
    _start();
    _restore();
  }

  void _start() {
    _sh = _task.shell();
    _sh.onEdit = _openEditor;
    _sh.onClear = () => _lines.clear();
    _lines
      ..clear()
      ..add(const _Line('Shell-ul USO (bash): scrie direct, fără click. help: comenzile; nano fisier: editorul; ↑↓ istoricul, Tab completează; Verifică: verifică ce ai făcut.', 3));
  }

  Future<void> _restore() async {
    final d = await AcsProgress.draft(widget.problem);
    if (d == null || !mounted) return;
    try {
      final list = (json.decode(d) as List).cast<Map>();
      setState(() {
        for (final e in list) {
          final m = e.cast<String, String>();
          _journal.add(m);
          if (m['cmd'] != null) {
            _echo(m['cmd']!, _sh.shortCwd);
            _show(_sh.run(m['cmd']!));
          } else if (m['write'] != null) {
            _sh.fs.write(m['write']!, '/', m['text'] ?? '');
          }
        }
        if (list.isNotEmpty) _lines.add(const _Line('(sesiunea de data trecută, refăcută)', 3));
      });
      _toBottom();
      focusConsole();
    } catch (_) {
      // an old draft we can't read: start clean
    }
  }

  void _save() => AcsProgress.saveDraft(widget.problem, json.encode(_journal));

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _editorFocus.dispose();
    _scroll.dispose();
    _editor?.dispose();
    super.dispose();
  }

  void _echo(String cmd, String dir) {
    final parts = cmd.split('\n');
    _lines.add(_Line(parts.first, 2, dir));
    for (final p in parts.skip(1)) {
      _lines.add(_Line(p, 2, '>'));
    }
  }

  void _show(List<(String, bool)> chunks) {
    for (final (text, err) in chunks) {
      final t = text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
      for (final l in t.split('\n')) {
        _lines.add(_Line(l, err ? 1 : 0));
      }
    }
    if (_lines.length > 3000) _lines.removeRange(0, _lines.length - 3000);
  }

  void _submit(String text) {
    final full = _pending.isEmpty ? text : '$_pending\n$text';
    if (!Shell.complete(full)) {
      setState(() {
        _echo(text, _pending.isEmpty ? _sh.shortCwd : '>');
        _pending = full;
        _input.clear();
      });
      _focus.requestFocus();
      _toBottom();
      return;
    }
    final dir = _sh.shortCwd;
    setState(() {
      if (_pending.isEmpty) {
        _echo(text, dir);
      } else {
        _lines.add(_Line(text, 2, '>'));
      }
      _pending = '';
      _input.clear();
      _hist = -1;
      if (full.trim().isNotEmpty) {
        final chunks = _sh.run(full);
        _show(chunks);
        _journal.add({'cmd': full});
        _save();
      }
    });
    _focus.requestFocus();
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final h = _sh.history;
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (h.isEmpty) return KeyEventResult.handled;
      if (_hist == -1) _histDraft = _input.text;
      _hist = _hist == -1 ? h.length - 1 : (_hist - 1).clamp(0, h.length - 1);
      _setInput(h[_hist]);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_hist == -1) return KeyEventResult.handled;
      _hist++;
      if (_hist >= h.length) {
        _hist = -1;
        _setInput(_histDraft);
      } else {
        _setInput(h[_hist]);
      }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab) {
      _complete();
      return KeyEventResult.handled;
    }
    if (ctrl && e.logicalKey == LogicalKeyboardKey.keyL) {
      setState(() => _lines.clear());
      return KeyEventResult.handled;
    }
    if (ctrl && e.logicalKey == LogicalKeyboardKey.keyC) {
      setState(() {
        _lines.add(_Line('${_input.text}^C', 2, _pending.isEmpty ? _sh.shortCwd : '>'));
        _pending = '';
        _input.clear();
      });
      _toBottom();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _setInput(String s) {
    _input.value = TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }

  /// Tab: the rest of a file name (or a command), or the choices.
  void _complete() {
    final text = _input.text;
    final caret = _input.selection.baseOffset < 0 ? text.length : _input.selection.baseOffset;
    final before = text.substring(0, caret);
    final m = RegExp(r'[^\s|;&<>]*$').firstMatch(before)!;
    final word = m[0]!;
    final isCmd = before.substring(0, m.start).trim().isEmpty || RegExp(r'[|;&]\s*$').hasMatch(before.substring(0, m.start));
    final slash = word.lastIndexOf('/');
    final dirPart = slash < 0 ? '' : word.substring(0, slash + 1);
    final base = slash < 0 ? word : word.substring(slash + 1);
    final candidates = <String>[];
    if (isCmd && slash < 0) {
      for (final c in ['ls', 'cd', 'cat', 'echo', 'grep', 'find', 'chmod', 'mkdir', 'touch', 'rm', 'cp', 'mv', 'ln', 'sort', 'uniq', 'cut', 'tr', 'sed', 'awk', 'head', 'tail', 'wc', 'nano', 'bash', 'stat', 'pwd', 'tee', 'xargs', 'seq', 'printf', 'umask', 'history', 'clear', 'help']) {
        if (c.startsWith(base)) candidates.add(c);
      }
    }
    final dirAbs = Vfs.absolute(dirPart.isEmpty ? '.' : (dirPart.startsWith('~') ? '${Vfs.home}${dirPart.substring(1)}' : dirPart), _sh.cwd);
    final dir = _sh.fs.lookup(dirAbs, '/');
    if (dir != null && dir.isDir) {
      for (final e in dir.kids.entries) {
        if (e.key.startsWith(base) && (base.startsWith('.') || !e.key.startsWith('.'))) {
          final isDir = e.value.isDir || (e.value.isLink && (_sh.fs.lookup('$dirAbs/${e.key}', '/')?.isDir ?? false));
          candidates.add(isDir ? '${e.key}/' : e.key);
        }
      }
    }
    if (candidates.isEmpty) return;
    String common = candidates.first;
    for (final c in candidates.skip(1)) {
      var k = 0;
      while (k < common.length && k < c.length && common[k] == c[k]) {
        k++;
      }
      common = common.substring(0, k);
    }
    if (candidates.length == 1 && !common.endsWith('/')) common = '$common ';
    if (common.length > base.length) {
      final insert = dirPart + common;
      final nt = before.substring(0, m.start) + insert + text.substring(caret);
      _input.value = TextEditingValue(text: nt, selection: TextSelection.collapsed(offset: m.start + insert.length));
    } else if (candidates.length > 1) {
      setState(() {
        _echo(text, _sh.shortCwd);
        _lines.add(_Line(candidates.join('  '), 0));
      });
      _toBottom();
    }
  }

  // ---------------------------------------------------------------- the editor
  void _openEditor(String path) {
    final n = _sh.fs.lookup(path, '/');
    if (n != null && n.isDir) {
      _lines.add(_Line('nano: $path: Is a directory', 1));
      return;
    }
    if (n != null && !Vfs.may(n, 'r')) {
      _lines.add(_Line('nano: $path: Permission denied', 1));
      return;
    }
    _editor?.dispose();
    _editor = acsCodeController(n?.data ?? '', const {'if', 'then', 'else', 'elif', 'fi', 'for', 'in', 'do', 'done', 'while', 'until', 'case', 'esac', 'function', 'return', 'echo', 'read', 'local', 'exit', 'shift'}, comment: '#');
    _editing = path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing != null) _editorFocus.requestFocus();
    });
  }

  void _saveEditor() {
    final path = _editing;
    if (path == null) return;
    try {
      _sh.fs.write(path, '/', _editor!.text);
      _journal.add({'write': path, 'text': _editor!.text});
      _save();
      setState(() => _lines.add(_Line('[ am scris ${'\n'.allMatches(_editor!.text).length} linii în ${_short(path)} ]', 3)));
    } on ShError catch (e) {
      setState(() => _lines.add(_Line('nano: ${e.message}', 1)));
    }
  }

  void _closeEditor({bool save = false}) {
    if (save) _saveEditor();
    setState(() {
      _editing = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => focusConsole(evenOnTouch: true));
    _toBottom();
  }

  String _short(String p) => p.startsWith(Vfs.home) ? '~${p.substring(Vfs.home.length)}' : p;

  // ---------------------------------------------------------------- checks
  void _verify() {
    final r = _task.verify(_sh);
    setState(() => _checks = r);
    widget.onVerdict(ShellTask.passed(r));
    focusConsole();
  }

  void _reset() {
    setState(() {
      _journal.clear();
      _save();
      _pending = '';
      _checks = null;
      _editing = null;
      _start();
    });
    focusConsole();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final h = widget.narrow ? 380.0 : 460.0;
    final term = ink.terminal ? (ink.dark ? const Color(0xFF0A0C0B) : const Color(0xFF15191A)) : (ink.dark ? const Color(0xFF151618) : const Color(0xFF1E2126));
    const tfg = Color(0xFFD5DDD0), tacc = Color(0xFF9FCF8F), tmuted = Color(0xFF7D887A), tbad = Color(0xFFE88A80), tblue = Color(0xFF8AB4F0);
    final style = ink.mono(widget.narrow ? 13 : 14, color: tfg, height: 1.4);

    Widget line(_Line l) {
      switch (l.kind) {
        case 2:
          return Text.rich(
              TextSpan(children: [
                if (l.dir == '>')
                  const TextSpan(text: '> ', style: TextStyle(color: tmuted))
                else ...[
                  const TextSpan(text: 'student@acs', style: TextStyle(color: tacc, fontWeight: FontWeight.w700)),
                  const TextSpan(text: ':', style: TextStyle(color: tmuted)),
                  TextSpan(text: l.dir, style: const TextStyle(color: tblue, fontWeight: FontWeight.w700)),
                  const TextSpan(text: '\$ ', style: TextStyle(color: tmuted)),
                ],
                TextSpan(text: l.text),
              ]),
              style: style);
        case 1:
          return Text(l.text, style: style.copyWith(color: tbad));
        case 3:
          return Text(l.text, style: style.copyWith(color: tmuted, fontStyle: FontStyle.italic));
        default:
          return Text(l.text.isEmpty ? ' ' : l.text, style: style);
      }
    }

    final terminal = TapToFocus(
      onTap: () {
        // a click that ends a text selection leaves it to be copied
        if (!_focus.hasFocus) focusConsole(evenOnTouch: true);
      },
      child: Container(
        key: consoleKey,
        height: h,
        decoration: BoxDecoration(color: term, borderRadius: ink.terminal ? null : BorderRadius.circular(6), border: Border.all(color: ink.line)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2A302A)))),
              child: Row(children: [
                for (final c in const [Color(0xFFE07A6E), Color(0xFFD9B45A), Color(0xFF9FCF8F)])
                  Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(child: Text('student@acs: ${_sh.shortCwd}', style: style.copyWith(color: tmuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(
              child: SelectionArea(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  itemCount: _lines.length + 1,
                  itemBuilder: (context, i) {
                    if (i < _lines.length) return line(_lines[i]);
                    return SelectionContainer.disabled(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text.rich(
                              TextSpan(children: _pending.isNotEmpty
                                  ? const [TextSpan(text: '> ', style: TextStyle(color: tmuted))]
                                  : [
                                      const TextSpan(text: 'student@acs', style: TextStyle(color: tacc, fontWeight: FontWeight.w700)),
                                      const TextSpan(text: ':', style: TextStyle(color: tmuted)),
                                      TextSpan(text: _sh.shortCwd, style: const TextStyle(color: tblue, fontWeight: FontWeight.w700)),
                                      const TextSpan(text: '\$ ', style: TextStyle(color: tmuted)),
                                    ]),
                              style: style),
                          Expanded(
                            child: Focus(
                              onKeyEvent: _key,
                              skipTraversal: true,
                              child: TextField(
                                controller: _input,
                                focusNode: _focus,
                                autofocus: !acsTouchDevice,
                                style: style,
                                cursorColor: tacc,
                                cursorWidth: 8,
                                autocorrect: false,
                                enableSuggestions: false,
                                smartQuotesType: SmartQuotesType.disabled,
                                smartDashesType: SmartDashesType.disabled,
                                textInputAction: TextInputAction.send,
                                onSubmitted: _submit,
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final editor = _editing == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: ink.accent,
                child: Text('  GNU nano   ${_short(_editing!)}   ·   ^S salvează · Esc salvează și închide', style: ink.mono(13, weight: FontWeight.w700, color: ink.bg), overflow: TextOverflow.ellipsis),
              ),
              CallbackShortcuts(
                bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _closeEditor(save: true)},
                child: AcsCodeEditor(ink, _editor!, minHeight: h - 80, comment: '#', onSave: _saveEditor, focusNode: _editorFocus),
              ),
              const SizedBox(height: 8),
              ToolRow([
                AcsButton(ink, 'salvează ^S', _saveEditor, primary: true),
                AcsButton(ink, 'salvează și închide', () => _closeEditor(save: true)),
                AcsButton(ink, 'închide fără să salvezi', _closeEditor),
              ]),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        editor ?? terminal,
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check),
          AcsConfirmButton(ink, 'resetează fișierele', _reset),
          acsKeysHint(ink, '↑↓ istoric · Tab completează · Ctrl+L curăță'),
        ]),
        if (_checks != null) ...[
          const SizedBox(height: 12),
          ChecksView(ink, [for (final c in _checks!) Check(c.label, c.ok, c.detail)]),
        ],
      ],
    );
  }
}
