import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'clean_kit.dart';
import 'classes_models.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'homework_composer.dart';
import 'homework_dock.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer, showPbModal;
import 'workspace_models.dart';
import 'workspace_screen.dart' show wsAgo, wsDialogShell;

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

Widget _shell(Widget child) => Scaffold(
      backgroundColor: Pb.page,
      body: Column(children: [const CustomNavbar(), Expanded(child: child)]),
    );

Widget _spinner() => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));

Widget _sectionTitle(String t, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(t, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Pb.text))),
          if (trailing != null) trailing,
        ],
      ),
    );

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

/// A card with a coloured strip down its left edge.
Widget _accentCard(Color color, Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: ckDeco(r: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
        child: child,
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
        return snap.data == 'teacher' ? TeacherClassesView(uid: uid) : StudentClassesView(uid: uid);
      },
    );
  }
}

// ----------------------------------------------------------------- teacher
class TeacherClassesView extends StatefulWidget {
  final String uid;
  const TeacherClassesView({super.key, required this.uid});

  @override
  State<TeacherClassesView> createState() => _TeacherClassesViewState();
}

class _TeacherClassesViewState extends State<TeacherClassesView> {
  late final Stream<List<SchoolClass>> _classes = Classes.taughtBy(widget.uid);
  late final Stream<List<Homework>> _homework = Classes.assignedBy(widget.uid);
  String _name = 'Profesor';

  @override
  void initState() {
    super.initState();
    Workspace.teacherName(widget.uid).then((n) => _name = n).catchError((_) => _name);
  }

  Future<void> _newClass() async {
    final code = await showNewClassDialog(context, widget.uid, _name);
    if (code != null && mounted) context.go('/clasa/$code');
  }

  Future<void> _newHomework(List<SchoolClass> classes, {Set<String> preselect = const {}}) async {
    final ok = await showHomeworkComposer(context, teacherId: widget.uid, teacherName: _name, classes: classes, preselectClasses: preselect);
    if (ok == true && mounted) _toast(context, 'Tema a fost trimisă.');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return StreamBuilder<List<SchoolClass>>(
      stream: _classes,
      builder: (context, cs) {
        final classes = cs.data ?? const <SchoolClass>[];
        return StreamBuilder<List<Homework>>(
          stream: _homework,
          builder: (context, hs) {
            final hw = hs.data ?? const <Homework>[];
            return ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                PbContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clase și teme', style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w800, color: Pb.text)),
                                const SizedBox(height: 6),
                                Text(
                                  'Fă o clasă (chiar și pentru un singur elev), trimite-i linkul, iar elevul intră în ea după ce își face cont. '
                                  'Temele date clasei ajung la toți, și la cei care intră mai târziu.',
                                  style: TextStyle(fontSize: 15, color: Pb.muted, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              PbButton(text: 'Temă nouă', icon: Icons.assignment_add, onPressed: cs.hasData ? () => _newHomework(classes) : null),
                              PbButton(text: 'Clasă nouă', icon: Icons.group_add_outlined, variant: PbVariant.outlinePrimary, onPressed: _newClass),
                            ],
                          ),
                        ],
                      ),
                      _sectionTitle('Clasele tale', trailing: classes.isEmpty ? null : Text('${classes.length}', style: TextStyle(color: Pb.muted))),
                      if (!cs.hasData && !cs.hasError)
                        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)))
                      else if (classes.isEmpty)
                        _emptyBox(
                          Icons.groups_outlined,
                          'Încă nu ai nicio clasă',
                          'Creezi clasa, primești un link și îl trimiți pe WhatsApp sau pe mail. Elevul îl deschide, își face cont și rămâne în clasă.',
                          action: PbButton(text: 'Creează prima clasă', icon: Icons.group_add_outlined, onPressed: _newClass),
                        )
                      else
                        LayoutBuilder(builder: (context, box) {
                          final cols = box.maxWidth > 980 ? 3 : (box.maxWidth > 620 ? 2 : 1);
                          final w = (box.maxWidth - (cols - 1) * 14) / cols;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              for (final c in classes)
                                SizedBox(
                                  width: w,
                                  child: _ClassCard(
                                    c: c,
                                    homeworkCount: hw.where((h) => h.classIds.contains(c.id)).length,
                                    onHomework: () => _newHomework(classes, preselect: {c.id}),
                                  ),
                                ),
                            ],
                          );
                        }),
                      _sectionTitle('Teme date', trailing: hw.isEmpty ? null : Text('${hw.length}', style: TextStyle(color: Pb.muted))),
                      if (hw.isEmpty)
                        _emptyBox(
                          Icons.assignment_outlined,
                          'Nicio temă încă',
                          'O temă poate merge la o clasă întreagă sau la elevi anume, cu termen, probleme din bancă sau o pagină din Atelier.',
                        )
                      else
                        for (final h in hw)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: HomeworkProgressTile(homework: h, recipients: hwRecipients(h, classes)),
                          ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
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

class _ClassCard extends StatelessWidget {
  final SchoolClass c;
  final int homeworkCount;
  final VoidCallback onHomework;
  const _ClassCard({required this.c, required this.homeworkCount, required this.onHomework});

  @override
  Widget build(BuildContext context) {
    final color = c.subject.isEmpty ? ckColorFor(c.id) : ckSubjectColor(c.subject);
    final n = c.members.length;
    return CkHover(
      onTap: () => context.go(c.path),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: ckDeco(r: 16).copyWith(border: Border.all(color: h ? color.withOpacity(0.6) : Pb.border.withOpacity(0.7))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(11)),
                  child: Icon(c.subject.isEmpty ? Icons.groups_outlined : ckSubjectIcon(c.subject), size: 21, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: h ? color : Pb.text)),
                      Text(
                        [if (c.subject.isNotEmpty) c.subject, n == 0 ? 'niciun elev încă' : (n == 1 ? '1 elev' : '$n elevi'), if (homeworkCount > 0) '$homeworkCount teme'].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Pb.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (n > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: Stack(
                  children: [
                    for (var i = 0; i < n && i < 6; i++)
                      Positioned(
                        left: i * 20.0,
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Pb.surface, width: 2)),
                          child: CkAvatar(name: c.members[i].name, image: '', size: 26),
                        ),
                      ),
                    if (n > 6) Positioned(left: 6 * 20.0 + 6, top: 5, child: Text('+${n - 6}', style: TextStyle(fontSize: 12.5, color: Pb.muted))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PbButton(text: 'Temă', icon: Icons.assignment_add, size: PbSize.sm, onPressed: onHomework),
                PbButton(text: 'Copiază linkul', icon: Icons.link, size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => copyClassLink(context, c.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A homework as the teacher sees it: who finished it and who didn't.
class HomeworkProgressTile extends StatefulWidget {
  final Homework homework;
  final Map<String, String> recipients;
  const HomeworkProgressTile({super.key, required this.homework, required this.recipients});

  @override
  State<HomeworkProgressTile> createState() => _HomeworkProgressTileState();
}

class _HomeworkProgressTileState extends State<HomeworkProgressTile> {
  bool _open = false;

  Future<void> _delete() async {
    final ok = await showPbModal<bool>(
      context,
      title: 'Ștergi tema?',
      body: Text('„${widget.homework.displayTitle}” dispare și de la elevi. Nu se poate anula.'),
      actions: (c) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(c).pop(false)),
        PbButton(text: 'Șterge', variant: PbVariant.danger, onPressed: () => Navigator.of(c).pop(true)),
      ],
    );
    if (ok == true) {
      Classes.deleteHomework(widget.homework.id).catchError((_) {
        if (mounted) _toast(context, 'Nu am putut șterge tema.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.homework;
    final r = widget.recipients;
    final doneIds = r.keys.where(h.isDone).toList();
    final total = r.length;
    final frac = total == 0 ? 0.0 : doneIds.length / total;
    final dueC = h.dueAt == null ? Pb.muted : hwDueColor(h);
    return Container(
      decoration: ckDeco(r: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CkHover(
            onTap: () => setState(() => _open = !_open),
            builder: (hv) => Container(
              color: hv ? Pb.hoverBg : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(value: frac, strokeWidth: 3.5, color: hwGreen, backgroundColor: Pb.border),
                        Text('${doneIds.length}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Pb.text)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: total == 0 ? 'încă niciun elev' : '${doneIds.length} din $total au terminat'),
                            if (h.audience.isNotEmpty) TextSpan(text: ' · ${h.audience}'),
                            if (h.dueAt != null) TextSpan(text: ' · termen ${hwDueLabel(h.dueAt!)}', style: TextStyle(color: dueC, fontWeight: FontWeight.w600)),
                          ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Pb.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more, color: Pb.muted),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (h.instructions.trim().isNotEmpty) ...[
                    Text(h.instructions.trim(), style: TextStyle(fontSize: 14, color: Pb.text, height: 1.5)),
                    const SizedBox(height: 10),
                  ],
                  if (h.problems.isNotEmpty || h.material != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in h.problems) hwPill(p.title, ckSubjectColor(p.subject), icon: Icons.functions),
                          if (h.material != null) hwPill(h.material!.displayTitle, hwBlue, icon: Icons.auto_stories_outlined),
                        ],
                      ),
                    ),
                  if (total > 0)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final e in r.entries)
                          hwPill(e.value, h.isDone(e.key) ? hwGreen : Pb.muted, icon: h.isDone(e.key) ? Icons.check : Icons.schedule),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Dată ${wsAgo(h.createdAt)}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                      const Spacer(),
                      PbButton(text: 'Șterge', icon: Icons.delete_outline, size: PbSize.sm, variant: PbVariant.outlineDanger, onPressed: _delete),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- student
class StudentClassesView extends StatefulWidget {
  final String uid;
  const StudentClassesView({super.key, required this.uid});

  @override
  State<StudentClassesView> createState() => _StudentClassesViewState();
}

class _StudentClassesViewState extends State<StudentClassesView> {
  late final Stream<List<Homework>> _hw = Classes.forStudent(widget.uid);
  late final Stream<List<SchoolClass>> _classes = Classes.joinedBy(widget.uid);
  final _code = TextEditingController();
  bool _showDone = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    final c = Classes.cleanCode(_code.text);
    if (c.isEmpty) return;
    context.go('/clasa/$c');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return StreamBuilder<List<Homework>>(
      stream: _hw,
      builder: (context, hs) {
        final all = hs.data ?? const <Homework>[];
        final todo = all.where((h) => !h.isDone(widget.uid)).toList();
        final done = all.where((h) => h.isDone(widget.uid)).toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            PbContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 26),
                  Text('Temele mele', style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w800, color: Pb.text)),
                  const SizedBox(height: 6),
                  Text(
                    todo.isEmpty ? 'Nu ai nimic de făcut acum.' : (todo.length == 1 ? 'Ai o temă de făcut.' : 'Ai ${todo.length} teme de făcut.'),
                    style: TextStyle(fontSize: 15, color: Pb.muted),
                  ),
                  _sectionTitle('De făcut'),
                  if (!hs.hasData && !hs.hasError)
                    const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)))
                  else if (hs.hasError)
                    _emptyBox(Icons.cloud_off_outlined, 'Nu am putut încărca temele', 'Reîncarcă pagina.')
                  else if (todo.isEmpty)
                    _emptyBox(Icons.celebration_outlined, 'Totul e gata', 'Când profesorul îți dă o temă, apare aici și într-un buton mic în colțul ecranului, pe orice pagină.')
                  else
                    for (final h in todo) _card(h),
                  if (done.isNotEmpty) ...[
                    _sectionTitle('Terminate', trailing: PbLink(text: _showDone ? 'Ascunde' : 'Arată (${done.length})', fontSize: 14, onTap: () => setState(() => _showDone = !_showDone))),
                    if (_showDone) for (final h in done) _card(h),
                  ],
                  _sectionTitle('Clasele mele'),
                  StreamBuilder<List<SchoolClass>>(
                    stream: _classes,
                    builder: (context, cs) {
                      final classes = cs.data ?? const <SchoolClass>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (classes.isNotEmpty)
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final c in classes)
                                  CkHover(
                                    onTap: () => context.go(c.path),
                                    builder: (h) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: ckDeco(r: 12).copyWith(border: Border.all(color: h ? Pb.primary : Pb.border)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(c.subject.isEmpty ? Icons.groups_outlined : ckSubjectIcon(c.subject), size: 18, color: c.subject.isEmpty ? Pb.muted : ckSubjectColor(c.subject)),
                                          const SizedBox(width: 9),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(c.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Pb.text)),
                                                Text(c.teacherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(classes.isEmpty ? 'Ai primit un cod de clasă?' : 'Intră în altă clasă:', style: TextStyle(fontSize: 14, color: Pb.text)),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _code,
                                    onSubmitted: (_) => _join(),
                                    textCapitalization: TextCapitalization.characters,
                                    style: TextStyle(fontSize: 15, letterSpacing: 2, fontWeight: FontWeight.w700, color: Pb.text),
                                    cursorColor: Pb.primary,
                                    decoration: Pb.input(hint: 'ex. K7M2QX').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  ),
                                ),
                                PbButton(text: 'Intră', size: PbSize.sm, onPressed: _join),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(Homework h) {
    final c = hwDueColor(h, done: h.isDone(widget.uid));
    return _accentCard(c, HomeworkDetails(homework: h, uid: widget.uid));
  }
}

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
    if (c.teacherId == widget.uid) return _TeacherClassView(c: c, uid: widget.uid);
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
    return _StudentClassView(c: c, uid: widget.uid);
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

// ---- owner
class _TeacherClassView extends StatefulWidget {
  final SchoolClass c;
  final String uid;
  const _TeacherClassView({required this.c, required this.uid});

  @override
  State<_TeacherClassView> createState() => _TeacherClassViewState();
}

class _TeacherClassViewState extends State<_TeacherClassView> {
  late final Stream<List<Homework>> _hw = Classes.forClass(widget.c.id);
  late final Stream<List<SchoolClass>> _mine = Classes.taughtBy(widget.uid);

  SchoolClass get c => widget.c;

  Future<void> _homework() async {
    final mine = await _mine.first;
    if (!mounted) return;
    final ok = await showHomeworkComposer(context, teacherId: widget.uid, teacherName: c.teacherName, classes: mine, preselectClasses: {c.id});
    if (ok == true && mounted) _toast(context, 'Tema a fost trimisă.');
  }

  Future<void> _rename() => showDialog<String>(
        context: context,
        builder: (_) => _ClassNameDialog(uid: widget.uid, teacherName: c.teacherName, existing: c),
      );

  Future<void> _deleteClass() async {
    final ok = await showPbModal<bool>(
      context,
      title: 'Ștergi clasa?',
      body: Text('Elevii ies din „${c.displayName}” și linkul nu mai merge. Temele deja date rămân la elevii care le au.'),
      actions: (d) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(d).pop(false)),
        PbButton(text: 'Șterge clasa', variant: PbVariant.danger, onPressed: () => Navigator.of(d).pop(true)),
      ],
    );
    if (ok != true || !mounted) return;
    try {
      await Classes.deleteClass(c.id);
      if (mounted) context.go('/clase');
    } catch (_) {
      if (mounted) _toast(context, 'Nu am putut șterge clasa.');
    }
  }

  Future<void> _remove(ClassMember m) async {
    final ok = await showPbModal<bool>(
      context,
      title: 'Scoți elevul din clasă?',
      body: Text('${m.name} nu mai vede temele clasei. Poate reintra cu linkul.'),
      actions: (d) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(d).pop(false)),
        PbButton(text: 'Scoate', variant: PbVariant.danger, onPressed: () => Navigator.of(d).pop(true)),
      ],
    );
    if (ok == true) {
      Classes.removeMember(c.id, m.id).catchError((_) {
        if (mounted) _toast(context, 'Nu am putut scoate elevul.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final color = c.subject.isEmpty ? Pb.primary : ckSubjectColor(c.subject);
    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        PbContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Align(alignment: Alignment.centerLeft, child: PbLink(text: '← Toate clasele', fontSize: 14, onTap: () => context.go('/clase'))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.displayName, style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w800, color: Pb.text)),
                      Text(
                        [if (c.subject.isNotEmpty) c.subject, c.members.length == 1 ? '1 elev' : '${c.members.length} elevi'].join(' · '),
                        style: TextStyle(fontSize: 15, color: Pb.muted),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PbButton(text: 'Temă pentru clasă', icon: Icons.assignment_add, onPressed: _homework),
                      PbButton(text: 'Redenumește', icon: Icons.edit_outlined, variant: PbVariant.outlineSecondary, onPressed: _rename),
                      PbButton(text: 'Șterge', icon: Icons.delete_outline, variant: PbVariant.outlineDanger, onPressed: _deleteClass),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Invite box: the link is the main thing on this page.
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, size: 19, color: color),
                        const SizedBox(width: 8),
                        Text('Linkul clasei', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cine îl deschide își face cont (sau intră în cont) și ajunge direct în clasă. Rămâne acolo până îl scoți.',
                      style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
                      child: SelectableText(classLink(c.id), style: TextStyle(fontSize: 14.5, fontFamily: 'monospace', color: Pb.text)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PbButton(text: 'Copiază linkul', icon: Icons.copy, size: PbSize.sm, onPressed: () => copyClassLink(context, c.id)),
                        PbButton(text: 'Trimite pe WhatsApp', icon: Icons.chat_outlined, size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => shareClassOnWhatsApp(c)),
                        Text('sau codul ', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                        SelectableText(c.id, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2, color: Pb.text)),
                      ],
                    ),
                  ],
                ),
              ),
              _sectionTitle('Teme'),
              StreamBuilder<List<Homework>>(
                stream: _hw,
                builder: (context, s) {
                  final list = s.data ?? const <Homework>[];
                  if (!s.hasData && !s.hasError) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));
                  if (list.isEmpty) {
                    return _emptyBox(Icons.assignment_outlined, 'Nicio temă pentru clasa asta', 'Elevii văd tema imediat, într-un buton din colțul ecranului.',
                        action: PbButton(text: 'Dă prima temă', icon: Icons.assignment_add, onPressed: _homework));
                  }
                  return Column(
                    children: [
                      for (final h in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HomeworkProgressTile(homework: h, recipients: hwRecipients(h, [c])),
                        ),
                    ],
                  );
                },
              ),
              _sectionTitle('Elevi', trailing: Text('${c.members.length}', style: TextStyle(color: Pb.muted))),
              if (c.members.isEmpty)
                _emptyBox(Icons.person_add_alt, 'Niciun elev încă', 'Trimite linkul de mai sus. Elevii apar aici imediat ce intră.')
              else
                Container(
                  decoration: ckDeco(r: 14),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < c.members.length; i++)
                        Container(
                          decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: Pb.border))),
                          padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
                          child: Row(
                            children: [
                              CkAvatar(name: c.members[i].name, image: '', size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PbLink(text: c.members[i].name, fontSize: 14.5, onTap: () => context.go('/elev/${c.members[i].id}')),
                                    Text('a intrat ${wsAgo(c.members[i].joinedAt)}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Scoate din clasă',
                                icon: Icon(Icons.person_remove_outlined, size: 19, color: Pb.muted),
                                onPressed: () => _remove(c.members[i]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- member
class _StudentClassView extends StatefulWidget {
  final SchoolClass c;
  final String uid;
  const _StudentClassView({required this.c, required this.uid});

  @override
  State<_StudentClassView> createState() => _StudentClassViewState();
}

class _StudentClassViewState extends State<_StudentClassView> {
  late final Stream<List<Homework>> _hw = Classes.forClass(widget.c.id);

  Future<void> _leave() async {
    final ok = await showPbModal<bool>(
      context,
      title: 'Ieși din clasă?',
      body: Text('Nu mai primești temele din „${widget.c.displayName}”. Poți reveni cu linkul de la profesor.'),
      actions: (d) => [
        PbButton(text: 'Rămân', variant: PbVariant.secondary, onPressed: () => Navigator.of(d).pop(false)),
        PbButton(text: 'Ies din clasă', variant: PbVariant.danger, onPressed: () => Navigator.of(d).pop(true)),
      ],
    );
    if (ok != true || !mounted) return;
    try {
      await Classes.removeMember(widget.c.id, widget.uid);
      if (mounted) context.go('/clase');
    } catch (_) {
      if (mounted) _toast(context, 'Nu am putut ieși din clasă.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final isMobile = MediaQuery.of(context).size.width < 700;
    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        PbContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Align(alignment: Alignment.centerLeft, child: PbLink(text: '← Temele mele', fontSize: 14, onTap: () => context.go('/clase'))),
              const SizedBox(height: 12),
              Text(c.displayName, style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w800, color: Pb.text)),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('cu ', style: TextStyle(fontSize: 15, color: Pb.muted)),
                  PbLink(text: c.teacherName, fontSize: 15, onTap: () => context.go('/profesor/${c.teacherId}')),
                  Text(
                    [if (c.subject.isNotEmpty) ' · ${c.subject}', ' · ${c.members.length == 1 ? 'doar tu' : '${c.members.length} elevi'}'].join(),
                    style: TextStyle(fontSize: 15, color: Pb.muted),
                  ),
                ],
              ),
              _sectionTitle('Temele clasei'),
              StreamBuilder<List<Homework>>(
                stream: _hw,
                builder: (context, s) {
                  final list = s.data ?? const <Homework>[];
                  if (!s.hasData && !s.hasError) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));
                  if (list.isEmpty) {
                    return _emptyBox(Icons.assignment_outlined, 'Nicio temă deocamdată', 'Când profesorul dă o temă, o vezi aici și în colțul ecranului, pe orice pagină.');
                  }
                  final todo = list.where((h) => !h.isDone(widget.uid)).toList();
                  final done = list.where((h) => h.isDone(widget.uid)).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final h in [...todo, ...done])
                        _accentCard(hwDueColor(h, done: h.isDone(widget.uid)), HomeworkDetails(homework: h, uid: widget.uid)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: PbLink(text: 'Ieși din clasă', fontSize: 13.5, onTap: _leave)),
            ],
          ),
        ),
      ],
    );
  }
}
