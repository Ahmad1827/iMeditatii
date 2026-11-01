// The grey suggestion in a real browser, with no login and no typing: the code
// is set step by step and each step is logged, so a script can take screenshots.
// With web/claude_bridge.mjs running, the last steps ask Claude Code for real.
// Build: flutter build web -t tool/complete_harness.dart -o <folder>
import 'package:flutter/material.dart';
import 'package:iMeditatii/code_assistant.dart';
import 'package:iMeditatii/code_workbench.dart';

void log(String s) => print('HARNESS $s'); // ignore: avoid_print

TextEditingValue at(String s) {
  final c = s.indexOf('|');
  return TextEditingValue(text: s.replaceFirst('|', ''), selection: TextSelection.collapsed(offset: c));
}

const String head = '#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, s = 0;\n';

void main() {
  final c = CodeController(text: head);
  final ai = CodeAssistant(c);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: ListenableBuilder(listenable: ai, builder: (_, __) => CodeEditor(controller: c, assistant: ai))),
  ));

  Future<void> step(String name, String code) async {
    // the one character before the caret arrives as typing does
    final i = code.indexOf('|');
    c.value = at('${code.substring(0, i - 1)}|${code.substring(i + 1)}');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    c.value = at(code);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    log('$name ghost=${ai.ghost?.text}');
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  Future<void>.delayed(const Duration(seconds: 2), () async {
    await step('for', '$head    for (int i|)\n    return 0;\n}\n');
    await step('cin', '$head    cin >> |\n    return 0;\n}\n');
    await step('word', '$head    whi|\n    return 0;\n}\n');
    await ai.connect();
    log('link ${ai.link}');
    await step('claude', '$head    cin >> n;\n    // suma cifrelor lui n\n    |\n    return 0;\n}\n');
    for (var i = 0; i < 100 && !(ai.ghost?.fromClaude ?? false); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    log('claude-answer fromClaude=${ai.ghost?.fromClaude} problem=${ai.problem} ghost=${ai.ghost?.text}');
    log('DONE');
  });
}
