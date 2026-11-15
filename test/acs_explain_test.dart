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
import 'package:iMeditatii/acs/acs_problem_screen.dart';
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

/// The problem page's side: a check that gives [ok] with [attempt] (or nothing, when null).
class _Page {
  bool? ok;
  Attempt? attempt;
  int n = 0;
  final CheckRequest request = CheckRequest();
  _Page({bool? gives, Attempt? with_}) {
    if (gives != null) {
      request.verify = () {
        ok = gives;
        attempt = with_;
        n++;
      };
    }
  }
  LatestVerdict latest() => (ok: ok, attempt: attempt, n: n);
}

/// A bridge that answers [answer], in two pieces; [asked] gets what was sent.
http.Client _bridge(List<Map<String, dynamic>> asked, {String answer = '## Pe scurt\nAi pus finală starea **q1**.\n## Cum repari\nFă finală q0.'}) {
  var polls = 0;
  return MockClient((r) async {
    if (r.url.path == '/health') return _json(({'ok': true, 'version': 2}), 200);
    if (r.url.path == '/explain' && r.method == 'POST') {
      asked.add(jsonDecode(r.body) as Map<String, dynamic>);
      polls = 0;
      return _json(({'job': 'j${asked.length}'}), 200);
    }
    if (r.url.path.startsWith('/explain/')) {
      polls++;
      final from = int.parse(r.url.queryParameters['from'] ?? '0');
      final upTo = polls == 1 ? 20 : answer.length;
      return _json(({'text': answer.substring(from, upTo), 'next': upTo, 'done': polls > 1, 'error': null, 'session': '11111111-2222-3333-4444-555555555555'}), 200);
    }
    return http.Response('{}', 404);
  });
}

Future<void> _wait(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

/// The card over a page and the window layer, as the problem page puts them.
Future<ExplainController> _pump(WidgetTester t, AcsInk ink, _Page page, {VoidCallback? onNext}) async {
  final c = ExplainController(problem: _problem, course: 'LFA', request: page.request, latest: page.latest, onNext: onNext);
  addTearDown(c.dispose);
  ThemeManager.acsStyleNotifier.value = ink.terminal ? AcsStyle.terminal : AcsStyle.notebook;
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Stack(children: [
        Positioned(left: 16, right: 16, top: 16, child: ExplainLauncher(c, ink)),
        Positioned.fill(child: ExplainLayer(c)),
      ]),
    ),
  ));
  return c;
}

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
    testWidgets('a wrong answer: the panel checks it, then Claude explains (${style.name})', (t) async {
      SharedPreferences.setMockInitialValues({});
      final asked = <Map<String, dynamic>>[];
      ClaudeBridge.client = _bridge(asked);
      addTearDown(() => ClaudeBridge.client = http.Client());
      final ink = AcsInk.of(style, false);
      final page = _Page(gives: false, with_: _attempt);
      await _pump(t, ink, page);
      final button = find.textContaining(RegExp('de ce nu merge', caseSensitive: false));
      expect(button, findsWidgets);
      await t.tap(button.first);
      await _wait(t);
      expect(page.n, 1); // the panel asked for the check
      expect(asked, hasLength(1));
      expect(asked.first['prompt'], contains('δ(q0, a) = q1'));
      expect(find.text(ink.terminal ? '## Cum repari' : 'Cum repari'), findsOneWidget);
      expect(find.textContaining('Fă finală q0'), findsOneWidget);
      // a follow-up resumes the session
      await t.tap(find.text(ink.terminal ? '[ doar un indiciu ]' : 'doar un indiciu'));
      await _wait(t);
      expect(asked, hasLength(2));
      expect(asked.last['session'], '11111111-2222-3333-4444-555555555555');
      // closed, the talk is kept and the card brings it back
      await t.tap(find.byTooltip('Închide (discuția rămâne)'));
      await t.pump();
      expect(find.textContaining('Fă finală q0'), findsNothing);
      expect(find.textContaining('redeschizi'), findsOneWidget);
      await t.tap(find.textContaining(RegExp('de ce nu merge', caseSensitive: false)).first);
      await t.pump();
      expect(find.textContaining('Fă finală q0'), findsWidgets);
      // dragged by its bar, the window moves
      final before = t.getTopLeft(find.byTooltip('Șterge discuția'));
      await t.drag(find.byIcon(Icons.drag_indicator), const Offset(60, 40));
      await t.pump();
      final moved = t.getTopLeft(find.byTooltip('Șterge discuția')) - before;
      expect(moved.dx, greaterThan(20)); // less the drag's slop
      expect(moved.dy, greaterThan(10));
      // deleted, it waits for a new start
      await t.tap(find.byTooltip('Șterge discuția'));
      await _wait(t, 3);
      expect(find.textContaining('Fă finală q0'), findsNothing);
      expect(find.text('Discuția a fost ștearsă.'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('nothing sent: Claude says how to start, without the solution', (t) async {
    SharedPreferences.setMockInitialValues({});
    final asked = <Map<String, dynamic>>[];
    ClaudeBridge.client = _bridge(asked);
    addTearDown(() => ClaudeBridge.client = http.Client());
    final page = _Page(); // a check that gives no verdict (a grilă with nothing picked)
    await _pump(t, AcsInk.of(AcsStyle.notebook, false), page);
    await t.tap(find.textContaining('De ce nu merge').first);
    await _wait(t);
    expect(asked, hasLength(1));
    expect(asked.first['prompt'], contains('nu a trimis încă nimic'));
    expect(asked.first['prompt'], contains('NU îi da rezolvarea'));
    expect(find.textContaining('Cum începi'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a right answer: nothing is wrong, and Claude only if asked', (t) async {
    SharedPreferences.setMockInitialValues({});
    final asked = <Map<String, dynamic>>[];
    ClaudeBridge.client = _bridge(asked, answer: '## Pe scurt\nE corect: q0 ține minte paritatea.');
    addTearDown(() => ClaudeBridge.client = http.Client());
    var next = 0;
    final page = _Page(gives: true, with_: const Attempt('stări: q0, q1; finale: q0', '[✓] tot'));
    await _pump(t, AcsInk.of(AcsStyle.notebook, false), page, onNext: () => next++);
    await t.tap(find.textContaining('De ce nu merge').first);
    await _wait(t, 4);
    expect(find.text('Nu e nimic greșit'), findsOneWidget);
    expect(asked, isEmpty); // Claude is not asked for a right answer
    await t.tap(find.text('următoarea problemă'));
    expect(next, 1);
    await t.tap(find.text('explică-mi de ce e corect'));
    await _wait(t);
    expect(asked.single['prompt'], contains('Răspunsul studentului e corect'));
    expect(find.textContaining('De ce e corect'), findsOneWidget);
    expect(find.textContaining('q0 ține minte paritatea'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('with no bridge, the panel says how to start it', (t) async {
    SharedPreferences.setMockInitialValues({});
    ClaudeBridge.client = MockClient((r) async => throw const SocketException('refused'));
    addTearDown(() => ClaudeBridge.client = http.Client());
    final page = _Page(gives: false, with_: _attempt);
    await _pump(t, AcsInk.of(AcsStyle.notebook, false), page);
    await t.tap(find.textContaining('De ce nu merge').first);
    await _wait(t, 6);
    expect(find.textContaining('Nu găsesc Claude Code'), findsOneWidget);
    expect(find.textContaining('claude_bridge.mjs'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('an old bridge is asked to be restarted', (t) async {
    SharedPreferences.setMockInitialValues({});
    ClaudeBridge.client = MockClient((r) async => _json(({'ok': true, 'model': 'haiku'}), 200));
    addTearDown(() => ClaudeBridge.client = http.Client());
    final page = _Page(gives: false, with_: _attempt);
    await _pump(t, AcsInk.of(AcsStyle.notebook, true), page);
    await t.tap(find.textContaining('De ce nu merge').first);
    await _wait(t, 6);
    expect(find.textContaining('versiune veche'), findsOneWidget);
  });

  testWidgets('on a real problem page the button is there before anything is sent, and checks the workspace', (t) async {
    SharedPreferences.setMockInitialValues({});
    ClaudeBridge.client = MockClient((r) async => throw const SocketException('refused'));
    addTearDown(() => ClaudeBridge.client = http.Client());
    t.view.physicalSize = const Size(1300, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    ThemeManager.acsStyleNotifier.value = AcsStyle.notebook;
    await t.pumpWidget(const MaterialApp(home: AcsProblemScreen(course: 'lfa', id: '2')));
    for (var i = 0; i < 40 && find.textContaining('De ce nu merge').evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 50));
    }
    final button = find.textContaining('De ce nu merge').first;
    await t.ensureVisible(button);
    await t.tap(button);
    await _wait(t, 6);
    // the workspace's own check ran (its list of checks is drawn) and the bridge was looked for
    expect(find.textContaining('descrie exact limbajul'), findsOneWidget);
    expect(find.textContaining('Nu găsesc Claude Code'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
