// =============================================================================
// ALGAED: THE MATRIX ON THE BLACKBOARD
//   The matrix, exact fractions, a bar for an augmented one; the student
//   types row operations (L2 = L2 - 3L1, L1 <-> L3, L2 = 1/2 L2) or builds
//   them from the buttons, each one written down in a list that can be
//   undone. The goal (echelon, reduced, [I | A^-1]) is shown as it's reached;
//   some tasks then ask for a number read off the result (a rank, a
//   determinant, the solution).
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/rowops.dart';
import 'ws_common.dart';

class RowOpsWorkspace extends AcsWorkspace {
  const RowOpsWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<RowOpsWorkspace> createState() => _RowOpsWorkspaceState();
}

class _RowOpsWorkspaceState extends State<RowOpsWorkspace> {
  late final RowOpsTask _t = RowOpsTask.fromSpec(widget.problem.spec);
  final TextEditingController _cmd = TextEditingController();
  final FocusNode _focus = FocusNode();
  final List<TextEditingController> _answers = [];
  String? _error;
  List<Check>? _checks;
  // the builder
  int _a = 1, _b = 0;
  final TextEditingController _k = TextEditingController(text: '1');

  List<Map> get _answerSpecs => [for (final a in widget.problem.spec['answers'] as List? ?? const []) a as Map];

  @override
  void initState() {
    super.initState();
    for (final _ in _answerSpecs) {
      _answers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _cmd.dispose();
    _focus.dispose();
    _k.dispose();
    for (final c in _answers) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply(String text) {
    setState(() {
      try {
        _t.apply(text);
        _error = null;
        _cmd.clear();
      } on RowError catch (e) {
        _error = e.message;
      }
    });
    _focus.requestFocus();
  }

  void _verify() {
    final (ok, msg) = _t.goalState();
    final out = <Check>[Check(_goalLabel(), ok, ok ? '' : msg)];
    for (final (k, a) in _answerSpecs.indexed) {
      final want = Q.parse('${a['value']}');
      final text = _answers[k].text.trim();
      if (text.isEmpty) {
        out.add(Check('${a['label']}', false, 'nu ai scris valoarea'));
        continue;
      }
      try {
        final got = Q.parse(text);
        out.add(Check('${a['label']}', got == want, got == want ? '' : 'nu e $got'));
      } on RowError catch (e) {
        out.add(Check('${a['label']}', false, e.message));
      }
    }
    setState(() => _checks = out);
    widget.onVerdict(out.every((c) => c.ok));
  }

  String _goalLabel() => switch (_t.goal) {
        'rref' => 'matricea e în forma eșalon redusă (Gauss-Jordan)',
        'echelon' => 'matricea e în formă eșalon',
        'triangular' => 'matricea e superior triunghiulară',
        _ => 'în stânga barei e matricea unitate',
      };

  Widget _matrix(AcsInk ink) {
    final piv = _t.pivots();
    final cellW = widget.narrow ? 52.0 : 64.0;
    Widget cell(int i, int j) {
      final v = _t.m[i][j];
      final isPiv = piv.contains((i, j));
      return Container(
        width: cellW,
        height: 34,
        alignment: Alignment.center,
        color: isPiv ? ink.accent.withValues(alpha: 0.16) : null,
        child: Text('$v', style: ink.mono(v.d == BigInt.one ? 15 : 13, weight: isPiv ? FontWeight.w700 : FontWeight.w400, color: v.isZero ? ink.dim : ink.strong)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [for (var i = 0; i < _t.rows; i++) SizedBox(height: 34, child: Center(child: Text('L${i + 1} ', style: ink.mono(13, color: ink.muted))))]),
        Container(width: 6, height: _t.rows * 34.0, decoration: BoxDecoration(border: Border(left: BorderSide(color: ink.strong, width: 2), top: BorderSide(color: ink.strong, width: 2), bottom: BorderSide(color: ink.strong, width: 2)))),
        Column(children: [
          for (var i = 0; i < _t.rows; i++)
            Row(children: [
              for (var j = 0; j < _t.cols; j++) ...[
                if (j == _t.split) Container(width: 1.5, height: 34, color: ink.muted),
                cell(i, j),
              ],
            ]),
        ]),
        Container(width: 6, height: _t.rows * 34.0, decoration: BoxDecoration(border: Border(right: BorderSide(color: ink.strong, width: 2), top: BorderSide(color: ink.strong, width: 2), bottom: BorderSide(color: ink.strong, width: 2)))),
      ]),
    );
  }

  Widget _drop(AcsInk ink, int value, ValueChanged<int> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: ink.bg, border: Border.all(color: ink.line)),
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          underline: const SizedBox.shrink(),
          dropdownColor: ink.panel,
          style: ink.mono(14, weight: FontWeight.w700, color: ink.strong),
          items: [for (var i = 0; i < _t.rows; i++) DropdownMenuItem(value: i, child: Text('L${i + 1}'))],
          onChanged: (v) => setState(() => onChanged(v ?? 0)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final (ok, msg) = _t.goalState();
    final k = _k.text.trim().isEmpty ? '1' : _k.text.trim();
    final kTerm = k.startsWith('-') ? '- ${k.substring(1)}' : '+ $k';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          color: ink.bg,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _matrix(ink),
            const SizedBox(height: 8),
            Text('${ok ? '✓' : '·'} $msg${_t.goal == 'triangular' ? '   ·   det(A) = ${_t.detFactor.isOne ? '' : '(${Q.one / _t.detFactor}) · '}produsul diagonalei' : ''}',
                style: ink.mono(13, color: ok ? ink.good : ink.muted)),
            const SizedBox(height: 12),
            Row(children: [
              Text(ink.terminal ? '\$ ' : '› ', style: ink.mono(15, color: ink.accent, weight: FontWeight.w700)),
              Expanded(child: AcsField(ink, _cmd, width: double.infinity, focusNode: _focus, hint: 'L2 = L2 - 3L1   ·   L1 <-> L3   ·   L2 = 1/2 L2', onSubmitted: _apply)),
              const SizedBox(width: 8),
              AcsButton(ink, 'aplică', () => _apply(_cmd.text), primary: true),
            ]),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: ink.mono(13, color: ink.bad))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _drop(ink, _a, (v) => _a = v),
              Text('←', style: ink.mono(14)),
              Text('L${_a + 1}', style: ink.mono(14, weight: FontWeight.w700)),
              AcsField(ink, _k, width: 64, align: TextAlign.center, onChanged: (_) => setState(() {})),
              _drop(ink, _b, (v) => _b = v),
              AcsButton(ink, '+ k·L${_b + 1}', _a == _b ? null : () => _apply('L${_a + 1} = L${_a + 1} $kTerm L${_b + 1}')),
              AcsButton(ink, '× k', () => _apply('L${_a + 1} = ($k) L${_a + 1}')),
              AcsButton(ink, '↔ L${_b + 1}', _a == _b ? null : () => _apply('L${_a + 1} <-> L${_b + 1}')),
            ]),
            if (_t.history.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('operații: ${[for (final (i, o) in _t.history.indexed) '${i + 1}) ${o.text}'].join('   ')}', style: ink.mono(12.5, color: ink.muted)),
            ],
            if (_answerSpecs.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final (i, a) in _answerSpecs.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Text('${a['label']} ', style: ink.mono(14.5, weight: FontWeight.w700, color: ink.strong)),
                    AcsField(ink, _answers[i], width: 120, hint: 'de ex. -12 sau 3/2', onSubmitted: (_) => _verify()),
                  ]),
                ),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check),
          AcsButton(ink, 'anulează ultima', _t.history.isEmpty ? null : () => setState(_t.undo)),
          AcsButton(ink, 'de la început', () => setState(() {
                _t.reset();
                _error = null;
                _checks = null;
              })),
        ]),
        if (_checks != null) ...[const SizedBox(height: 12), ChecksView(ink, _checks!)],
      ],
    );
  }
}
