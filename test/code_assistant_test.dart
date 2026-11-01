// The suggestion in the real editor: when it appears, what Tab and Esc do, and
// that Claude's answer replaces the built-in one only while it is still current.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/code_assistant.dart';
import 'package:iMeditatii/code_workbench.dart';

TextEditingValue at(String s) {
  final c = s.indexOf('|');
  return TextEditingValue(text: s.replaceFirst('|', ''), selection: TextSelection.collapsed(offset: c));
}

String shown(CodeController c) {
  final o = c.selection.baseOffset;
  return c.text.replaceRange(o, o, '|');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(CodeController, CodeAssistant, FocusNode)> pump(WidgetTester t, {http.Client? client}) async {
    final c = CodeController(text: '');
    final ai = CodeAssistant(c, client: client);
    final f = FocusNode();
    addTearDown(() {
      ai.dispose();
      f.dispose();
    });
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ListenableBuilder(listenable: ai, builder: (_, __) => CodeEditor(controller: c, focusNode: f, assistant: ai)))));
    await t.pump();
    f.requestFocus();
    await t.pump();
    return (c, ai, f);
  }

  testWidgets('Tab takes the suggestion and puts the caret where the code goes', (t) async {
    final (c, ai, _) = await pump(t);
    c.value = at('whi|');
    await t.pump();
    expect(ai.ghost?.text, 'le ()');
    expect(find.textContaining('le ()', findRichText: true), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(shown(c), 'while (|)');
  });

  testWidgets('without a suggestion Tab still writes its spaces', (t) async {
    final (c, ai, _) = await pump(t);
    c.value = at('x|');
    await t.pump();
    expect(ai.ghost, isNull);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(shown(c), 'x    |');
  });

  testWidgets('Esc hides it, and then Tab writes its spaces', (t) async {
    final (c, ai, _) = await pump(t);
    c.value = at('whi|');
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    expect(ai.ghost, isNull);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(shown(c), 'whi    |');
  });

  testWidgets('it goes away when the caret moves, and is not offered after deleting or pasting', (t) async {
    final (c, ai, _) = await pump(t);
    c.value = at('whi|');
    await t.pump();
    c.value = at('wh|i');
    await t.pump();
    expect(ai.ghost, isNull);

    c.value = at('whil|');
    await t.pump();
    expect(ai.ghost, isNotNull);
    c.value = at('whi|');
    await t.pump();
    expect(ai.ghost, isNull);

    c.value = at('${'x = 1;\n' * 30}whi|');
    await t.pump();
    expect(ai.ghost, isNull);
  });

  testWidgets('Ctrl+Space asks even when the last change was not typing', (t) async {
    final (c, ai, _) = await pump(t);
    c.value = at('whil|');
    c.value = at('whi|');
    await t.pump();
    expect(ai.ghost, isNull);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pump();
    expect(ai.ghost?.text, 'le ()');
  });

  testWidgets('switched off, nothing is suggested', (t) async {
    final (c, ai, _) = await pump(t);
    ai.setEnabled(false);
    c.value = at('whi|');
    await t.pump();
    expect(ai.ghost, isNull);
  });

  testWidgets('nobody contacts the computer until the student connects', (t) async {
    var calls = 0;
    final (c, _, _) = await pump(t, client: MockClient((_) async {
      calls++;
      return http.Response('{}', 500);
    }));
    c.value = at('whi|');
    await t.pump(const Duration(seconds: 3));
    expect(calls, 0);
  });

  group('connected to Claude Code', () {
    http.Client bridge(FutureOr<String> Function(Map<String, dynamic>) answer) => MockClient((r) async {
          if (r.url.path == '/health') return http.Response('{"ok":true}', 200);
          return http.Response.bytes(utf8.encode(jsonEncode({'completion': await answer(jsonDecode(r.body) as Map<String, dynamic>)})), 200);
        });

    testWidgets('after a pause its answer replaces the built-in one', (t) async {
      Map<String, dynamic>? asked;
      final (c, ai, _) = await pump(t, client: bridge((b) {
        asked = b;
        return 'le (n > 0) {';
      }));
      await t.runAsync(() => ai.connect());
      c.value = at('whi|');
      await t.pump();
      expect(ai.ghost!.fromClaude, isFalse);
      await t.pump(const Duration(milliseconds: 900));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
      expect(asked, {'before': 'whi', 'after': '', 'lang': 'cpp'});
      expect(ai.ghost!.fromClaude, isTrue);
      expect(ai.ghost!.text, 'le (n > 0) {');
    });

    testWidgets('an answer for code that changed meanwhile is thrown away', (t) async {
      final answer = Completer<String>();
      final (c, ai, _) = await pump(t, client: bridge((_) => answer.future));
      await t.runAsync(() => ai.connect());
      c.value = at('whi|');
      await t.pump(const Duration(milliseconds: 900));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect(ai.thinking, isTrue);

      c.value = at('whil|');
      await t.pump();
      answer.complete('old answer');
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
      expect(ai.ghost?.fromClaude, isFalse);
      expect(ai.ghost?.text, 'e ()');
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('when the bridge stops, the built-in completer carries on', (t) async {
      var up = true;
      final client = MockClient((r) async {
        if (!up) throw http.ClientException('refused');
        return http.Response('{"ok":true}', 200);
      });
      final (c, ai, _) = await pump(t, client: client);
      await t.runAsync(() => ai.connect());
      expect(ai.link, ClaudeLink.ready);
      up = false;
      c.value = at('whi|');
      await t.pump(const Duration(milliseconds: 900));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
      expect(ai.link, ClaudeLink.unreachable);
      expect(ai.ghost?.text, 'le ()');
    });
  });
}
