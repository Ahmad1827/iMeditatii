import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'classes_models.dart' show Classes;
import 'clean_kit.dart';
import 'exercise_list_screen.dart' show ExerciseListScreen;
import 'ui_components.dart' show Pb, PbButton, PbSize;

// =============================================================================
// Pregătirea pentru BAC: every chapter the exam covers, and how far the student
// is in each. The chapters are those of assets/data/exercises.json, grades
// IX–XII, without the olympiad and the extra practice.
// =============================================================================

enum BacStatus { notStarted, started, covered }

class BacTopic {
  final String subject;
  final String grade;
  final String chapter; // as in exercises.json: "3. Recursivitate"
  final List<String> ids;
  const BacTopic({required this.subject, required this.grade, required this.chapter, required this.ids});

  /// Problems to solve before the chapter counts as covered.
  static const int goal = 3;

  String get name => chapter.replaceFirst(RegExp(r'^\d+\.\s*'), '');

  int get target => ids.length < goal ? ids.length : goal;

  /// Solved problems of the chapter; [solved] holds progress keys ("<materie>_<clasa>_<id>").
  int solvedIn(Set<String> solved) => ids.where((id) => solved.contains('${subject}_${grade}_$id')).length;

  BacStatus status(Set<String> solved) {
    final n = solvedIn(solved);
    if (n == 0) return BacStatus.notStarted;
    return n >= target ? BacStatus.covered : BacStatus.started;
  }

  String get path => '/lista-exercitii?materie=${Uri.encodeComponent(subject)}'
      '&clasa=${Uri.encodeComponent(grade)}&capitol=${Uri.encodeComponent(chapter)}';
}

class Bac {
  static const List<String> subjects = ['Informatică', 'Matematică'];

  static bool _counts(String chapter) {
    final l = chapter.toLowerCase();
    return !l.contains('olimpiad') && !l.contains('suplimentar');
  }

  /// The BAC chapters of [subject], by grade and then in the order of the chapters.
  static List<BacTopic> topics(Map<String, dynamic> exercises, String subject) {
    final grades = (exercises[subject] as Map<String, dynamic>?) ?? const {};
    final keys = grades.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 99).compareTo(int.tryParse(b) ?? 99));
    return [
      for (final g in keys)
        for (final e in (grades[g] as Map<String, dynamic>).entries)
          if (_counts(e.key) && (e.value as List).isNotEmpty)
            BacTopic(subject: subject, grade: g, chapter: e.key, ids: [for (final p in e.value as List) '${p['id']}']),
    ];
  }

  /// The first chapter not yet covered: the one to work on next.
  static BacTopic? next(List<BacTopic> topics, Set<String> solved) {
    for (final t in topics) {
      if (t.status(solved) == BacStatus.started) return t;
    }
    for (final t in topics) {
      if (t.status(solved) != BacStatus.covered) return t;
    }
    return null;
  }

  static String roman(String grade) => const {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'}[grade] ?? grade;
}

/// The dashboard card: chapters as chips, grouped by grade, and the next one to do.
class BacProgressCard extends StatefulWidget {
  final String uid;
  const BacProgressCard({super.key, required this.uid});

  @override
  State<BacProgressCard> createState() => _BacProgressCardState();
}

class _BacProgressCardState extends State<BacProgressCard> {
  static const Color _amber = Color(0xFFF59E0B);
  static const String _subjectKey = 'bac_progress_subject';

  Map<String, dynamic>? _exercises;
  String _subject = Bac.subjects.first;
  Set<String> _local = {}; // marked solved on this device
  Set<String> _account = {}; // users/{uid}.solvedIds, which also counts maths checked by a teacher
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = Classes.solvedBy(widget.uid).listen((s) {
      if (mounted) setState(() => _account = s);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = json.decode(await rootBundle.loadString('assets/data/exercises.json')) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_subjectKey) ?? prefs.getString(ExerciseListScreen.lastSubjectKey);
      if (!mounted) return;
      setState(() {
        _exercises = data;
        _local = prefs.getKeys().where((k) => prefs.get(k) == true).toSet();
        if (Bac.subjects.contains(saved)) _subject = saved!;
      });
    } catch (e) {
      debugPrint('BAC: $e');
    }
  }

  void _pick(String subject) {
    setState(() => _subject = subject);
    SharedPreferences.getInstance().then((p) => p.setString(_subjectKey, subject));
  }

  @override
  Widget build(BuildContext context) {
    final data = _exercises;
    final solved = {..._local, ..._account};
    final topics = data == null ? const <BacTopic>[] : Bac.topics(data, _subject);
    final covered = topics.where((t) => t.status(solved) == BacStatus.covered).length;
    final next = Bac.next(topics, solved);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ckCardTitle(Icons.flag_outlined, 'Pregătirea pentru BAC', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final s in Bac.subjects) Padding(padding: const EdgeInsets.only(left: 6), child: _subjectChip(s)),
          ])),
          if (data == null)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)))
          else ...[
            Row(
              children: [
                Text('$covered', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Pb.text, height: 1)),
                Text(' din ${topics.length} capitole acoperite', style: TextStyle(fontSize: 14, color: Pb.muted)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: topics.isEmpty ? 0 : covered / topics.length),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, color: ckSubjectColor(_subject), backgroundColor: Pb.gray),
              ),
            ),
            const SizedBox(height: 6),
            Text('Un capitol e acoperit când ai rezolvat ${BacTopic.goal} probleme din el.', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            for (final g in {for (final t in topics) t.grade}) ...[
              const SizedBox(height: 14),
              Text('Clasa a ${Bac.roman(g)}-a', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final t in topics.where((t) => t.grade == g)) _topicChip(t, solved)],
              ),
            ],
            const SizedBox(height: 16),
            if (next == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
                child: Text('Ai acoperit toate capitolele. Continuă cu subiectele de BAC rămase.',
                    style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45)),
              )
            else
              PbButton(
                text: 'Următorul: ${next.name}',
                icon: Icons.arrow_forward,
                size: PbSize.sm,
                fullWidth: true,
                onPressed: () => context.go(next.path),
              ),
          ],
        ],
      ),
    );
  }

  Widget _subjectChip(String s) {
    final sel = s == _subject;
    final c = ckSubjectColor(s);
    return CkHover(
      onTap: () => _pick(s),
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? c.withOpacity(0.12) : (hover ? Pb.hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: sel ? c.withOpacity(0.5) : Pb.border),
        ),
        child: Text(s == 'Informatică' ? 'Info' : 'Mate',
            style: TextStyle(fontSize: 12.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? c : Pb.muted)),
      ),
    );
  }

  Widget _topicChip(BacTopic t, Set<String> solved) {
    final status = t.status(solved);
    final n = t.solvedIn(solved);
    final (icon, color) = switch (status) {
      BacStatus.covered => (Icons.check_circle, Pb.primary),
      BacStatus.started => (Icons.timelapse, _amber),
      BacStatus.notStarted => (Icons.radio_button_unchecked, Pb.muted),
    };
    return Tooltip(
      message: '$n din ${t.ids.length} probleme rezolvate',
      child: CkHover(
        onTap: () => context.go(t.path),
        builder: (hover) => Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
          decoration: BoxDecoration(
            color: hover ? Pb.hoverBg : (status == BacStatus.notStarted ? Colors.transparent : color.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: status == BacStatus.notStarted ? Pb.border : color.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(child: Text(t.name, style: TextStyle(fontSize: 13, color: Pb.text))),
              const SizedBox(width: 6),
              Text(status == BacStatus.covered ? '$n' : '$n/${t.target}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status == BacStatus.notStarted ? Pb.muted : color)),
            ],
          ),
        ),
      ),
    );
  }
}
