// =============================================================================
// "DE CE NU MERGE AȘA?": Claude Code, on the student's own computer, explains
// why the answer just sent is wrong
//   The page cannot start a program, so it talks to web/claude_bridge.mjs (the
//   same bridge the IDE's completion uses) on 127.0.0.1:7823: POST /explain
//   starts an answer, GET /explain/<job>?from=n gives what is new, and a
//   question after it resumes the same Claude session.
//   127.0.0.1 is only contacted once the student presses the button (Chrome
//   asks every page that tries); after it was found once, it is looked for
//   by itself.
//   The prompt holds the problem, the answer, what the checks found and,
//   privately, the reference solution; the answer comes back in the markup
//   [AcsText] draws, with ## headings.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../code_assistant.dart' show CodeAssistant;
import 'acs_data.dart';
import 'acs_kit.dart';
import 'ws/ws_common.dart' show Attempt, CheckRequest;

enum BridgeState { found, old, missing }

/// The bridge on this computer, if any.
class ClaudeBridge {
  static const String base = 'http://127.0.0.1:7823';
  static const String _kFound = 'ide_claude'; // shared with the IDE: found once, looked for by itself
  static http.Client client = http.Client();

  static Future<bool> remembered() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_kFound) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<BridgeState> probe() async {
    try {
      final r = await client.get(Uri.parse('$base/health')).timeout(const Duration(seconds: 3));
      if (r.statusCode != 200) return BridgeState.missing;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      SharedPreferences.getInstance().then((p) => p.setBool(_kFound, true)).catchError((_) => false);
      return ((j['version'] as num?) ?? 1) >= 2 ? BridgeState.found : BridgeState.old;
    } catch (_) {
      return BridgeState.missing;
    }
  }

  static Future<String> start(String prompt, {String? session}) async {
    final r = await client
        .post(Uri.parse('$base/explain'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'prompt': prompt, 'session': session}))
        .timeout(const Duration(seconds: 10));
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final id = j['job'];
    if (id is! String) throw Exception('${j['error'] ?? 'podul nu a pornit întrebarea'}');
    return id;
  }

  static Future<Map<String, dynamic>> poll(String job, int from) async {
    final r = await client.get(Uri.parse('$base/explain/$job?from=$from')).timeout(const Duration(seconds: 10));
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<void> stop(String job) async {
    try {
      await client.post(Uri.parse('$base/explain/$job/stop'), headers: {'Content-Type': 'application/json'}, body: '{}').timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}

// ---------------------------------------------------------------- the prompt
String _fence(String s) {
  final t = s.trim().isEmpty ? '(gol)' : s.trimRight();
  return '```\n${t.replaceAll('```', "'''")}\n```';
}

/// The spec without what is only drawn; long ones are cut.
String _specText(Map<String, dynamic> spec) {
  var s = const JsonEncoder.withIndent(' ').convert(spec);
  if (s.length > 6000) s = '${s.substring(0, 6000)}\n... (tăiat)';
  return s;
}

/// Why Claude is asked: the answer is refused, nothing was sent yet, or it is right.
enum ExplainMode { wrong, empty, correct }

String explainPrompt(AcsProblem p, Attempt a, {String course = '', ExplainMode mode = ExplainMode.wrong}) {
  final grila = p.kind == 'grila';
  final task = switch (mode) {
    ExplainMode.wrong => grila ? _grilaTask : _exerciseTask,
    ExplainMode.empty => _emptyTask,
    ExplainMode.correct => _correctTask,
  };
  final report = switch (mode) {
    ExplainMode.empty => 'studentul nu a trimis încă nimic${a.answer.trim().isEmpty ? '' : ' (mai sus e ce e acum în spațiul de lucru, poate doar începutul dat)'}',
    ExplainMode.correct => 'răspunsul trece toate verificările: e corect\n${a.report}'.trim(),
    ExplainMode.wrong => a.report.isEmpty ? 'răspunsul nu e acceptat' : a.report,
  };
  return '''
Materia: ${course.isEmpty ? p.course.toUpperCase() : course}. Capitolul: ${p.chapter}. Tipul problemei: ${p.kindLabel}${p.source.isEmpty ? '' : '. Sursa: ${p.source}'}.

# Problema: ${p.title}
${p.statement}

# Răspunsul studentului
${_fence(a.answer)}

# Ce a găsit verificatorul site-ului
${_fence(report)}

# Doar pentru tine (studentul nu le vede încă)
Indiciul problemei: ${p.hint.isEmpty ? '(nu are)' : p.hint}

Rezolvarea de referință:
${p.solution.isEmpty ? '(nu are)' : p.solution}

Datele verificatorului:
${_fence(_specText(p.spec))}

# Ce vreau de la tine
$task''';
}

const String _exerciseTask = '''Explică exhaustiv de ce răspunsul studentului nu e corect. Lucrează pe răspunsul LUI, nu pe unul ideal: citează exact bucata greșită. Structura, cu aceste titluri:
## Pe scurt
Una-două propoziții: greșeala principală.
## Unde greșește
Fiecare greșeală separat (dacă sunt mai multe), cu locul exact din răspuns.
## Contraexemplu, pas cu pas
Ia un caz concret pe care răspunsul dă greș (de preferat cel găsit de verificator) și urmărește-l pas cu pas într-un bloc ``` (configurații, stări, derivări, valori de variabile, ce e cazul): ce face răspunsul studentului și ce ar trebui să facă.
## De ce se întâmplă
Ideea greșită din spate și teoria care o lămurește (definiția sau teorema din curs), cu un exemplu mic.
## Cum repari
Direcția concretă și ce trebuie schimbat. Dacă răspunsul e aproape bun, arată exact modificarea. Nu copia rezolvarea de referință întreagă: dă pașii care duc la ea.
## Verifică-te
2-4 intrări pe care studentul le poate încerca după ce repară, cu rezultatul corect pentru fiecare.

Fii complet, dar nu umple: fiecare frază trebuie să ajute. Folosește notația cursului. Nu afirma ceva despre răspuns pe care nu l-ai verificat chiar tu, pe el.''';

const String _emptyTask = '''Studentul nu a trimis încă nimic și te întreabă cum să înceapă. NU îi da rezolvarea: învață-l s-o găsească singur. Structura, cu aceste titluri:
## Ce cere problema
Cerința spusă simplu, cu 2-3 exemple concrete de intrări și ce trebuie să iasă pentru ele.
## Ce trebuie să știi
Teoria din curs de care e nevoie (definiții, construcții), pe scurt, cu un exemplu mic diferit de problemă.
## Cum o abordezi
Pașii de gândire, în ordine, ca întrebări pe care și le pune singur; primul pas făcut împreună, restul lăsați lui.
## Greșeli frecvente
Ce greșesc de obicei studenții la tipul ăsta de problemă.
## Verifică-te
2-4 intrări pe care să-și testeze răspunsul, cu rezultatul corect pentru fiecare.''';

const String _correctTask = '''Răspunsul studentului e corect: trece toate verificările. Spune-i asta clar de la început, apoi ajută-l să înțeleagă de ce. Structura, cu aceste titluri:
## Pe scurt
Confirmă că e corect și spune într-o frază ideea care îl face să funcționeze.
## De ce merge
Explică pe răspunsul LUI, cu un exemplu urmărit pas cu pas într-un bloc ```.
## Ce ar fi stricat-o
2-3 variante greșite apropiate (capcanele tipice) și de ce n-ar fi mers.
## Altă cale
Dacă rezolvarea de referință sau altă metodă e diferită, arat-o pe scurt și compar-o cu a lui (mai simplă? mai generală?). Dacă nu e cazul, sari peste.
## Mai departe
Ce să exerseze în continuare ca să fixeze ideea.''';

const String _grilaTask = '''E o grilă. Explică exhaustiv de ce varianta (variantele) aleasă de student e greșită. Structura, cu aceste titluri:
## Pe scurt
Una-două propoziții: de ce nu merge varianta aleasă.
## De ce nu e așa
Pentru fiecare variantă aleasă greșit: ce afirmă exact, de ce e falsă (sau incompletă), cu un contraexemplu concret dacă se poate.
## Teoria din spate
Definiția, teorema sau proprietatea din curs care decide întrebarea, cu un exemplu mic.
## Cum gândești întrebarea
Metoda prin care se ajunge la răspuns, aplicată pe întrebare, fără să spui direct litera corectă: studentul trebuie să o poată alege singur.
## Capcana
Ce confuzie face de obicei pe cineva să aleagă varianta asta.''';

/// What a follow-up chip asks.
const List<(String, String)> _followUps = [
  ('alt exemplu', 'Dă-mi încă un contraexemplu, diferit, și urmărește-l pas cu pas.'),
  ('doar un indiciu', 'Dă-mi un singur indiciu scurt, cel mai util, fără să-mi spui rezolvarea.'),
  ('explică teoria mai simplu', 'Explică-mi teoria din spate mai simplu, ca pentru cineva care o vede prima dată, cu un exemplu desenat în text.'),
  ('arată rezolvarea', 'Acum arată-mi rezolvarea completă, explicată pas cu pas, și compar-o cu ce am scris eu.'),
];

// ---------------------------------------------------------------- the panel
class _Turn {
  final String? question; // null: the first explanation
  String text = '';
  String? error;
  bool done = false;
  _Turn(this.question);
}

enum _Phase { idle, checking, correct, looking, missing, old, talking }

/// The last verdict the problem page heard: solved or not, the answer, and
/// how many verdicts so far (so a new one is told from the old).
typedef LatestVerdict = ({bool? ok, Attempt? attempt, int n});

/// Under the workspace, always. Pressed, it first checks what is on the
/// workspace now: wrong, Claude says why; nothing sent, how to start; right,
/// that nothing is wrong (and Claude can say why it works).
class ExplainPanel extends StatefulWidget {
  final AcsProblem problem;
  final AcsInk ink;
  final String course;
  final CheckRequest? request;
  final LatestVerdict Function() latest;
  final VoidCallback? onNext;
  const ExplainPanel({super.key, required this.problem, required this.ink, required this.latest, this.request, this.course = '', this.onNext});

  @override
  State<ExplainPanel> createState() => _ExplainPanelState();
}

class _ExplainPanelState extends State<ExplainPanel> {
  _Phase _phase = _Phase.idle;
  final List<_Turn> _turns = [];
  String? _session, _job;
  Timer? _timer;
  int _from = 0;
  final TextEditingController _askField = TextEditingController();
  ExplainMode _mode = ExplainMode.wrong;
  Attempt _attempt = const Attempt('');
  int _usedN = -1; // the verdict the conversation is about

  bool get _busy => _turns.isNotEmpty && !_turns.last.done;

  @override
  void dispose() {
    _timer?.cancel();
    if (_busy && _job != null) ClaudeBridge.stop(_job!);
    _askField.dispose();
    super.dispose();
  }

  /// Checks what is on the workspace now, then decides what to say.
  Future<void> _start() async {
    setState(() {
      _phase = _Phase.checking;
      _turns.clear();
      _session = null;
    });
    final before = widget.latest().n;
    try {
      await Future.sync(() => widget.request?.verify?.call()).timeout(const Duration(minutes: 2));
    } catch (_) {
      // a check that failed to run: what was heard before is used
    }
    if (!mounted) return;
    final l = widget.latest();
    _usedN = l.n;
    final heard = l.n != before && l.attempt != null;
    final a = heard ? l.attempt! : (l.attempt ?? const Attempt(''));
    if (heard && l.ok == true) {
      setState(() {
        _attempt = a;
        _phase = _Phase.correct;
      });
      return;
    }
    final nothing = !heard && l.attempt == null || a.answer.trim().isEmpty;
    _ask(nothing ? ExplainMode.empty : ExplainMode.wrong, a);
  }

  Future<void> _ask(ExplainMode mode, Attempt a) async {
    setState(() {
      _mode = mode;
      _attempt = a;
      _phase = _Phase.looking;
    });
    final s = await ClaudeBridge.probe();
    if (!mounted) return;
    if (s != BridgeState.found) {
      setState(() => _phase = s == BridgeState.old ? _Phase.old : _Phase.missing);
      return;
    }
    setState(() => _phase = _Phase.talking);
    _send(null, explainPrompt(widget.problem, a, course: widget.course, mode: mode));
  }

  Future<void> _send(String? label, String prompt) async {
    final turn = _Turn(label);
    setState(() => _turns.add(turn));
    try {
      _job = await ClaudeBridge.start(prompt, session: _session);
      _from = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _poll(turn));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        turn.error = 'Nu am putut vorbi cu Claude Code: e pornit podul? ($e)';
        turn.done = true;
      });
    }
  }

  bool _polling = false;
  Future<void> _poll(_Turn turn) async {
    if (_polling || _job == null) return;
    _polling = true;
    try {
      final j = await ClaudeBridge.poll(_job!, _from);
      if (!mounted) return;
      setState(() {
        turn.text += '${j['text'] ?? ''}';
        _from = (j['next'] as num?)?.toInt() ?? _from;
        if (j['session'] is String) _session = j['session'] as String;
        if (j['done'] == true) {
          turn.done = true;
          if (j['error'] is String) turn.error = j['error'] as String;
          _timer?.cancel();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        turn.error = 'Podul nu mai răspunde (l-ai închis?).';
        turn.done = true;
      });
      _timer?.cancel();
    } finally {
      _polling = false;
    }
  }

  void _stop() {
    final j = _job;
    if (j != null) ClaudeBridge.stop(j);
  }

  void _followUp(String label, String prompt) {
    if (_busy || _session == null) return;
    _send(label, prompt);
  }

  void _askTyped() {
    final q = _askField.text.trim();
    if (q.isEmpty) return;
    _askField.clear();
    _followUp(q, q);
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final Widget body = switch (_phase) {
      _Phase.idle => _idle(ink),
      _Phase.checking => _note(ink, 'Verific ce ai scris...', spinner: true),
      _Phase.correct => _correct(ink),
      _Phase.looking => _note(ink, 'Caut Claude Code pe calculatorul tău...', spinner: true),
      _Phase.missing || _Phase.old => _setup(ink, _phase == _Phase.old),
      _Phase.talking => _talk(ink),
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: c)),
        child: KeyedSubtree(key: ValueKey(_phase), child: body),
      ),
    );
  }

  BoxDecoration _card(AcsInk ink, {Color? edge}) => BoxDecoration(
        color: ink.panel,
        border: Border.all(color: edge ?? ink.line, width: edge == null ? 1 : 1.4),
        borderRadius: ink.terminal ? null : BorderRadius.circular(10),
      );

  Widget _idle(AcsInk ink) => AcsTap(
        label: 'De ce nu merge așa?',
        onTap: _start,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: _card(ink, edge: h ? ink.strong : ink.accent).copyWith(color: h ? ink.hover : ink.panel),
          child: Row(children: [
            _Pulse(ink: ink, child: Icon(Icons.psychology_alt_outlined, size: 26, color: ink.accent)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ink.terminal ? '\$ de ce nu merge așa?' : 'De ce nu merge așa?', style: ink.mono(16, weight: FontWeight.w800, color: ink.strong)),
                const SizedBox(height: 2),
                Text('Verifică ce ai scris până acum și, dacă e greșit, Claude îți arată pe exemple unde și de ce. N-ai scris nimic? Îți spune cum să începi. Merge cu Claude Code de pe calculatorul tău.',
                    style: ink.mono(13, color: ink.muted)),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: h ? ink.strong : ink.accent),
          ]),
        ),
      );

  Widget _correct(AcsInk ink) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(ink, edge: ink.good).copyWith(color: ink.good.withValues(alpha: ink.dark ? 0.10 : 0.07)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.verified_rounded, size: 24, color: ink.good),
            const SizedBox(width: 10),
            Expanded(child: Text(ink.terminal ? '[✓] nu e nimic greșit' : 'Nu e nimic greșit', style: ink.mono(16.5, weight: FontWeight.w800, color: ink.good))),
          ]),
          const SizedBox(height: 6),
          Text('Răspunsul tău trece toate verificările: problema e rezolvată. Vrei să știi de ce merge și ce l-ar fi stricat?', style: ink.mono(13.5, color: ink.fg)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            AcsButton(ink, 'explică-mi de ce e corect', () => _ask(ExplainMode.correct, _attempt), primary: true, icon: Icons.psychology_alt_outlined),
            if (widget.onNext != null) AcsButton(ink, 'următoarea problemă', widget.onNext, icon: Icons.arrow_forward),
            AcsButton(ink, 'verifică din nou', _start, icon: Icons.refresh),
          ]),
        ]),
      );

  Widget _note(AcsInk ink, String text, {bool spinner = false}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(ink),
        child: Row(children: [
          if (spinner) ...[SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ink.accent)), const SizedBox(width: 10)],
          Expanded(child: Text(text, style: ink.mono(14, color: ink.muted))),
        ]),
      );

  Widget _setup(AcsInk ink, bool old) {
    Widget step(String n, String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: ink.accent, shape: ink.terminal ? BoxShape.rectangle : BoxShape.circle),
              child: Text(n, style: ink.mono(12.5, weight: FontWeight.w800, color: ink.bg)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: ink.mono(14, weight: FontWeight.w700, color: ink.strong)), const SizedBox(height: 4), child])),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(ink, edge: ink.warn),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(old ? 'Podul pentru Claude Code e o versiune veche' : 'Nu găsesc Claude Code pe calculatorul tău',
            style: ink.mono(15.5, weight: FontWeight.w800, color: ink.strong)),
        const SizedBox(height: 4),
        Text(
            old
                ? 'Îl ai pornit, dar nu știe încă să explice. Oprește-l (Ctrl+C) și pornește-l din nou cu comanda de mai jos: descarcă versiunea nouă.'
                : 'Explicația o scrie Claude Code, folosind contul tău. Pagina nu poate porni programe, așa că un mic „pod” face legătura. Problema, răspunsul tău și rezolvarea ajung la Claude.',
            style: ink.mono(13.5, color: ink.muted)),
        if (!old)
          step('1', 'Ai Claude Code instalat și te-ai autentificat',
              Text('Dacă nu: instalează-l de pe claude.com/claude-code, apoi rulează o dată `claude` într-un terminal.', style: ink.mono(13, color: ink.muted))),
        step(old ? '1' : '2', 'Pornește podul și lasă terminalul deschis (îți trebuie Node 18+)', _command(ink)),
        step(old ? '2' : '3', 'Apasă din nou', Align(alignment: Alignment.centerLeft, child: AcsButton(ink, 'încearcă din nou', _start, primary: true, icon: Icons.refresh))),
      ]),
    );
  }

  Widget _command(AcsInk ink) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(color: ink.bg, border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(6)),
        child: Row(children: [
          Expanded(child: SelectableText(CodeAssistant.setupCommand, style: ink.mono(12.5, color: ink.strong))),
          IconButton(
            tooltip: 'Copiază comanda',
            icon: Icon(Icons.copy_all_outlined, size: 18, color: ink.accent),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: CodeAssistant.setupCommand));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Comanda a fost copiată.'), duration: Duration(seconds: 2)));
            },
          ),
        ]),
      );

  Widget _talk(AcsInk ink) {
    final last = _turns.isEmpty ? null : _turns.last;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: _card(ink, edge: ink.accent),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.psychology_alt_outlined, size: 20, color: ink.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                switch (_mode) {
                  ExplainMode.wrong => ink.terminal ? 'claude: de ce nu merge așa' : 'De ce nu merge așa',
                  ExplainMode.empty => ink.terminal ? 'claude: cum începi' : 'Cum începi',
                  ExplainMode.correct => ink.terminal ? 'claude: de ce e corect' : 'De ce e corect',
                },
                style: ink.mono(15.5, weight: FontWeight.w800, color: ink.strong)),
          ),
          if (_busy) ...[
            _Dots(ink),
            const SizedBox(width: 8),
            AcsButton(ink, 'oprește', _stop, icon: Icons.stop_rounded),
          ],
        ]),
        for (final t in _turns) ...[
          if (t.question != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: ink.accent.withValues(alpha: 0.12), borderRadius: ink.terminal ? null : BorderRadius.circular(10)),
                child: Text(t.question!, style: ink.mono(13.5, color: ink.strong)),
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (t.text.isEmpty && !t.done) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Claude citește problema și răspunsul tău...', style: ink.mono(13.5, color: ink.muted))),
          if (t.text.isNotEmpty) ExplainText(t.text, ink, writing: !t.done),
          if (t.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.error!, style: ink.mono(13.5, color: ink.bad))),
        ],
        if (last != null && last.done && widget.latest().n != _usedN) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: ink.warn.withValues(alpha: 0.10), borderRadius: ink.terminal ? null : BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Text('Ai trimis alt răspuns de atunci.', style: ink.mono(13.5, color: ink.strong))),
              AcsButton(ink, 'analizează-l', _start, primary: true, icon: Icons.refresh),
            ]),
          ),
        ],
        if (last != null && last.done) ...[
          const SizedBox(height: 14),
          if (last.error != null && last.text.isEmpty)
            Align(alignment: Alignment.centerLeft, child: AcsButton(ink, 'încearcă din nou', _restart, icon: Icons.refresh))
          else if (_session != null) ...[
            Text('Mai departe', style: ink.mono(12.5, weight: FontWeight.w800, color: ink.muted).copyWith(letterSpacing: 1)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (label, q) in _followUps) AcsButton(ink, label, () => _followUp(label, q)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _askField,
                  onSubmitted: (_) => _askTyped(),
                  style: ink.mono(14, color: ink.strong),
                  cursorColor: ink.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Întreabă ce nu e clar...',
                    hintStyle: ink.mono(13.5, color: ink.dim),
                    filled: true,
                    fillColor: ink.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.line), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 6)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.accent, width: 1.5), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 6)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AcsButton(ink, 'trimite', _askTyped, primary: true, icon: Icons.send_rounded),
            ]),
          ],
        ],
      ]),
    );
  }

  void _restart() => _start();
}

// ---------------------------------------------------------------- the answer
/// Claude's answer: ## headings, and [AcsText] for what is under each; the
/// part being written fades in, with a caret at its end.
class ExplainText extends StatelessWidget {
  final String text;
  final AcsInk ink;
  final bool writing;
  const ExplainText(this.text, this.ink, {super.key, this.writing = false});

  /// Markdown that [AcsText] does not draw, turned into what it does.
  static String tidy(String s) => s
      .replaceAll('\r', '')
      .replaceAllMapped(RegExp(r'^(\s*)[*+]\s+', multiLine: true), (m) => '${m[1]}- ')
      .replaceAllMapped(RegExp(r'^(\s*)(\d{1,2})\.\s+', multiLine: true), (m) => '${m[1]}${m[2]}) ')
      .replaceAll(RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$', multiLine: true), '')
      .replaceAllMapped(RegExp(r'(?<![*\w])\*([^*\n]+)\*(?![*\w])'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'\\\((.+?)\\\)'), (m) => '\$${m[1]}\$')
      .replaceAllMapped(RegExp(r'\\\[([\s\S]+?)\\\]'), (m) => '\$\$${m[1]}\$\$');

  /// (heading or null, body) pieces.
  static List<(String?, String)> sections(String text) {
    final out = <(String?, String)>[];
    String? head;
    final body = StringBuffer();
    var fenced = false;
    for (final line in tidy(text).split('\n')) {
      if (line.trimLeft().startsWith('```')) fenced = !fenced;
      final h = fenced ? null : RegExp(r'^\s{0,3}#{1,6}\s+(.*)$').firstMatch(line);
      if (h != null) {
        if (head != null || body.toString().trim().isNotEmpty) out.add((head, body.toString().trim()));
        head = h[1]!.replaceAll('**', '').trim();
        body.clear();
      } else {
        body.writeln(line);
      }
    }
    if (head != null || body.toString().trim().isNotEmpty) out.add((head, body.toString().trim()));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final parts = sections(text);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, (head, body)) in parts.indexed)
        _FadeIn(
          key: ValueKey('s$i'),
          child: Padding(
            padding: EdgeInsets.only(top: i == 0 ? 4 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (head != null)
                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
                  child: Text(ink.terminal ? '## $head' : head, style: ink.mono(15.5, weight: FontWeight.w800, color: ink.accent)),
                ),
              if (body.isNotEmpty) AcsText(body, ink, size: 14.5),
              if (writing && i == parts.length - 1) _Caret(ink),
            ]),
          ),
        ),
    ]);
  }
}

class _FadeIn extends StatelessWidget {
  final Widget child;
  const _FadeIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, t, c) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: c)),
        child: child,
      );
}

/// A blinking block at the end of what is being written.
class _Caret extends StatefulWidget {
  final AcsInk ink;
  const _Caret(this.ink);

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: FadeTransition(
          opacity: TweenSequence([TweenSequenceItem(tween: ConstantTween(1.0), weight: 1), TweenSequenceItem(tween: ConstantTween(0.0), weight: 1)]).animate(_c),
          child: Container(width: 9, height: 17, margin: const EdgeInsets.only(top: 2), color: widget.ink.accent),
        ),
      );
}

/// Three dots going up and down while Claude writes.
class _Dots extends StatefulWidget {
  final AcsInk ink;
  const _Dots(this.ink);

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, -4 * _bump((_c.value - i * 0.15) % 1), 0),
              decoration: BoxDecoration(color: widget.ink.accent, shape: BoxShape.circle),
            ),
        ]),
      );

  static double _bump(double t) => t < 0.4 ? (t < 0.2 ? t / 0.2 : (0.4 - t) / 0.2) : 0;
}

/// The icon breathing, to say the button is new.
class _Pulse extends StatefulWidget {
  final AcsInk ink;
  final Widget child;
  const _Pulse({required this.ink, required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    // a few breaths, then still (a loop would keep tests and the page busy)
    _c.repeat(reverse: true, count: 4);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: Tween(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)), child: widget.child);
}
