import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'clean_kit.dart';
import 'code_workbench.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'ink_page.dart';
import 'note_editor.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, showPbModal;
import 'workspace_models.dart';

// =============================================================================
// ATELIER — the teacher's workspace: notebook pages and code files in one
// place, opened as tabs, saved as you type, and sent to students in two clicks.
// =============================================================================
const Color _noteColor = Color(0xFF3B82F6);
const Color _inkColor = Color(0xFFE5484D);
const Color _pyColor = Color(0xFFF59E0B);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFE5484D);

Color wsDocColor(String type, String lang) =>
    type == WsDoc.ink ? _inkColor : (type == WsDoc.note ? _noteColor : (lang == 'python' ? _pyColor : Pb.primary));
IconData wsDocIcon(String type) =>
    type == WsDoc.ink ? Icons.draw_outlined : (type == WsDoc.note ? Icons.sticky_note_2_outlined : Icons.code);

String wsAgo(DateTime? d) {
  if (d == null) return 'acum';
  final n = DateTime.now();
  final diff = n.difference(d);
  if (diff.inSeconds < 60) return 'acum';
  if (diff.inMinutes < 60) return 'acum ${diff.inMinutes} min';
  if (d.year == n.year && d.month == n.month && d.day == n.day) return 'azi, ${DateFormat('HH:mm').format(d)}';
  final y = n.subtract(const Duration(days: 1));
  if (d.year == y.year && d.month == y.month && d.day == y.day) return 'ieri, ${DateFormat('HH:mm').format(d)}';
  return DateFormat(d.year == n.year ? 'dd.MM' : 'dd.MM.yyyy').format(d);
}

enum _Save { saved, dirty, saving, error, tooLarge }

class _Session {
  final String id;
  final String type;
  final String initialContent;
  final TextEditingController title;
  final NoteEditorHandle note = NoteEditorHandle();
  final InkPageHandle ink = InkPageHandle();
  final ValueNotifier<_Save> status = ValueNotifier(_Save.saved);
  String code;
  String lang;
  String stdin;
  Timer? timer;
  bool dirty = false;
  bool closed = false;
  int rev = 0;

  _Session(WsDoc d)
      : id = d.id,
        type = d.type,
        initialContent = d.content,
        title = TextEditingController(text: d.title),
        code = d.content,
        lang = d.lang,
        stdin = d.stdin;

  bool get isCode => type == WsDoc.code;
  bool get isInk => type == WsDoc.ink;
  String get content => isCode ? code : ((isInk ? ink.read() : note.read()) ?? initialContent);
  int get maxLength => isInk ? InkDoc.maxLength : NoteContent.maxLength;
  String get displayTitle => title.text.trim().isEmpty ? (isCode ? 'Fișier fără nume' : 'Pagină fără titlu') : title.text.trim();

  void dispose() {
    closed = true;
    timer?.cancel();
    title.dispose();
    status.dispose();
  }
}

class WorkspaceScreen extends StatelessWidget {
  final String? openDocId;
  final String? create; // "note" | "cpp" | "python": start with a new document

  const WorkspaceScreen({super.key, this.openDocId, this.create});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: WorkspaceBody(uid: FirebaseAuth.instance.currentUser?.uid ?? '', openDocId: openDocId, create: create),
          ),
        ],
      ),
    );
  }
}

/// Everything below the navbar. Takes the user id as a parameter so it does
/// not depend on the auth plugin.
class WorkspaceBody extends StatefulWidget {
  final String uid;
  final String? openDocId;
  final String? create;

  const WorkspaceBody({super.key, required this.uid, this.openDocId, this.create});

  @override
  State<WorkspaceBody> createState() => _WorkspaceBodyState();
}

class _WorkspaceBodyState extends State<WorkspaceBody> {
  late final String _uid = widget.uid;

  StreamSubscription<List<WsDoc>>? _docsSub;
  StreamSubscription<List<WsShare>>? _sentSub;
  List<WsDoc> _docs = const [];
  Map<String, List<WsShare>> _sent = const {};
  bool _loading = true;
  String? _loadError;

  List<WsStudent>? _students;
  String _teacherName = 'Profesor';

  final Map<String, _Session> _sessions = {};
  final List<String> _open = [];
  String? _active;
  String? _pendingOpen;

  final TextEditingController _search = TextEditingController();
  String _q = '';
  String _filter = 'all'; // all | note | code
  String? _section;
  bool _sidebar = true;
  bool _mobileList = true;

  @override
  void initState() {
    super.initState();
    if (_uid.isEmpty) {
      _loading = false;
      return;
    }
    _pendingOpen = widget.openDocId;
    _docsSub = Workspace.myDocs(_uid).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _docs = list;
          _loading = false;
          _loadError = null;
        });
        final want = _pendingOpen;
        if (want != null) {
          final d = list.where((x) => x.id == want);
          if (d.isNotEmpty) {
            _pendingOpen = null;
            _openDoc(d.first);
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _loadError = '$e';
          });
        }
      },
    );
    _sentSub = Workspace.sentBy(_uid).listen((list) {
      if (!mounted) return;
      final map = <String, List<WsShare>>{};
      for (final s in list) {
        (map[s.docId] ??= []).add(s);
      }
      setState(() => _sent = map);
    }, onError: (_) {});

    Workspace.studentsOf(_uid).then((s) {
      if (mounted) setState(() => _students = s);
    }).catchError((_) {
      if (mounted) setState(() => _students = const []);
    });
    Workspace.teacherName(_uid).then((n) => _teacherName = n).catchError((_) => _teacherName);

    final c = widget.create;
    if (c != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final id = await _create(c == 'ink'
            ? WsTemplate.mathPage
            : (c == 'note'
                ? WsTemplate.all.first
                : WsTemplate.all.firstWhere((t) => t.type == WsDoc.code && t.lang == (c == 'python' ? 'python' : 'cpp'))));
        // Swap "?nou=" for the new document, so a reload does not create another one.
        if (id != null && mounted) context.go('/atelier?doc=$id');
      });
    }
  }

  @override
  void dispose() {
    _docsSub?.cancel();
    _sentSub?.cancel();
    // The editors are already gone; their last content is kept by the handle.
    // Controllers are released once the final saves have read from them.
    final sessions = _sessions.values.toList();
    Future.wait([for (final s in sessions) _save(s)]).whenComplete(() {
      for (final s in sessions) {
        s.dispose();
      }
    });
    _search.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- saving
  void _touch(_Session s) {
    if (s.closed) return;
    s.dirty = true;
    s.rev++;
    s.status.value = _Save.dirty;
    s.timer?.cancel();
    s.timer = Timer(const Duration(milliseconds: 900), () => _save(s));
  }

  Future<void> _save(_Session s) async {
    s.timer?.cancel();
    s.timer = null;
    if (!s.dirty) return;
    final rev = s.rev;
    final fields = <String, dynamic>{'title': s.title.text.trim()};
    if (s.isCode) {
      fields['content'] = s.code;
      fields['lang'] = s.lang;
      fields['stdin'] = s.stdin;
    } else {
      final c = s.isInk ? s.ink.read() : s.note.read();
      if (c != null) {
        if (c.length > s.maxLength) {
          if (!s.closed) s.status.value = _Save.tooLarge;
          return;
        }
        fields['content'] = c;
      }
    }
    if (!s.closed) s.status.value = _Save.saving;
    try {
      await Workspace.update(s.id, fields);
      if (s.rev == rev) {
        s.dirty = false;
        if (!s.closed) s.status.value = _Save.saved;
      }
    } catch (_) {
      if (!s.closed) s.status.value = _Save.error;
    }
  }

  // ---------------------------------------------------------------- documents
  void _openDoc(WsDoc d) {
    setState(() {
      _sessions.putIfAbsent(d.id, () => _Session(d));
      if (!_open.contains(d.id)) _open.add(d.id);
      _active = d.id;
      _mobileList = false;
    });
  }

  void _closeTab(String id) {
    final s = _sessions[id];
    if (s == null) return;
    // Save what is left, then release the controllers once the tab is unmounted.
    _save(s).whenComplete(() => WidgetsBinding.instance.addPostFrameCallback((_) => s.dispose()));
    setState(() {
      final i = _open.indexOf(id);
      _open.remove(id);
      _sessions.remove(id);
      if (_active == id) {
        _active = _open.isEmpty ? null : _open[i.clamp(0, _open.length - 1)];
        if (_active == null) _mobileList = true;
      }
    });
  }

  Future<String?> _create(WsTemplate t) async {
    final content = t.build();
    final section = _section ?? '';
    try {
      final id = await Workspace.create(
        ownerId: _uid,
        type: t.type,
        title: t.title,
        content: content,
        lang: t.lang,
        stdin: t.stdin,
        section: section,
      );
      if (!mounted) return id;
      _openDoc(WsDoc(
        id: id,
        ownerId: _uid,
        type: t.type,
        title: t.title,
        content: content,
        lang: t.lang,
        stdin: t.stdin,
        section: section,
        updatedAt: DateTime.now(),
      ));
      return id;
    } catch (e) {
      _toast('Nu am putut crea documentul. Verifică conexiunea și încearcă din nou.');
      return null;
    }
  }

  Future<void> _duplicate(WsDoc d) async {
    final s = _sessions[d.id];
    try {
      await Workspace.create(
        ownerId: _uid,
        type: d.type,
        title: '${s?.displayTitle ?? d.displayTitle} (copie)',
        content: s?.content ?? d.content,
        lang: s?.lang ?? d.lang,
        stdin: s?.stdin ?? d.stdin,
        section: d.section,
      );
    } catch (_) {
      _toast('Nu am putut duplica documentul.');
    }
  }

  Future<void> _delete(WsDoc d) async {
    final sentTo = _sent[d.id]?.length ?? 0;
    final ok = await showPbModal<bool>(
      context,
      title: 'Ștergi documentul?',
      body: Text(
        '„${_sessions[d.id]?.displayTitle ?? d.displayTitle}” va fi șters definitiv din atelierul tău.'
        '${sentTo > 0 ? ' Copiile deja trimise (la $sentTo ${sentTo == 1 ? 'elev' : 'elevi'}) rămân la ei.' : ''}',
      ),
      actions: (ctx) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
        PbButton(text: 'Șterge', variant: PbVariant.danger, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    );
    if (ok != true) return;
    final s = _sessions[d.id];
    if (s != null) {
      s.dirty = false; // nothing left to save
      _closeTab(d.id);
    }
    try {
      await Workspace.delete(d.id);
    } catch (_) {
      _toast('Nu am putut șterge documentul.');
    }
  }

  Future<void> _moveToSection(WsDoc d) async {
    final sections = _sections();
    final res = await showDialog<String>(
      context: context,
      builder: (_) => _SectionDialog(sections: sections, current: d.section),
    );
    if (res == null || res == d.section) return;
    try {
      await Workspace.update(d.id, {'section': res}, touch: false);
    } catch (_) {
      _toast('Nu am putut muta documentul.');
    }
  }

  List<String> _sections() {
    final set = <String>{for (final d in _docs) if (d.section.trim().isNotEmpty) d.section.trim()};
    return set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)));
  }

  // ---------------------------------------------------------------- sending
  Future<void> _send(String docId) async {
    final s = _sessions[docId];
    final d = _docs.where((x) => x.id == docId).firstOrNull;
    if (s == null && d == null) return;
    final students = _students ?? await Workspace.studentsOf(_uid).catchError((_) => <WsStudent>[]);
    if (!mounted) return;
    _students ??= students;

    final already = {for (final sh in _sent[docId] ?? const <WsShare>[]) sh.studentId: sh};
    final title = s?.displayTitle ?? d!.displayTitle;
    final res = await showDialog<(List<WsStudent>, String)>(
      context: context,
      builder: (_) => _SendDialog(title: title, students: students, already: already),
    );
    if (res == null || res.$1.isEmpty || !mounted) return;

    if (s != null && s.dirty) await _save(s);
    final content = s?.content ?? d!.content;
    if (content.length > (s?.maxLength ?? (d!.isInk ? InkDoc.maxLength : NoteContent.maxLength))) {
      _toast('Pagina e prea mare ca să fie trimisă. Șterge din ce ai scris și încearcă din nou.');
      return;
    }
    try {
      await Workspace.send(
        docId: docId,
        type: s?.type ?? d!.type,
        title: s?.title.text.trim() ?? d!.title,
        content: content,
        lang: s?.lang ?? d!.lang,
        stdin: s?.stdin ?? d!.stdin,
        teacherId: _uid,
        teacherName: _teacherName,
        students: res.$1,
        message: res.$2,
      );
      _toast(res.$1.length == 1 ? 'Trimis către ${res.$1.first.name}.' : 'Trimis către ${res.$1.length} elevi.');
    } catch (_) {
      _toast('Nu am putut trimite. Verifică conexiunea și încearcă din nou.');
    }
  }

  void _showSent(String docId) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StreamBuilder<List<WsShare>>(
        stream: Workspace.sentBy(_uid).map((l) => l.where((s) => s.docId == docId).toList()),
        initialData: _sent[docId] ?? const [],
        builder: (ctx, snap) => _SentDialog(
          shares: snap.data ?? const [],
          onOpen: (sh) {
            Navigator.of(dialogCtx).pop();
            context.push('/material/${sh.id}');
          },
          onUnsend: (sh) => Workspace.unsend(sh.id).catchError((_) => _toast('Nu am putut retrage materialul.')),
          onSendMore: () {
            Navigator.of(dialogCtx).pop();
            _send(docId);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    Widget body;
    if (_uid.isEmpty) {
      body = _centerMessage(
        Icons.lock_outline,
        'Intră în cont ca să-ți deschizi atelierul.',
        action: PbButton(text: 'Autentificare', onPressed: () => context.go('/login')),
      );
    } else if (isMobile) {
      body = _mobileList || _active == null ? _sidebarPanel(isMobile: true) : _main(isMobile: true);
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: _sidebar ? 296 : 0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 296,
                maxWidth: 296,
                child: _sidebarPanel(isMobile: false),
              ),
            ),
          ),
          Expanded(child: _main(isMobile: false)),
        ],
      );
    }

    return ColoredBox(color: Pb.page, child: body);
  }

  Widget _centerMessage(IconData icon, String text, {Widget? action}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: Pb.muted),
              const SizedBox(height: 10),
              Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, color: Pb.text)),
              if (action != null) ...[const SizedBox(height: 14), action],
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------- sidebar
  List<PopupMenuEntry<WsTemplate>> _newMenu() {
    PopupMenuItem<WsTemplate> item(WsTemplate t, IconData icon, Color c, String label, {String? sub}) => PopupMenuItem(
          value: t,
          height: sub == null ? 40 : 50,
          child: Row(
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(fontSize: 14, color: Pb.text)),
                    if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ],
                ),
              ),
            ],
          ),
        );
    final t = WsTemplate.all;
    return [
      item(WsTemplate.mathPage, Icons.draw_outlined, _inkColor, 'Caiet de matematică', sub: 'Scrii de mână pe toată pagina'),
      item(t[0], Icons.sticky_note_2_outlined, _noteColor, 'Pagină de text'),
      item(t[3], Icons.code, Pb.primary, 'Fișier C++'),
      item(t[4], Icons.code, _pyColor, 'Fișier Python'),
      const PopupMenuDivider(),
      item(t[1], Icons.event_note_outlined, _noteColor, t[1].name, sub: t[1].desc),
      item(t[2], Icons.assignment_outlined, _noteColor, t[2].name, sub: t[2].desc),
      item(t[6], Icons.draw_outlined, _inkColor, t[6].name, sub: t[6].desc),
      item(t[7], Icons.draw_outlined, _inkColor, t[7].name, sub: t[7].desc),
    ];
  }

  Widget _sidebarPanel({required bool isMobile}) {
    final q = _q.trim().toLowerCase();
    final sections = _sections();
    if (_section != null && !sections.contains(_section)) _section = null;

    final list = _docs.where((d) {
      if (_filter != 'all' && d.isCode != (_filter == WsDoc.code)) return false;
      if (_section != null && d.section.trim() != _section) return false;
      if (q.isEmpty) return true;
      final title = (_sessions[d.id]?.displayTitle ?? d.displayTitle).toLowerCase();
      return title.contains(q) || d.section.toLowerCase().contains(q) || (d.isCode && d.content.toLowerCase().contains(q));
    }).toList();
    final pinned = list.where((d) => d.pinned).toList();
    final rest = list.where((d) => !d.pinned).toList();

    Widget seg(String v, String label) {
      final sel = _filter == v;
      return Expanded(
        child: CkHover(
          onTap: () => setState(() => _filter = v),
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.5) : Colors.transparent),
              borderRadius: BorderRadius.circular(7),
              boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
          ),
        ),
      );
    }

    Widget chip(String? value, String label) {
      final sel = _section == value;
      return CkHover(
        onTap: () => setState(() => _section = value),
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: sel ? Pb.link.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sel ? Pb.link.withOpacity(0.6) : Pb.border),
          ),
          child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.link : Pb.text)),
        ),
      );
    }

    Widget groupLabel(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(t.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.6)),
        );

    Widget content;
    if (_loading) {
      content = const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));
    } else if (_loadError != null) {
      content = _centerMessage(Icons.cloud_off_outlined, 'Nu am putut încărca documentele. Reîncarcă pagina.');
    } else if (_docs.isEmpty) {
      content = _centerMessage(Icons.auto_stories_outlined, 'Atelierul e gol.\nCreează prima pagină sau primul fișier.');
    } else if (list.isEmpty) {
      content = _centerMessage(Icons.search_off, 'Niciun document nu se potrivește.');
    } else {
      content = ListView(
        padding: const EdgeInsets.only(bottom: 110), // keeps the last rows clear of the theme buttons
        children: [
          if (pinned.isNotEmpty) ...[groupLabel('Fixate'), for (final d in pinned) _sideItem(d)],
          if (pinned.isNotEmpty && rest.isNotEmpty) groupLabel('Toate'),
          if (pinned.isEmpty) const SizedBox(height: 6),
          for (final d in rest) _sideItem(d),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: isMobile ? null : Border(right: BorderSide(color: Pb.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Înapoi la panou',
                  icon: Icon(Icons.arrow_back, size: 19, color: Pb.muted),
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context.go('/panou-profesor'),
                ),
                const SizedBox(width: 2),
                Expanded(child: Text('Atelier', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.3))),
                PopupMenuButton<WsTemplate>(
                  tooltip: 'Document nou',
                  color: Pb.surface,
                  padding: EdgeInsets.zero,
                  onSelected: _create,
                  itemBuilder: (_) => _newMenu(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: Pb.primary, borderRadius: BorderRadius.circular(9)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 17, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Nou', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(fontSize: 14, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: Pb.input(hint: 'Caută în atelier').copyWith(
                hintStyle: TextStyle(fontSize: 14, color: Pb.muted),
                prefixIcon: Icon(Icons.search, size: 17, color: Pb.muted),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [seg('all', 'Toate'), seg(WsDoc.note, 'Caiet'), seg(WsDoc.code, 'Cod')]),
            ),
          ),
          if (sections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: SizedBox(
                height: 28,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    chip(null, 'Toate secțiunile'),
                    for (final s in sections) Padding(padding: const EdgeInsets.only(left: 6), child: chip(s, s)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(height: 1, color: Pb.border),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _sideItem(WsDoc d) {
    final s = _sessions[d.id];
    final sel = _active == d.id;
    final color = wsDocColor(d.type, s?.lang ?? d.lang);
    final sent = _sent[d.id]?.length ?? 0;
    final unseen = _sent[d.id]?.where((x) => !x.seen).length ?? 0;
    final title = s?.displayTitle ?? d.displayTitle;
    final meta = [
      if (d.section.trim().isNotEmpty) d.section.trim(),
      if (d.isCode) (s?.lang ?? d.lang) == 'python' ? 'Python' : 'C++',
      if (d.isInk) 'Scris de mână',
      wsAgo(d.updatedAt),
    ].join(' · ');

    return CkHover(
      onTap: () => _openDoc(d),
      builder: (h) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(9)),
              child: Icon(wsDocIcon(d.type), size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (d.pinned) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 12, color: Pb.muted)),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: Pb.text),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.muted)),
                ],
              ),
            ),
            if (sent > 0)
              Tooltip(
                message: unseen == 0 ? 'Trimis la $sent, văzut de toți' : 'Trimis la $sent, $unseen încă nu ${unseen == 1 ? 'l-a' : 'l-au'} deschis',
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: (unseen == 0 ? _green : _noteColor).withOpacity(0.13), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(unseen == 0 ? Icons.done_all : Icons.send, size: 11, color: unseen == 0 ? _green : _noteColor),
                      const SizedBox(width: 3),
                      Text('$sent', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: unseen == 0 ? _green : _noteColor)),
                    ],
                  ),
                ),
              ),
            _docMenu(d, visible: h || sel),
          ],
        ),
      ),
    );
  }

  Widget _docMenu(WsDoc d, {bool visible = true, IconData icon = Icons.more_vert}) {
    Widget mi(IconData i, String t, {bool danger = false}) => Row(
          children: [
            Icon(i, size: 17, color: danger ? Pb.danger : Pb.muted),
            const SizedBox(width: 10),
            Text(t, style: TextStyle(fontSize: 13.5, color: danger ? Pb.danger : Pb.text)),
          ],
        );
    final sent = _sent[d.id]?.length ?? 0;
    return Opacity(
      opacity: visible ? 1 : 0,
      child: PopupMenuButton<String>(
        tooltip: 'Opțiuni',
        color: Pb.surface,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: Pb.muted),
        splashRadius: 16,
        constraints: const BoxConstraints(minWidth: 210),
        onSelected: (v) {
          switch (v) {
            case 'send':
              _send(d.id);
              break;
            case 'sent':
              _showSent(d.id);
              break;
            case 'pin':
              Workspace.update(d.id, {'pinned': !d.pinned}, touch: false).catchError((_) => _toast('Nu am putut fixa documentul.'));
              break;
            case 'section':
              _moveToSection(d);
              break;
            case 'dup':
              _duplicate(d);
              break;
            case 'del':
              _delete(d);
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'send', height: 38, child: mi(Icons.send_outlined, 'Trimite elevilor')),
          if (sent > 0) PopupMenuItem(value: 'sent', height: 38, child: mi(Icons.done_all, 'Cui i-am trimis ($sent)')),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'pin', height: 38, child: mi(d.pinned ? Icons.push_pin_outlined : Icons.push_pin, d.pinned ? 'Anulează fixarea' : 'Fixează sus')),
          PopupMenuItem(value: 'section', height: 38, child: mi(Icons.folder_open_outlined, 'Mută în secțiune')),
          PopupMenuItem(value: 'dup', height: 38, child: mi(Icons.copy_outlined, 'Duplică')),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'del', height: 38, child: mi(Icons.delete_outline, 'Șterge', danger: true)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- main area
  Widget _main({required bool isMobile}) {
    final active = _active == null ? null : _sessions[_active];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topBar(active, isMobile),
        Container(height: 1, color: Pb.border),
        Expanded(
          child: active == null
              ? _welcome(isMobile)
              : ColoredBox(
                  color: Pb.surface,
                  child: IndexedStack(
                    index: _open.indexOf(active.id),
                    children: [for (final id in _open) _editorFor(_sessions[id]!, isMobile)],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _topBar(_Session? active, bool isMobile) {
    final doc = active == null ? null : _docs.where((d) => d.id == active.id).firstOrNull;
    final sent = active == null ? 0 : (_sent[active.id]?.length ?? 0);

    final tabs = ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final id in _open)
          _Tab(
            session: _sessions[id]!,
            selected: id == _active,
            onTap: () => setState(() => _active = id),
            onClose: () => _closeTab(id),
          ),
      ],
    );

    return Container(
      height: 46,
      color: Pb.surface,
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              tooltip: 'Toate documentele',
              icon: Icon(Icons.arrow_back, size: 20, color: Pb.muted),
              splashRadius: 18,
              onPressed: () => setState(() => _mobileList = true),
            )
          else
            IconButton(
              tooltip: _sidebar ? 'Ascunde lista' : 'Arată lista',
              icon: Icon(_sidebar ? Icons.menu_open : Icons.menu, size: 20, color: Pb.muted),
              splashRadius: 18,
              onPressed: () => setState(() => _sidebar = !_sidebar),
            ),
          Expanded(
            child: isMobile
                ? (active == null
                    ? const SizedBox.shrink()
                    : Text(active.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)))
                : tabs,
          ),
          if (active != null) ...[
            const SizedBox(width: 8),
            ValueListenableBuilder<_Save>(valueListenable: active.status, builder: (_, v, __) => _saveBadge(v, compact: isMobile)),
            const SizedBox(width: 8),
            if (sent > 0 && !isMobile)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PbButton(
                  text: 'Trimis la $sent',
                  icon: Icons.done_all,
                  variant: PbVariant.outlineSecondary,
                  size: PbSize.sm,
                  onPressed: () => _showSent(active.id),
                ),
              ),
            PbButton(
              text: isMobile ? 'Trimite' : 'Trimite elevilor',
              icon: Icons.send,
              size: PbSize.sm,
              onPressed: () => _send(active.id),
            ),
            if (doc != null) _docMenu(doc) else const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _saveBadge(_Save v, {bool compact = false}) {
    IconData icon;
    String text;
    Color color = Pb.muted;
    String? tip;
    switch (v) {
      case _Save.saved:
        icon = Icons.cloud_done_outlined;
        text = 'Salvat';
        break;
      case _Save.dirty:
      case _Save.saving:
        icon = Icons.sync;
        text = 'Se salvează';
        break;
      case _Save.error:
        icon = Icons.cloud_off_outlined;
        text = 'Nesalvat';
        color = _red;
        tip = 'Nu am putut salva. Se reîncearcă la următoarea modificare.';
        break;
      case _Save.tooLarge:
        icon = Icons.warning_amber_rounded;
        text = 'Pagină prea mare';
        color = _red;
        tip = 'Pagina a depășit limita de mărime. Șterge din ce ai scris ca să poată fi salvată.';
        break;
    }
    final w = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        if (!compact || color == _red) ...[
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12.5, color: color)),
        ],
      ],
    );
    return tip == null ? w : Tooltip(message: tip, child: w);
  }

  Widget _editorFor(_Session s, bool isMobile) {
    final doc = _docs.where((d) => d.id == s.id).firstOrNull;
    final section = doc?.section.trim() ?? '';

    if (!s.isCode && !s.isInk) {
      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: s.title,
            onChanged: (_) {
              _touch(s);
              setState(() {});
            },
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: Pb.primary,
            style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.6, height: 1.2),
            decoration: InputDecoration.collapsed(
              hintText: 'Pagină fără titlu',
              hintStyle: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.muted.withOpacity(0.5), letterSpacing: -0.6, height: 1.2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [if (section.isNotEmpty) section, 'modificat ${wsAgo(doc?.updatedAt)}'].join('  ·  '),
            style: TextStyle(fontSize: 12.5, color: Pb.muted),
          ),
        ],
      );
      return NoteEditor(
        key: ValueKey('note-${s.id}'),
        initialContent: s.initialContent,
        handle: s.note,
        onDirty: () => _touch(s),
        header: header,
        compact: isMobile,
      );
    }

    final color = wsDocColor(s.type, s.lang);
    return Column(
      key: ValueKey('${s.type}-${s.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Pb.border))),
          child: Row(
            children: [
              Icon(s.isInk ? Icons.draw_outlined : Icons.insert_drive_file_outlined, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: s.title,
                  onChanged: (_) {
                    _touch(s);
                    setState(() {});
                  },
                  cursorColor: Pb.primary,
                  autocorrect: false,
                  textCapitalization: s.isInk ? TextCapitalization.sentences : TextCapitalization.none,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text),
                  decoration: InputDecoration.collapsed(
                    hintText: s.isInk ? 'Pagină fără titlu' : 'Numele fișierului',
                    hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.muted.withOpacity(0.6)),
                  ),
                ),
              ),
              if (section.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(section, style: TextStyle(fontSize: 12, color: Pb.muted)),
                ),
              ],
            ],
          ),
        ),
        if (s.isInk)
          Expanded(
            child: InkPage(initialContent: s.initialContent, handle: s.ink, compact: isMobile, onDirty: () => _touch(s)),
          ),
        if (!s.isInk) Expanded(
          child: CodeWorkbench(
            initialCode: s.initialContent,
            initialLang: s.lang,
            initialStdin: s.stdin,
            compact: isMobile,
            onCodeChanged: (v) {
              s.code = v;
              _touch(s);
            },
            onLangChanged: (v) {
              s.lang = v;
              _touch(s);
              setState(() {});
            },
            onStdinChanged: (v) {
              s.stdin = v;
              _touch(s);
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- welcome
  Widget _welcome(bool isMobile) {
    Widget card(WsTemplate t, IconData icon) {
      final color = wsDocColor(t.type, t.lang);
      return CkHover(
        onTap: () => _create(t),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
          width: isMobile ? double.infinity : 250,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: h ? color.withOpacity(0.55) : Pb.border),
            boxShadow: [BoxShadow(color: (h ? color : Colors.black).withOpacity(h ? 0.14 : 0.04), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Pb.text)),
                    const SizedBox(height: 2),
                    Text(t.desc, style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final t = WsTemplate.all;
    Widget group(String title, List<Widget> cards) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.3)),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 12, children: cards),
          ],
        );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 40, isMobile ? 22 : 44, isMobile ? 16 : 40, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atelierul tău', style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(
                'Scrie de mână pe o pagină întreagă, ca într-un caiet, sau deschide un fișier de cod și rulează-l pe loc. '
                'Totul se salvează singur. Când e gata, trimite-l elevilor și îl găsesc în panoul lor.',
                style: TextStyle(fontSize: 15, color: Pb.muted, height: 1.55),
              ),
              const SizedBox(height: 28),
              group('SCRIS DE MÂNĂ', [
                card(t[5], Icons.draw_outlined),
                card(t[6], Icons.draw_outlined),
                card(t[7], Icons.draw_outlined),
              ]),
              const SizedBox(height: 26),
              group('PAGINI DE TEXT', [
                card(t[0], Icons.sticky_note_2_outlined),
                card(t[1], Icons.event_note_outlined),
                card(t[2], Icons.assignment_outlined),
              ]),
              const SizedBox(height: 26),
              group('COD', [card(t[3], Icons.code), card(t[4], Icons.code)]),
              if (_docs.isNotEmpty && !isMobile) ...[
                const SizedBox(height: 30),
                Row(
                  children: [
                    Icon(Icons.west, size: 16, color: Pb.muted),
                    const SizedBox(width: 8),
                    Text('Sau deschide un document din listă.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Tab
// =============================================================================
class _Tab extends StatefulWidget {
  final _Session session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;
  const _Tab({required this.session, required this.selected, required this.onTap, required this.onClose});

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final sel = widget.selected;
    final color = wsDocColor(s.type, s.lang);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTertiaryTapUp: (_) => widget.onClose(),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: sel ? Pb.page : (_hover ? Pb.hoverBg : Colors.transparent),
            border: Border(
              left: BorderSide(color: Pb.border),
              bottom: BorderSide(color: sel ? color : Colors.transparent, width: 2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(wsDocIcon(s.type), size: 15, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: s.title,
                  builder: (_, __, ___) => Text(
                    s.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Opacity(
                opacity: sel || _hover ? 1 : 0,
                child: IconButton(
                  tooltip: 'Închide',
                  icon: Icon(Icons.close, size: 15, color: Pb.muted),
                  splashRadius: 13,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Dialogs
// =============================================================================
Widget wsDialogShell({required String title, String? subtitle, required Widget body, required List<Widget> actions, double maxWidth = 520}) {
  return Dialog(
    backgroundColor: Pb.surface,
    insetPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Pb.border)),
    child: Builder(
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(ctx).size.height * 0.86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Pb.text)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: Pb.muted, size: 20), splashRadius: 18, onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
            Container(height: 1, color: Pb.border),
            Flexible(child: body),
            Container(height: 1, color: Pb.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: actions),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SendDialog extends StatefulWidget {
  final String title;
  final List<WsStudent> students;
  final Map<String, WsShare> already;
  const _SendDialog({required this.title, required this.students, required this.already});

  @override
  State<_SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends State<_SendDialog> {
  final Set<String> _sel = {};
  final TextEditingController _msg = TextEditingController();
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _msg.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.students;
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty ? all : all.where((s) => s.name.toLowerCase().contains(q)).toList();
    final allSel = list.isNotEmpty && list.every((s) => _sel.contains(s.id));

    Widget body;
    if (all.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 34, color: Pb.muted),
            const SizedBox(height: 10),
            Text('Încă nu ai elevi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(height: 4),
            Text(
              'Poți trimite materiale elevilor cu care ai o conversație. Când un elev îți scrie, apare aici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.45),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                    style: TextStyle(fontSize: 14, color: Pb.text),
                    cursorColor: Pb.primary,
                    decoration: Pb.input(hint: 'Caută un elev').copyWith(
                      hintStyle: TextStyle(fontSize: 14, color: Pb.muted),
                      prefixIcon: Icon(Icons.search, size: 17, color: Pb.muted),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PbButton(
                  text: allSel ? 'Niciunul' : 'Toți',
                  variant: PbVariant.outlineSecondary,
                  size: PbSize.sm,
                  onPressed: list.isEmpty
                      ? null
                      : () => setState(() {
                            if (allSel) {
                              _sel.removeAll(list.map((s) => s.id));
                            } else {
                              _sel.addAll(list.map((s) => s.id));
                            }
                          }),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                if (list.isEmpty)
                  Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('Niciun elev cu acest nume.', style: TextStyle(fontSize: 14, color: Pb.muted)))),
                for (final s in list)
                  CkHover(
                    onTap: () => setState(() => _sel.contains(s.id) ? _sel.remove(s.id) : _sel.add(s.id)),
                    builder: (h) {
                      final sel = _sel.contains(s.id);
                      final prev = widget.already[s.id];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? Pb.primary.withOpacity(0.07) : (h ? Pb.hoverBg : Colors.transparent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: sel ? Pb.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: sel ? Pb.primary : Pb.inputBorder, width: 1.6),
                              ),
                              child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            CkAvatar(name: s.name, image: '', size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text)),
                                  if (prev != null)
                                    Text(
                                      'Are deja o versiune, trimisă ${wsAgo(prev.sentAt)}. Va fi înlocuită.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Pb.muted),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: TextField(
              controller: _msg,
              maxLines: 2,
              minLines: 1,
              maxLength: 300,
              style: TextStyle(fontSize: 14, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: Pb.input(hint: 'Un mesaj pentru elevi (opțional)').copyWith(
                hintStyle: TextStyle(fontSize: 14, color: Pb.muted),
                counterText: '',
              ),
            ),
          ),
        ],
      );
    }

    final n = _sel.length;
    return wsDialogShell(
      title: 'Trimite elevilor',
      subtitle: '„${widget.title}” ajunge în panoul lor, la Materiale primite.',
      body: body,
      actions: [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(context).pop()),
        if (all.isNotEmpty)
          PbButton(
            text: n == 0 ? 'Alege elevii' : (n == 1 ? 'Trimite la un elev' : 'Trimite la $n elevi'),
            icon: Icons.send,
            onPressed: n == 0
                ? null
                : () => Navigator.of(context).pop((all.where((s) => _sel.contains(s.id)).toList(), _msg.text.trim())),
          ),
      ],
    );
  }
}

class _SentDialog extends StatelessWidget {
  final List<WsShare> shares;
  final ValueChanged<WsShare> onOpen;
  final ValueChanged<WsShare> onUnsend;
  final VoidCallback onSendMore;
  const _SentDialog({required this.shares, required this.onOpen, required this.onUnsend, required this.onSendMore});

  @override
  Widget build(BuildContext context) {
    final seen = shares.where((s) => s.seen).length;

    Widget pill(String t, Color c, IconData i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: 12, color: c),
              const SizedBox(width: 4),
              Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
            ],
          ),
        );

    return wsDialogShell(
      title: 'Cui i-am trimis',
      subtitle: shares.isEmpty ? null : '$seen din ${shares.length} ${shares.length == 1 ? 'elev l-a' : 'elevi l-au'} deschis.',
      body: shares.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(26),
              child: Text('Nu mai e trimis nimănui.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, color: Pb.muted)),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                for (final s in shares)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    child: Row(
                      children: [
                        CkAvatar(name: s.studentName, image: '', size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text)),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('trimis ${wsAgo(s.sentAt)}', style: TextStyle(fontSize: 12, color: Pb.muted)),
                                  s.seen ? pill('Văzut', _green, Icons.done_all) : pill('Nedeschis', Pb.muted, Icons.schedule),
                                  if (s.studentEdited) pill('A lucrat pe el', _noteColor, Icons.edit_outlined),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: s.studentEdited ? 'Vezi ce a lucrat elevul' : 'Vezi ce are elevul',
                          icon: Icon(Icons.open_in_new, size: 18, color: Pb.muted),
                          splashRadius: 17,
                          onPressed: () => onOpen(s),
                        ),
                        IconButton(
                          tooltip: 'Retrage de la acest elev',
                          icon: const Icon(Icons.undo, size: 18, color: _red),
                          splashRadius: 17,
                          onPressed: () => onUnsend(s),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      actions: [
        PbButton(text: 'Închide', variant: PbVariant.secondary, onPressed: () => Navigator.of(context).pop()),
        PbButton(text: 'Trimite și altora', icon: Icons.send, onPressed: onSendMore),
      ],
    );
  }
}

class _SectionDialog extends StatefulWidget {
  final List<String> sections;
  final String current;
  const _SectionDialog({required this.sections, required this.current});

  @override
  State<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends State<_SectionDialog> {
  late final TextEditingController _c = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return wsDialogShell(
      title: 'Mută în secțiune',
      subtitle: 'Secțiunile grupează documentele, de exemplu pe clase sau pe capitole.',
      maxWidth: 460,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _c,
              autofocus: true,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
              style: TextStyle(fontSize: 15, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: Pb.input(hint: 'Numele secțiunii, de exemplu Clasa a X-a').copyWith(counterText: ''),
            ),
            if (widget.sections.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in widget.sections)
                    CkHover(
                      onTap: () => setState(() => _c.text = s),
                      builder: (h) {
                        final sel = _c.text.trim() == s;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel ? Pb.link.withOpacity(0.10) : (h ? Pb.hoverBg : Colors.transparent),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: sel ? Pb.link.withOpacity(0.6) : Pb.border),
                          ),
                          child: Text(s, style: TextStyle(fontSize: 13, color: sel ? Pb.link : Pb.text)),
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.current.isNotEmpty)
          PbButton(text: 'Scoate din secțiune', variant: PbVariant.outlineSecondary, onPressed: () => Navigator.of(context).pop('')),
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(context).pop()),
        PbButton(text: 'Mută', onPressed: () => Navigator.of(context).pop(_c.text.trim())),
      ],
    );
  }
}
