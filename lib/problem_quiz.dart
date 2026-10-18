import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'ui_components.dart';

// =============================================================================
// QUESTIONS BEFORE A PROBLEM
//   Opening a problem asks a few multiple-choice questions that lead into it:
//   the idea to use, a trap in the statement, a small case worked by hand.
//   Each answer is explained on the spot. Nothing is graded or saved, and
//   "Sari peste" goes straight to the problem.
//   The questions of the problems in the app are in
//   assets/data/problem_quizzes.json (subject → grade → id); a problem added
//   by a teacher carries its own, in its 'intrebari' field.
// =============================================================================

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer; // index in [options]
  final String explanation;
  const QuizQuestion(this.question, this.options, this.answer, [this.explanation = '']);

  /// From {q, o, a, e}, or null when it isn't a usable question.
  static QuizQuestion? fromJson(Object? j) {
    if (j is! Map) return null;
    final q = '${j['q'] ?? ''}'.trim();
    final o = j['o'] is List ? [for (final x in j['o'] as List) '$x'.trim()] : const <String>[];
    final a = j['a'] is int ? j['a'] as int : int.tryParse('${j['a']}') ?? -1;
    if (q.isEmpty || o.length < 2 || o.any((x) => x.isEmpty) || a < 0 || a >= o.length) return null;
    return QuizQuestion(q, o, a, '${j['e'] ?? ''}'.trim());
  }

  Map<String, dynamic> toJson() => {'q': question, 'o': options, 'a': answer, if (explanation.isNotEmpty) 'e': explanation};
}

class ProblemQuiz {
  static Map<String, dynamic>? _bank;

  /// The questions for a problem: its own ([problem]'s 'intrebari'), else the
  /// app's for [subject] / [grade] / [id]. Empty when it has none.
  static Future<List<QuizQuestion>> load(String subject, String grade, String id, {Map<String, dynamic>? problem}) async {
    final own = parse(problem?['intrebari']);
    if (own.isNotEmpty) return own;
    try {
      _bank ??= json.decode(await rootBundle.loadString('assets/data/problem_quizzes.json')) as Map<String, dynamic>;
      return parse(_bank![subject]?[grade]?[id]);
    } catch (e) {
      debugPrint('Întrebări: $e');
      return const [];
    }
  }

  static List<QuizQuestion> parse(Object? list) =>
      list is List ? list.map(QuizQuestion.fromJson).whereType<QuizQuestion>().toList() : const [];
}

/// Asks [questions] in a dialog; returns when the student finishes or skips.
Future<void> showProblemQuiz(BuildContext context, List<QuizQuestion> questions, {Random? random}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: ProblemQuizCard(questions: questions, random: random),
      ),
    ),
  );
}

class ProblemQuizCard extends StatefulWidget {
  final List<QuizQuestion> questions;
  final Random? random; // tests fix the order of the options
  const ProblemQuizCard({super.key, required this.questions, this.random});

  @override
  State<ProblemQuizCard> createState() => _ProblemQuizCardState();
}

class _ProblemQuizCardState extends State<ProblemQuizCard> {
  int _i = 0;
  int? _picked; // index into the shown order
  int _right = 0;
  late final List<List<int>> _order; // the options of each question, shuffled

  @override
  void initState() {
    super.initState();
    final r = widget.random ?? Random();
    _order = [for (final q in widget.questions) List.generate(q.options.length, (k) => k)..shuffle(r)];
  }

  QuizQuestion get _q => widget.questions[_i];
  bool get _last => _i == widget.questions.length - 1;

  void _pick(int shown) {
    if (_picked != null) return;
    setState(() {
      _picked = shown;
      if (_order[_i][shown] == _q.answer) _right++;
    });
  }

  void _next() {
    if (_last) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => _card(s.isClean));
  }

  Widget _card(bool clean) {
    final text = clean ? Pb.text : AppColors.ink;
    final muted = clean ? Pb.muted : AppColors.textMuted;
    final accent = clean ? Pb.primary : AppColors.sunset;
    final ok = clean ? Pb.success : AppColors.forest;
    final bad = clean ? Pb.danger : AppColors.sunset;
    final answered = _picked != null;
    final n = widget.questions.length;

    final head = Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 20, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            clean ? 'Înainte să începi' : 'ÎNAINTE SĂ ÎNCEPI',
            style: TextStyle(fontSize: 13.5, fontWeight: clean ? FontWeight.w600 : FontWeight.w900, color: muted, letterSpacing: clean ? 0 : 1),
          ),
        ),
        for (var k = 0; k < n; k++)
          Container(
            width: k == _i ? 18 : 8,
            height: 8,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: k <= _i ? accent : (clean ? Pb.border : AppColors.cloud),
              borderRadius: BorderRadius.circular(clean ? 99 : 0),
            ),
          ),
        const SizedBox(width: 10),
        Text('${_i + 1} / $n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted)),
      ],
    );

    Widget option(int shown) {
      final real = _order[_i][shown];
      final isAnswer = real == _q.answer;
      final isPicked = shown == _picked;
      Color border = clean ? Pb.border : AppColors.border;
      Color? fill;
      IconData? mark;
      Color? markColor;
      if (answered && isAnswer) {
        border = ok;
        fill = ok.withValues(alpha: 0.10);
        mark = Icons.check_circle;
        markColor = ok;
      } else if (isPicked) {
        border = bad;
        fill = bad.withValues(alpha: 0.10);
        mark = Icons.cancel;
        markColor = bad;
      }
      final dim = answered && !isAnswer && !isPicked;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: fill ?? (clean ? Pb.surface : AppColors.cardBg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(clean ? 10 : 0),
            side: BorderSide(color: border, width: clean ? (answered && (isAnswer || isPicked) ? 1.6 : 1) : 2.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: answered ? null : () => _pick(shown),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: clean ? Pb.hoverBg : AppColors.cloud,
                      borderRadius: BorderRadius.circular(clean ? 6 : 0),
                    ),
                    child: Text(
                      String.fromCharCode(65 + shown),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: dim ? muted : text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _q.options[real],
                        style: TextStyle(fontSize: 15, height: 1.4, color: dim ? muted : text, fontWeight: clean ? FontWeight.w400 : FontWeight.w600),
                      ),
                    ),
                  ),
                  if (mark != null) ...[const SizedBox(width: 8), Icon(mark, size: 20, color: markColor)],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final right = answered && _order[_i][_picked!] == _q.answer;
    final verdict = answered
        ? Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (right ? ok : bad).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(clean ? 10 : 0),
              border: Border.all(color: (right ? ok : bad).withValues(alpha: clean ? 0.35 : 1), width: clean ? 1 : 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  right ? 'Corect!' : 'Nu chiar.',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: right ? ok : bad),
                ),
                if (_q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_q.explanation, style: TextStyle(fontSize: 14, height: 1.45, color: text)),
                ],
              ],
            ),
          )
        : const SizedBox.shrink();

    final buttons = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: muted),
          child: Text(_last && answered ? 'Închide' : 'Sari peste', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        ),
        Opacity(
          opacity: answered ? 1 : 0.45,
          child: IgnorePointer(
            ignoring: !answered,
            child: RetroButton(
              text: _last ? 'La problemă' : 'Continuă',
              icon: _last ? Icons.play_arrow : Icons.arrow_forward,
              bgColor: AppColors.forest,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              onPressed: _next,
            ),
          ),
        ),
      ],
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        const SizedBox(height: 16),
        Text(
          _q.question,
          style: TextStyle(fontSize: 18, height: 1.4, fontWeight: clean ? FontWeight.w600 : FontWeight.w800, color: text),
        ),
        const SizedBox(height: 14),
        for (var k = 0; k < _q.options.length; k++) option(k),
        verdict,
        if (_last && answered)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('$_right din $n corecte', textAlign: TextAlign.right, style: TextStyle(fontSize: 13.5, color: muted)),
          ),
        const SizedBox(height: 14),
        buttons,
      ],
    );

    return Container(
      decoration: clean
          ? BoxDecoration(
              color: Pb.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Pb.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12))],
            )
          : BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border, width: 3),
              boxShadow: AppStyle.hardShadow(6),
            ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: KeyedSubtree(key: ValueKey(_i), child: body),
      ),
    );
  }
}
