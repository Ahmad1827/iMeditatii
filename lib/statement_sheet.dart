import 'package:flutter/material.dart';

import 'statement.dart';
import 'statement_text.dart';
import 'ui_components.dart';

// =============================================================================
// A STATEMENT AS ON THE EXAM SHEET
//   Problems from an exam have a picture of their paper. The others get the
//   same look made from their own statement: a white sheet, the papers' faces,
//   the text in one column, the example in a ruled table.
// =============================================================================

/// What the sheet says, top to bottom, in the statement's markup. Apart from
/// the widget so it can be checked without drawing anything.
class SheetText {
  final String title;
  final List<String> paragraphs; // the story, then the task
  final List<String> options; // a multiple-choice problem's, "a)" to "d)"
  final String? input, output;
  final List<String> limits;
  final List<Map<String, String>> examples;
  final List<String> explained;
  final String? file;

  const SheetText({
    required this.title,
    required this.paragraphs,
    this.options = const [],
    this.input,
    this.output,
    this.limits = const [],
    this.examples = const [],
    this.explained = const [],
    this.file,
  });

  static SheetText of(Map problem) {
    String? str(List<String> keys) {
      for (final k in keys) {
        final v = problem[k];
        if (v == null || v is List) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty && t != '-') return t;
      }
      return null;
    }

    List<String>? list(List<String> keys) {
      for (final k in keys) {
        final v = problem[k];
        if (v is List && v.isNotEmpty) return v.map((e) => e.toString()).toList();
      }
      return null;
    }

    final file = str(['fisier', 'file']);
    final parts = StatementParts.of(problem, file: file);
    final raw = problem['examples'] ?? problem['exemple'];
    final expl = str(['explicatie', 'explanation']);
    const limitKeys = ['restrictii', 'constraints', 'restrictions'];
    return SheetText(
      title: str(['title']) ?? '',
      paragraphs: [...parts.context, ...parts.body],
      options: problem['tip_exercitiu'] == 'grila' ? (list(['variante']) ?? const []) : const [],
      input: str(['input', 'date_intrare']),
      output: str(['output', 'date_iesire']),
      limits: list(limitKeys) ?? [if (str(limitKeys) != null) str(limitKeys)!],
      examples: [
        for (final e in raw is Map ? [raw] : (raw is List ? raw : const []))
          if (e is Map) {'input': '${e['input'] ?? ''}', 'output': '${e['output'] ?? ''}'},
      ],
      explained: [if (expl != null) expl, ...parts.examples],
      file: file,
    );
  }

  bool get isEmpty => paragraphs.isEmpty;
}

class StatementSheet extends StatelessWidget {
  final SheetText text;
  const StatementSheet(this.text, {super.key});

  static const double _size = 15.5;
  static const double _lead = 1.38;

  Widget _p(String t) => StatementText(t, fontSize: _size, height: _lead, paper: true);

  /// "**Label:** text", the way the papers lead into a part.
  Widget _led(String label, String t) => _p('**$label:** $t');

  Widget _example(Map<String, String> ex) {
    const line = BorderSide(color: StatementText.ink, width: 0.8);
    Widget cell(String v, {bool head = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: head
              ? Text(v, style: const TextStyle(fontFamily: 'Arimo', fontWeight: FontWeight.w700, fontSize: 14, color: StatementText.ink, letterSpacing: 0))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(v.isEmpty ? ' ' : v, style: StatementText.paperCode(14, height: 1.3)),
                ),
        );
    return Table(
      border: const TableBorder(top: line, bottom: line, left: line, right: line, verticalInside: line, horizontalInside: line),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(children: [cell(text.file == null ? 'Date de intrare' : '${text.file}.in', head: true), cell(text.file == null ? 'Date de ieșire' : '${text.file}.out', head: true)]),
        TableRow(children: [cell(ex['input']!), cell(ex['output']!)]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[
      if (text.title.isNotEmpty)
        Text(text.title, style: const TextStyle(fontFamily: 'Arimo', fontWeight: FontWeight.w700, fontSize: 17, height: 1.3, color: StatementText.ink, letterSpacing: 0)),
      for (final p in text.paragraphs) _p(p),
      for (final (i, o) in text.options.indexed) _p('**${String.fromCharCode(97 + i)})** $o'),
      if (text.input != null) _led('Date de intrare', text.input!),
      if (text.output != null) _led('Date de ieșire', text.output!),
      if (text.limits.isNotEmpty) _p('**Restricții și precizări:**\n${text.limits.map((l) => '- $l').join('\n')}'),
      for (final (i, ex) in text.examples.indexed) ...[
        _p(text.examples.length == 1 ? '**Exemplu:**' : '**Exemplul ${i + 1}:**'),
        _example(ex),
      ],
      for (final p in text.explained) _p(p.startsWith('Exemplu') ? p : '**Explicație:** $p'),
    ];
    return Container(
      color: Colors.white, // paper is white in the dark theme too
      padding: const EdgeInsets.fromLTRB(40, 34, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, b) in blocks.indexed) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 9), child: b),
        ],
      ),
    );
  }
}

void showStatementSheet(BuildContext context, Map problem) => showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (d) => Dialog(
        backgroundColor: Pb.surface,
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 6, 10),
                child: Row(
                  children: [
                    Expanded(child: Text('Enunțul pe foaie', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text))),
                    IconButton(tooltip: 'Închide', icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(d).pop()),
                  ],
                ),
              ),
              Container(height: 1, color: Pb.border),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: SingleChildScrollView(child: StatementSheet(SheetText.of(problem))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Text('Enunțul problemei, așezat ca pe o foaie de examen. Mărește cu două degete sau cu rotița.',
                    style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ),
            ],
          ),
        ),
      ),
    );
