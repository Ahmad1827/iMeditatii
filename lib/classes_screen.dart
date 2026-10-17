import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_colors.dart';
import 'classroom_kit.dart';
import 'clean_kit.dart';
import 'classes_models.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'homework_composer.dart';
import 'homework_dock.dart';
import 'ui_components.dart' show Pb, PbButton, PbCodeBox, PbVariant, PbContainer, showPbModal;
import 'workspace_models.dart';
import 'workspace_screen.dart' show wsDialogShell;
import 'home_ambient.dart' show HomeSky;
import 'math_sheet.dart' show SheetReviewCard;

part 'classroom_scene.dart';

// =============================================================================
// CLASSES
//   /clase         the classroom of your class (see classroom_scene.dart)
//   /clasa/:code   the invite link. Logged out: what the class is + sign up /
//                  log in (they come back here and join). Student: joins and
//                  picks a desk. Owner: their classroom.
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

// ----------------------------------------------------------------- student
int _byDue(Homework a, Homework b) {
  if (a.dueAt == null && b.dueAt == null) return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
  if (a.dueAt == null) return 1;
  if (b.dueAt == null) return -1;
  return a.dueAt!.compareTo(b.dueAt!);
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

