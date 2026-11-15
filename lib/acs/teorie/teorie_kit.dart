// =============================================================================
// THEORY PAGES: the pieces the visualisations share
//   A bar to walk through the steps of an algorithm (first, back, play,
//   forward, last), a part that opens on a tap (a proof, a solution), and the
//   readers for what the lesson files write: automata, places, names.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../acs_kit.dart';
import '../engine/lfa.dart';

/// Step k of n, with buttons; [onChanged] gets the new step. Play walks to
/// the end, one step every [every].
class StepBar extends StatefulWidget {
  final AcsInk ink;
  final int step, count;
  final ValueChanged<int> onChanged;
  final String Function(int step)? label;
  final Duration every;
  const StepBar(this.ink, {super.key, required this.step, required this.count, required this.onChanged, this.label, this.every = const Duration(milliseconds: 900)});

  @override
  State<StepBar> createState() => _StepBarState();
}

class _StepBarState extends State<StepBar> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    if (_timer != null) {
      setState(() => _timer?.cancel());
      _timer = null;
      return;
    }
    if (widget.step >= widget.count - 1) widget.onChanged(0);
    setState(() {
      _timer = Timer.periodic(widget.every, (t) {
        if (!mounted) return;
        if (widget.step >= widget.count - 1) {
          setState(() {
            t.cancel();
            _timer = null;
          });
          return;
        }
        widget.onChanged(widget.step + 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final s = widget.step, n = widget.count;
    final playing = _timer != null;
    return Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      AcsButton(ink, '⇤', s > 0 ? () => widget.onChanged(0) : null),
      AcsButton(ink, '◀', s > 0 ? () => widget.onChanged(s - 1) : null),
      AcsButton(ink, playing ? 'pauză' : 'redă', n > 1 ? _play : null, primary: !playing, icon: playing ? Icons.pause : Icons.play_arrow_rounded),
      AcsButton(ink, '▶', s < n - 1 ? () => widget.onChanged(s + 1) : null),
      AcsButton(ink, '⇥', s < n - 1 ? () => widget.onChanged(n - 1) : null),
      const SizedBox(width: 4),
      Text(widget.label?.call(s) ?? 'pasul ${s + 1} din $n', style: ink.mono(13, color: ink.muted)),
    ]);
  }
}

/// A part shown on a tap: "vezi demonstrația", "vezi rezolvarea".
class Reveal extends StatefulWidget {
  final AcsInk ink;
  final String label;
  final Widget child;
  final bool open;
  const Reveal(this.ink, this.label, this.child, {super.key, this.open = false});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  late bool _open = widget.open;

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: AcsTap(
          label: widget.label,
          onTap: () => setState(() => _open = !_open),
          builder: (h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
                ink.terminal ? '${_open ? '[-]' : '[+]'} ${widget.label}' : '${_open ? '▾' : '▸'} ${widget.label}',
                style: ink.mono(14, weight: FontWeight.w700, color: h ? ink.strong : ink.accent)),
          ),
        ),
      ),
      if (_open) Padding(padding: const EdgeInsets.only(top: 6), child: widget.child),
    ]);
  }
}

/// A small rounded label.
Widget teorieTag(AcsInk ink, String text, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: 0.6)),
        borderRadius: ink.terminal ? null : BorderRadius.circular(20),
      ),
      child: Text(ink.terminal ? '[$text]' : text, style: ink.mono(12, color: c, weight: FontWeight.w600)),
    );

// ---------------------------------------------------------------- reading the files
Nfa nfaOf(Object? j) => Nfa.fromJson(j as Map);

List<String> alphabetOf(Map j) => '${j['alphabet'] ?? 'ab'}'.split('');

List<String>? namesOf(Object? j) => j is List ? [for (final x in j) '$x'] : null;

/// Places written as [[x, y], ...].
List<(double, double)>? placesOf(Object? j) {
  if (j is! List) return null;
  return [for (final p in j) (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())];
}

/// A word to show: the empty one as ε.
String wordShown(String w) => w.isEmpty ? lfaEps : w;
