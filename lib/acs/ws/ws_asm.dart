// =============================================================================
// IOCLA: x86 ASSEMBLY ON AN EMULATOR
//   The student writes the function in NASM; "rulează testele" calls it as C
//   would (cdecl) on every test; "pas cu pas" runs one test an instruction at
//   a time, the line lit in the editor, with the registers, the flags and the
//   top of the stack beside it.
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/x86.dart';
import 'ws_common.dart';

const _asmKeywords = {
  'mov', 'movzx', 'movsx', 'lea', 'xchg', 'add', 'sub', 'adc', 'sbb', 'inc', 'dec', 'neg', 'not', 'and', 'or', 'xor', 'test', 'cmp',
  'shl', 'sal', 'shr', 'sar', 'rol', 'ror', 'mul', 'imul', 'div', 'idiv', 'cdq', 'push', 'pop', 'call', 'ret', 'jmp', 'loop', 'leave',
  'je', 'jz', 'jne', 'jnz', 'jg', 'jge', 'jl', 'jle', 'ja', 'jae', 'jb', 'jbe', 'js', 'jns', 'jc', 'jnc', 'jo', 'jno', 'jecxz',
  'sete', 'setne', 'setl', 'setg', 'setle', 'setge', 'section', 'global', 'extern', 'db', 'dw', 'dd', 'resb', 'resw', 'resd', 'times', 'equ',
  'byte', 'word', 'dword', 'eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'esp', 'ebp', 'ax', 'bx', 'cx', 'dx', 'al', 'ah', 'bl', 'bh', 'cl', 'ch', 'dl', 'dh',
};

class AsmWorkspace extends AcsWorkspace {
  const AsmWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<AsmWorkspace> createState() => _AsmWorkspaceState();
}

class _AsmWorkspaceState extends State<AsmWorkspace> {
  late final TextEditingController _code;
  late final AsmCall _call;
  late final List<AsmCase> _cases;
  List<AsmCaseResult>? _results;
  String? _error;

  // stepping
  Cpu? _cpu;
  List<int> _ptrs = const [];
  int _espEnd = 0;
  int _caseIndex = 0;
  String _stepNote = '';
  Map<String, int> _prevRegs = const {};

  @override
  void initState() {
    super.initState();
    final spec = widget.problem.spec;
    _call = AsmCall.fromSpec(spec);
    _cases = [for (final c in spec['tests'] as List) AsmCase.fromJson(c as Map)];
    _code = acsCodeController(spec['starter'] as String? ?? '', _asmKeywords, comment: ';');
    AcsProgress.draft(widget.problem).then((d) {
      if (d != null && d.trim().isNotEmpty && mounted) _code.text = d;
    });
    _code.addListener(() => AcsProgress.saveDraft(widget.problem, _code.text));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  AsmProgram? _assemble() {
    try {
      final p = Assembler.assemble(_code.text);
      setState(() => _error = null);
      return p;
    } on AsmError catch (e) {
      setState(() {
        _error = 'eroare de asamblare: $e';
        _results = null;
        _cpu = null;
      });
      return null;
    }
  }

  void _runTests() {
    final prog = _assemble();
    if (prog == null) {
      widget.onVerdict(false);
      return;
    }
    final r = [for (final c in _cases) _call.run(prog, c)];
    setState(() {
      _results = r;
      _cpu = null;
    });
    widget.onVerdict(r.every((x) => x.ok));
  }

  void _startStep() {
    final prog = _assemble();
    if (prog == null) return;
    // the first failing test, or the first one
    var k = 0;
    if (_results != null) {
      final f = _results!.indexWhere((r) => !r.ok);
      if (f >= 0) k = f;
    }
    try {
      final (cpu, ptrs) = _call.prepare(prog, _cases[k]);
      setState(() {
        _cpu = cpu;
        _ptrs = ptrs;
        _espEnd = cpu.esp + 4;
        _caseIndex = k;
        _stepNote = 'testul ${k + 1}: ${_call.describe(_cases[k])}';
        _prevRegs = Map.of(cpu.r);
      });
    } on AsmError catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _step({int count = 1}) {
    final cpu = _cpu;
    if (cpu == null) return;
    setState(() {
      _prevRegs = Map.of(cpu.r);
      try {
        for (var k = 0; k < count; k++) {
          if (!cpu.step()) break;
        }
        if (cpu.halted) {
          final r = _call.check(cpu, _ptrs, _cases[_caseIndex], _espEnd);
          _stepNote = 'testul ${_caseIndex + 1} s-a terminat: ${r.ok ? 'corect' : r.message}';
        }
      } on AsmError catch (e) {
        _stepNote = e.toString();
        cpu.halted = true;
      }
    });
  }

  String _hex(int v) => '0x${(v & 0xffffffff).toRadixString(16).padLeft(8, '0')}';

  Widget _debugger(AcsInk ink) {
    final cpu = _cpu!;
    final cells = ink.mono(13);
    Widget reg(String n) {
      final v = cpu.r[n]!;
      final changed = _prevRegs[n] != v;
      return SizedBox(
        width: 230,
        child: Text.rich(TextSpan(children: [
          TextSpan(text: n.padRight(4), style: TextStyle(color: ink.muted, fontWeight: FontWeight.w700)),
          TextSpan(text: _hex(v), style: TextStyle(color: changed ? ink.warn : ink.strong, fontWeight: changed ? FontWeight.w700 : null)),
          TextSpan(text: '  ${Cpu.signed(v, 4)}', style: TextStyle(color: ink.dim)),
        ]), style: cells),
      );
    }

    final stack = <Widget>[];
    for (var k = 0; k < 8; k++) {
      final a = cpu.esp + 4 * k;
      String v;
      try {
        v = _hex(cpu.read(a, 4));
      } catch (_) {
        break;
      }
      final mark = a == cpu.r['ebp'] ? '  ← ebp' : '';
      stack.add(Text('${k == 0 ? '[esp]   ' : '[esp+${4 * k}]'.padRight(8)} $v${v == _hex(returnSentinel) ? '  (adresa de întoarcere)' : ''}$mark',
          style: cells.copyWith(color: k == 0 ? ink.strong : ink.fg)));
    }
    return AcsBox(
      ink,
      title: 'pas cu pas · ${cpu.halted ? 'oprit' : 'linia ${cpu.line}'} · ${cpu.steps} instrucțiuni',
      color: ink.bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_stepNote, style: ink.mono(13, color: ink.muted)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 2, children: [for (final n in ['eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp', 'esp']) reg(n)]),
        const SizedBox(height: 6),
        Text.rich(TextSpan(children: [
          for (final (n, f) in [('CF', cpu.cf), ('ZF', cpu.zf), ('SF', cpu.sf), ('OF', cpu.of)])
            TextSpan(text: '$n=${f ? 1 : 0}   ', style: TextStyle(color: f ? ink.accent : ink.dim, fontWeight: f ? FontWeight.w700 : null)),
        ]), style: cells),
        const SizedBox(height: 8),
        Text('stiva', style: ink.mono(12.5, color: ink.muted, weight: FontWeight.w700)),
        ...stack,
        if (cpu.out.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('ieșire: ${cpu.out}', style: cells),
        ],
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'pas', cpu.halted ? null : () => _step(), primary: true),
          AcsButton(ink, '10 pași', cpu.halted ? null : () => _step(count: 10)),
          AcsButton(ink, 'până la capăt', cpu.halted ? null : () => _step(count: Cpu.maxSteps)),
          AcsButton(ink, 'de la început', _startStep),
          AcsButton(ink, 'închide', () => setState(() => _cpu = null)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final spec = widget.problem.spec;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('; ${spec['signature'] ?? _call.entry}', style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 6),
        AcsCodeEditor(ink, _code, minHeight: widget.narrow ? 300 : 380, keywords: _asmKeywords, comment: ';', onRun: _runTests, markLine: _cpu == null || _cpu!.halted ? null : _cpu!.line),
        const SizedBox(height: 10),
        ToolRow([
          AcsButton(ink, 'rulează testele', _runTests, primary: true, icon: Icons.play_arrow),
          AcsButton(ink, 'pas cu pas', _startStep, icon: Icons.skip_next),
          AcsConfirmButton(ink, 'cod inițial', () => setState(() => _code.text = spec['starter'] as String? ?? '')),
          acsKeysHint(ink, 'Ctrl+Enter rulează testele'),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: ink.mono(13.5, color: ink.bad)),
        ],
        if (_cpu != null) ...[const SizedBox(height: 12), _debugger(ink)],
        if (_results != null) ...[
          const SizedBox(height: 12),
          ChecksView(ink, [for (final r in _results!) Check(_call.describe(r.c) + (r.c.ret == null ? '' : ' = ${r.c.ret}'), r.ok, r.message)],
              title: _results!.every((r) => r.ok) ? 'teste: toate trec' : 'teste: ${_results!.where((r) => r.ok).length} din ${_results!.length}'),
        ],
      ],
    );
  }
}
