// "De ce nu merge așa?": what is sent to Claude, how its answer is drawn,
// and the panel against a bridge that is there, old, or missing (the bridge
// is faked: http's MockClient answers as web/claude_bridge.mjs does).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/acs_kit.dart';
import 'package:iMeditatii/acs/explain.dart';
import 'package:iMeditatii/acs/ws/ws_common.dart';
import 'package:iMeditatii/theme_manager.dart';

const _problem = AcsProblem(
  course: 'lfa',
  id: '2',
  title: 'Număr par de a',
  chapter: '1. Automate finite deterministe',
  difficulty: 'ușoară',
  source: '',
  statement: 'Construiește un AFD peste {a, b} care acceptă cuvintele cu un număr par de a.',
  hint: 'Două stări: par și impar.',
  solution: 'q0 par (inițială, finală), q1 impar.',
  kind: 'lfa',
  spec: {'mode': 'dfa', 'alphabet': 'ab'},
);

const _attempt = Attempt('stări: q0, q1; inițială q0; finale: q1\nδ(q0, a) = q1', '[✗] acceptă ε\n    ar trebui acceptat, automatul tău îl respinge');

http.Response _json(Object o, int status) => http.Response.bytes(utf8.encode(jsonEncode(o)), status, headers: {'content-type': 'application/json; charset=utf-8'});

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: child))));

void main() {
  setUpAll(() async {
    ByteData bytes(String path) => ByteData.view(File(path).readAsBytesSync().buffer);
    await (FontLoader('Iosevka')
          ..addFont(Future.value(bytes('assets/fonts/Iosevka-Regular.ttf')))
          ..addFont(Future.value(bytes('assets/fonts/Iosevka-Bold.ttf'))))
        .load();
  });

  test('the prompt has the problem, the answer, the checks and the private solution', () {
    final p = explainPrompt(_problem, _attempt, course: 'Limbaje Formale și Automate');
    expect(p, contains('Limbaje Formale și Automate'));
    expect(p, contains(_problem.statement));
    expect(p, contains('δ(q0, a) = q1'));
    expect(p, contains('[✗] acceptă ε'));
    expect(p, contains('q0 par (inițială, finală)'));
    expect(p, contains('## Contraexemplu, pas cu pas'));
    // a grilă asks not to give the letter away
    final g = explainPrompt(
        const AcsProblem(course: 'lfa', id: '9', title: 'g', chapter: 'c', difficulty: 'medie', source: '', statement: 's', hint: '', solution: '', kind: 'grila', spec: {}),
        const Attempt('am ales: a) x'));
    expect(g, contains('fără să spui direct litera corectă'));
  });

  test('the checks become lines a tutor can read', () {
    expect(reportOf(const [Check('acceptă ab', true), Check('acceptă ε', false, 'îl respinge')]), '[✓] acceptă ab\n[✗] acceptă ε\n    îl respinge');
  });

  test('the answer is cut at its headings, Markdown turned into the site markup', () {
    final s = ExplainText.sections('Intro\n## Pe scurt\nGreșeala e **F**.\n### Unde\n* unu\n1. doi\n```\n# nu e titlu\n```\n');
    expect(s.length, 3);
    expect(s[0], (null, 'Intro'));
    expect(s[1].$1, 'Pe scurt');
    expect(s[2].$1, 'Unde');
    expect(s[2].$2, contains('- unu'));
    expect(s[2].$2, contains('1) doi'));
    expect(s[2].$2, contains('# nu e titlu')); // inside a fence: not a heading
    expect(ExplainText.tidy(r'vezi \(q_0\)'), r'vezi $q_0$');
  });

  for (final style in AcsStyle.values) {
    testWidgets('the panel explains, through the bridge (${style.name})', (t) async {
      SharedPreferences.setMockInitialValues({});
      final asked = <Map<String, dynamic>>[];
      var polls = 0;
      ClaudeBridge.client = MockClient((r) async {
        if (r.url.path == '/health') return _json(({'ok': true, 'version': 2}), 200);
        if (r.url.path == '/explain' && r.method == 'POST') {
          asked.add(jsonDecode(r.body) as Map<String, dynamic>);
          return _json(({'job': 'j${asked.length}'}), 200);
        }
        if (r.url.path.startsWith('/explain/')) {
          polls++;
          final from = int.parse(r.url.queryParameters['from'] ?? '0');
          const all = '## Pe scurt\nAi pus finală starea **q1**.\n## Cum repari\nFă finală q0.';
          final upTo = polls == 1 ? 20 : all.length;
          return _json(({'text': all.substring(from, upTo), 'next': upTo, 'done': polls > 1, 'error': null, 'session': '11111111-2222-3333-4444-555555555555'}), 200);
        }
        return http.Response('{}', 404);
      });
      addTearDown(() => ClaudeBridge.client = http.Client());
      final ink = AcsInk.of(style, false);
      await t.pumpWidget(_host(ExplainPanel(problem: _problem, attempt: _attempt, ink: ink, course: 'LFA')));
      final button = find.textContaining(RegExp('de ce nu merge', caseSensitive: false));
      expect(button, findsWidgets);
      await t.tap(button.first);
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(asked, hasLength(1));
      expect(asked.first['prompt'], contains('δ(q0, a) = q1'));
      expect(find.text(ink.terminal ? '## Cum repari' : 'Cum repari'), findsOneWidget);
      expect(find.textContaining('Fă finală q0'), findsOneWidget);
      // a follow-up resumes the session
      await t.tap(find.text(ink.terminal ? '[ doar un indiciu ]' : 'doar un indiciu'));
      polls = 0;
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(asked, hasLength(2));
      expect(asked.last['session'], '11111111-2222-3333-4444-555555555555');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('with no bridge, the panel says how to start it', (t) async {
    SharedPreferences.setMockInitialValues({});
    ClaudeBridge.client = MockClient((r) async => throw const SocketException('refused'));
    addTearDown(() => ClaudeBridge.client = http.Client());
    await t.pumpWidget(_host(ExplainPanel(problem: _problem, attempt: _attempt, ink: AcsInk.of(AcsStyle.notebook, false))));
    await t.tap(find.textContaining('De ce nu merge').first);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.textContaining('Nu găsesc Claude Code'), findsOneWidget);
    expect(find.textContaining('claude_bridge.mjs'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('an old bridge is asked to be restarted', (t) async {
    SharedPreferences.setMockInitialValues({});
    ClaudeBridge.client = MockClient((r) async => _json(({'ok': true, 'model': 'haiku'}), 200));
    addTearDown(() => ClaudeBridge.client = http.Client());
    await t.pumpWidget(_host(ExplainPanel(problem: _problem, attempt: _attempt, ink: AcsInk.of(AcsStyle.notebook, true))));
    await t.tap(find.textContaining('De ce nu merge').first);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.textContaining('versiune veche'), findsOneWidget);
  });
}
