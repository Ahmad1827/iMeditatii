// =============================================================================
// APD: THREADS RUN BY HAND, AND EVERY INTERLEAVING TRIED
//   The student is the scheduler: a button per thread runs its next step, and
//   the shared variables, the locals, the locks and the semaphores are shown
//   after each one. Three kinds of task: say every value a variable can end
//   with, find the order that produces a given end (or a deadlock), or
//   synchronise the code so that every order ends right. A program that fails
//   gets the order that breaks it, ready to be replayed step by step.
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/apd.dart';
import 'ws_common.dart';

const Set<String> _apdWords = {'shared', 'lock', 'unlock', 'sem', 'barrier', 'thread', 'P', 'V', 'acquire', 'release', 'await'};

class ApdWorkspace extends AcsWorkspace {
  const ApdWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<ApdWorkspace> createState() => _ApdWorkspaceState();
}

class _ApdWorkspaceState extends State<ApdWorkspace> {
  late final ApdTask _task = ApdTask.fromSpec(widget.problem.spec);
  bool get _fix => _task.mode == 'fix';

  late final TextEditingController _code = acsCodeController(_task.program, _apdWords, comment: '#');
  final TextEditingController _values = TextEditingController();
  Program? _program;
  String? _error;
  List<RunState> _run = const []; // the states so far; the last is the current one
  List<String> _order = const []; // the threads run, in order
  List<Check> _checks = const [];
  List<String>? _breaking; // a schedule that breaks the student's program
  bool _reachedSaid = false;

  @override
  void initState() {
    super.initState();
    _parse();
    if (_fix) {
      AcsProgress.draft(widget.problem).then((d) {
        if (d != null && mounted && d.trim().isNotEmpty) _code.text = d;
      });
      _code.addListener(() {
        AcsProgress.saveDraft(widget.problem, _code.text);
        setState(() {
          _checks = const [];
          _breaking = null;
          _parse();
        });
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _values.dispose();
    super.dispose();
  }

  void _parse() {
    try {
      _program = Program.parse(_code.text);
      _error = null;
      _run = [_program!.start()];
      _order = const [];
    } on ApdError catch (e) {
      _program = null;
      _error = e.message;
    }
  }

  void _stepThread(int t) {
    final p = _program!;
    if (!p.enabled(_run.last, t)) return;
    setState(() {
      _run = [..._run, p.step(_run.last, t)];
      _order = [..._order, p.threads[t].name];
    });
    if (_task.mode == 'schedule' && !_reachedSaid && _task.reached(p, _run.last)) {
      _reachedSaid = true;
      widget.onVerdict(true);
    }
  }

  void _back() => setState(() {
        if (_run.length > 1) {
          _run = _run.sublist(0, _run.length - 1);
          _order = _order.sublist(0, _order.length - 1);
        }
      });

  void _restart() => setState(() {
        if (_program != null) _run = [_program!.start()];
        _order = const [];
      });

  /// Runs [schedule] from the start, so it can be looked at with ← and →.
  void _replay(List<String> schedule) {
    final p = _program;
    if (p == null) return;
    var s = p.start();
    final run = [s];
    final order = <String>[];
    for (final name in schedule) {
      final t = p.threads.indexWhere((x) => x.name == name);
      if (t < 0 || !p.enabled(s, t)) break;
      s = p.step(s, t);
      run.add(s);
      order.add(name);
    }
    setState(() {
      _run = run;
      _order = order;
    });
  }

  void _verify() {
    final List<(String, bool, String)> r;
    if (_task.mode == 'outcomes') {
      r = _task.checkOutcomes(_values.text);
    } else if (_fix) {
      r = _task.checkFix(_code.text);
      _breaking = null;
      if (!r.every((c) => c.$2) && _program != null) {
        final x = _program!.explore();
        _breaking = x.deadlock ??
            [for (final f in x.finals) if (!_task.expect.entries.every((e) => f.$1[e.key] == e.value)) f.$2].firstOrNull;
      }
    } else {
      final ok = _program != null && _task.reached(_program!, _run.last);
      r = [
        (
          _task.goalDeadlock ? 'toate firele rămase sunt blocate' : 'toate firele s-au terminat cu ${ApdTask.say(_task.goal)}',
          ok,
          _task.goalDeadlock ? 'încă se mai poate rula un fir, sau toate s-au terminat' : 'rulează firele până la capăt, în altă ordine',
        ),
      ];
    }
    setState(() => _checks = [for (final (l, ok, d) in r) Check(l, ok, d)]);
    widget.onVerdict(r.every((c) => c.$2));
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final p = _program;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fix) ...[
          Text(
              ink.terminal
                  ? '# adaugă lock(m)/unlock(m), P(s)/V(s) sau await(b); declară-le sus: lock m · sem s = 1 · barrier b = 2'
                  : 'Adaugă lock(m)/unlock(m), P(s)/V(s) sau await(b). Declară-le sus: lock m · sem s = 1 · barrier b = 2.',
              style: ink.mono(13.5, color: ink.muted)),
          const SizedBox(height: 8),
          AcsCodeEditor(ink, _code, minHeight: 220, keywords: _apdWords, comment: '#', onRun: _verify),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: ink.mono(13.5, color: ink.bad))),
          const SizedBox(height: 8),
          ToolRow([
            AcsButton(ink, 'verifică toate întrețeserile', _verify, primary: true, icon: Icons.check),
            AcsConfirmButton(ink, 'codul de la început', () => _code.text = _task.program),
            acsKeysHint(ink, 'Ctrl+Enter verifică'),
          ]),
          if (_checks.isNotEmpty) ...[const SizedBox(height: 12), ChecksView(ink, _checks)],
          if (_breaking != null) ...[
            const SizedBox(height: 8),
            ToolRow([AcsButton(ink, 'rulează pas cu pas ordinea care îl strică', () => _replay(_breaking!), icon: Icons.play_arrow)]),
          ],
          const SizedBox(height: 14),
        ],
        if (p != null) _scheduler(ink, p),
        if (!_fix) ...[
          const SizedBox(height: 12),
          if (_task.mode == 'outcomes') ...[
            Text(
                ink.terminal
                    ? '# toate valorile cu care se poate termina ${_task.ask}, despărțite prin virgulă'
                    : 'Scrie toate valorile cu care se poate termina ${_task.ask}, despărțite prin virgulă:',
                style: ink.mono(13.5, color: ink.muted)),
            const SizedBox(height: 8),
            ToolRow([
              AcsField(ink, _values, width: 220, hint: 'de exemplu 1, 2', onSubmitted: (_) => _verify()),
              AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check),
            ]),
          ] else
            ToolRow([AcsButton(ink, 'verifică starea la care ai ajuns', _verify, primary: true, icon: Icons.check)]),
          if (_checks.isNotEmpty) ...[const SizedBox(height: 12), ChecksView(ink, _checks)],
        ],
      ],
    );
  }

  // ---------------------------------------------------------------- the run
  Widget _scheduler(AcsInk ink, Program p) {
    final s = _run.last;
    final dead = p.deadlocked(s), done = p.done(s);
    Widget thread(int t) {
      final code = p.threads[t];
      final can = p.enabled(s, t);
      final nxt = p.next(s, t);
      return AcsBox(
        ink,
        title: ink.terminal ? 'thread ${code.name}' : 'Firul ${code.name}',
        color: ink.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, st) in code.steps.indexed)
              Text('${i == s.pc[t] ? '▶' : (i < s.pc[t] ? '✓' : ' ')} ${st.text}',
                  style: ink.mono(13.5,
                      color: i == s.pc[t] ? (can ? ink.accent : ink.bad) : (i < s.pc[t] ? ink.dim : ink.fg), weight: i == s.pc[t] ? FontWeight.w700 : null)),
            const SizedBox(height: 8),
            AcsButton(
              ink,
              nxt == null ? '${code.name}: gata' : (can ? 'rulează ${code.name}' : '${code.name}: blocat'),
              can ? () => _stepThread(t) : null,
              primary: can,
              icon: can ? Icons.play_arrow : null,
            ),
          ],
        ),
      );
    }

    String values(Map<String, int> m) => m.isEmpty ? '-' : m.entries.where((e) => e.key != '·').map((e) => '${e.key} = ${e.value}').join('   ');
    final state = <(String, String)>[
      ('partajate', values(s.shared)),
      for (var t = 0; t < p.threads.length; t++)
        if (s.locals[t].isNotEmpty)
          ('în ${p.threads[t].name}', [values(s.locals[t]), if (s.locals[t].containsKey('·')) 'valoare citită, încă nescrisă: ${s.locals[t]['·']}'].where((x) => x != '-' && x.isNotEmpty).join('   ')),
      if (p.locks.isNotEmpty) ('lock-uri', [for (final l in p.locks) '$l: ${s.owner[l] == -1 ? 'liber' : 'ținut de ${p.threads[s.owner[l]!].name}'}'].join('   ')),
      if (p.sems.isNotEmpty) ('semafoare', values(s.sems)),
      if (p.barriers.isNotEmpty) ('bariere', [for (final b in p.barriers.keys) '$b: ${s.arrived[b]} din ${p.barriers[b]} au ajuns'].join('   ')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            ink.terminal
                ? '# tu ești planificatorul: alege ce fir face următorul pas'
                : 'Tu ești planificatorul: alege ce fir face următorul pas.',
            style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final cols = widget.narrow ? 1 : p.threads.length.clamp(1, 3);
          final w = (c.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: [for (var t = 0; t < p.threads.length; t++) SizedBox(width: w, child: thread(t))]);
        }),
        const SizedBox(height: 10),
        AcsBox(
          ink,
          title: ink.terminal ? 'starea după ${_order.length} pași' : 'Starea după ${_order.length} pași',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, v) in state)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${label.padRight(11)} ', style: TextStyle(color: ink.muted)),
                    TextSpan(text: v, style: TextStyle(color: ink.strong, fontWeight: FontWeight.w700)),
                  ]), style: ink.mono(14)),
                ),
              const SizedBox(height: 4),
              Text('ordinea: ${_order.isEmpty ? '(niciun pas încă)' : _order.join(' ')}', style: ink.mono(13.5, color: ink.muted)),
              if (dead) Text('BLOCAJ: niciun fir nu mai poate face un pas.', style: ink.mono(14, color: ink.bad, weight: FontWeight.w700)),
              if (done) Text('Toate firele s-au terminat.', style: ink.mono(14, color: ink.good, weight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ToolRow([
          AcsButton(ink, '← un pas înapoi', _run.length > 1 ? _back : null),
          AcsButton(ink, 'de la capăt', _run.length > 1 ? _restart : null),
        ]),
      ],
    );
  }
}
