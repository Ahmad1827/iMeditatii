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
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../code_assistant.dart' show CodeAssistant;
import '../theme_manager.dart';
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

// ---------------------------------------------------------------- the talk
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

/// What is said with Claude on one problem, and where its window is. The
/// problem page owns it: the card under the statement starts it, the
/// window floating over the page shows it.
///   Started, it first checks what is on the workspace now: wrong, Claude
///   says why; nothing sent, how to start; right, that nothing is wrong
///   (and Claude says why it works, if asked).
class ExplainController extends ChangeNotifier {
  final AcsProblem problem;
  final String course;
  final CheckRequest? request;
  final LatestVerdict Function() latest;
  final VoidCallback? onNext;
  ExplainController({required this.problem, required this.latest, this.request, this.course = '', this.onNext});

  _Phase _phase = _Phase.idle;
  final List<_Turn> _turns = [];
  String? _session, _job;
  Timer? _timer;
  int _from = 0;
  bool _polling = false;
  ExplainMode mode = ExplainMode.wrong;
  Attempt _attempt = const Attempt('');
  int _usedN = -1; // the verdict the talk is about
  bool _disposed = false;

  // the window
  bool open = false;
  bool minimized = false;
  Offset? place; // its top left; null: where it first goes
  Size? size;

  bool get busy => _turns.isNotEmpty && !_turns.last.done;
  bool get started => _phase != _Phase.idle;
  bool get answerChanged => latest().n != _usedN;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (busy && _job != null) ClaudeBridge.stop(_job!);
    super.dispose();
  }

  void show() {
    open = true;
    minimized = false;
    _changed();
  }

  void close() {
    open = false;
    _changed();
  }

  void moveTo(Offset at, Size now) {
    place = at;
    size ??= now;
    _changed();
  }

  void resize(Size s) {
    size = s;
    _changed();
  }

  void toggleMinimized() {
    minimized = !minimized;
    _changed();
  }

  /// Everything said is forgotten: the window waits for a new start.
  void clear() {
    _timer?.cancel();
    if (busy && _job != null) ClaudeBridge.stop(_job!);
    _turns.clear();
    _session = null;
    _job = null;
    _phase = _Phase.idle;
    _changed();
  }

  /// Checks what is on the workspace now, then decides what to say.
  Future<void> start() async {
    _timer?.cancel();
    if (busy && _job != null) ClaudeBridge.stop(_job!);
    _turns.clear();
    _session = null;
    _phase = _Phase.checking;
    show();
    final before = latest().n;
    try {
      await Future.sync(() => request?.verify?.call()).timeout(const Duration(minutes: 2));
    } catch (_) {
      // a check that failed to run: what was heard before is used
    }
    if (_disposed) return;
    final l = latest();
    _usedN = l.n;
    final heard = l.n != before && l.attempt != null;
    final a = heard ? l.attempt! : (l.attempt ?? const Attempt(''));
    if (heard && l.ok == true) {
      _attempt = a;
      _phase = _Phase.correct;
      _changed();
      return;
    }
    final nothing = !heard && l.attempt == null || a.answer.trim().isEmpty;
    ask(nothing ? ExplainMode.empty : ExplainMode.wrong, a);
  }

  Future<void> ask(ExplainMode m, Attempt a) async {
    mode = m;
    _attempt = a;
    _phase = _Phase.looking;
    _changed();
    final s = await ClaudeBridge.probe();
    if (_disposed) return;
    if (s != BridgeState.found) {
      _phase = s == BridgeState.old ? _Phase.old : _Phase.missing;
      _changed();
      return;
    }
    _phase = _Phase.talking;
    _send(null, explainPrompt(problem, a, course: course, mode: m));
  }

  Future<void> _send(String? label, String prompt) async {
    final turn = _Turn(label);
    _turns.add(turn);
    _changed();
    try {
      _job = await ClaudeBridge.start(prompt, session: _session);
      _from = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _poll(turn));
    } catch (e) {
      turn.error = 'Nu am putut vorbi cu Claude Code: e pornit podul? ($e)';
      turn.done = true;
      _changed();
    }
  }

  Future<void> _poll(_Turn turn) async {
    if (_polling || _job == null || _disposed) return;
    _polling = true;
    try {
      final j = await ClaudeBridge.poll(_job!, _from);
      if (_disposed || !_turns.contains(turn)) return;
      turn.text += '${j['text'] ?? ''}';
      _from = (j['next'] as num?)?.toInt() ?? _from;
      if (j['session'] is String) _session = j['session'] as String;
      if (j['done'] == true) {
        turn.done = true;
        if (j['error'] is String) turn.error = j['error'] as String;
        _timer?.cancel();
      }
      _changed();
    } catch (_) {
      if (_disposed || !_turns.contains(turn)) return;
      turn.error = 'Podul nu mai răspunde (l-ai închis?).';
      turn.done = true;
      _timer?.cancel();
      _changed();
    } finally {
      _polling = false;
    }
  }

  void stop() {
    final j = _job;
    if (j != null) ClaudeBridge.stop(j);
  }

  void followUp(String label, String prompt) {
    if (busy || _session == null) return;
    _send(label, prompt);
  }
}

BoxDecoration _card(AcsInk ink, {Color? edge}) => BoxDecoration(
      color: ink.panel,
      border: Border.all(color: edge ?? ink.line, width: edge == null ? 1 : 1.4),
      borderRadius: ink.terminal ? null : BorderRadius.circular(10),
    );

// ---------------------------------------------------------------- the card
/// Under the statement (under the workspace on a phone): starts the talk,
/// or brings its window back.
class ExplainLauncher extends StatelessWidget {
  final ExplainController c;
  final AcsInk ink;
  const ExplainLauncher(this.c, this.ink, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final kept = c.started && !c.open;
          return AcsTap(
            label: 'De ce nu merge așa?',
            onTap: kept ? c.show : (c.open && c.started ? c.show : c.start),
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
                    Text(
                        kept
                            ? 'Ai o discuție cu Claude despre problema asta: apasă ca s-o redeschizi.'
                            : c.open
                                ? 'Discuția e deschisă în fereastra de deasupra paginii: o muți trăgând de bara ei.'
                                : 'Verifică ce ai scris până acum și, dacă e greșit, Claude îți arată pe exemple unde și de ce. N-ai scris nimic? Îți spune cum să începi. Merge cu Claude Code de pe calculatorul tău.',
                        style: ink.mono(13, color: ink.muted)),
                  ]),
                ),
                const SizedBox(width: 8),
                Icon(kept || c.open ? Icons.open_in_new_rounded : Icons.arrow_forward, size: 18, color: h ? ink.strong : ink.accent),
              ]),
            ),
          );
        },
      );
}

// ---------------------------------------------------------------- the window
/// The talk in a window over the page, moved by its bar and sized from its
/// corner, so the answer on the page stays in sight. Put it in a Stack over
/// the whole page: where there is no window, the page is touched.
class ExplainLayer extends StatelessWidget {
  final ExplainController c;
  const ExplainLayer(this.c, {super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([c, ThemeManager.themeNotifier, ThemeManager.acsStyleNotifier]),
        builder: (context, _) {
          if (!c.open) return const SizedBox.shrink();
          final ink = AcsInk.current;
          return LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            final phone = w < 600;
            final size = c.size ?? (phone ? Size(w - 16, h * 0.72) : Size(math.min(620, w * 0.46), math.max(380, h - 110)));
            final sw = size.width.clamp(300.0, w).toDouble(), sh = size.height.clamp(220.0, h).toDouble();
            final at = c.place ?? (phone ? Offset(8, h - sh - 8) : const Offset(24, 64));
            final left = at.dx.clamp(80 - sw, w - 80).toDouble(), top = at.dy.clamp(0.0, math.max(0.0, h - 52)).toDouble();
            return Stack(children: [
              Positioned(
                left: left,
                top: top,
                width: sw,
                height: c.minimized ? null : sh,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(opacity: t, child: Transform.scale(scale: 0.96 + 0.04 * t, alignment: Alignment.topLeft, child: child)),
                  child: Material(
                    color: ink.bg,
                    elevation: 8,
                    shadowColor: Colors.black54,
                    shape: ink.terminal
                        ? RoundedRectangleBorder(side: BorderSide(color: ink.accent, width: 1.2))
                        : RoundedRectangleBorder(side: BorderSide(color: ink.accent, width: 1.2), borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: DefaultTextStyle(
                      style: ink.mono(14),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _bar(ink, left, top, sw, sh),
                        if (!c.minimized)
                          Expanded(
                            child: Stack(children: [
                              Positioned.fill(child: _WindowBody(c, ink)),
                              Positioned(right: 0, bottom: 0, child: _grip(ink, sw, sh, w, h)),
                            ]),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ]);
          });
        },
      );

  Widget _bar(AcsInk ink, double left, double top, double sw, double sh) {
    Widget icon(IconData i, String tip, VoidCallback? on) => IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          iconSize: 19,
          color: ink.strong,
          disabledColor: ink.dim,
          onPressed: on,
          icon: Icon(i),
        );
    final title = switch (c.mode) {
      ExplainMode.wrong => 'De ce nu merge așa',
      ExplainMode.empty => 'Cum începi',
      ExplainMode.correct => 'De ce e corect',
    };
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          c.moveTo(Offset(left, top) + d.delta, Size(sw, sh));
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          decoration: BoxDecoration(color: ink.accent.withValues(alpha: 0.12), border: Border(bottom: BorderSide(color: ink.line))),
          child: Row(children: [
            Icon(Icons.drag_indicator, size: 18, color: ink.muted),
            const SizedBox(width: 4),
            Icon(Icons.psychology_alt_outlined, size: 19, color: ink.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ink.terminal ? 'claude: ${title.toLowerCase()}' : title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ink.mono(14.5, weight: FontWeight.w800, color: ink.strong)),
            ),
            if (c.busy) ...[_Dots(ink), const SizedBox(width: 6)],
            icon(Icons.delete_outline_rounded, 'Șterge discuția', c.started ? c.clear : null),
            icon(c.minimized ? Icons.expand_more_rounded : Icons.minimize_rounded, c.minimized ? 'Mărește' : 'Micșorează', c.toggleMinimized),
            icon(Icons.close_rounded, 'Închide (discuția rămâne)', c.close),
          ]),
        ),
      ),
    );
  }

  Widget _grip(AcsInk ink, double sw, double sh, double w, double h) => MouseRegion(
        cursor: SystemMouseCursors.resizeDownRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) {
            c.resize(Size((sw + d.delta.dx).clamp(300.0, w), (sh + d.delta.dy).clamp(220.0, h)));
          },
          child: Padding(padding: const EdgeInsets.all(3), child: Icon(Icons.south_east_rounded, size: 16, color: ink.muted)),
        ),
      );
}

class _WindowBody extends StatefulWidget {
  final ExplainController c;
  final AcsInk ink;
  const _WindowBody(this.c, this.ink);

  @override
  State<_WindowBody> createState() => _WindowBodyState();
}

class _WindowBodyState extends State<_WindowBody> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _field = TextEditingController();
  int _turns = 0;

  ExplainController get c => widget.c;

  @override
  void dispose() {
    _scroll.dispose();
    _field.dispose();
    super.dispose();
  }

  void _askTyped() {
    final q = _field.text.trim();
    if (q.isEmpty) return;
    _field.clear();
    c.followUp(q, q);
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    // a new question: shown from its start
    if (c._turns.length != _turns) {
      final grew = c._turns.length > _turns;
      _turns = c._turns.length;
      if (grew && _turns > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
        });
      }
    }
    final last = c._turns.isEmpty ? null : c._turns.last;
    final canAsk = c._phase == _Phase.talking && last != null && last.done && c._session != null && !(last.error != null && last.text.isEmpty);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(c._phase), child: _content(ink, last)),
          ),
        ),
      ),
      if (canAsk) _askBar(ink),
    ]);
  }

  Widget _content(AcsInk ink, _Turn? last) => switch (c._phase) {
        _Phase.idle => _fresh(ink),
        _Phase.checking => _note(ink, 'Verific ce ai scris...'),
        _Phase.correct => _correct(ink),
        _Phase.looking => _note(ink, 'Caut Claude Code pe calculatorul tău...'),
        _Phase.missing || _Phase.old => _setup(ink, c._phase == _Phase.old),
        _Phase.talking => _talk(ink, last),
      };

  Widget _fresh(AcsInk ink) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Discuția a fost ștearsă.', style: ink.mono(15, weight: FontWeight.w800, color: ink.strong)),
        const SizedBox(height: 4),
        Text('Claude verifică din nou ce e acum în spațiul de lucru și o ia de la capăt.', style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 12),
        AcsButton(ink, 'analizează ce am scris acum', c.start, primary: true, icon: Icons.psychology_alt_outlined),
      ]);

  Widget _note(AcsInk ink, String text) => Row(children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ink.accent)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: ink.mono(14, color: ink.muted))),
      ]);

  Widget _correct(AcsInk ink) => Container(
        padding: const EdgeInsets.all(14),
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
            AcsButton(ink, 'explică-mi de ce e corect', () => c.ask(ExplainMode.correct, c._attempt), primary: true, icon: Icons.psychology_alt_outlined),
            if (c.onNext != null) AcsButton(ink, 'următoarea problemă', c.onNext, icon: Icons.arrow_forward),
            AcsButton(ink, 'verifică din nou', c.start, icon: Icons.refresh),
          ]),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(old ? 'Podul pentru Claude Code e o versiune veche' : 'Nu găsesc Claude Code pe calculatorul tău', style: ink.mono(15.5, weight: FontWeight.w800, color: ink.strong)),
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
      step(old ? '2' : '3', 'Apasă din nou', Align(alignment: Alignment.centerLeft, child: AcsButton(ink, 'încearcă din nou', c.start, primary: true, icon: Icons.refresh))),
    ]);
  }

  Widget _command(AcsInk ink) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(color: ink.panel, border: Border.all(color: ink.line), borderRadius: ink.terminal ? null : BorderRadius.circular(6)),
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

  Widget _talk(AcsInk ink, _Turn? last) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final t in c._turns) ...[
          if (t.question != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: ink.accent.withValues(alpha: 0.13), borderRadius: ink.terminal ? null : BorderRadius.circular(10)),
                child: Text(t.question!, style: ink.mono(13.5, color: ink.strong)),
              ),
            ),
          ],
          const SizedBox(height: 4),
          if (t.text.isEmpty && !t.done) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Claude citește problema și răspunsul tău...', style: ink.mono(13.5, color: ink.muted))),
          if (t.text.isNotEmpty) ExplainText(t.text, ink, writing: !t.done),
          if (t.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.error!, style: ink.mono(13.5, color: ink.bad))),
        ],
        if (c.busy) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: AcsButton(ink, 'oprește', c.stop, icon: Icons.stop_rounded)),
        ],
        if (last != null && last.done && c.answerChanged) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: ink.warn.withValues(alpha: 0.10), borderRadius: ink.terminal ? null : BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Text('Ai trimis alt răspuns de atunci.', style: ink.mono(13.5, color: ink.strong))),
              AcsButton(ink, 'analizează-l', c.start, primary: true, icon: Icons.refresh),
            ]),
          ),
        ],
        if (last != null && last.done && last.error != null && last.text.isEmpty) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: AcsButton(ink, 'încearcă din nou', c.start, icon: Icons.refresh)),
        ],
      ]);

  Widget _askBar(AcsInk ink) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(color: ink.panel, border: Border(top: BorderSide(color: ink.line))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final (label, q) in _followUps) Padding(padding: const EdgeInsets.only(right: 8), child: AcsButton(ink, label, () => c.followUp(label, q))),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _field,
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
        ]),
      );
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
      .replaceAllMapped(RegExp(r'\*\*([^*\n]+)\*\*'), (m) => '**${m[1]!.replaceAll('`', '')}**')
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
