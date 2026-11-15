// =============================================================================
// A WRITTEN ANSWER, GRADED BY ITS BAREM
//   The seminar tests ask for an argument on paper ("Arătați că…", "Cum
//   putem verifica…", a proof with the pumping lemma). The student writes it
//   here (kept on the device), then compares it with the model answer and
//   the barem: each item ticked if the answer has it, the points added up;
//   three quarters of them or more and the problem counts as solved.
//   "De ce nu merge așa?" sends the text to Claude, who grades it by the same
//   barem. spec: {model: text, barem: [{text, points}]}.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import 'ws_common.dart';

class WrittenWorkspace extends AcsWorkspace {
  const WrittenWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<WrittenWorkspace> createState() => _WrittenWorkspaceState();
}

class _WrittenWorkspaceState extends State<WrittenWorkspace> {
  final TextEditingController _text = TextEditingController();
  late final List<({String text, double points})> _barem = [
    for (final b in widget.problem.spec['barem'] as List? ?? const [])
      (text: '${(b as Map)['text']}', points: (b['points'] as num?)?.toDouble() ?? 0),
  ];
  late final Set<int> _ticked = {};
  bool _shown = false; // the model answer and the barem
  bool _tooShort = false;

  double get _total => _barem.fold(0, (a, b) => a + b.points);
  double get _score => [for (final i in _ticked) _barem[i].points].fold(0, (a, b) => a + b);
  bool get _passed => _total > 0 && _score >= _total * 0.75;

  @override
  void initState() {
    super.initState();
    CheckHook.find(context)?.verify = _report;
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        final j = json.decode(d) as Map;
        _text.text = '${j['text'] ?? ''}';
        setState(() {
          _ticked.addAll([for (final i in j['ticked'] as List? ?? const []) (i as num).toInt()]);
          _shown = j['shown'] == true;
        });
      } catch (_) {
        _text.text = d; // an old plain draft
      }
    });
    _text.addListener(_save);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    AcsProgress.saveDraft(widget.problem, json.encode({'text': _text.text, 'ticked': _ticked.toList(), 'shown': _shown}));
    if (_tooShort && _text.text.trim().length >= 15) setState(() => _tooShort = false);
  }

  String _pts(double p) => p == p.roundToDouble() ? '${p.round()}' : p.toString().replaceAll('.', ',');

  /// What was written and what was ticked, for the problem page (and Claude).
  Attempt get _attempt => Attempt(
        _text.text,
        _shown
            ? 'autoevaluare după barem: ${_pts(_score)} din ${_pts(_total)} p\n${[for (final (i, b) in _barem.indexed) '${_ticked.contains(i) ? '[✓]' : '[ ]'} ${b.text} (${_pts(b.points)}p)'].join('\n')}'
            : 'răspuns scris, încă necomparat cu baremul',
      );

  /// Asked by the problem page: what is written now. Solved only by the barem.
  void _report() => widget.onVerdict(_shown && _passed, _attempt);

  void _compare({bool anyway = false}) {
    if (!anyway && _text.text.trim().length < 15) {
      setState(() => _tooShort = true);
      return;
    }
    setState(() {
      _shown = true;
      _tooShort = false;
    });
    _save();
  }

  void _tick(int i) {
    setState(() => _ticked.contains(i) ? _ticked.remove(i) : _ticked.add(i));
    _save();
  }

  void _done() => widget.onVerdict(_passed, _attempt);

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AcsBox(
        ink,
        title: ink.terminal ? 'raspuns.txt' : 'Răspunsul tău, ca pe foaie',
        color: ink.bg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Scrie argumentarea completă: ce construiești sau ce alegi, și de ce merge. La test contează justificarea, nu doar rezultatul.',
              style: ink.mono(13, color: ink.muted)),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: widget.narrow ? 8 : 12,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: ink.mono(14.5, color: ink.strong, height: 1.5),
            cursorColor: ink.accent,
            decoration: InputDecoration(
              hintText: 'De exemplu: „Fie M = (K, Σ, δ, s, F) un AFD pentru L. Construiesc…”',
              hintStyle: ink.mono(14, color: ink.dim),
              filled: true,
              fillColor: ink.panel,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.line), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 6)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.accent, width: 1.5), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 6)),
            ),
          ),
          const SizedBox(height: 10),
          ToolRow([
            AcsButton(ink, _shown ? 'baremul e deschis' : 'compară cu baremul', _shown ? null : _compare, primary: !_shown, icon: Icons.fact_check_outlined),
            if (_tooShort) AcsButton(ink, 'arată oricum', () => _compare(anyway: true)),
          ]),
          if (_tooShort)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('N-ai scris aproape nimic. Încearcă întâi singur: baremul te ajută mai mult după ce ai o idee a ta.', style: ink.mono(13, color: ink.warn)),
            ),
        ]),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: !_shown
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  AcsBox(ink,
                      title: ink.terminal ? 'barem.txt' : 'Baremul: bifează ce ai în răspuns',
                      color: ink.bg,
                      trailing: Text('${_pts(_score)} / ${_pts(_total)} p', style: ink.mono(14, weight: FontWeight.w800, color: _passed ? ink.good : ink.accent)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final (i, b) in _barem.indexed)
                          AcsTap(
                            label: b.text,
                            onTap: () => _tick(i),
                            builder: (h) => Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: _ticked.contains(i) ? ink.good.withValues(alpha: 0.10) : (h ? ink.hover : Colors.transparent),
                                borderRadius: ink.terminal ? null : BorderRadius.circular(6),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, right: 8),
                                  child: Icon(_ticked.contains(i) ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: _ticked.contains(i) ? ink.good : ink.muted),
                                ),
                                Expanded(child: AcsText(b.text, ink, size: 14)),
                                const SizedBox(width: 8),
                                Text('${_pts(b.points)}p', style: ink.mono(13, weight: FontWeight.w700, color: ink.muted)),
                              ]),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: Text(
                                _passed ? 'Ai cel puțin trei sferturi din puncte: la test ar fi aproape tot.' : 'Ca să o socotești rezolvată îți trebuie cel puțin ${_pts(_total * 0.75)} p. Completează răspunsul și bifează din nou.',
                                style: ink.mono(13, color: _passed ? ink.good : ink.muted)),
                          ),
                          const SizedBox(width: 8),
                          AcsButton(ink, 'gata', _done, primary: true, icon: Icons.check),
                        ]),
                      ])),
                  const SizedBox(height: 14),
                  AcsBox(ink, title: ink.terminal ? 'model.txt' : 'Un răspuns model', color: ink.bg, child: AcsText('${widget.problem.spec['model'] ?? ''}', ink, size: 14.5)),
                ]),
              ),
      ),
    ]);
  }
}
