import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'classroom_kit.dart';
import 'clean_kit.dart';
import 'classes_models.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'homework_composer.dart';
import 'homework_dock.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer, showPbModal;
import 'workspace_models.dart';
import 'workspace_screen.dart' show wsAgo, wsDialogShell, wsDocColor;
import 'home_ambient.dart' show HomeSky;

part 'classroom_scene.dart';

// =============================================================================
// CLASSES
//   /clase         teacher: their classes + homework given, with progress
//                  student: their homework + the classes they are in
//   /clasa/:code   the invite link. Logged out: what the class is + sign up /
//                  log in (they come back here and join). Student: joins and
//                  sees the class's homework. Owner: manage the class.
// =============================================================================

/// The public site, used for links when the app isn't running on the web.
const String _site = 'https://ahmad1827.github.io';

String classLink(String code) {
  final base = Uri.base;
  final origin = (base.scheme == 'http' || base.scheme == 'https') ? base.origin : _site;
  return '$origin/clasa/$code';
}

void _toast(BuildContext context, String m) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

Future<void> copyClassLink(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: classLink(code)));
  if (context.mounted) _toast(context, 'Linkul a fost copiat. Trimite-l elevilor.');
}

Future<void> shareClassOnWhatsApp(SchoolClass c) => launchUrl(
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Intră în clasa „${c.displayName}” pe iMeditații: ${classLink(c.id)}')}'),
      mode: LaunchMode.externalApplication,
    );

/// The classes pages are a classroom on the site's meadow.
Widget _shell(Widget child) => Scaffold(
      backgroundColor: Pb.page,
      body: Column(children: [const CustomNavbar(), Expanded(child: _Meadow(child: child))]),
    );

class _Meadow extends StatefulWidget {
  final Widget child;
  const _Meadow({required this.child});

  @override
  State<_Meadow> createState() => _MeadowState();
}

class _MeadowState extends State<_Meadow> {
  final _content = GlobalKey();

  @override
  Widget build(BuildContext context) => HomeSky(
        armies: false,
        blockers: [_content],
        child: KeyedSubtree(key: _content, child: widget.child),
      );
}

Widget _spinner() => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));

Widget _emptyBox(IconData icon, String title, String text, {Widget? action}) => Container(
      padding: const EdgeInsets.all(22),
      decoration: ckDeco(r: 16),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Pb.muted),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
          const SizedBox(height: 5),
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.5)),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );

/// Who a homework went to, by id: members of its classes plus direct picks.
Map<String, String> hwRecipients(Homework h, List<SchoolClass> classes) {
  final out = <String, String>{};
  for (final c in classes) {
    if (!h.classIds.contains(c.id)) continue;
    for (final m in c.members) {
      out[m.id] = m.name;
    }
  }
  for (final id in h.studentIds) {
    out.putIfAbsent(id, () => h.studentNames[id] ?? 'Elev');
  }
  return out;
}

// ----------------------------------------------------------------- /clase
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) => _shell(ClassesBody(uid: FirebaseAuth.instance.currentUser?.uid ?? ''));
}

class ClassesBody extends StatelessWidget {
  final String uid;
  const ClassesBody({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return PbContainer(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _emptyBox(
            Icons.lock_outline,
            'Intră în cont',
            'Clasele și temele sunt legate de contul tău.',
            action: PbButton(text: 'Autentificare', onPressed: () => context.go('/login')),
          ),
        ),
      );
    }
    return FutureBuilder<String?>(
      future: Classes.roleOf(uid),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _spinner();
        return ClassroomView(uid: uid, teacher: snap.data == 'teacher');
      },
    );
  }
}

// ----------------------------------------------------------------- teacher
/// A homework is still open while someone it went to hasn't finished it.
bool _hwOpen(Homework h, Map<String, String> r) => r.isEmpty || r.keys.any((id) => !h.isDone(id));

/// The homework a teacher gave, with tabs for open / finished by everyone and
/// grouped by deadline, like the student sees theirs.
class _TeacherHomeworkList extends StatefulWidget {
  final List<Homework> homework;
  final List<SchoolClass> classes;
  final bool showClass;
  final Widget empty;
  const _TeacherHomeworkList({required this.homework, required this.classes, required this.empty, this.showClass = true});

  @override
  State<_TeacherHomeworkList> createState() => _TeacherHomeworkListState();
}

class _TeacherHomeworkListState extends State<_TeacherHomeworkList> {
  int _tab = 0;
  String? _classFilter;

  @override
  Widget build(BuildContext context) {
    if (widget.homework.isEmpty) return widget.empty;

    final rec = {for (final h in widget.homework) h.id: hwRecipients(h, widget.classes)};
    bool pass(Homework h) => _classFilter == null || h.classIds.contains(_classFilter);
    final open = widget.homework.where((h) => _hwOpen(h, rec[h.id]!)).toList()..sort(_byDue);
    final closed = widget.homework.where((h) => !_hwOpen(h, rec[h.id]!)).toList()
      ..sort((a, b) => (b.dueAt ?? b.createdAt ?? DateTime(0)).compareTo(a.dueAt ?? a.createdAt ?? DateTime(0)));
    final withHw = widget.showClass ? widget.classes.where((c) => widget.homework.any((h) => h.classIds.contains(c.id))).toList() : const <SchoolClass>[];

    final children = <Widget>[];
    if (_tab == 0) {
      final shown = open.where(pass).toList();
      if (shown.isEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _emptyBox(Icons.celebration_outlined, 'Toți elevii au terminat', 'Temele terminate de toată lumea sunt la „Terminate de toți”.'),
        ));
      }
      var first = true;
      for (final g in _Due.values) {
        final items = shown.where((h) => _dueOf(h) == g).toList();
        if (items.isEmpty) continue;
        children.add(_groupLabel(_dueTitle(g), _dueGroupColor(g), items.length));
        for (final h in items) {
          children.add(HomeworkProgressTile(key: ValueKey('open_${h.id}'), homework: h, recipients: rec[h.id]!, showClass: widget.showClass, initiallyOpen: first));
          first = false;
        }
      }
    } else {
      final shown = closed.where(pass).toList();
      children.add(const SizedBox(height: 16));
      if (shown.isEmpty) {
        children.add(_emptyBox(Icons.hourglass_empty, 'Nicio temă terminată de toți', 'Când toți elevii apasă „Am terminat”, tema trece aici.'));
      }
      for (final h in shown) {
        children.add(HomeworkProgressTile(key: ValueKey('closed_${h.id}'), homework: h, recipients: rec[h.id]!, showClass: widget.showClass));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tabs([('Active', open.length), ('Terminate de toți', closed.length)], _tab, (i) => setState(() => _tab = i)),
        if (withHw.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip('Toate', _classFilter == null, () => setState(() => _classFilter = null)),
              for (final c in withHw)
                _filterChip(c.displayName, _classFilter == c.id, () => setState(() => _classFilter = _classFilter == c.id ? null : c.id), color: _classColor(c)),
            ],
          ),
        ],
        ...children,
      ],
    );
  }
}

Future<String?> showNewClassDialog(BuildContext context, String uid, String teacherName) => showDialog<String>(
      context: context,
      builder: (_) => _ClassNameDialog(uid: uid, teacherName: teacherName),
    );

class _ClassNameDialog extends StatefulWidget {
  final String uid;
  final String teacherName;
  final SchoolClass? existing;
  const _ClassNameDialog({required this.uid, required this.teacherName, this.existing});

  @override
  State<_ClassNameDialog> createState() => _ClassNameDialogState();
}

class _ClassNameDialogState extends State<_ClassNameDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _subject = TextEditingController(text: widget.existing?.subject ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Scrie un nume, de ex. „9B Mate” sau „Andrei, BAC”.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ex = widget.existing;
      if (ex != null) {
        await Classes.rename(ex.id, _name.text, _subject.text);
        if (mounted) Navigator.of(context).pop(ex.id);
      } else {
        final code = await Classes.create(teacherId: widget.uid, teacherName: widget.teacherName, name: _name.text, subject: _subject.text);
        if (mounted) Navigator.of(context).pop(code);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Nu am putut salva clasa. Încearcă din nou.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => wsDialogShell(
        title: widget.existing == null ? 'Clasă nouă' : 'Redenumește clasa',
        subtitle: widget.existing == null ? 'După ce o creezi primești linkul pentru elevi.' : null,
        maxWidth: 460,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                maxLength: 60,
                onSubmitted: (_) => _save(),
                style: TextStyle(fontSize: 15, color: Pb.text),
                cursorColor: Pb.primary,
                decoration: Pb.input(hint: 'Numele clasei').copyWith(counterText: ''),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subject,
                maxLength: 40,
                onSubmitted: (_) => _save(),
                style: TextStyle(fontSize: 15, color: Pb.text),
                cursorColor: Pb.primary,
                decoration: Pb.input(hint: 'Materia (opțional)').copyWith(counterText: ''),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontSize: 13.5, color: hwRed, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        actions: [
          PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(context).pop()),
          PbButton(text: widget.existing == null ? 'Creează clasa' : 'Salvează', loading: _busy, onPressed: _save),
        ],
      );
}

/// A homework as the teacher sees it: a calendar tile with the deadline, how
/// many finished, and when opened, each student with how far they got.
class HomeworkProgressTile extends StatefulWidget {
  final Homework homework;
  final Map<String, String> recipients;
  final bool showClass;
  final bool initiallyOpen;
  const HomeworkProgressTile({super.key, required this.homework, required this.recipients, this.showClass = true, this.initiallyOpen = false});

  @override
  State<HomeworkProgressTile> createState() => _HomeworkProgressTileState();
}

class _HomeworkProgressTileState extends State<HomeworkProgressTile> {
  late bool _open = widget.initiallyOpen;

  Homework get h => widget.homework;

  Future<void> _delete() async {
    final ok = await showPbModal<bool>(
      context,
      title: 'Ștergi tema?',
      body: Text('„${h.displayTitle}” dispare și de la elevi. Nu se poate anula.'),
      actions: (c) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(c).pop(false)),
        PbButton(text: 'Șterge', variant: PbVariant.danger, onPressed: () => Navigator.of(c).pop(true)),
      ],
    );
    if (ok == true) {
      Classes.deleteHomework(h.id).catchError((_) {
        if (mounted) _toast(context, 'Nu am putut șterge tema.');
      });
    }
  }

  Widget _dateTile(Color c, bool allDone) {
    final d = h.dueAt;
    return Container(
      width: 52,
      height: 56,
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: allDone
          ? const Icon(Icons.done_all_rounded, color: hwGreen, size: 24)
          : d == null
              ? Icon(Icons.event_available_outlined, color: c, size: 22)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_weekdayShort[d.weekday - 1], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c, letterSpacing: 0.6)),
                    Text('${d.day}', style: TextStyle(fontSize: 21, height: 1.1, fontWeight: FontWeight.w800, color: c)),
                  ],
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipients;
    final doneN = r.keys.where(h.isDone).length;
    final total = r.length;
    final allDone = total > 0 && doneN == total;
    final c = allDone ? hwGreen : hwDueColor(h);
    final to = widget.showClass ? h.audience : [for (final s in h.studentIds) h.studentNames[s] ?? 'Elev'].join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NotebookPaper(
      border: _open && !allDone ? c.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CkHover(
            onTap: () => setState(() => _open = !_open),
            builder: (hv) => Container(
              color: hv ? Pb.primary.withOpacity(0.04) : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Row(
                children: [
                  _dateTile(c, allDone),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.displayTitle,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text, height: 1.3)),
                        if (to.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('pentru $to', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Pb.muted)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                total == 0 ? 'încă niciun elev' : '$doneN din $total au terminat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: allDone ? hwGreen : Pb.text),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (total > 0)
                              SizedBox(
                                width: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: doneN / total,
                                    minHeight: 5,
                                    backgroundColor: Pb.gray,
                                    valueColor: const AlwaysStoppedAnimation(hwGreen),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (h.dueAt != null)
                              hwPill(h.overdue ? 'Termen trecut · ${hwDueLabel(h.dueAt!)}' : 'Termen: ${hwDueLabel(h.dueAt!)}', hwDueColor(h), icon: Icons.schedule)
                            else
                              hwPill('Fără termen', Pb.muted, icon: Icons.schedule),
                            if (h.problems.isNotEmpty) hwPill(h.problems.length == 1 ? '1 problemă' : '${h.problems.length} probleme', Pb.muted, icon: Icons.code),
                            if (h.material != null) hwPill('Fișă din Atelier', Pb.muted, icon: Icons.description_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(turns: _open ? 0.5 : 0, duration: const Duration(milliseconds: 180), child: Icon(Icons.expand_more, color: Pb.muted)),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open ? const SizedBox(width: double.infinity) : _details(r),
          ),
        ],
      ),
    ),
    );
  }

  Widget _label(String t, {String? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.5))),
            if (trailing != null) Text(trailing, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pb.muted)),
          ],
        ),
      );

  Widget _details(Map<String, String> r) {
    // Not done first, so the teacher sees who still has to do it.
    final ids = r.keys.toList()..sort((a, b) => (h.isDone(a) ? 1 : 0).compareTo(h.isDone(b) ? 1 : 0));
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border.withOpacity(0.7)))),
      padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width < 700 ? 16 : 90, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (h.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.format_quote_rounded, size: 18, color: Pb.muted)),
                  const SizedBox(width: 10),
                  Expanded(child: SelectableText(h.instructions.trim(), style: TextStyle(fontSize: 14, color: Pb.text, height: 1.5))),
                ],
              ),
            ),
          ],
          if (h.problems.isNotEmpty || h.material != null) ...[
            _label('PAȘII TEMEI'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < h.problems.length; i++)
                  CkHover(
                    onTap: () => GoRouter.of(context).push(h.problems[i].path),
                    builder: (hv) => hwPill('${i + 1}. ${h.problems[i].title.isEmpty ? h.problems[i].id : h.problems[i].title}', ckSubjectColor(h.problems[i].subject),
                        icon: ckSubjectIcon(h.problems[i].subject)),
                  ),
                if (h.material != null)
                  hwPill('${h.problems.length + 1}. ${h.material!.displayTitle}', wsDocColor(h.material!.type, h.material!.lang), icon: Icons.description_outlined),
              ],
            ),
          ],
          _label('ELEVI', trailing: r.isEmpty ? null : '${r.keys.where(h.isDone).length}/${r.length} au terminat'),
          if (r.isEmpty)
            Text('Clasa nu are încă elevi. Tema ajunge și la cei care intră mai târziu.', style: TextStyle(fontSize: 13.5, color: Pb.muted))
          else
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Pb.border)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < ids.length; i++) _StudentProgressRow(homework: h, id: ids[i], name: r[ids[i]]!, first: i == 0),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Dată ${wsAgo(h.createdAt)}', style: TextStyle(fontSize: 12.5, color: Pb.muted))),
              PbButton(text: 'Șterge', icon: Icons.delete_outline, size: PbSize.sm, variant: PbVariant.outlineDanger, onPressed: _delete),
            ],
          ),
        ],
      ),
    );
  }
}

/// One student in a homework: done or not, and how many of its problems they
/// solved so far.
class _StudentProgressRow extends StatefulWidget {
  final Homework homework;
  final String id;
  final String name;
  final bool first;
  const _StudentProgressRow({required this.homework, required this.id, required this.name, required this.first});

  @override
  State<_StudentProgressRow> createState() => _StudentProgressRowState();
}

class _StudentProgressRowState extends State<_StudentProgressRow> {
  late final Stream<Set<String>> _solved = Classes.solvedBy(widget.id);

  @override
  Widget build(BuildContext context) {
    final h = widget.homework;
    final done = h.isDone(widget.id);
    return Container(
      decoration: BoxDecoration(border: widget.first ? null : Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          CkAvatar(name: widget.name, image: '', size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PbLink(text: widget.name, fontSize: 14, onTap: () => context.go('/elev/${widget.id}')),
                if (h.problems.isNotEmpty)
                  StreamBuilder<Set<String>>(
                    stream: _solved,
                    builder: (context, s) {
                      final n = h.problems.where((p) => (s.data ?? const <String>{}).contains(p.progressKey)).length;
                      return Text('$n/${h.problems.length} probleme rezolvate', style: TextStyle(fontSize: 12, color: Pb.muted));
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            hwPill(h.done[widget.id] == null ? 'Terminată' : 'Terminată ${wsAgo(h.done[widget.id])}', hwGreen, icon: Icons.check)
          else if (h.overdue)
            hwPill('Întârziată', hwRed, icon: Icons.error_outline)
          else
            hwPill('În lucru', hwAmber, icon: Icons.schedule),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- student
const _weekdayShort = ['LUN', 'MAR', 'MIE', 'JOI', 'VIN', 'SÂM', 'DUM'];

/// Groups of homework by how soon it is due, in the order they are shown.
enum _Due { late, today, tomorrow, week, later, none }

_Due _dueOf(Homework h) {
  final d = h.dueAt;
  if (d == null) return _Due.none;
  final now = DateTime.now();
  if (d.isBefore(now)) return _Due.late;
  final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days == 0) return _Due.today;
  if (days == 1) return _Due.tomorrow;
  if (days < 7) return _Due.week;
  return _Due.later;
}

String _dueTitle(_Due d) => const {
      _Due.late: 'Termen depășit',
      _Due.today: 'Azi',
      _Due.tomorrow: 'Mâine',
      _Due.week: 'Săptămâna aceasta',
      _Due.later: 'Mai târziu',
      _Due.none: 'Fără termen',
    }[d]!;

Color _dueGroupColor(_Due d) => switch (d) {
      _Due.late || _Due.today => hwRed,
      _Due.tomorrow => hwAmber,
      _Due.week || _Due.later => hwBlue,
      _Due.none => Pb.muted,
    };

int _byDue(Homework a, Homework b) {
  if (a.dueAt == null && b.dueAt == null) return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
  if (a.dueAt == null) return 1;
  if (b.dueAt == null) return -1;
  return a.dueAt!.compareTo(b.dueAt!);
}

int _byDoneAt(Homework a, Homework b, String uid) => (b.done[uid] ?? DateTime(0)).compareTo(a.done[uid] ?? DateTime(0));

Widget _groupLabel(String text, Color c, int n) => paperLabel(text, dot: c, count: '$n');

/// One homework, as the student sees it in a list: a calendar tile with the
/// due date, the title and progress, and the steps when opened.
class StudentHomeworkCard extends StatefulWidget {
  final Homework homework;
  final String uid;
  final Set<String> solved;
  final bool initiallyOpen;
  final bool showClass;

  const StudentHomeworkCard({super.key, required this.homework, required this.uid, required this.solved, this.initiallyOpen = false, this.showClass = true});

  @override
  State<StudentHomeworkCard> createState() => _StudentHomeworkCardState();
}

class _StudentHomeworkCardState extends State<StudentHomeworkCard> {
  late bool _open = widget.initiallyOpen;

  Homework get h => widget.homework;

  Widget _dateTile(bool done, Color c) {
    final d = h.dueAt;
    return Container(
      width: 52,
      height: 56,
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: done
          ? const Icon(Icons.check_rounded, color: hwGreen, size: 26)
          : d == null
              ? Icon(Icons.event_available_outlined, color: c, size: 22)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_weekdayShort[d.weekday - 1], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c, letterSpacing: 0.6)),
                    Text('${d.day}', style: TextStyle(fontSize: 21, height: 1.1, fontWeight: FontWeight.w800, color: c)),
                  ],
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = h.isDone(widget.uid);
    final c = hwDueColor(h, done: done);
    final solvedN = h.problems.where((p) => widget.solved.contains(p.progressKey)).length;
    final from = [
      h.teacherName,
      if (widget.showClass) ...[for (final id in h.classIds) h.classNames[id] ?? id],
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NotebookPaper(
      border: _open && !done ? c.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CkHover(
            onTap: () => setState(() => _open = !_open),
            builder: (hv) => Container(
              color: hv ? Pb.primary.withOpacity(0.04) : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Row(
                children: [
                  _dateTile(done, c),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: done ? Pb.muted : Pb.text, height: 1.3)),
                        const SizedBox(height: 2),
                        Text(from, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Pb.muted)),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (done)
                              hwPill('Terminată', hwGreen, icon: Icons.check)
                            else if (h.dueAt != null)
                              hwPill(h.overdue ? 'Întârziată · ${hwDueLabel(h.dueAt!)}' : 'Termen: ${hwDueLabel(h.dueAt!)}', c, icon: Icons.schedule)
                            else
                              hwPill('Fără termen', Pb.muted, icon: Icons.schedule),
                            if (h.problems.isNotEmpty)
                              hwPill('$solvedN/${h.problems.length} probleme', solvedN == h.problems.length ? hwGreen : Pb.muted, icon: Icons.code),
                            if (h.material != null) hwPill('Fișă din Atelier', Pb.muted, icon: Icons.description_outlined),
                            if (h.isHidden(widget.uid) && !done) hwPill('Ascunsă din bară', Pb.muted, icon: Icons.visibility_off_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more, color: Pb.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border.withOpacity(0.7)))),
                    padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width < 700 ? 16 : 90, 4, 16, 16),
                    child: HomeworkDetails(homework: h, uid: widget.uid, showHeader: false, showPills: false, solved: widget.solved),
                  ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Two or three big tabs: "De făcut 3" / "Terminate 5".
Widget _tabs(List<(String, int)> tabs, int active, ValueChanged<int> onTap) => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Pb.gray.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: CkHover(
                onTap: () => onTap(i),
                builder: (hv) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == active ? Pb.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: i == active ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(tabs[i].$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: i == active ? Pb.text : Pb.muted)),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(color: i == active ? Pb.primary : Pb.border, borderRadius: BorderRadius.circular(99)),
                        child: Text('${tabs[i].$2}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: i == active ? Colors.white : Pb.muted)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

Widget _filterChip(String label, bool on, VoidCallback onTap, {Color? color}) => CkHover(
      onTap: onTap,
      builder: (hv) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? (color ?? Pb.primary).withOpacity(0.12) : (hv ? Pb.hoverBg : Pb.surface),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? (color ?? Pb.primary) : Pb.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: on ? (color ?? Pb.primary) : Pb.text)),
      ),
    );

Color _classColor(SchoolClass c) => c.subject.isEmpty ? ckColorFor(c.id) : ckSubjectColor(c.subject);

// ----------------------------------------------------------------- /clasa/:code
class ClassScreen extends StatelessWidget {
  final String code;
  const ClassScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) => _shell(ClassBody(uid: FirebaseAuth.instance.currentUser?.uid ?? '', code: code));
}

class ClassBody extends StatefulWidget {
  final String uid;
  final String code;
  const ClassBody({super.key, required this.uid, required this.code});

  @override
  State<ClassBody> createState() => _ClassBodyState();
}

class _ClassBodyState extends State<ClassBody> {
  late final String _code = Classes.cleanCode(widget.code);
  StreamSubscription<SchoolClass?>? _sub;
  SchoolClass? _class;
  bool _loading = true;
  bool _missing = false;
  bool _unreadable = false; // logged out and the rules don't let us peek
  String? _role;
  bool _joining = false;
  String? _joinError;

  bool get _loggedIn => widget.uid.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_loggedIn) Classes.rememberInvite(_code);
    if (_loggedIn) {
      Classes.roleOf(widget.uid).then((r) {
        if (mounted) setState(() => _role = r ?? 'student');
        _maybeJoin();
      });
    }
    _sub = Classes.watch(_code).listen(
      (c) {
        if (!mounted) return;
        setState(() {
          _class = c;
          _missing = c == null;
          _loading = false;
        });
        _maybeJoin();
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (_loggedIn) {
            _missing = true;
          } else {
            _unreadable = true;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// A student who opens the link joins straight away: that's the whole point.
  Future<void> _maybeJoin() async {
    final c = _class;
    if (c == null || _role == null || _joining) return;
    if (_role == 'teacher' || c.hasMember(widget.uid)) {
      Classes.forgetInvite();
      return;
    }
    setState(() {
      _joining = true;
      _joinError = null;
    });
    try {
      await Classes.join(c.id, widget.uid, await Classes.userName(widget.uid));
      await Classes.forgetInvite();
      if (mounted) _toast(context, 'Ai intrat în clasa „${c.displayName}”.');
    } catch (_) {
      if (mounted) setState(() => _joinError = 'Nu am putut să te adaug în clasă. Reîncarcă pagina.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || (_loggedIn && _role == null)) return _spinner();
    final c = _class;
    if (!_loggedIn) return _invite(c);
    if (_missing || c == null) {
      return PbContainer(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _emptyBox(
            Icons.link_off,
            'Clasa nu mai există',
            'Linkul e greșit sau profesorul a șters clasa. Cere-i un link nou.',
            action: PbButton(text: 'Înapoi la clase', onPressed: () => context.go('/clase')),
          ),
        ),
      );
    }
    if (c.teacherId == widget.uid) return ClassroomView(uid: widget.uid, teacher: true, code: c.id);
    if (_role == 'teacher') {
      return PbContainer(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _emptyBox(
            Icons.school_outlined,
            '${c.displayName} · ${c.teacherName}',
            'Linkul acesta e pentru elevi. Trimite-l elevilor tăi ca să intre în clasă.',
            action: PbButton(text: 'Copiază linkul', icon: Icons.link, onPressed: () => copyClassLink(context, c.id)),
          ),
        ),
      );
    }
    if (!c.hasMember(widget.uid)) {
      return PbContainer(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _joinError != null
              ? _emptyBox(Icons.error_outline, 'Ceva n-a mers', _joinError!, action: PbButton(text: 'Încearcă din nou', onPressed: _maybeJoin))
              : _spinner(),
        ),
      );
    }
    return ClassroomView(uid: widget.uid, teacher: false, code: c.id);
  }

  Widget _invite(SchoolClass? c) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ListView(
      children: [
        PbContainer(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                margin: EdgeInsets.only(top: isMobile ? 24 : 60, bottom: 40),
                padding: EdgeInsets.all(isMobile ? 22 : 32),
                decoration: ckDeco(r: 20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Pb.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
                      child: Icon(c == null || c.subject.isEmpty ? Icons.groups_outlined : ckSubjectIcon(c.subject), size: 32, color: Pb.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Ai fost invitat într-o clasă', style: TextStyle(fontSize: 14, color: Pb.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      c?.displayName ?? 'Clasa $_code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w800, color: Pb.text),
                    ),
                    if (c != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [c.teacherName, if (c.subject.isNotEmpty) c.subject].join(' · '),
                        style: TextStyle(fontSize: 15, color: Pb.muted),
                      ),
                    ],
                    if (_missing && !_unreadable) ...[
                      const SizedBox(height: 14),
                      Text('Nu găsesc clasa. Verifică linkul primit.', style: const TextStyle(color: hwRed, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Fă-ți cont sau intră în cel pe care îl ai. Rămâi în clasă și vezi temele de la profesor imediat ce ți le dă.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Pb.text, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    PbButton(text: 'Creează cont', icon: Icons.person_add_alt, fullWidth: true, onPressed: () => context.go('/inregistrare')),
                    const SizedBox(height: 10),
                    PbButton(text: 'Am deja cont', icon: Icons.login, fullWidth: true, variant: PbVariant.outlinePrimary, onPressed: () => context.go('/login')),
                    const SizedBox(height: 14),
                    Text('Codul clasei: $_code', style: TextStyle(fontSize: 12.5, color: Pb.muted, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

