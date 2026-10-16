import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'clean_kit.dart';
import 'classes_models.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize;
import 'workspace_screen.dart' show wsDocColor, wsDocIcon, wsDialogShell;

// =============================================================================
// HOMEWORK — what a student sees.
//   HomeworkDetails   one assignment: instructions, problems, the Atelier page,
//                     "done" and "hide from the dock"
//   HomeworkDock      the floating reminder shown on every page while a
//                     student has homework left to do
// =============================================================================
const Color hwBlue = Color(0xFF3B82F6);
const Color hwAmber = Color(0xFFF59E0B);
const Color hwRed = Color(0xFFE5484D);
const Color hwGreen = Color(0xFF10B981);

const _weekdays = ['luni', 'marți', 'miercuri', 'joi', 'vineri', 'sâmbătă', 'duminică'];

/// "azi, 18:00" · "mâine, 08:00" · "vineri" · "12.11" · "a trecut termenul".
String hwDueLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final days = day.difference(today).inDays;
  final time = (d.hour == 23 && d.minute == 59) ? '' : ', ${DateFormat('HH:mm').format(d)}';
  if (d.isBefore(now)) {
    if (days == 0) return 'azi$time, a trecut';
    if (days == -1) return 'ieri$time';
    return DateFormat(d.year == now.year ? 'dd.MM' : 'dd.MM.yyyy').format(d);
  }
  if (days == 0) return 'azi$time';
  if (days == 1) return 'mâine$time';
  if (days < 7) return '${_weekdays[d.weekday - 1]}$time';
  return DateFormat(d.year == now.year ? 'dd.MM' : 'dd.MM.yyyy').format(d);
}

/// Colour of the due date: red when late or due today, amber for tomorrow.
Color hwDueColor(Homework h, {bool done = false}) {
  if (done) return hwGreen;
  final d = h.dueAt;
  if (d == null) return Pb.muted;
  if (d.isBefore(DateTime.now())) return hwRed;
  final hours = d.difference(DateTime.now()).inHours;
  if (hours < 24) return hwRed;
  if (hours < 48) return hwAmber;
  return hwBlue;
}

Widget hwPill(String text, Color c, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
          ),
        ],
      ),
    );

/// Shows one homework in a dialog. [ctx] must be under the app's Navigator.
Future<void> showHomeworkDialog(BuildContext ctx, Homework h, String uid) => showDialog(
      context: ctx,
      builder: (c) => wsDialogShell(
        title: h.displayTitle,
        subtitle: 'De la ${h.teacherName}${h.audience.isEmpty ? '' : ' · ${h.audience}'}',
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: HomeworkDetails(homework: h, uid: uid, onNavigate: () => Navigator.of(c).pop(), showHeader: false),
        ),
        actions: [PbButton(text: 'Închide', variant: PbVariant.secondary, onPressed: () => Navigator.of(c).pop())],
      ),
    );

// ----------------------------------------------------------------- details
class HomeworkDetails extends StatefulWidget {
  final Homework homework;
  final String uid;
  final bool showHeader;
  final VoidCallback? onNavigate; // e.g. close the dialog before leaving the page

  const HomeworkDetails({super.key, required this.homework, required this.uid, this.showHeader = true, this.onNavigate});

  @override
  State<HomeworkDetails> createState() => _HomeworkDetailsState();
}

class _HomeworkDetailsState extends State<HomeworkDetails> {
  bool _opening = false;
  bool? _done; // optimistic, until the stream catches up
  bool? _hidden;

  Homework get h => widget.homework;
  bool get done => _done ?? h.isDone(widget.uid);
  bool get hidden => _hidden ?? h.isHidden(widget.uid);

  @override
  void didUpdateWidget(covariant HomeworkDetails old) {
    super.didUpdateWidget(old);
    _done = null;
    _hidden = null;
  }

  void _toast(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  void _go(String path) {
    final router = GoRouter.of(context);
    widget.onNavigate?.call();
    router.push(path);
  }

  Future<void> _openMaterial() async {
    setState(() => _opening = true);
    try {
      final name = await Classes.userName(widget.uid);
      final id = await Classes.openMaterial(h, widget.uid, name);
      if (mounted) _go('/material/$id');
    } catch (e) {
      _toast(e is StateError ? e.message : 'Nu am putut deschide materialul.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _setDone(bool v) async {
    setState(() => _done = v);
    try {
      await Classes.setDone(h.id, widget.uid, v);
      if (v && mounted) _toast('Bravo! Profesorul vede că ai terminat.');
    } catch (_) {
      if (mounted) setState(() => _done = null);
      _toast('Nu am putut salva. Încearcă din nou.');
    }
  }

  Future<void> _setHidden(bool v) async {
    setState(() => _hidden = v);
    try {
      await Classes.setHidden(h.id, widget.uid, v);
    } catch (_) {
      if (mounted) setState(() => _hidden = null);
      _toast('Nu am putut salva. Încearcă din nou.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueC = hwDueColor(h, done: done);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Text(h.displayTitle, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text)),
          const SizedBox(height: 2),
          Text('De la ${h.teacherName}${h.audience.isEmpty ? '' : ' · ${h.audience}'}', style: TextStyle(fontSize: 13, color: Pb.muted)),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (done) hwPill('Terminată', hwGreen, icon: Icons.check),
            if (h.dueAt != null)
              hwPill(
                h.overdue && !done ? 'Termen depășit: ${hwDueLabel(h.dueAt!)}' : 'Termen: ${hwDueLabel(h.dueAt!)}',
                dueC,
                icon: Icons.event_outlined,
              )
            else
              hwPill('Fără termen', Pb.muted, icon: Icons.event_outlined),
            if (hidden && !done) hwPill('Ascunsă din bară', Pb.muted, icon: Icons.visibility_off_outlined),
          ],
        ),
        if (h.instructions.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(h.instructions.trim(), style: TextStyle(fontSize: 14.5, color: Pb.text, height: 1.5)),
        ],
        if (h.problems.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('PROBLEME', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          for (final p in h.problems)
            CkHover(
              onTap: () => _go(p.path),
              builder: (hv) => AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: hv ? Pb.primary.withOpacity(0.06) : Pb.hoverBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: hv ? Pb.primary.withOpacity(0.4) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(ckSubjectIcon(p.subject), size: 17, color: ckSubjectColor(p.subject)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.title.isEmpty ? p.id : p.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                    ),
                    Text('${p.subject}${p.grade.isEmpty ? '' : ', a ${p.grade}-a'}', style: TextStyle(fontSize: 12, color: Pb.muted)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, size: 17, color: hv ? Pb.primary : Pb.muted),
                  ],
                ),
              ),
            ),
        ],
        if (h.material != null) ...[
          const SizedBox(height: 14),
          Text('DIN ATELIER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          CkHover(
            onTap: _opening ? null : _openMaterial,
            builder: (hv) {
              final m = h.material!;
              final c = wsDocColor(m.type, m.lang);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: hv ? c.withOpacity(0.07) : Pb.hoverBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: hv ? c.withOpacity(0.45) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(wsDocIcon(m.type), size: 18, color: c),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(m.displayTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                    ),
                    if (_opening)
                      SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: c))
                    else
                      Text('Deschide', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c)),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            done
                ? PbButton(text: 'Nu am terminat', icon: Icons.undo, size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => _setDone(false))
                : PbButton(text: 'Am terminat', icon: Icons.check, size: PbSize.sm, variant: PbVariant.success, onPressed: () => _setDone(true)),
            if (!done)
              hidden
                  ? PbButton(text: 'Arată în bară', icon: Icons.visibility_outlined, size: PbSize.sm, variant: PbVariant.outlinePrimary, onPressed: () => _setHidden(false))
                  : PbButton(text: 'Ascunde din bară', icon: Icons.visibility_off_outlined, size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => _setHidden(true)),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- dock
/// The floating "homework to do" reminder. Mounted once in MaterialApp.builder,
/// above the Navigator, so it gets the router passed in instead of reading it
/// from context.
class HomeworkDock extends StatefulWidget {
  final GoRouter router;

  /// The signed-in user's id; defaults to Firebase Auth. Tests pass their own.
  final Stream<String?>? users;

  const HomeworkDock({super.key, required this.router, this.users});

  @override
  State<HomeworkDock> createState() => _HomeworkDockState();
}

class _HomeworkDockState extends State<HomeworkDock> {
  StreamSubscription<String?>? _authSub;
  StreamSubscription<List<Homework>>? _hwSub;
  String? _uid;
  String? _current; // latest id from the auth stream, while its role loads
  List<Homework> _hw = const [];
  bool _open = false;
  bool _showHidden = false;
  String _path = '';
  int _seenCount = 0; // pulse when something new arrives

  // Pages where the dock would be in the way, or that already list homework.
  static const _hiddenOn = ['/login', '/inregistrare', '/completare-profil', '/alege-rol', '/video-call', '/chat', '/clase', '/clasa'];
  // Pages with an editor or console down the right edge: just a small round button.
  static const _compactOn = ['/exercitiu', '/material', '/atelier', '/mesaj-platit'];

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRoute);
    _onRoute();
    _authSub = (widget.users ?? FirebaseAuth.instance.authStateChanges().map((u) => u?.uid)).listen(_onUser);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    _authSub?.cancel();
    _hwSub?.cancel();
    super.dispose();
  }

  void _onRoute() {
    String p;
    try {
      p = widget.router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      p = '';
    }
    if (p != _path && mounted) {
      setState(() {
        _path = p;
        _open = false;
      });
    }
  }

  Future<void> _onUser(String? uid) async {
    _hwSub?.cancel();
    _hwSub = null;
    _current = uid;
    if (mounted) {
      setState(() {
        _uid = null;
        _hw = const [];
      });
    }
    if (uid == null) return;
    // Teachers give homework, they don't get any.
    if (await Classes.roleOf(uid) == 'teacher') return;
    if (!mounted || _current != uid) return;
    setState(() => _uid = uid);
    _hwSub = Classes.forStudent(uid).listen(
      (list) {
        if (mounted) setState(() => _hw = list);
      },
      onError: (_) {},
    );
  }

  List<Homework> get _todo => _hw.where((h) => !h.isDone(_uid!)).toList();

  BuildContext? get _navCtx => widget.router.routerDelegate.navigatorKey.currentContext;

  void _openDetails(Homework h) {
    final c = _navCtx;
    if (c == null) return;
    setState(() => _open = false);
    showHomeworkDialog(c, h, _uid!);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null || _hiddenOn.any((p) => _path.startsWith(p))) return const SizedBox.shrink();
    final todo = _todo;
    if (todo.isEmpty) return const SizedBox.shrink();
    final visible = todo.where((h) => !h.isHidden(uid)).toList();
    final hidden = todo.where((h) => h.isHidden(uid)).toList();

    final mq = MediaQuery.of(context);
    final isMobile = mq.size.width < 750;
    final compact = _compactOn.any((p) => _path.startsWith(p)) || visible.isEmpty;
    final fresh = visible.length > _seenCount;

    return Positioned(
      right: isMobile ? 14 : 20,
      bottom: (isMobile ? 14 : 20) + mq.padding.bottom,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomRight,
              child: _open ? _panel(context, visible, hidden, isMobile) : const SizedBox(width: 0, height: 0),
            ),
            if (_open) const SizedBox(height: 10),
            _pillButton(visible, hidden, compact, fresh),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(List<Homework> visible, List<Homework> hidden, bool compact, bool fresh) {
    final next = visible.isEmpty ? null : visible.first;
    final accent = visible.isEmpty ? Pb.muted : (next!.dueAt == null ? hwBlue : hwDueColor(next));
    final n = visible.length;
    return CkHover(
      onTap: () => setState(() {
        _open = !_open;
        _seenCount = visible.length;
      }),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        constraints: BoxConstraints(minWidth: 44, maxWidth: compact ? 44 : 330),
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
        decoration: BoxDecoration(
          color: Pb.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _open || h || fresh ? accent : Pb.border, width: fresh ? 2 : 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: compact
            ? Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(_open ? Icons.close : Icons.assignment_outlined, size: 20, color: n == 0 ? Pb.muted : accent),
                  if (n > 0 && !_open)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(99)),
                        child: Text('$n', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_open ? Icons.close : Icons.assignment_outlined, size: 19, color: accent),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: n == 1 ? '1 temă' : '$n teme', style: TextStyle(fontWeight: FontWeight.w700, color: Pb.text)),
                        if (next != null)
                          TextSpan(
                            text: next.dueAt == null ? ' · ${next.displayTitle}' : ' · ${hwDueLabel(next.dueAt!)}',
                            style: TextStyle(color: next.dueAt == null ? Pb.muted : accent, fontWeight: FontWeight.w600),
                          ),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _panel(BuildContext context, List<Homework> visible, List<Homework> hidden, bool isMobile) {
    final uid = _uid!;
    final w = isMobile ? MediaQuery.of(context).size.width - 28 : 360.0;
    final list = [...visible, if (_showHidden) ...hidden];
    return Container(
      width: w,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pb.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 10, 11),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, size: 18, color: Pb.muted),
                const SizedBox(width: 8),
                Expanded(child: Text('Teme de făcut', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text))),
                _TextBtn(
                  text: 'Toate temele',
                  onTap: () {
                    setState(() => _open = false);
                    widget.router.go('/clase');
                  },
                ),
              ],
            ),
          ),
          Container(height: 1, color: Pb.border),
          Flexible(
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Le-ai ascuns pe toate. Le găsești mai jos sau la Toate temele.',
                        style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4)),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [for (final h in list) _row(h, uid)],
                  ),
          ),
          if (hidden.isNotEmpty)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Icon(Icons.visibility_off_outlined, size: 15, color: Pb.muted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(hidden.length == 1 ? '1 temă ascunsă' : '${hidden.length} teme ascunse',
                        style: TextStyle(fontSize: 13, color: Pb.muted)),
                  ),
                  _TextBtn(text: _showHidden ? 'Ascunde-le' : 'Arată-le', onTap: () => setState(() => _showHidden = !_showHidden)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(Homework h, String uid) {
    final isHidden = h.isHidden(uid);
    final c = hwDueColor(h);
    return CkHover(
      onTap: () => _openDetails(h),
      builder: (hv) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: hv ? Pb.hoverBg : Colors.transparent,
          border: Border(left: BorderSide(color: isHidden ? Colors.transparent : c, width: 3), bottom: BorderSide(color: Pb.border)),
        ),
        padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: isHidden ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text)),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        if (h.dueAt != null)
                          TextSpan(text: '${h.overdue ? 'Întârziată · ' : ''}${hwDueLabel(h.dueAt!)} · ', style: TextStyle(color: c, fontWeight: FontWeight.w600)),
                        TextSpan(text: h.teacherName),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Pb.muted),
                    ),
                  ],
                ),
              ),
            ),
            _IconBtn(
              icon: isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              tip: isHidden ? 'Arată în bară' : 'Ascunde',
              onTap: () => Classes.setHidden(h.id, uid, !isHidden).catchError((_) {}),
            ),
            _IconBtn(
              icon: Icons.check_circle_outline,
              tip: 'Am terminat',
              color: hwGreen,
              onTap: () => Classes.setDone(h.id, uid, true).catchError((_) {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TextBtn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => CkHover(
        onTap: onTap,
        builder: (h) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.link, decoration: h ? TextDecoration.underline : null)),
        ),
      );
}

/// Icon button without a Tooltip: the dock sits above the app's Overlay.
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tip;
  final Color? color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.tip, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => Semantics(
        label: tip,
        button: true,
        child: CkHover(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: h ? (color ?? Pb.muted).withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 19, color: h ? (color ?? Pb.text) : Pb.muted),
          ),
        ),
      );
}
