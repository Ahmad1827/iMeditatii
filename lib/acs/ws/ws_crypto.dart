// =============================================================================
// ISC: A DECODING BENCH
//   The scrambled text on top, the student's steps under it, and after each
//   step what it leaves, so a wrong turn is seen at once. A Caesar step with
//   no shift yet lists all 25 shifts to read through, as a brute force would.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import '../engine/crypto.dart';
import 'ws_common.dart';

class CryptoWorkspace extends AcsWorkspace {
  const CryptoWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<CryptoWorkspace> createState() => _CryptoWorkspaceState();
}

class _StepRow {
  final String kind;
  final TextEditingController arg = TextEditingController();
  _StepRow(this.kind, [String a = '']) {
    arg.text = a;
  }
  CryptoOp get op => CryptoOp(kind, arg.text);
}

class _CryptoWorkspaceState extends State<CryptoWorkspace> {
  late final CryptoTask _task = CryptoTask.fromSpec(widget.problem.spec);
  final List<_StepRow> _rows = [];
  bool? _verdict;

  @override
  void initState() {
    super.initState();
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        setState(() {
          for (final j in json.decode(d) as List) {
            _add('${j['op']}', '${j['arg'] ?? ''}', save: false);
          }
        });
      } catch (_) {
        // an old draft we can't read: start clean
      }
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.arg.dispose();
    }
    super.dispose();
  }

  void _add(String kind, String arg, {bool save = true}) {
    final r = _StepRow(kind, arg);
    r.arg.addListener(_changed);
    _rows.add(r);
    if (save) _changed();
  }

  void _changed() {
    if (!mounted) return;
    setState(() => _verdict = null);
    AcsProgress.saveDraft(widget.problem, json.encode([for (final r in _rows) r.op.toJson()]));
  }

  void _verify() {
    final ok = _task.solvedBy([for (final r in _rows) r.op]);
    setState(() => _verdict = ok);
    widget.onVerdict(ok);
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final run = CryptoRun.of(_task.cipher, [for (final r in _rows) r.op]);
    Widget data(String text, {Color? color}) => SelectableText(text.length > 600 ? '${text.substring(0, 600)}…' : text, style: ink.mono(14, color: color ?? ink.strong));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcsBox(ink, title: ink.terminal ? 'textul interceptat' : 'Textul interceptat', color: ink.bg, child: data(_task.cipher)),
        const SizedBox(height: 10),
        for (final (i, r) in _rows.indexed) ...[
          ToolRow([
            SizedBox(width: 22, child: Text('${i + 1}.', style: ink.mono(14, color: ink.muted))),
            Text(CryptoOp.names[r.kind]!, style: ink.mono(14, weight: FontWeight.w700, color: ink.accent)),
            if (r.op.needsArg) AcsField(ink, r.arg, width: 130, hint: CryptoOp.argHints[r.kind]),
            AcsButton(ink, '↑', i > 0 ? () => _move(i, -1) : null),
            AcsButton(ink, '↓', i < _rows.length - 1 ? () => _move(i, 1) : null),
            AcsButton(ink, 'șterge', () {
              _rows.removeAt(i).arg.dispose();
              _changed();
            }),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 0, 10),
            child: i < run.outputs.length
                ? data('→ ${showBytes(run.outputs[i])}', color: printable(run.outputs[i]) ? ink.fg : ink.muted)
                : (i == run.outputs.length
                    ? (r.kind == 'rot' && r.arg.text.trim().isEmpty ? _allShifts(ink, i == 0 ? utf8.encode(_task.cipher) : run.outputs[i - 1], r) : Text('✗ ${run.error}', style: ink.mono(13.5, color: ink.bad)))
                    : Text('(așteaptă pasul dinainte)', style: ink.mono(13.5, color: ink.dim))),
          ),
        ],
        Text(ink.terminal ? '# adaugă un pas; se aplică de sus în jos' : 'Adaugă un pas; se aplică de sus în jos:', style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 6),
        ToolRow([for (final k in CryptoOp.names.keys) AcsButton(ink, '+ ${CryptoOp.names[k]!.split(':').first.split(',').first}', () => _add(k, ''))]),
        const SizedBox(height: 12),
        ToolRow([
          AcsButton(ink, 'verifică flag-ul', _verify, primary: true, icon: Icons.flag_outlined),
          if (_verdict != null)
            Text(_verdict! ? 'ăsta e flag-ul' : 'ce a rămas la sfârșit nu e flag-ul (are forma ISC{...})',
                style: ink.mono(14, weight: FontWeight.w700, color: _verdict! ? ink.good : ink.bad)),
        ]),
      ],
    );
  }

  /// Every shift of [input], to pick the one that reads as text.
  Widget _allShifts(AcsInk ink, List<int> input, _StepRow r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('toate deplasările (apasă pe cea care se citește):', style: ink.mono(13, color: ink.muted)),
          for (var n = 1; n < 26; n++)
            AcsTap(
              label: 'deplasarea $n',
              onTap: () => r.arg.text = '$n',
              builder: (h) {
                final t = showBytes(CryptoOp('rot', '$n').apply(input));
                return Text('${'$n'.padLeft(2)}  ${t.length > 48 ? '${t.substring(0, 48)}…' : t}', style: ink.mono(13, color: h ? ink.accent : ink.fg));
              },
            ),
        ],
      );

  void _move(int i, int d) {
    final r = _rows.removeAt(i);
    _rows.insert(i + d, r);
    _changed();
  }
}
