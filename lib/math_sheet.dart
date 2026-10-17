import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'classes_models.dart';
import 'ink_page.dart';
import 'ui_components.dart';
import 'workspace_screen.dart' show wsAgo;

// =============================================================================
// MATHS ON A SHEET
//   A maths problem isn't answered with a choice or a number: the student
//   writes the whole solution on a sheet (an ink page, like OneNote) and sends
//   it. A person checks it: the admin in the dashboard, or a teacher whose
//   homework has the problem, from the student's desk. Accepted, it counts as
//   solved; turned down, the student reads why, fixes the sheet and sends it again.
// =============================================================================

/// Maths problems are solved on a sheet.
bool isMathSubject(String subject) => subject.trim().toLowerCase().startsWith('mate');

/// The reviewer's reason as quoted in a sentence: without its own full stop.
String _quoted(String note) => '„${note.trim().replaceAll(RegExp(r'[.!]+$'), '')}”';

/// The longest sheet that can be sent (a Firestore document holds 1 MB).
const int sheetMaxLength = 400000;

/// Where a reviewer's answer key comes from: [loadExercise]; tests swap it.
Future<Map<String, dynamic>?> Function(String subject, String grade, String id) exerciseSource = loadExercise;

/// A problem by subject, grade and id: those that come with the app, then Firestore.
Future<Map<String, dynamic>?> loadExercise(String subject, String grade, String id) async {
  try {
    final data = json.decode(await rootBundle.loadString('assets/data/exercise_details.json'));
    final e = data[subject]?[grade]?[id];
    if (e is Map) return Map<String, dynamic>.from(e);
  } catch (_) {}
  try {
    final d = await FirebaseFirestore.instance.collection('exercises').doc(id).get();
    if (d.exists) return d.data();
  } catch (_) {}
  return null;
}

// ---------------------------------------------------------------- the student
/// Where the student writes their solution and sends it to be checked, with
/// what became of the last one they sent.
class MathSheetPanel extends StatefulWidget {
  final HwProblem problem;
  final bool fill; // take the height it's given (beside the statement) instead of a fixed one
  final VoidCallback? onAccepted;
  final String? uid; // who's writing; the signed-in user when null
  const MathSheetPanel({super.key, required this.problem, this.fill = false, this.onAccepted, this.uid});

  @override
  State<MathSheetPanel> createState() => _MathSheetPanelState();
}

class _MathSheetPanelState extends State<MathSheetPanel> {
  late final String? _uid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _sent =
      _uid == null ? null : Classes.solutions.doc(Classes.solutionId(_uid, widget.problem.progressKey)).snapshots();
  final InkPageHandle _ink = InkPageHandle();
  String? _initial; // what the sheet opened with: the last one sent
  bool _dirty = false; // written on since it was sent
  bool _sending = false;
  bool _wasAccepted = false;

  Future<void> _send() async {
    final uid = _uid;
    final sheet = _ink.read();
    if (uid == null || sheet == null || _ink.isEmpty) return;
    setState(() => _sending = true);
    try {
      final name = await Classes.userName(uid).catchError((_) => 'Elev');
      await Classes.saveSheet(uid: uid, studentName: name, problem: widget.problem, sheet: sheet);
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
        content: Text('Trimisă la verificare. Vezi aici răspunsul când e gata.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Nu am putut trimite foaia: $e'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Pb.border.withOpacity(0.7)));
    if (_uid == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rezolvarea ta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
            const SizedBox(height: 6),
            Text('Intră în cont ca să scrii rezolvarea pe foaie și s-o trimiți la verificare.', style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.4)),
            const SizedBox(height: 14),
            PbButton(text: 'Autentificare', onPressed: () => context.go('/login')),
          ],
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sent,
      builder: (context, snap) {
        if (!snap.hasData && !snap.hasError) {
          return Container(height: 200, decoration: card, alignment: Alignment.center, child: const CircularProgressIndicator(color: Pb.primary));
        }
        final data = snap.data?.data();
        final s = data == null ? null : Solution.fromJson(data);
        final sheet = s != null && s.isSheet ? s : null;
        _initial ??= sheet?.last ?? '';
        if (sheet != null && sheet.approved && !_wasAccepted) {
          _wasAccepted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onAccepted?.call());
        }
        final isMobile = MediaQuery.of(context).size.width < 700;
        final page = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: Pb.border)),
            child: InkPage(
              initialContent: _initial!,
              handle: _ink,
              onDirty: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              compact: isMobile,
              maxLength: sheetMaxLength,
            ),
          ),
        );
        final canSend = !_sending && (_dirty || sheet == null);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Text('Rezolvarea ta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(height: 4),
              Text(
                'Scrie pe foaie ca la tablă: pașii, calculele și răspunsul. Apoi trimite-o: un profesor o verifică.',
                style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4),
              ),
              if (sheet != null) ...[const SizedBox(height: 12), _status(sheet)],
              const SizedBox(height: 12),
              if (widget.fill) Expanded(child: page) else SizedBox(height: isMobile ? 480 : 560, child: page),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dirty && sheet != null ? 'Ai modificat foaia de când ai trimis-o.' : '',
                      style: TextStyle(fontSize: 13, color: Pb.muted),
                    ),
                  ),
                  PbButton(
                    text: sheet == null ? 'Trimite la verificare' : 'Trimite din nou',
                    icon: Icons.send_outlined,
                    variant: PbVariant.success,
                    loading: _sending,
                    onPressed: canSend ? _send : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _status(Solution s) {
    final by = s.reviewedName.isEmpty ? '' : ' de ${s.reviewedName}';
    if (s.approved) {
      return PbAlert(type: PbAlertType.success, icon: Icons.check_circle_outline, text: 'Acceptată$by. Problema e rezolvată.');
    }
    if (s.rejected) {
      return PbAlert(
        type: PbAlertType.danger,
        icon: Icons.edit_note,
        text: 'Nu e acceptată încă$by${s.reviewNote.isEmpty ? '' : ': ${_quoted(s.reviewNote)}'}. Corectează pe foaie și trimite din nou.',
      );
    }
    return PbAlert(type: PbAlertType.info, icon: Icons.hourglass_top_rounded, text: 'Trimisă ${wsAgo(s.lastAt)}. Așteaptă verificarea.');
  }
}

// ---------------------------------------------------------------- the reviewer
/// One sheet to check: what the student wrote, the answer key, and the green light or not.
class SheetReviewCard extends StatefulWidget {
  final Solution solution;
  final String reviewerId;
  final String reviewerName;
  final double sheetHeight;
  final bool showStudent; // the admin's queue: whose it is and which problem
  final VoidCallback? onDecided;
  const SheetReviewCard({
    super.key,
    required this.solution,
    required this.reviewerId,
    required this.reviewerName,
    this.sheetHeight = 420,
    this.showStudent = true,
    this.onDecided,
  });

  @override
  State<SheetReviewCard> createState() => _SheetReviewCardState();
}

class _SheetReviewCardState extends State<SheetReviewCard> {
  late final HwProblem? _p = widget.solution.exercise;
  late final Future<Map<String, dynamic>?> _key = _p == null ? Future.value(null) : exerciseSource(_p.subject, _p.grade, _p.id);
  bool _busy = false;

  Future<void> _decide(bool accept) async {
    var note = '';
    if (!accept) {
      final ctl = TextEditingController();
      final ok = await showPbModal<bool>(
        context,
        title: 'Ce trebuie corectat?',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Elevul vede motivul pe pagina problemei și poate trimite din nou.', style: TextStyle(fontSize: 14, color: Pb.muted)),
            const SizedBox(height: 12),
            TextField(controller: ctl, autofocus: true, maxLines: 3, decoration: Pb.input(hint: 'ex. Ai greșit semnul la pasul 2.')),
          ],
        ),
        actions: (d) => [
          PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(d).pop(false)),
          PbButton(text: 'Respinge', variant: PbVariant.danger, onPressed: () => Navigator.of(d).pop(true)),
        ],
      );
      if (ok != true) return;
      note = ctl.text;
    }
    setState(() => _busy = true);
    try {
      await Classes.reviewSheet(
        uid: widget.solution.uid,
        key: widget.solution.key,
        accept: accept,
        note: note,
        reviewerId: widget.reviewerId,
        reviewerName: widget.reviewerName,
      );
      widget.onDecided?.call();
    } catch (e) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Nu am putut salva decizia: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solution;
    final p = _p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showStudent) ...[
          Text('${s.studentName.isEmpty ? 'Elev' : s.studentName} · ${p?.title ?? s.key}',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text)),
          const SizedBox(height: 2),
          Text('${p == null ? '' : '${p.subject}, a ${p.grade}-a · '}trimisă ${wsAgo(s.lastAt)}', style: TextStyle(fontSize: 13, color: Pb.muted)),
          const SizedBox(height: 10),
        ],
        if (!s.pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PbAlert(
              type: s.approved ? PbAlertType.success : PbAlertType.danger,
              text: s.approved
                  ? 'Acceptată de ${s.reviewedName}.'
                  : 'Respinsă de ${s.reviewedName}${s.reviewNote.isEmpty ? '' : ': ${_quoted(s.reviewNote)}'}.',
            ),
          ),
        SizedBox(
          height: widget.sheetHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: Pb.border)),
              child: InkPage(key: ValueKey('${s.uid}${s.key}${s.lastAt}'), initialContent: s.last, readOnly: true, compact: true),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // the answer key, for the reviewer only
        FutureBuilder<Map<String, dynamic>?>(
          future: _key,
          builder: (context, k) {
            final e = k.data;
            final answer = e?['raspuns_corect']?.toString();
            final worked = e?['solutie']?.toString();
            if (answer == null && worked == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (answer != null && answer.isNotEmpty)
                    Text('Răspunsul corect: $answer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text)),
                  if (worked != null && worked.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(worked, style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45)),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (p != null) PbButton(text: 'Problema', variant: PbVariant.link, size: PbSize.sm, onPressed: () => GoRouter.of(context).push(p.path)),
            PbButton(text: s.rejected ? 'Respinsă' : 'Respinge', icon: Icons.close, variant: PbVariant.outlineDanger, size: PbSize.sm, onPressed: _busy ? null : () => _decide(false)),
            PbButton(text: s.approved ? 'Acceptată' : 'Acceptă', icon: Icons.check, variant: PbVariant.success, size: PbSize.sm, loading: _busy, onPressed: _busy ? null : () => _decide(true)),
          ],
        ),
      ],
    );
  }
}

/// The admin's queue of sheets waiting to be checked.
class SheetReviewQueue extends StatefulWidget {
  final String? reviewerId; // the signed-in user when null
  const SheetReviewQueue({super.key, this.reviewerId});

  @override
  State<SheetReviewQueue> createState() => _SheetReviewQueueState();
}

class _SheetReviewQueueState extends State<SheetReviewQueue> {
  late final String _uid = widget.reviewerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<Solution>> _queue = Classes.pendingSheets();
  late final Future<String> _name = Classes.userName(_uid).catchError((_) => 'Administrator');

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _name,
        builder: (context, name) => StreamBuilder<List<Solution>>(
          stream: _queue,
          builder: (context, q) {
            if (!q.hasData && !q.hasError) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Pb.primary)));
            final list = q.data ?? const <Solution>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text('Nicio rezolvare de verificat.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in list)
                  Container(
                    key: ValueKey('${s.uid}${s.key}'),
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Pb.border)),
                    child: SheetReviewCard(solution: s, reviewerId: _uid, reviewerName: name.data ?? 'Administrator'),
                  ),
              ],
            );
          },
        ),
      );
}

/// How many sheets wait to be checked, for a counter on the dashboard.
Stream<int> pendingSheetCount() => Classes.pendingSheets().map((l) => l.length);
