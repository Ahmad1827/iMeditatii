import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_system.dart';

/// Two panes with a divider between them that the mouse can drag. [ratio] is
/// the first pane's share of the room; a double click puts it back to
/// [defaultRatio]. Neither pane goes under its minimum while there is room for
/// both; in a space too small for that, each gets half.
class PaneSplit extends StatelessWidget {
  final Axis axis; // horizontal: side by side; vertical: one over the other
  final double ratio;
  final double defaultRatio;
  final ValueChanged<double> onChanged;
  final VoidCallback? onChangeEnd;
  final double minFirst;
  final double minSecond;
  final double gap;
  final Widget first;
  final Widget second;

  const PaneSplit({
    super.key,
    required this.axis,
    required this.ratio,
    required this.defaultRatio,
    required this.onChanged,
    this.onChangeEnd,
    this.minFirst = 200,
    this.minSecond = 200,
    this.gap = 14,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final across = axis == Axis.horizontal;
        final room = (across ? c.maxWidth : c.maxHeight) - gap;
        final lo = minFirst < room / 2 ? minFirst : room / 2;
        final hi = room - minSecond > room / 2 ? room - minSecond : room / 2;
        final size = (room * ratio).clamp(lo, hi).toDouble();
        final divider = _Divider(
          across: across,
          gap: gap,
          onDrag: (d) => onChanged(((size + d).clamp(lo, hi).toDouble()) / room),
          onEnd: onChangeEnd,
          onReset: () {
            onChanged(defaultRatio);
            onChangeEnd?.call();
          },
        );
        return Flex(
          direction: axis,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: across ? size : null, height: across ? null : size, child: first),
            divider,
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _Divider extends StatefulWidget {
  final bool across;
  final double gap;
  final ValueChanged<double> onDrag;
  final VoidCallback? onEnd;
  final VoidCallback onReset;

  const _Divider({required this.across, required this.gap, required this.onDrag, this.onEnd, required this.onReset});

  @override
  State<_Divider> createState() => _DividerState();
}

class _DividerState extends State<_Divider> {
  bool _hover = false;
  bool _drag = false;

  @override
  Widget build(BuildContext context) {
    final across = widget.across;
    final lit = _hover || _drag;
    final grip = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: across ? (lit ? 4 : 3) : (lit ? 56 : 34),
      height: across ? (lit ? 56 : 34) : (lit ? 4 : 3),
      decoration: BoxDecoration(color: lit ? Pb.primary : Pb.inputBorder, borderRadius: BorderRadius.circular(2)),
    );
    void end() {
      setState(() => _drag = false);
      widget.onEnd?.call();
    }

    return MouseRegion(
      cursor: across ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down, // from the press itself, so it stays under the mouse
        onDoubleTap: widget.onReset,
        onHorizontalDragStart: across ? (_) => setState(() => _drag = true) : null,
        onHorizontalDragUpdate: across ? (d) => widget.onDrag(d.delta.dx) : null,
        onHorizontalDragEnd: across ? (_) => end() : null,
        onVerticalDragStart: across ? null : (_) => setState(() => _drag = true),
        onVerticalDragUpdate: across ? null : (d) => widget.onDrag(d.delta.dy),
        onVerticalDragEnd: across ? null : (_) => end(),
        child: SizedBox(
          width: across ? widget.gap : null,
          height: across ? null : widget.gap,
          child: Center(child: grip),
        ),
      ),
    );
  }
}
