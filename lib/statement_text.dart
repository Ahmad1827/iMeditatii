import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'design_system.dart';
import 'statement.dart';

// =============================================================================
// A STATEMENT'S TEXT, AS WRITTEN
//   Draws the markup of statement.dart: formulas typeset (matrices, fractions,
//   integrals), code in monospace, bullets and lettered parts lined up. Put it
//   in a SelectionArea to let the text be copied.
// =============================================================================

class StatementText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double height;
  final Color? color;
  final FontWeight? weight;

  const StatementText(this.text, {super.key, this.fontSize = 15.5, this.height = 1.7, this.color, this.weight});

  @override
  Widget build(BuildContext context) {
    final blocks = Markup.blocks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in blocks.indexed) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 8), child: _block(b)),
      ],
    );
  }

  TextStyle get _style => TextStyle(fontSize: fontSize, height: height, color: color ?? Pb.text, fontWeight: weight);

  Widget _block(StatementBlock b) {
    switch (b.kind) {
      case BlockKind.prose:
        return line(b.text, _style);
      case BlockKind.math:
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _tex(b.text, _style, display: true),
          ),
        );
      case BlockKind.code:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: Pb.codeBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Pb.border)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(b.text, style: Pb.mono(fontSize - 1.5, color: Pb.text)),
          ),
        );
      case BlockKind.bullets:
      case BlockKind.parts:
        final parts = b.kind == BlockKind.parts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in b.items.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: parts ? 28 : 18,
                      child: parts
                          ? Text(b.labels[i], style: _style.copyWith(fontWeight: FontWeight.w700, color: Pb.primary))
                          : Padding(
                              padding: EdgeInsets.only(top: fontSize * height / 2 - 3, left: 4),
                              child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Pb.primary, shape: BoxShape.circle)),
                            ),
                    ),
                    Expanded(child: line(item, _style)),
                  ],
                ),
              ),
          ],
        );
    }
  }

  /// One run of prose, its formulas and code inline.
  static Widget line(String text, TextStyle style) {
    final size = style.fontSize ?? 15.5;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final s in Markup.spans(text))
            switch (s.kind) {
              SpanKind.text => TextSpan(text: s.text),
              SpanKind.bold => TextSpan(text: s.text, style: const TextStyle(fontWeight: FontWeight.w700)),
              SpanKind.code => TextSpan(
                  text: s.text,
                  style: Pb.mono(size * 0.9, color: Pb.inlineCode, height: style.height ?? 1.6).copyWith(backgroundColor: Pb.codeChip),
                ),
              SpanKind.tex => WidgetSpan(alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic, child: _tex(s.text, style)),
            },
        ],
      ),
    );
  }

  static Widget _tex(String tex, TextStyle style, {bool display = false}) => Math.tex(
        tex,
        mathStyle: display ? MathStyle.display : MathStyle.text,
        textStyle: style.copyWith(fontSize: (style.fontSize ?? 15.5) * 1.08, height: 1),
        onErrorFallback: (_) => Text(tex, style: Pb.mono((style.fontSize ?? 15.5) * 0.9, color: style.color)),
      );
}
