import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'classes_models.dart';
import 'ink_page.dart';
import 'statement_text.dart';
import 'ui_components.dart';
import 'workspace_screen.dart' show wsAgo;

// =============================================================================
// MATHS ON A SHEET
//   A maths problem isn't answered with a choice or a number: the student
//   writes the whole solution on a sheet (an ink page, like OneNote), or on
//   paper and adds pictures of it, and sends it. A person checks it: the admin in the dashboard, or a teacher whose
//   homework has the problem, from the student's desk. Accepted, it counts as
//   solved; turned down, the student reads why, fixes the sheet and sends it again.
// =============================================================================

/// Maths problems are solved on a sheet.
bool isMathSubject(String subject) => subject.trim().toLowerCase().startsWith('mate');

/// The reviewer's reason as quoted in a sentence: without its own full stop.
String _quoted(String note) => '„${note.trim().replaceAll(RegExp(r'[.!]+$'), '')}”';

/// The longest sheet that can be sent (a Firestore document holds 1 MB).
const int sheetMaxLength = 400000;

/// The most pictures one solution can have.
const int sheetMaxPhotos = 6;

/// Where a picture of a solution goes: [uploadSolutionPhoto]; tests swap it.
Future<String> Function(String uid, String key, Uint8List bytes) photoUploader = uploadSolutionPhoto;

/// Stores a picture of [uid]'s solution to [key] and gives back its link.
Future<String> uploadSolutionPhoto(String uid, String key, Uint8List bytes) async {
  final ref = FirebaseStorage.instance.ref('solution_photos/$uid/${key.replaceAll('/', '_')}/${DateTime.now().millisecondsSinceEpoch}.jpg');
  await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
  return ref.getDownloadURL();
}

/// A picture of a solution, full screen, to zoom in on.
void showSolutionPhoto(BuildContext context, String url) => showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(maxScale: 5, child: Center(child: Image.network(url, fit: BoxFit.contain))),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Închide',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(d).pop(),
              ),
            ),
          ],
        ),
      ),
    );

/// A row of pictures of a solution; tap one to see it big. With [onRemove]
/// (the student, before sending), each has an × to take it out.
class SolutionPhotos extends StatelessWidget {
  final List<String> photos;
  final double size;
  final void Function(String url)? onRemove;
  const SolutionPhotos({super.key, required this.photos, this.size = 96, this.onRemove});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, url) in photos.indexed)
            Semantics(
              button: true,
              label: 'Poza ${i + 1}',
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => showSolutionPhoto(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(color: Pb.hoverBg, border: Border.all(color: Pb.border)),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, color: Pb.muted),
                        ),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => onRemove!(url),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
}

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
  InkPageHandle _ink = InkPageHandle();
  String? _initial; // what the sheet opened with: the last one sent, or what was written in the big view
  int _page = 0; // bumped to rebuild the sheet with [_initial]
  bool _dirty = false; // written on since it was sent
  bool _sending = false;
  bool _wasAccepted = false;
  List<String>? _photos; // the pictures to send: those last sent, then as the student adds and removes them
  bool _uploading = false;

  Future<void> _addPhotos(ImageSource source) async {
    final uid = _uid;
    final room = sheetMaxPhotos - (_photos?.length ?? 0);
    if (uid == null || room <= 0) return;
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = source == ImageSource.camera
          ? [if (await picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 80) case final x?) x]
          : await picker.pickMultiImage(maxWidth: 2000, maxHeight: 2000, imageQuality: 80);
    } catch (_) {
      picked = const [];
    }
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    try {
      for (final x in picked.take(room)) {
        final url = await photoUploader(uid, widget.problem.progressKey, await x.readAsBytes());
        if (!mounted) return;
        setState(() {
          _photos = [...?_photos, url];
          _dirty = true;
        });
      }
      if (picked.length > room && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text('Poți adăuga cel mult $sheetMaxPhotos poze.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Nu am putut încărca poza: $e'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// The sheet big, in the middle of the screen. What's written there comes
  /// back to the small one; it can be sent from there too.
  Future<void> _enlarge() async {
    final big = InkPageHandle();
    final start = _ink.read() ?? _initial ?? '';
    final send = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (d) {
        final narrow = MediaQuery.of(d).size.width < 700;
        return Dialog(
          insetPadding: EdgeInsets.all(narrow ? 0 : 24),
          backgroundColor: Pb.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(narrow ? 0 : 16)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(narrow ? 10 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.problem.title.isEmpty ? 'Rezolvarea ta' : widget.problem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PbButton(
                      text: 'Micșorează',
                      icon: Icons.close_fullscreen,
                      variant: PbVariant.secondary,
                      size: PbSize.sm,
                      onPressed: () => Navigator.of(d).pop(false),
                    ),
                    const SizedBox(width: 8),
                    PbButton(
                      text: 'Trimite',
                      icon: Icons.send_outlined,
                      variant: PbVariant.success,
                      size: PbSize.sm,
                      onPressed: () => Navigator.of(d).pop(true),
                    ),
                  ],
                ),
                SizedBox(height: narrow ? 8 : 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(border: Border.all(color: Pb.border)),
                      child: InkPage(
                        initialContent: start,
                        handle: big,
                        onDirty: () {
                          if (!_dirty && mounted) setState(() => _dirty = true);
                        },
                        compact: narrow,
                        maxLength: sheetMaxLength,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    // the small sheet starts again from what was written big, with its own handle
    // (the old page, going away, leaves its last state on the old one)
    setState(() {
      _initial = big.read() ?? start;
      _ink = InkPageHandle();
      _page++;
    });
    if (send == true) await _send(from: big);
  }

  Future<void> _send({InkPageHandle? from}) async {
    final uid = _uid;
    final ink = from ?? _ink;
    final photos = _photos ?? const <String>[];
    final sheet = ink.isEmpty ? '' : ink.read();
    if (uid == null || sheet == null || (sheet.isEmpty && photos.isEmpty)) return;
    setState(() => _sending = true);
    try {
      final name = await Classes.userName(uid).catchError((_) => 'Elev');
      await Classes.saveSheet(uid: uid, studentName: name, problem: widget.problem, sheet: sheet, photos: photos);
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
        _photos ??= [...?sheet?.photos];
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
              key: ValueKey(_page),
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
        final canSend = !_sending && !_uploading && (_dirty || sheet == null);
        final photos = _photos!;
        final full = photos.length >= sheetMaxPhotos;
        final paper = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photos.isNotEmpty) ...[
              SolutionPhotos(
                photos: photos,
                size: isMobile ? 80 : 96,
                onRemove: _sending
                    ? null
                    : (url) => setState(() {
                          _photos = [...photos]..remove(url);
                          _dirty = true;
                        }),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PbButton(
                  text: 'Fă o poză',
                  icon: Icons.photo_camera_outlined,
                  variant: PbVariant.secondary,
                  size: PbSize.sm,
                  onPressed: _uploading || full ? null : () => _addPhotos(ImageSource.camera),
                ),
                PbButton(
                  text: 'Din galerie',
                  icon: Icons.photo_library_outlined,
                  variant: PbVariant.secondary,
                  size: PbSize.sm,
                  loading: _uploading,
                  onPressed: _uploading || full ? null : () => _addPhotos(ImageSource.gallery),
                ),
                Text(
                  photos.isEmpty ? 'Ai rezolvat pe hârtie? Adaugă poze cu foaia.' : '${photos.length} / $sheetMaxPhotos poze',
                  style: TextStyle(fontSize: 13, color: Pb.muted),
                ),
              ],
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Rezolvarea ta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text))),
                  PbButton(
                    text: 'Mărește foaia',
                    icon: Icons.open_in_full,
                    variant: PbVariant.secondary,
                    size: PbSize.sm,
                    onPressed: _sending ? null : _enlarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Scrie pe foaie ca la tablă: pașii, calculele și răspunsul, sau rezolvă pe hârtie și adaugă poze. Apoi trimite: un profesor verifică.',
                style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4),
              ),
              if (sheet != null) ...[const SizedBox(height: 12), _status(sheet)],
              const SizedBox(height: 12),
              if (widget.fill) Expanded(child: page) else SizedBox(height: isMobile ? 480 : 560, child: page),
              const SizedBox(height: 12),
              paper,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dirty && sheet != null ? 'Ai modificat rezolvarea de când ai trimis-o.' : '',
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

  Widget _status(Solution s) => sheetStatus(s);
}

/// What became of a solution the student sent: waiting, accepted, or turned down and why.
Widget sheetStatus(Solution s) {
  final by = s.reviewedName.isEmpty ? '' : ' de ${s.reviewedName}';
  if (s.approved) {
    return PbAlert(type: PbAlertType.success, icon: Icons.check_circle_outline, text: 'Acceptată$by. Problema e rezolvată.');
  }
  if (s.rejected) {
    return PbAlert(
      type: PbAlertType.danger,
      icon: Icons.edit_note,
      text: 'Respinsă$by${s.reviewNote.isEmpty ? '' : ': ${_quoted(s.reviewNote)}'}. Corectează și trimite din nou.',
    );
  }
  return PbAlert(type: PbAlertType.info, icon: Icons.hourglass_top_rounded, text: 'Trimisă ${wsAgo(s.lastAt)}. Așteaptă verificarea.');
}

/// The student's own view of what they sent: its status, the sheet and the pictures.
class SheetSubmission extends StatelessWidget {
  final Solution solution;
  const SheetSubmission({super.key, required this.solution});

  @override
  Widget build(BuildContext context) {
    final s = solution;
    String when(DateTime? d) => d == null ? '' : '${d.day}.${d.month}.${d.year}, ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        sheetStatus(s),
        const SizedBox(height: 10),
        Text(
          [
            if (s.lastAt != null) 'Trimisă ${when(s.lastAt)}',
            if (!s.pending && s.reviewedAt != null) 'verificată ${when(s.reviewedAt)}',
          ].join(' · '),
          style: TextStyle(fontSize: 13, color: Pb.muted),
        ),
        if (s.last.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: Pb.border)),
                child: InkPage(key: ValueKey('${s.key}${s.lastAt}'), initialContent: s.last, readOnly: true, compact: true),
              ),
            ),
          ),
        ],
        if (s.photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SolutionPhotos(photos: s.photos),
        ],
      ],
    );
  }
}

/// Every solution the student sent on a problem, newest first: the newest
/// open, the older ones a line each that opens on a tap. [current] stands in
/// for the history when there is none yet (sent before attempts were kept).
class SheetHistory extends StatefulWidget {
  final String uid;
  final String problemKey;
  final Solution? current;
  const SheetHistory({super.key, required this.uid, required this.problemKey, this.current});

  @override
  State<SheetHistory> createState() => _SheetHistoryState();
}

class _SheetHistoryState extends State<SheetHistory> {
  late final Stream<List<Solution>> _attempts = Classes.attempts(widget.uid, widget.problemKey);
  final Set<int> _open = {}; // by attempt number

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Solution>>(
        stream: _attempts,
        builder: (context, snap) {
          var list = snap.data ?? const <Solution>[];
          if (list.isEmpty && widget.current != null) list = [widget.current!];
          if (list.isEmpty) {
            if (!snap.hasData && !snap.hasError) return const Center(child: CircularProgressIndicator(color: Pb.primary));
            return Text('Nu ai trimis încă o rezolvare.', style: TextStyle(fontSize: 14.5, color: Pb.muted));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, a) in list.indexed) _attempt(list.length - i, a, newest: i == 0),
            ],
          );
        },
      );

  Widget _attempt(int n, Solution a, {required bool newest}) {
    final open = newest || _open.contains(n);
    final (label, color) = a.approved
        ? ('Acceptată', Pb.success)
        : a.rejected
            ? ('Respinsă', Pb.danger)
            : ('La verificare', const Color(0xFFB45309));
    final head = Row(
      children: [
        Text('Încercarea $n', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Pb.text)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const Spacer(),
        Text(wsAgo(a.lastAt), style: TextStyle(fontSize: 12.5, color: Pb.muted)),
        if (!newest) ...[
          const SizedBox(width: 6),
          Icon(open ? Icons.expand_less : Icons.expand_more, size: 18, color: Pb.muted),
        ],
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: newest ? color.withOpacity(0.5) : Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (newest)
            head
          else
            InkWell(
              onTap: () => setState(() => open ? _open.remove(n) : _open.add(n)),
              child: head,
            ),
          if (open) ...[const SizedBox(height: 10), SheetSubmission(solution: a)],
        ],
      ),
    );
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
        if (s.last.isNotEmpty) ...[
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
        ],
        if (s.photos.isNotEmpty) ...[
          Text('Poze cu rezolvarea (apasă ca să mărești)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.muted)),
          const SizedBox(height: 6),
          SolutionPhotos(photos: s.photos, size: 120),
          const SizedBox(height: 10),
        ],
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
                    StatementText('**Răspunsul corect:** $answer', fontSize: 14, height: 1.45),
                  if (worked != null && worked.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    StatementText(worked, fontSize: 13.5, color: Pb.muted, height: 1.45),
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
