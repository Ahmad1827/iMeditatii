import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'statement.dart';
import 'statement_text.dart';
import 'ui_components.dart';

// =============================================================================
// A PROBLEM'S WHOLE STATEMENT, AS THE STUDENT READS IT
//   Where it comes from, the story, Cerința, what is read and written, the
//   limits, the examples and a closed hint. The problem's page shows it, and so
//   does the panel beside the code in the IDE.
// =============================================================================
class ProblemStatement extends StatefulWidget {
  final Map problem;
  final bool showOptions; // a maths multiple-choice problem's options, A to D
  final List<Widget> footer;

  const ProblemStatement({super.key, required this.problem, this.showOptions = false, this.footer = const []});

  @override
  State<ProblemStatement> createState() => _ProblemStatementState();
}

class _ProblemStatementState extends State<ProblemStatement> {
  bool _cHintOpen = false;

  String? _str(List<String> keys) {
    for (final k in keys) {
      final v = widget.problem[k];
      if (v == null || v is List) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty && t != '-') return t;
    }
    return null;
  }

  List<String>? _list(List<String> keys) {
    for (final k in keys) {
      final v = widget.problem[k];
      if (v is List && v.isNotEmpty) return v.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// A problem with files, like at the olympiad: its name.
  String? get _file {
    final f = _str(['fisier', 'file'])?.trim();
    return f == null || f.isEmpty ? null : f;
  }

  List<Map<String, String>> get _examples {
    final out = <Map<String, String>>[];
    void add(dynamic e) {
      if (e is Map) out.add({'input': (e['input'] ?? '').toString(), 'output': (e['output'] ?? '').toString()});
    }

    final raw = widget.problem['examples'] ?? widget.problem['exemple'];
    if (raw is Map) {
      add(raw);
    } else if (raw is List) {
      raw.forEach(add);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final input = _str(['input', 'date_intrare']);
    final output = _str(['output', 'date_iesire']);
    final cList = _list(['restrictii', 'constraints', 'restrictions']);
    final cText = _str(['restrictii', 'constraints', 'restrictions']);
    final hint = _str(['hint', 'indicatie']);
    final expl = _str(['explicatie', 'explanation']);
    final examples = _examples;
    final parts = StatementParts.of(widget.problem, file: _file);
    final options = widget.showOptions && widget.problem['tip_exercitiu'] == 'grila' ? (_list(['variante']) ?? const <String>[]) : const <String>[];
    // what explains the first example: its own field, then the statement's "Exemplu: ..." paragraphs
    final explained = [if (expl != null) expl, ...parts.examples];
    final source = parts.source.isNotEmpty ? parts.source : _str(['sursa']);
    final pictures = _list(['imagine_originala']) ?? [if (_str(['imagine_originala']) != null) _str(['imagine_originala'])!];

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (source != null || pictures.isNotEmpty) ...[_cOrigin(source, pictures), const SizedBox(height: 16)],
          if (_str(['nota_examen']) != null) ...[_cExamNote(_str(['nota_examen'])!), const SizedBox(height: 16)],
          if (_file != null) ...[
            PbAlert(
              type: PbAlertType.info,
              icon: Icons.description_outlined,
              text: 'Problemă cu fișiere: citești din $_file.in și scrii în $_file.out. Ce citești de la tastatură e gol, iar ce afișezi pe ecran nu se ia în calcul.',
            ),
            const SizedBox(height: 16),
          ],
          if (parts.context.isNotEmpty) ...[_cContext(parts.context), const SizedBox(height: 14)],
          _cTask(parts.body),
          if (options.isNotEmpty) _cSection('Variante de răspuns', Icons.checklist_rtl, _cOptions(options)),
          if (input != null || output != null) _cSection('Date', Icons.swap_horiz, _cInOut(input, output)),
          if (cList != null || cText != null) _cSection('Restricții', Icons.rule, _cConstraints(cList ?? [cText!])),
          for (var i = 0; i < examples.length; i++)
            _cSection(examples.length == 1 ? 'Exemplu' : 'Exemplul ${i + 1}', Icons.science_outlined, _cExample(examples[i], i == 0 ? explained : const [])),
          if (examples.isEmpty && explained.isNotEmpty) _cSection('Exemplu', Icons.science_outlined, _cExplanation(explained)),
          if (hint != null) _cHint(hint),
          ...widget.footer,
        ],
      ),
    );
  }

  Widget _cSection(String title, IconData icon, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: Pb.primary),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  /// Where the problem comes from, and the page of the paper it was set on.
  Widget _cOrigin(String? source, List<String> pictures) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
        child: Row(
          children: [
            Icon(source != null && source.startsWith('BAC') ? Icons.history_edu_outlined : Icons.emoji_events_outlined, size: 18, color: Pb.muted),
            const SizedBox(width: 10),
            Expanded(child: Text(source ?? 'Subiectul original', style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.4, fontWeight: FontWeight.w500))),
            if (pictures.isNotEmpty) ...[
              const SizedBox(width: 8),
              PbButton(
                text: source != null && source.startsWith('AcadNet') ? 'Figurile' : 'Subiectul original',
                icon: Icons.image_outlined,
                variant: PbVariant.outlineSecondary,
                size: PbSize.sm,
                onPressed: () => _showOriginal(pictures, source),
              ),
            ],
          ],
        ),
      );

  void _showOriginal(List<String> pictures, String? source) => showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (d) => Dialog(
          backgroundColor: Pb.surface,
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 6, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(source ?? 'Subiectul original', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
                      ),
                      IconButton(tooltip: 'Închide', icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(d).pop()),
                    ],
                  ),
                ),
                Container(height: 1, color: Pb.border),
                Flexible(
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: SingleChildScrollView(
                      child: Container(
                        color: Colors.white, // the paper is white in the dark theme too
                        padding: const EdgeInsets.all(8),
                        child: Column(children: [for (final p in pictures) Image.asset(p, fit: BoxFit.fitWidth, width: double.infinity)]),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: Text('Din varianta oficială a Ministerului Educației. Mărește cu două degete sau cu rotița.',
                      style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                ),
              ],
            ),
          ),
        ),
      );

  /// What was different at the exam (a file instead of the keyboard, the
  /// algorithm described in words), so the task above it can say only what to do here.
  Widget _cExamNote(String note) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 16, color: Pb.muted)),
          const SizedBox(width: 8),
          Expanded(child: StatementText(note, fontSize: 13.5, height: 1.5, color: Pb.muted)),
        ],
      );

  /// The story and the definitions: what the words of the task mean.
  Widget _cContext(List<String> paragraphs) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: Icon(Icons.menu_book_outlined, size: 18, color: Pb.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, p) in paragraphs.indexed)
                    Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 10), child: StatementText(p, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );

  /// What the student has to do, on a card of its own.
  Widget _cTask(List<String> paragraphs) => ClipRRect(
        borderRadius: BorderRadius.circular(12), // a one-sided border can't be rounded itself
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Pb.primary.withOpacity(AppColors.isDark ? 0.10 : 0.05),
            border: const Border(left: BorderSide(color: Pb.primary, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CERINȚA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Pb.primary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              if (paragraphs.isEmpty) Text('Fără enunț.', style: TextStyle(fontSize: 15.5, color: Pb.muted)),
              for (final (i, p) in paragraphs.indexed)
                Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 12), child: StatementText(p, fontSize: 16)),
            ],
          ),
        ),
      );

  /// A maths multiple-choice problem's options, A to D, as on the paper.
  Widget _cOptions(List<String> options) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth >= 440 ? (c.maxWidth - 10) / 2 : c.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, o) in options.indexed)
                Container(
                  width: w,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Pb.primary.withOpacity(0.12), shape: BoxShape.circle),
                        child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Pb.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: StatementText(o, fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
            ],
          );
        },
      );

  /// What is read and what is written, side by side.
  Widget _cInOut(String? input, String? output) {
    Widget card(IconData icon, Color tint, String label, String text) => Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Pb.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: tint.withOpacity(0.13), borderRadius: BorderRadius.circular(7)),
                    child: Icon(icon, size: 15, color: tint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text))),
                ],
              ),
              const SizedBox(height: 8),
              StatementText(text, fontSize: 14.5, height: 1.6),
            ],
          ),
        );
    final cards = [
      if (input != null) card(Icons.login, const Color(0xFF2563EB), _file == null ? 'Date de intrare' : 'Date de intrare · $_file.in', input),
      if (output != null) card(Icons.logout, Pb.primary, _file == null ? 'Date de ieșire' : 'Date de ieșire · $_file.out', output),
    ];
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 480 && cards.length == 2
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: cards[0]), const SizedBox(width: 10), Expanded(child: cards[1])],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final (i, c) in cards.indexed) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 10), child: c)],
            ),
    );
  }

  /// The limits, one chip each.
  Widget _cConstraints(List<String> items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final it in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Pb.codeBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Pb.border)),
              child: StatementText.line(it, TextStyle(fontSize: 14, height: 1.45, color: Pb.text)),
            ),
        ],
      );

  /// One example: what goes in and what comes out side by side (named after
  /// the files when the problem has them), with what explains it underneath.
  Widget _cExample(Map<String, String> ex, List<String> explanation) {
    Widget box(IconData icon, String label, String v) => Container(
          decoration: BoxDecoration(color: Pb.codeBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: Pb.muted),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted)),
                  ],
                ),
              ),
              Container(height: 1, color: Pb.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(v.isEmpty ? ' ' : v, style: Pb.mono(14, color: Pb.text)),
                ),
              ),
            ],
          ),
        );
    final input = box(Icons.login, _file == null ? 'Intrare' : '$_file.in', ex['input']!);
    final output = box(Icons.logout, _file == null ? 'Ieșire' : '$_file.out', ex['output']!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 440
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: input),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 18, color: Pb.muted)),
                      Expanded(child: output),
                    ],
                  ),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [input, const SizedBox(height: 10), output]),
        ),
        if (explanation.isNotEmpty) ...[const SizedBox(height: 10), _cExplanation(explanation)],
      ],
    );
  }

  Widget _cExplanation(List<String> paragraphs) => ClipRRect(
        borderRadius: BorderRadius.circular(10), // a one-sided border can't be rounded itself
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.06),
            border: const Border(left: BorderSide(color: Color(0xFF2563EB), width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "Exemplu (cerința 3): ..." is a case of its own, not this example explained
              Text(paragraphs.every((p) => p.startsWith('Exemplu (')) ? 'Alt exemplu' : 'De ce',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
              const SizedBox(height: 6),
              for (final (i, p) in paragraphs.indexed)
                Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 8), child: StatementText(p, fontSize: 14.5, height: 1.6)),
            ],
          ),
        ),
      );

  Widget _cHint(String hint) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _cHintOpen = !_cHintOpen),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Pb.muted),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Indiciu', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text))),
                        Icon(_cHintOpen ? Icons.expand_less : Icons.expand_more, color: Pb.muted),
                      ],
                    ),
                  ),
                ),
              ),
              if (_cHintOpen) ...[
                Container(height: 1, color: Pb.border),
                Padding(padding: const EdgeInsets.all(14), child: StatementText(hint, fontSize: 15, height: 1.6)),
              ],
            ],
          ),
        ),
      );
}
