// =============================================================================
// A QUESTION OF A MULTIPLE-CHOICE TEST (Admitere, and the courses' grile)
//   As at the exam: answers a), b)... and one correct (spec answer). The student
//   picks one (a click, or the keys a–f) and checks it (Enter); a wrong one is
//   crossed out and stays so. With spec answers (a list), several are correct,
//   as in the Moodle tests "select one or more": the student ticks them and
//   checks the whole set; a wrong set only says so, nothing is crossed out. Solved, a program's question shows what the
//   program really prints (run with g++ when the problem was made). A scratch
//   pad under it keeps the working, like the draft sheet at the exam.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import 'ws_common.dart';

const List<String> grilaLetters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

class GrilaWorkspace extends AcsWorkspace {
  const GrilaWorkspace({super.key, required super.problem, required super.ink, required super.onVerdict, required super.narrow});

  @override
  State<GrilaWorkspace> createState() => _GrilaWorkspaceState();
}

class _GrilaWorkspaceState extends State<GrilaWorkspace> {
  late final List<String> _options = [for (final o in widget.problem.spec['options'] as List) '$o'];
  late final Set<int> _answers = widget.problem.spec['answers'] is List
      ? {for (final a in widget.problem.spec['answers'] as List) (a as num).toInt()}
      : {(widget.problem.spec['answer'] as num).toInt()};
  late final bool _multi = widget.problem.spec['answers'] is List;
  late final int _answer = _answers.first;
  int? _picked;
  final Set<int> _ticked = {};
  int _misses = 0;
  final Set<int> _wrong = {};
  bool _solved = false;
  final TextEditingController _scratch = TextEditingController();
  bool _showScratch = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_key);
    AcsProgress.draft(widget.problem).then((d) {
      if (d == null || !mounted) return;
      try {
        final j = json.decode(d) as Map;
        setState(() {
          _wrong.addAll([for (final w in j['wrong'] as List? ?? const []) (w as num).toInt()]);
          _solved = j['solved'] == true;
          if (_solved) {
            _picked = _answer;
            _ticked.addAll(_answers);
          }
          _scratch.text = j['scratch'] as String? ?? '';
          _showScratch = _scratch.text.isNotEmpty;
        });
      } catch (_) {
        // an old draft we can't read: start clean
      }
    });
    _scratch.addListener(_save);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_key);
    _scratch.dispose();
    super.dispose();
  }

  void _save() => AcsProgress.saveDraft(widget.problem, json.encode({'wrong': _wrong.toList(), 'solved': _solved, 'scratch': _scratch.text}));

  /// a–f picks an answer, Enter checks it, while no text field is being typed in.
  bool _key(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted || _solved) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final kb = HardwareKeyboard.instance;
    if (kb.isControlPressed || kb.isMetaPressed || kb.isAltPressed) return false;
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx != null && (ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null)) return false;
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_multi ? _ticked.isEmpty : _picked == null) return false;
      _verify();
      return true;
    }
    final i = grilaLetters.indexOf(e.character?.toLowerCase() ?? '');
    if (i < 0 || i >= _options.length) return false;
    _pick(i);
    return true;
  }

  void _pick(int i) {
    if (_solved || _wrong.contains(i)) return;
    if (_multi) {
      setState(() => _ticked.contains(i) ? _ticked.remove(i) : _ticked.add(i));
      return;
    }
    setState(() => _picked = i);
  }

  void _verify() {
    if (_multi) {
      if (_ticked.isEmpty || _solved) return;
      final ok = _ticked.length == _answers.length && _ticked.containsAll(_answers);
      setState(() {
        if (ok) {
          _solved = true;
        } else {
          _misses++;
        }
      });
      _save();
      widget.onVerdict(ok);
      return;
    }
    final p = _picked;
    if (p == null || _solved) return;
    final ok = p == _answer;
    setState(() {
      if (ok) {
        _solved = true;
      } else {
        _wrong.add(p);
        _picked = null;
      }
    });
    _save();
    widget.onVerdict(ok);
  }

  void _again() {
    setState(() {
      _solved = false;
      _picked = null;
      _wrong.clear();
      _ticked.clear();
      _misses = 0;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final output = widget.problem.spec['output'] as String?;
    Widget option(int i) {
      final letter = grilaLetters[i];
      final wrong = _wrong.contains(i);
      final right = _solved && _answers.contains(i);
      final picked = (_multi ? _ticked.contains(i) : _picked == i) && !_solved;
      final color = right ? ink.good : (wrong ? ink.bad : (picked ? ink.accent : ink.line));
      final mark = ink.terminal
          ? (right ? '[✓]' : wrong ? '[✗]' : picked ? (_multi ? '[x]' : '[•]') : '[ ]')
          : (right ? '✓' : wrong ? '✗' : picked ? (_multi ? '☑' : '●') : (_multi ? '☐' : '○'));
      return AcsTap(
        label: '$letter) ${_options[i]}',
        onTap: _solved || wrong ? null : () => _pick(i),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: right
                ? ink.good.withValues(alpha: 0.12)
                : picked
                    ? ink.accent.withValues(alpha: 0.10)
                    : (h && !wrong && !_solved ? ink.hover : ink.panel),
            border: Border.all(color: color, width: picked || right ? 1.6 : 1),
            borderRadius: ink.terminal ? null : BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: ink.terminal ? 40 : 26,
                child: Text(mark, style: ink.mono(15, weight: FontWeight.w700, color: right ? ink.good : wrong ? ink.bad : picked ? ink.accent : ink.dim)),
              ),
              Text('$letter)  ', style: ink.mono(15, weight: FontWeight.w700, color: wrong ? ink.dim : ink.strong)),
              Expanded(
                child: Opacity(
                  opacity: wrong ? 0.45 : 1,
                  child: AcsText(_options[i], ink, size: widget.narrow ? 14.5 : 15.5, color: wrong ? ink.muted : ink.fg),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            _multi
                ? (ink.terminal ? '# bifează toate răspunsurile corecte (unul sau mai multe)' : 'Bifează toate răspunsurile corecte (unul sau mai multe):')
                : (ink.terminal ? '# alege răspunsul corect (unul singur)' : 'Alege răspunsul corect (unul singur):'),
            style: ink.mono(13.5, color: ink.muted)),
        const SizedBox(height: 8),
        for (var i = 0; i < _options.length; i++) option(i),
        const SizedBox(height: 4),
        ToolRow([
          if (_solved)
            AcsButton(ink, 'încă o dată', _again)
          else if (_multi)
            AcsButton(ink, _ticked.isEmpty ? 'bifează răspunsurile' : 'verifică ${[for (final t in _ticked.toList()..sort()) '${grilaLetters[t]})'].join(' ')}',
                _ticked.isEmpty ? null : _verify, primary: true, icon: Icons.check)
          else
            AcsButton(ink, _picked == null ? 'alege un răspuns' : 'verifică ${grilaLetters[_picked!]})', _picked == null ? null : _verify, primary: true, icon: Icons.check),
          acsKeysHint(ink, 'tastele a–${grilaLetters[_options.length - 1]} ${_multi ? 'bifează' : 'aleg'} · Enter verifică'),
        ]),
        if (_multi && _misses > 0 && !_solved) ...[
          const SizedBox(height: 10),
          Text('${ink.terminal ? '[✗] ' : ''}Nu e combinația corectă${_misses > 1 ? ' ($_misses încercări)' : ''}. Mai încearcă: poate fi corect unul singur, sau mai multe.',
              style: ink.mono(14, color: ink.bad, weight: FontWeight.w700)),
        ],
        if (_wrong.isNotEmpty && !_solved) ...[
          const SizedBox(height: 10),
          Text(
              _wrong.length == 1
                  ? (ink.terminal ? '[✗] ${grilaLetters[_wrong.first]}) nu e corect. Mai încearcă.' : '${grilaLetters[_wrong.first]}) nu e corect. Mai încearcă.')
                  : '${[for (final w in _wrong.toList()..sort()) '${grilaLetters[w]})'].join(', ')} nu sunt corecte.',
              style: ink.mono(14, color: ink.bad, weight: FontWeight.w700)),
        ],
        if (_solved && output != null) ...[
          const SizedBox(height: 12),
          AcsBox(ink,
              title: ink.terminal ? '\$ ./a.out' : 'ce afișează programul, rulat',
              color: ink.bg,
              child: SelectableText(output.isEmpty ? '(nimic)' : output, style: ink.mono(14, color: ink.strong))),
        ],
        const SizedBox(height: 14),
        AcsTap(
          label: 'ciornă',
          onTap: () => setState(() => _showScratch = !_showScratch),
          builder: (h) => Text('${_showScratch ? '[−]' : '[+]'} ciornă', style: ink.mono(14, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)),
        ),
        if (_showScratch) ...[
          const SizedBox(height: 6),
          TextField(
            controller: _scratch,
            maxLines: null,
            minLines: 5,
            style: ink.mono(14, color: ink.strong, height: 1.5),
            cursorColor: ink.accent,
            decoration: InputDecoration(
              hintText: 'calculele tale (rămân aici pe acest dispozitiv)',
              hintStyle: ink.mono(13.5, color: ink.dim),
              filled: true,
              fillColor: ink.panel,
              isDense: true,
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.line), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ink.accent), borderRadius: BorderRadius.circular(ink.terminal ? 0 : 4)),
            ),
          ),
        ],
      ],
    );
  }
}
