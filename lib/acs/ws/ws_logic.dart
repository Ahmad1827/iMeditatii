// =============================================================================
// PL: LOGIC, DESIGNED AND CHECKED
//   expr — the student writes each output as a boolean expression; the
//          Karnaugh map beside it shows, as they type, which cells their
//          expression covers and which are wrong.
//   mux  — wires a multiplexer: its select lines and what goes on each input.
//   fsm  — fills a Mealy machine's table and tries it on input strings.
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/logic.dart';
import 'ws_common.dart';

class LogicWorkspace extends AcsWorkspace {
  const LogicWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<LogicWorkspace> createState() => _LogicWorkspaceState();
}

class _LogicWorkspaceState extends State<LogicWorkspace> {
  Map get spec => widget.problem.spec;
  String get mode => spec['mode'] as String;
  List<Check>? _checks;

  // expr
  late final ExprTask? _expr = mode == 'expr' ? ExprTask.fromSpec(spec) : null;
  final Map<String, TextEditingController> _fields = {};
  String? _focused;

  // mux
  late final MuxTask? _mux = mode == 'mux' ? MuxTask.fromSpec(spec) : null;
  List<String> _sel = [];
  List<String> _data = [];

  // fsm
  late final FsmTask? _fsm = mode == 'fsm' ? FsmTask.fromSpec(spec) : null;
  final List<TextEditingController> _names = [];
  final List<List<String>> _next = [];
  final List<List<int>> _out = [];
  final TextEditingController _sim = TextEditingController(text: '0110101');

  @override
  void initState() {
    super.initState();
    if (_expr != null) {
      for (final o in _expr.outputs) {
        final c = TextEditingController();
        c.addListener(() {
          setState(() {});
          _saveDraft();
        });
        _fields[o.name] = c;
      }
      _focused = _expr.outputs.first.name;
    }
    if (_mux != null) {
      _sel = [for (var k = 0; k < _mux.selects; k++) _mux.vars[k]];
      _data = List.filled(1 << _mux.selects, '0');
    }
    if (_fsm != null) {
      for (final n in ['S0', 'S1']) {
        _addState(n);
      }
    }
    _loadDraft();
  }

  void _addState([String? name]) {
    final n = name ?? 'S${_names.length}';
    _names.add(TextEditingController(text: n)..addListener(() => setState(() {})));
    _next.add([_names.first.text, _names.first.text]);
    _out.add([0, 0]);
  }

  Future<void> _loadDraft() async {
    final d = await AcsProgress.draft(widget.problem);
    if (d == null || !mounted) return;
    if (_expr != null) {
      final parts = d.split('\u0001');
      for (final (k, o) in _expr.outputs.indexed) {
        if (k < parts.length) _fields[o.name]!.text = parts[k];
      }
    }
  }

  void _saveDraft() {
    if (_expr != null) AcsProgress.saveDraft(widget.problem, [for (final o in _expr.outputs) _fields[o.name]!.text].join('\u0001'));
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final c in _names) {
      c.dispose();
    }
    _sim.dispose();
    super.dispose();
  }

  void _verify() {
    final out = <Check>[];
    if (_expr != null) {
      for (final o in _expr.outputs) {
        for (final c in _expr.check(o.name, _fields[o.name]!.text)) {
          out.add(Check(c.label, c.ok, c.detail));
        }
      }
    } else if (_mux != null) {
      for (final c in _mux.check(_sel, _data)) {
        out.add(Check(c.label, c.ok, c.detail));
      }
    } else if (_fsm != null) {
      final m = _machine();
      for (final c in m == null ? [const LogicCheck('numele stărilor sunt diferite și nevide', false)] : _fsm.check(m)) {
        out.add(Check(c.label, c.ok, c.detail));
      }
    }
    setState(() => _checks = out);
    widget.onVerdict(out.isNotEmpty && out.every((c) => c.ok));
  }

  Mealy? _machine() {
    final names = [for (final c in _names) c.text.trim()];
    if (names.any((n) => n.isEmpty) || names.toSet().length != names.length) return null;
    return Mealy(names, {
      for (var i = 0; i < names.length; i++) names[i]: [(_next[i][0], _out[i][0]), (_next[i][1], _out[i][1])],
    }, names.first);
  }

  // ---------------------------------------------------------------- expr
  Widget _symbols(AcsInk ink) {
    final symbols = ["'", '·', '+', '⊕', '↑', '↓', '(', ')'];
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final s in symbols)
        AcsTap(
          label: 'simbolul $s',
          onTap: () {
            final c = _fields[_focused];
            if (c == null) return;
            final sel = c.selection.isValid ? c.selection : TextSelection.collapsed(offset: c.text.length);
            c.value = c.value.replaced(sel, s);
          },
          builder: (h) => Container(
            width: 34,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: h ? ink.hover : ink.panel, border: Border.all(color: ink.line)),
            child: Text(s, style: ink.mono(15, weight: FontWeight.w700, color: ink.accent)),
          ),
        ),
    ]);
  }

  Widget _kmap(AcsInk ink, LogicTarget t, String text) {
    final vars = _expr!.vars;
    List<bool>? mine;
    try {
      if (text.trim().isNotEmpty) mine = Bool.table(BoolParser.parse(text, vars), vars);
    } catch (_) {
      mine = null;
    }
    const gray = [0, 1, 3, 2];
    final n = vars.length;
    if (n < 2 || n > 4) return const SizedBox.shrink();
    final rowBits = n ~/ 2, colBits = n - rowBits;
    final rows = rowBits == 1 ? [0, 1] : gray;
    final cols = colBits == 1 ? [0, 1] : gray;
    String bits(int v, int k) => v.toRadixString(2).padLeft(k, '0');
    Widget cell(int r, int c) {
      final m = (r << colBits) | c;
      final dc = t.dc.contains(m);
      final want = t.ones.contains(m);
      final got = mine?[m];
      final wrong = got != null && !dc && got != want;
      return Container(
        width: 44,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: got == true ? ink.accent.withValues(alpha: 0.25) : ink.bg,
          border: Border.all(color: wrong ? ink.bad : ink.line, width: wrong ? 2 : 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(dc ? '–' : (want ? '1' : '0'), style: ink.mono(14, weight: FontWeight.w700, color: want ? ink.strong : ink.dim, height: 1.1)),
          Text('m$m', style: ink.mono(9, color: ink.dim, height: 1)),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Karnaugh pentru ${t.name}: cifra e ținta, umplerea e expresia ta${mine == null ? '' : ', roșu = greșit'}', style: ink.mono(12, color: ink.muted)),
      const SizedBox(height: 4),
      Row(children: [
        SizedBox(width: 54, child: Text('${vars.sublist(0, rowBits).join()}\\${vars.sublist(rowBits).join()}', style: ink.mono(11, color: ink.muted))),
        for (final c in cols) SizedBox(width: 44, child: Text(bits(c, colBits), textAlign: TextAlign.center, style: ink.mono(11.5, color: ink.muted))),
      ]),
      for (final r in rows)
        Row(children: [
          SizedBox(width: 54, child: Text(bits(r, rowBits), style: ink.mono(11.5, color: ink.muted))),
          for (final c in cols) cell(r, c),
        ]),
    ]);
  }

  Widget _exprUi(AcsInk ink) {
    final e = _expr!;
    final args = e.vars.join(', ');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          'Variabile: ${e.vars.join(' ')} (prima e bitul cel mai semnificativ).  Negația: a\' sau !a; ȘI: ab sau a·b; SAU: +; XOR: ⊕ sau ^; NAND: ↑; NOR: ↓.'
          '${e.allowed == null ? '' : '\nPorți permise: ${e.allowed!.map((o) => ExprTask.opNames[o]).join(', ')}.'}',
          style: ink.mono(12.5, color: ink.muted)),
      const SizedBox(height: 10),
      for (final o in e.outputs) ...[
        Row(children: [
          Text('${o.name}($args) = ', style: ink.mono(15, weight: FontWeight.w700, color: ink.strong)),
          Expanded(
            child: Focus(
              onFocusChange: (f) {
                if (f) setState(() => _focused = o.name);
              },
              child: AcsField(ink, _fields[o.name]!, width: double.infinity, hint: 'de exemplu ab\' + c', onSubmitted: (_) => _verify()),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ],
      _symbols(ink),
      const SizedBox(height: 12),
      Wrap(spacing: 24, runSpacing: 14, children: [for (final o in e.outputs) _kmap(ink, o, _fields[o.name]!.text)]),
    ]);
  }

  // ---------------------------------------------------------------- mux
  Widget _drop(AcsInk ink, String value, List<String> items, ValueChanged<String> onChanged, {double width = 72}) => Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: ink.bg, border: Border.all(color: ink.line)),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          isDense: true,
          underline: const SizedBox.shrink(),
          dropdownColor: ink.panel,
          style: ink.mono(14, color: ink.strong, weight: FontWeight.w700),
          iconEnabledColor: ink.muted,
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );

  Widget _muxUi(AcsInk ink) {
    final m = _mux!;
    final choices = m.inputChoices(_sel);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MUX ${1 << m.selects}:1 · alege liniile de selecție (prima e cea mai semnificativă) și ce intră pe fiecare intrare de date.', style: ink.mono(12.5, color: ink.muted)),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var k = 0; k < _data.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Text('D$k ', style: ink.mono(13.5, color: ink.muted)),
                _drop(ink, _data[k], choices, (v) => setState(() => _data[k] = v)),
                Container(width: 18, height: 1.5, color: ink.dim),
              ]),
            ),
        ]),
        Container(
          width: 74,
          height: _data.length * 38.0,
          decoration: BoxDecoration(border: Border.all(color: ink.accent, width: 2), color: ink.panel),
          alignment: Alignment.center,
          child: Text('MUX\n${1 << m.selects}:1', textAlign: TextAlign.center, style: ink.mono(13, weight: FontWeight.w700, color: ink.accent)),
        ),
        Padding(
          padding: EdgeInsets.only(top: _data.length * 19.0 - 10),
          child: Row(children: [Container(width: 24, height: 1.5, color: ink.dim), Text(' f', style: ink.mono(15, weight: FontWeight.w700))]),
        ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (var k = 0; k < _sel.length; k++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('S${_sel.length - 1 - k} = ', style: ink.mono(13.5, color: ink.muted)),
            _drop(ink, _sel[k], m.vars, (v) => setState(() => _sel[k] = v), width: 64),
          ]),
      ]),
    ]);
  }

  // ---------------------------------------------------------------- fsm
  Widget _fsmUi(AcsInk ink) {
    final names = [for (final c in _names) c.text.trim().isEmpty ? '?' : c.text.trim()];
    final m = _machine();
    final simOut = m == null
        ? '(stări cu nume lipsă sau repetate)'
        : () {
            final input = _sim.text.replaceAll(RegExp(r'[^01]'), '');
            try {
              return m.run(input);
            } catch (_) {
              return '(o tranziție duce într-o stare care nu mai există)';
            }
          }();
    Widget head(String t, double w) => SizedBox(width: w, child: Text(t, style: ink.mono(12.5, color: ink.muted, weight: FontWeight.w700)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Automat Mealy: pentru fiecare stare și fiecare bit de intrare, starea următoare și ieșirea. Prima stare e cea inițială.', style: ink.mono(12.5, color: ink.muted)),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [head('stare', 86), head('x=0: următoarea / ieșire', 196), head('x=1: următoarea / ieșire', 196)]),
          const SizedBox(height: 4),
          for (var i = 0; i < _names.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                AcsField(ink, _names[i], width: 76),
                const SizedBox(width: 10),
                for (final k in [0, 1]) ...[
                  _drop(ink, _next[i][k], names, (v) => setState(() => _next[i][k] = v), width: 96),
                  const SizedBox(width: 6),
                  AcsTap(
                    label: 'ieșirea',
                    onTap: () => setState(() => _out[i][k] = 1 - _out[i][k]),
                    builder: (h) => Container(
                      width: 46,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _out[i][k] == 1 ? ink.accent : (h ? ink.hover : ink.bg), border: Border.all(color: ink.line)),
                      child: Text('/${_out[i][k]}', style: ink.mono(14, weight: FontWeight.w700, color: _out[i][k] == 1 ? ink.bg : ink.strong)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ]),
            ),
        ]),
      ),
      ToolRow([
        AcsButton(ink, '+ stare', _names.length >= 8 ? null : () => setState(() => _addState())),
        AcsButton(ink, '− ultima stare', _names.length <= 1
            ? null
            : () => setState(() {
                  _names.removeLast().dispose();
                  _next.removeLast();
                  _out.removeLast();
                })),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Text('încearcă: ', style: ink.mono(13.5, color: ink.muted)),
        AcsField(ink, _sim, width: 200, onChanged: (_) => setState(() {})),
      ]),
      const SizedBox(height: 6),
      Text('intrare: ${_sim.text.replaceAll(RegExp(r'[^01]'), '')}\nieșire:  $simOut', style: ink.mono(14, color: ink.strong)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(
          ink,
          color: ink.bg,
          child: switch (mode) { 'expr' => _exprUi(ink), 'mux' => _muxUi(ink), _ => _fsmUi(ink) },
        ),
        const SizedBox(height: 10),
        ToolRow([AcsButton(ink, 'verifică', _verify, primary: true, icon: Icons.check)]),
        if (_checks != null) ...[const SizedBox(height: 12), ChecksView(ink, _checks!)],
      ],
    );
  }
}
