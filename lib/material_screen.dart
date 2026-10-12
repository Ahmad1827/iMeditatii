import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'clean_kit.dart';
import 'code_workbench.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'ink_page.dart';
import 'note_editor.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, showPbModal;
import 'workspace_models.dart';
import 'workspace_screen.dart' show wsAgo, wsDocColor, wsDocIcon;

// =============================================================================
// MATERIAL — what a student sees when they open something a teacher sent.
// Text notes are read-only (checklists can be ticked). Code opens in the same
// IDE the teacher used, on the student's own saved copy. A handwritten page
// can be written on: the student's ink is a separate layer over the teacher's.
// The teacher can open the same link to see how the student got on.
// =============================================================================
class MaterialScreen extends StatelessWidget {
  final String shareId;
  const MaterialScreen({super.key, required this.shareId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(child: MaterialBody(uid: FirebaseAuth.instance.currentUser?.uid ?? '', shareId: shareId)),
        ],
      ),
    );
  }
}

/// Everything below the navbar; the viewer's id is a parameter.
class MaterialBody extends StatefulWidget {
  final String uid;
  final String shareId;
  const MaterialBody({super.key, required this.uid, required this.shareId});

  @override
  State<MaterialBody> createState() => _MaterialBodyState();
}

class _MaterialBodyState extends State<MaterialBody> {
  late final String _uid = widget.uid;

  WsShare? _share;
  bool _loading = true;
  bool _missing = false;

  Map<String, bool> _checks = {};
  String? _myCode; // student's working copy (code), or their ink layer (handwritten page)
  final InkPageHandle _ink = InkPageHandle();
  Timer? _timer;
  bool _dirty = false;
  final ValueNotifier<int> _saveState = ValueNotifier(0); // 0 saved, 1 saving, 2 error
  int _resetCount = 0;
  bool _showOriginal = false; // teacher: original vs. student's copy

  bool get _isStudent => _share != null && _share!.studentId == _uid;
  bool get _isTeacher => _share != null && _share!.teacherId == _uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_dirty) _saveCopy();
    _saveState.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await Workspace.shares.doc(widget.shareId).get();
      if (!mounted) return;
      if (!snap.exists) {
        setState(() {
          _loading = false;
          _missing = true;
        });
        return;
      }
      final s = WsShare.fromSnap(snap);
      setState(() {
        _share = s;
        _checks = Map.of(s.checks);
        _myCode = s.studentContent;
        _loading = false;
      });
      if (s.studentId == _uid && !s.seen) {
        Workspace.markSeen(s.id).catchError((_) {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _missing = true;
        });
      }
    }
  }

  void _onCode(String v) {
    final wasEdited = _myCode != null && _myCode != _share!.content;
    _myCode = v;
    if (wasEdited != (v != _share!.content)) setState(() {}); // shows / hides the reset button
    _dirty = true;
    _saveState.value = 1;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1000), _saveCopy);
  }

  void _onInk() {
    _dirty = true;
    _saveState.value = 1;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), _saveCopy);
  }

  Future<void> _saveCopy() async {
    _timer?.cancel();
    final s = _share;
    if (s == null || !_dirty) return;
    _dirty = false;
    if (s.isInk) _myCode = _ink.isEmpty ? null : _ink.read();
    try {
      await Workspace.saveStudentCopy(s.id, _myCode);
      if (mounted && !_dirty) _saveState.value = 0;
    } catch (_) {
      _dirty = true;
      if (mounted) _saveState.value = 2;
    }
  }

  Future<void> _reset() async {
    final ok = await showPbModal<bool>(
      context,
      title: 'Revii la versiunea profesorului?',
      body: const Text('Modificările tale din acest fișier se pierd și codul redevine cel primit.'),
      actions: (ctx) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
        PbButton(text: 'Revino', variant: PbVariant.danger, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    );
    if (ok != true || !mounted) return;
    _timer?.cancel();
    _dirty = false;
    setState(() {
      _myCode = null;
      _resetCount++;
    });
    _saveState.value = 0;
    Workspace.saveStudentCopy(_share!.id, null).catchError((_) {});
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_isTeacher ? '/atelier' : '/panou-elev');
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary));
    } else if (_uid.isEmpty) {
      body = _message(Icons.lock_outline, 'Intră în cont ca să vezi materialul.', 'Autentificare', () => context.go('/login'));
    } else if (_missing || _share == null) {
      body = _message(Icons.link_off, 'Materialul nu mai există. Poate că profesorul l-a retras.', 'Înapoi la panou', () => context.go('/panou-elev'));
    } else if (!_isStudent && !_isTeacher) {
      body = _message(Icons.lock_outline, 'Acest material a fost trimis altcuiva.', 'Înapoi acasă', () => context.go('/'));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(_share!, isMobile),
          Container(height: 1, color: Pb.border),
          Expanded(
            child: _share!.isCode
                ? _codeBody(_share!, isMobile)
                : (_share!.isInk ? _inkBody(_share!, isMobile) : _noteBody(_share!, isMobile)),
          ),
        ],
      );
    }

    return ColoredBox(color: Pb.page, child: body);
  }

  Widget _message(IconData icon, String text, String cta, VoidCallback onTap) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Pb.muted),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Pb.text)),
              const SizedBox(height: 16),
              PbButton(text: cta, onPressed: onTap),
            ],
          ),
        ),
      );

  Widget _header(WsShare s, bool isMobile) {
    final color = wsDocColor(s.type, s.lang);
    final who = _isTeacher ? 'Trimis lui ${s.studentName}' : 'De la ${s.teacherName}';
    final meta = [
      who,
      wsAgo(s.sentAt),
      if (s.isCode) s.langLabel,
      if (s.version > 1) 'versiunea ${s.version}',
    ].join('  ·  ');

    return Container(
      color: Pb.surface,
      padding: EdgeInsets.fromLTRB(isMobile ? 6 : 14, 10, isMobile ? 12 : 18, 10),
      child: Row(
        children: [
          IconButton(tooltip: 'Înapoi', icon: Icon(Icons.arrow_back, size: 20, color: Pb.muted), splashRadius: 18, onPressed: _back),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
            child: Icon(wsDocIcon(s.type), size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.displayTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isMobile ? 16.5 : 18.5, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.2)),
                const SizedBox(height: 1),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ],
            ),
          ),
          if ((s.isCode || s.isInk) && _isStudent)
            ValueListenableBuilder<int>(
              valueListenable: _saveState,
              builder: (_, v, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(v == 0 ? Icons.cloud_done_outlined : (v == 1 ? Icons.sync : Icons.cloud_off_outlined),
                      size: 16, color: v == 2 ? const Color(0xFFE5484D) : Pb.muted),
                  if (!isMobile) ...[
                    const SizedBox(width: 5),
                    Text(v == 0 ? (s.isInk ? 'Ce ai scris e salvat' : 'Copia ta e salvată') : (v == 1 ? 'Se salvează' : 'Nesalvat'),
                        style: TextStyle(fontSize: 12.5, color: v == 2 ? const Color(0xFFE5484D) : Pb.muted)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _teacherNote(WsShare s) {
    if (s.message.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: Pb.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pb.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CkAvatar(name: s.teacherName, image: '', size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isTeacher ? 'Mesajul tău' : s.teacherName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted)),
                const SizedBox(height: 2),
                Text(s.message.trim(), style: TextStyle(fontSize: 14.5, color: Pb.text, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteBody(WsShare s, bool isMobile) {
    final todos = NoteContent.parse(s.content).where((b) => b.type == NoteBlock.todo).toList();
    final done = todos.where((b) => _checks[b.id] ?? b.checked).length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isMobile ? 10 : 24, isMobile ? 12 : 24, isMobile ? 10 : 24, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.message.trim().isNotEmpty) ...[_teacherNote(s), const SizedBox(height: 12)],
              if (todos.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.checklist, size: 17, color: Pb.muted),
                    const SizedBox(width: 8),
                    Text(
                      _isTeacher ? '${s.studentName.split(' ').first} a bifat $done din ${todos.length}' : 'Ai bifat $done din ${todos.length}',
                      style: TextStyle(fontSize: 13, color: Pb.muted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(value: done / todos.length, minHeight: 5, color: Pb.primary, backgroundColor: Pb.gray),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 40, isMobile ? 18 : 34, isMobile ? 16 : 40, isMobile ? 24 : 44),
                decoration: ckDeco(r: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(
                      s.displayTitle,
                      style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.6, height: 1.2),
                    ),
                    const SizedBox(height: 14),
                    NoteView(
                      content: s.content,
                      checks: _checks,
                      onCheck: _isStudent
                          ? (id, v) {
                              setState(() => _checks[id] = v);
                              Workspace.saveCheck(s.id, id, v).catchError((_) {});
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inkBody(WsShare s, bool isMobile) {
    final hasCopy = s.studentContent != null;
    final showOriginal = _isTeacher && (_showOriginal || !hasCopy);

    Widget seg(bool original, String label) {
      final sel = showOriginal == original;
      return CkHover(
        onTap: () => setState(() => _showOriginal = original),
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
            boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.message.trim().isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: _teacherNote(s)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              if (_isTeacher && hasCopy) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [seg(false, 'Cu ce a scris elevul'), seg(true, 'Doar ce ai trimis')]),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  _isTeacher
                      ? (hasCopy
                          ? 'Elevul a scris pe pagină ${wsAgo(s.studentUpdatedAt)}.'
                          : (s.seen ? 'Elevul a deschis pagina, dar nu a scris nimic pe ea.' : 'Elevul încă nu a deschis pagina.'))
                      : 'Poți scrie direct pe pagină. Ce scrii tu se salvează și îl vede și profesorul; ce a scris profesorul rămâne neschimbat.',
                  style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Pb.border),
        Expanded(
          child: _isTeacher
              ? InkPage(
                  key: ValueKey('ink-$showOriginal'),
                  base: s.content,
                  initialContent: showOriginal ? '' : s.studentContent!,
                  readOnly: true,
                  compact: isMobile,
                )
              : InkPage(
                  base: s.content,
                  initialContent: _myCode ?? '',
                  handle: _ink,
                  onDirty: _onInk,
                  compact: isMobile,
                  maxLength: 400000,
                ),
        ),
      ],
    );
  }

  Widget _codeBody(WsShare s, bool isMobile) {
    final teacherView = _isTeacher;
    final hasCopy = s.studentEdited;
    final showOriginal = teacherView && (_showOriginal || !hasCopy);
    final code = teacherView ? (showOriginal ? s.content : s.studentContent!) : (_myCode ?? s.content);
    final edited = !teacherView && _myCode != null && _myCode != s.content;

    Widget seg(bool original, String label) {
      final sel = showOriginal == original;
      return CkHover(
        onTap: () => setState(() => _showOriginal = original),
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
            boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
        ),
      );
    }

    final banner = <Widget>[
      if (s.message.trim().isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: _teacherNote(s)),
      if (teacherView)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              if (hasCopy)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [seg(false, 'Ce a lucrat elevul'), seg(true, 'Ce ai trimis')]),
                ),
              if (hasCopy) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasCopy
                      ? 'Ultima modificare a elevului: ${wsAgo(s.studentUpdatedAt)}. Poți rula codul, dar nu îl poți schimba de aici.'
                      : (s.seen ? 'Elevul a deschis fișierul, dar nu l-a modificat.' : 'Elevul încă nu a deschis fișierul.'),
                  style: TextStyle(fontSize: 13, color: Pb.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...banner,
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 0 : 12, 12, isMobile ? 0 : 12, isMobile ? 0 : 12),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: isMobile
                  ? BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border)))
                  : ckDeco(r: 14),
              child: CodeWorkbench(
                key: ValueKey('wb-$_resetCount-$showOriginal'),
                initialCode: code,
                initialLang: s.lang,
                initialStdin: s.stdin,
                readOnly: teacherView,
                compact: isMobile,
                onCodeChanged: teacherView ? null : _onCode,
                actions: [
                  if (edited)
                    Tooltip(
                      message: 'Revino la codul primit de la profesor',
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: PbButton(
                          text: isMobile ? 'Resetează' : 'Versiunea profesorului',
                          icon: Icons.restart_alt,
                          variant: PbVariant.outlineSecondary,
                          size: PbSize.sm,
                          onPressed: _reset,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
