import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'code_complete.dart';
import 'code_workbench.dart' show CodeController;

enum ClaudeLink { off, connecting, ready, unreachable }

// =============================================================================
// AUTOCOMPLETE FOR THE IDE: decides when to suggest. The built-in completer
// answers on every key. If the student connected Claude Code, a pause in typing
// also asks it, through web/claude_bridge.mjs on their own computer, and its
// answer replaces the built-in one.
//
// 127.0.0.1 is never contacted until the student asks for it: Chrome shows every
// page that tries a permission prompt, which nobody else should see.
// =============================================================================
class CodeAssistant extends ChangeNotifier {
  static const String _base = 'http://127.0.0.1:7823';
  static const String setupCommand = 'curl -fsSL https://ahmad1827.github.io/claude_bridge.mjs -o claude_bridge.mjs && node claude_bridge.mjs';
  static const String _kEnabled = 'ide_autocomplete';
  static const String _kClaude = 'ide_claude';
  static const Duration _pause = Duration(milliseconds: 800);

  final CodeController _controller;

  CodeAssistant(this._controller, {http.Client? client}) : _http = client ?? http.Client() {
    _text = _controller.text;
    _caret = _controller.selection.baseOffset;
    _controller.addListener(_onChange);
    _load();
  }

  final http.Client _http;
  late String _text;
  late int _caret;
  int _gen = 0; // a Claude answer counts only if nothing changed since it was asked
  Timer? _timer;
  DateTime _nextProbe = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  bool enabled = true;
  bool thinking = false;
  ClaudeLink link = ClaudeLink.off;
  String? problem; // the last error from Claude Code, shown in the dialog
  Ghost? ghost;

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool(_kEnabled) ?? true;
      if (_disposed) return;
      notifyListeners();
      if (p.getBool(_kClaude) ?? false) await connect(remember: false);
    } catch (_) {}
  }

  void _show(Ghost? g) {
    if (g == ghost) return;
    ghost = g;
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _gen++;
    if (thinking) {
      thinking = false;
      notifyListeners();
    }
  }

  void _onChange() {
    final text = _controller.text;
    final sel = _controller.selection;
    final caret = sel.baseOffset;
    if (text == _text) {
      if (caret != _caret) {
        _caret = caret;
        _stop();
        _show(null);
      }
      return;
    }
    final grew = text.length - _text.length;
    _text = text;
    _caret = caret;
    _stop();
    // only while typing: not after deleting, not after pasting a whole program
    if (!enabled || grew <= 0 || grew > 80 || !sel.isCollapsed) return _show(null);
    _show(CodeComplete.suggest(text, caret, lang: _controller.lang));
    if (link == ClaudeLink.ready || link == ClaudeLink.unreachable) {
      _timer = Timer(_pause, _askClaude);
    }
  }

  void dismiss() {
    _stop();
    _show(null);
  }

  /// Ctrl+Space: a suggestion now, even if the last change was not typing.
  void requestNow() {
    if (!enabled) return;
    _stop();
    final text = _controller.text;
    final caret = _controller.selection.baseOffset;
    _show(CodeComplete.suggest(text, caret, lang: _controller.lang));
    if (link != ClaudeLink.off) _askClaude();
  }

  Future<void> _askClaude() async {
    if (_disposed) return;
    final text = _controller.text;
    final caret = _controller.selection.baseOffset;
    if (!CodeComplete.canComplete(text, caret)) return;

    if (link == ClaudeLink.unreachable) {
      if (DateTime.now().isBefore(_nextProbe)) return;
      if (!await _probe() || _disposed) return;
      notifyListeners();
    }

    final gen = ++_gen;
    thinking = true;
    notifyListeners();
    try {
      final res = await _http
          .post(Uri.parse('$_base/complete'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'before': text.substring(0, caret), 'after': text.substring(caret), 'lang': _controller.lang}))
          .timeout(const Duration(seconds: 35));
      if (_disposed || gen != _gen) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      thinking = false;
      final error = body['error'];
      problem = error is String ? error : null;
      final completion = body['completion'];
      if (completion is String) {
        final g = CodeComplete.fromModel(completion, text, caret);
        if (g != null) ghost = g;
      }
      notifyListeners();
    } catch (_) {
      if (_disposed || gen != _gen) return;
      thinking = false;
      link = ClaudeLink.unreachable;
      _nextProbe = DateTime.now().add(const Duration(seconds: 15));
      notifyListeners();
    }
  }

  Future<bool> _probe() async {
    try {
      final res = await _http.get(Uri.parse('$_base/health')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        link = ClaudeLink.ready;
        problem = null;
        return true;
      }
    } catch (_) {}
    link = ClaudeLink.unreachable;
    _nextProbe = DateTime.now().add(const Duration(seconds: 15));
    return false;
  }

  /// Looks for the bridge; stays on (and keeps looking) if it is not running yet.
  Future<void> connect({bool remember = true}) async {
    link = ClaudeLink.connecting;
    notifyListeners();
    if (remember) _savePref(_kClaude, true);
    await _probe();
    if (!_disposed) notifyListeners();
  }

  void disconnect() {
    _stop();
    link = ClaudeLink.off;
    problem = null;
    _savePref(_kClaude, false);
    notifyListeners();
  }

  void setEnabled(bool on) {
    enabled = on;
    if (!on) {
      _stop();
      ghost = null;
    }
    _savePref(_kEnabled, on);
    notifyListeners();
  }

  void _savePref(String key, bool value) {
    SharedPreferences.getInstance().then((p) => p.setBool(key, value)).catchError((_) => false);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _controller.removeListener(_onChange);
    _http.close();
    super.dispose();
  }
}
