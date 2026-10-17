part of 'classes_screen.dart';

// =============================================================================
// THE CLASSROOM
//   A room sketched in ink and watercolour on a sheet of paper lying on the
//   meadow: the board and the teacher's desk (catedra) at the front, double
//   school desks (bănci) with chairs, empty until students come.
//   A student picks a free chair once; tapping their desk zooms in and the
//   homework is on the desk. The teacher taps a student's desk to see how
//   that student is doing, or the catedra for the link and all homework.
// =============================================================================

/// What is zoomed in on.
class _Focus {
  final String key; // which desk to zoom from
  final String? studentId; // a student's place, or null for the catedra
  const _Focus(this.key, this.studentId);
}

class ClassroomView extends StatefulWidget {
  final String uid;
  final bool teacher;
  final String? code; // the class to open first
  const ClassroomView({super.key, required this.uid, required this.teacher, this.code});

  @override
  State<ClassroomView> createState() => _ClassroomViewState();
}

class _ClassroomViewState extends State<ClassroomView> with SingleTickerProviderStateMixin {
  late final Stream<List<SchoolClass>> _classes = widget.teacher ? Classes.taughtBy(widget.uid) : Classes.joinedBy(widget.uid);
  late final Stream<List<Homework>> _hw = widget.teacher ? Classes.assignedBy(widget.uid) : Classes.forStudent(widget.uid);
  late final Stream<Set<String>> _solved = Classes.solvedBy(widget.uid);
  late final Stream<Map<String, Map<String, Solution>>> _sent = widget.teacher ? Classes.solutionsFor(widget.uid) : const Stream.empty();
  Map<String, Map<String, Solution>> _sentNow = const {}; // the teacher's: student id -> problem key -> what they sent
  late final Future<String> _name =
      (widget.teacher ? Workspace.teacherName(widget.uid) : Classes.userName(widget.uid)).catchError((_) => widget.teacher ? 'Profesor' : 'Elev');

  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _t = CurvedAnimation(parent: _zoom, curve: Curves.easeInOutCubic);
  final _viewport = GlobalKey();
  final _keys = <String, GlobalKey>{};
  String? _selected;
  _Focus? _focus;
  Rect? _from;

  GlobalKey _key(String k) => _keys.putIfAbsent(k, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    _selected = widget.code == null ? null : Classes.cleanCode(widget.code!);
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _open(_Focus f) {
    final box = _keys[f.key]?.currentContext?.findRenderObject() as RenderBox?;
    final vp = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || vp == null) return;
    // Aim at the wooden top of the desk, so the zoom ends on wood and the
    // papers appear on it. As drawn on screen: the catedra is smaller on a phone.
    final r = MatrixUtils.transformRect(box.getTransformTo(vp), Offset.zero & box.size);
    setState(() {
      _from = f.studentId == null
          ? Rect.fromLTWH(r.left + r.width * 8 / 250, r.top + r.height * 84 / 190, r.width * 234 / 250, r.height * 26 / 190)
          : Rect.fromLTWH(r.left + r.width * 0.1, r.top + r.height * 0.02, r.width * 0.8, r.height * 0.26);
      _focus = f;
    });
    _zoom.forward(from: 0);
  }

  /// Scrolls to the desk first if it's off screen (a phone, a big class), then zooms in.
  Future<void> _goTo(_Focus f) async {
    final ctx = _keys[f.key]?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut, alignment: 0.4);
    if (mounted) _open(f);
  }

  Future<void> _close() async {
    await _zoom.reverse();
    if (mounted) setState(() => _focus = null);
  }

  Future<void> _newHomework(List<SchoolClass> classes, SchoolClass? c) async {
    final name = await _name;
    if (!mounted) return;
    final ok = await showHomeworkComposer(context, teacherId: widget.uid, teacherName: name, classes: classes, preselectClasses: {if (c != null) c.id});
    if (ok == true && mounted) _toast(context, 'Tema a fost trimisă.');
  }

  Future<void> _newClass() async {
    final code = await showNewClassDialog(context, widget.uid, await _name);
    if (code != null && mounted) setState(() => _selected = code);
  }

  Future<void> _joinByCode() async {
    final ctl = TextEditingController();
    final code = await showPbModal<String>(
      context,
      title: 'Intră într-o clasă',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Scrie codul de 6 caractere primit de la profesor (e la finalul linkului).', style: TextStyle(fontSize: 14, color: Pb.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: ctl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (v) => Navigator.of(context).pop(v),
            style: TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w700, color: Pb.text),
            decoration: Pb.input(hint: 'ex. K7M2QX'),
          ),
        ],
      ),
      actions: (d) => [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(d).pop()),
        PbButton(text: 'Intră', onPressed: () => Navigator.of(d).pop(ctl.text)),
      ],
    );
    final c = Classes.cleanCode(code ?? '');
    if (c.isNotEmpty && mounted) context.go('/clasa/$c');
  }

  Future<void> _sit(SchoolClass c, int seat) async {
    try {
      await Classes.takeSeat(c.id, widget.uid, seat);
      if (mounted) _toast(context, 'Ți-ai ales locul. Apasă pe banca ta ca să-ți vezi temele.');
    } catch (e) {
      if (mounted) _toast(context, e is StateError ? e.message : 'Nu am putut să te așez. Încearcă din nou.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolClass>>(
      stream: _classes,
      builder: (context, cs) => StreamBuilder<List<Homework>>(
        stream: _hw,
        builder: (context, hs) => StreamBuilder<Set<String>>(
          stream: widget.teacher ? const Stream.empty() : _solved,
          builder: (context, ss) => StreamBuilder<Map<String, Map<String, Solution>>>(
            stream: _sent,
            builder: (context, ns) {
              _sentNow = ns.data ?? const {};
              if (!cs.hasData && !cs.hasError) return _spinner();
              final classes = cs.data ?? const <SchoolClass>[];
              final c = classes.where((x) => x.id == _selected).firstOrNull ?? classes.firstOrNull;
              final hw = hs.data ?? const <Homework>[];
              final solved = ss.data ?? const <String>{};
              return LayoutBuilder(
                builder: (context, box) => Stack(
                  key: _viewport,
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _t,
                        child: _room(classes, c, hw, box.maxWidth),
                        builder: (context, child) {
                          final r = _from;
                          final t = _t.value;
                          if (r == null || t == 0) return child!;
                          final target = math.max(box.maxWidth / r.width, box.maxHeight / r.height);
                          final s = 1 + (target - 1) * t;
                          final c0 = r.center;
                          final at = Offset.lerp(c0, Offset(box.maxWidth / 2, box.maxHeight / 2), t)!;
                          return IgnorePointer(
                            child: Opacity(
                              opacity: (1 - (t - 0.9) / 0.1).clamp(0.0, 1.0),
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..translate(at.dx - c0.dx * s, at.dy - c0.dy * s)
                                  ..scale(s),
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_focus != null && c != null)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _t,
                          builder: (context, child) => IgnorePointer(
                            ignoring: _t.value < 0.95,
                            child: Opacity(opacity: ((_t.value - 0.72) / 0.28).clamp(0.0, 1.0), child: child),
                          ),
                          child: _desk(_focus!, classes, c, hw, solved),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// How many solutions the teacher's students in [c] sent that they haven't opened yet.
  int _newIn(SchoolClass c) => [
        for (final m in c.members) ...?_sentNow[m.id]?.values.where((s) => s.isNewFor(widget.uid)),
      ].length;

  // ---------------------------------------------------------------- the room
  Widget _room(List<SchoolClass> classes, SchoolClass? c, List<Homework> hw, double width) {
    final narrow = width < 760;
    final sheet = narrow ? 16.0 : 40.0; // the paper's margin
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(narrow ? 10 : 24, 16, narrow ? 10 : 24, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Container(
            padding: EdgeInsets.fromLTRB(sheet, narrow ? 18 : 30, sheet, narrow ? 22 : 34),
            decoration: BoxDecoration(
              color: paperColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _signs(classes, c),
                SizedBox(height: narrow ? 18 : 28),
                _front(classes, c, hw, narrow),
                SizedBox(height: narrow ? 22 : 36),
                // what to do here, before the benches: on a phone they run long
                if (c != null) ...[
                  Center(child: _hint(c)),
                  SizedBox(height: narrow ? 14 : 20),
                ],
                _benches(c, hw, narrow, math.min(1080.0, width - (narrow ? 20 : 48)) - sheet * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The classes as words along the top of the page, the open one
  /// underlined by hand.
  Widget _signs(List<SchoolClass> classes, SchoolClass? c) {
    Widget tab(String text, {bool on = false, IconData? icon, VoidCallback? onTap}) => CkHover(
          onTap: onTap,
          builder: (h) => CustomPaint(
            painter: on || h ? _Underline(on ? inkColor : inkColor.withOpacity(0.3), seed: text.hashCode) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 15, color: Pb.primary), const SizedBox(width: 5)],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: icon != null ? Pb.primary : inkColor.withOpacity(on ? 1 : 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Wrap(
      spacing: 22,
      runSpacing: 8,
      children: [
        for (final x in classes) tab(x.displayName, on: x.id == c?.id, onTap: () => setState(() => _selected = x.id)),
        if (widget.teacher)
          tab('Clasă nouă', icon: Icons.add, onTap: _newClass)
        else
          tab(classes.isEmpty ? 'Am un cod de clasă' : 'Altă clasă', icon: Icons.vpn_key_outlined, onTap: _joinByCode),
      ],
    );
  }

  /// The board and the catedra.
  Widget _front(List<SchoolClass> classes, SchoolClass? c, List<Homework> hw, bool narrow) {
    final board = Chalkboard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c == null) ...[
            Text(widget.teacher ? 'Prima ta clasă' : 'Încă nu ești într-o clasă', style: chalk(narrow ? 36 : 46, height: 1.1)),
            const SizedBox(height: 6),
            Text(
              widget.teacher
                  ? 'Fă o clasă (chiar și pentru un singur elev), trimite-i linkul și elevii își iau loc în bănci.'
                  : 'Deschide linkul primit de la profesor sau scrie codul clasei.',
              style: chalk(narrow ? 20 : 23, color: inkColor.withOpacity(0.6), weight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
            ChalkButton(
              text: widget.teacher ? 'Creează clasa' : 'Am un cod de clasă',
              icon: widget.teacher ? Icons.group_add_outlined : Icons.vpn_key_outlined,
              filled: true,
              onTap: widget.teacher ? _newClass : _joinByCode,
            ),
          ] else ...[
            Text(c.subject.isEmpty ? 'Clasa' : c.subject, style: chalk(narrow ? 20 : 22, color: Pb.primary, weight: FontWeight.w600)),
            Text(c.displayName, style: chalk(narrow ? 40 : 52, height: 1.1)),
            const SizedBox(height: 4),
            Text(
              widget.teacher
                  ? '${c.members.isEmpty ? 'Niciun elev încă' : (c.members.length == 1 ? '1 elev' : '${c.members.length} elevi')} · cod ${c.id}'
                  : 'cu ${c.teacherName}',
              style: chalk(narrow ? 20 : 23, color: inkColor.withOpacity(0.6), weight: FontWeight.w400),
            ),
            // straight to the desk, without looking for it
            if (_shortcut(c, hw) case (final label, final focus)) ...[
              const SizedBox(height: 14),
              ChalkButton(text: label, icon: widget.teacher ? Icons.mark_email_unread_outlined : Icons.menu_book_outlined, filled: true, color: Pb.primary, onTap: () => _goTo(focus)),
            ],
            if (widget.teacher) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChalkButton(text: 'Temă nouă', icon: Icons.assignment_add, filled: true, onTap: () => _newHomework(classes, c)),
                  ChalkButton(text: 'Copiază linkul', icon: Icons.link, onTap: () => copyClassLink(context, c.id)),
                  ChalkButton(
                    text: 'Redenumește',
                    icon: Icons.edit_outlined,
                    onTap: () => showDialog<String>(context: context, builder: (_) => _ClassNameDialog(uid: widget.uid, teacherName: c.teacherName, existing: c)),
                  ),
                  ChalkButton(text: 'Șterge clasa', icon: Icons.delete_outline, color: hwRed, onTap: () => _deleteClass(c)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
    if (c == null) return board;
    final catedra = _Catedra(
      key: _key('catedra'),
      name: c.teacherName,
      teacher: widget.teacher,
      papers: widget.teacher ? hw.where((h) => h.classIds.contains(c.id)).length : 0,
      onTap: widget.teacher ? () => _open(const _Focus('catedra', null)) : () => context.go('/profesor/${c.teacherId}'),
    );
    if (narrow) {
      // smaller on a phone, so the benches aren't far down
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [board, const SizedBox(height: 14), Center(child: SizedBox(width: 190, height: 190 * 190 / 250, child: FittedBox(child: catedra)))],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Expanded(child: board), const SizedBox(width: 36), catedra],
    );
  }

  /// The button on the board that opens a desk: the student's own, or for the
  /// teacher the first student who sent something new. Null when there's none.
  (String, _Focus)? _shortcut(SchoolClass c, List<Homework> hw) {
    final (seats, _) = _seating(c);
    if (widget.teacher) {
      final n = _newIn(c);
      final i = seats.indexWhere((m) => m != null && (_sentNow[m.id]?.values.any((s) => s.isNewFor(widget.uid)) ?? false));
      if (n == 0 || i < 0) return null;
      final who = seats[i]!.name.split(' ').first;
      return (n == 1 ? 'Soluție nouă de la $who' : '$n soluții noi · prima de la $who', _Focus('bench_${i ~/ 2}', seats[i]!.id));
    }
    final i = seats.indexWhere((m) => m?.id == widget.uid);
    if (i < 0) return null;
    final todo = _homeworkOf(c, hw, widget.uid).where((h) => !h.isDone(widget.uid)).length;
    return (todo == 0 ? 'Banca ta' : 'Banca ta · ${todo == 1 ? '1 temă' : '$todo teme'}', _Focus('bench_${i ~/ 2}', widget.uid));
  }

  /// Who sits where. A student who picked a chair sits there; the others take
  /// the free chairs in the order they joined. The viewing student only sits
  /// once they pick a chair themselves.
  (List<ClassMember?>, bool) _seating(SchoolClass c) {
    final members = [...c.members]..sort((a, b) => (a.joinedAt ?? DateTime(0)).compareTo(b.joinedAt ?? DateTime(0)));
    var n = math.max(10, ((members.length + 1) ~/ 2) * 2);
    for (final s in c.seats.values) {
      if (s + 1 > n) n = ((s + 2) ~/ 2) * 2;
    }
    final seats = List<ClassMember?>.filled(n, null);
    for (final m in members) {
      final s = c.seats[m.id];
      if (s != null && s >= 0 && seats[s] == null) seats[s] = m;
    }
    final meUnseated = !widget.teacher && !seats.any((m) => m?.id == widget.uid);
    for (final m in members) {
      if (seats.any((x) => x?.id == m.id) || (meUnseated && m.id == widget.uid)) continue;
      final free = seats.indexWhere((x) => x == null);
      if (free >= 0) seats[free] = m;
    }
    return (seats, meUnseated);
  }

  Widget _benches(SchoolClass? c, List<Homework> hw, bool narrow, double width) {
    final (seats, meUnseated) = c == null ? (List<ClassMember?>.filled(10, null), false) : _seating(c);
    final cols = narrow ? 2 : 3;
    final avail = math.min(1000.0, width);
    final gapX = narrow ? 14.0 : 40.0;
    final w = math.min(240.0, (avail - gapX * (cols - 1)) / cols);
    final benches = <Widget>[];
    for (var b = 0; b < seats.length ~/ 2; b++) {
      benches.add(_Bench(
        key: _key('bench_$b'),
        width: w,
        sides: [for (final i in [b * 2, b * 2 + 1]) _side(c, hw, seats[i], i, meUnseated, b)],
      ));
    }
    return Wrap(alignment: WrapAlignment.center, spacing: gapX, runSpacing: narrow ? 18 : 34, children: benches);
  }

  _Side _side(SchoolClass? c, List<Homework> hw, ClassMember? m, int seat, bool meUnseated, int bench) {
    if (m == null) {
      final pick = c != null && !widget.teacher;
      return _Side(
        empty: true,
        pickable: pick && meUnseated,
        onTap: !pick ? null : () => _sit(c, seat),
      );
    }
    final me = m.id == widget.uid;
    final mine = c == null ? const <Homework>[] : _homeworkOf(c, hw, m.id);
    final todo = mine.where((h) => !h.isDone(m.id)).length;
    return _Side(
      name: m.name,
      me: me,
      fresh: widget.teacher && (_sentNow[m.id]?.values.any((s) => s.isNewFor(widget.uid)) ?? false),
      paper: widget.teacher ? (mine.isEmpty ? null : '${mine.length - todo}/${mine.length}') : (me && mine.isNotEmpty ? (todo == 0 ? '✓' : '$todo') : null),
      paperLate: widget.teacher ? mine.any((h) => !h.isDone(m.id) && h.overdue) : (me && mine.any((h) => !h.isDone(m.id) && h.overdue)),
      onTap: widget.teacher || me
          ? () => _open(_Focus('bench_$bench', m.id))
          : () => _toast(context, 'Aici stă ${m.name}.'),
    );
  }

  /// The homework a student has in this class: the class's own, plus what
  /// this class's teacher sent them directly.
  List<Homework> _homeworkOf(SchoolClass c, List<Homework> hw, String sid) => [
        for (final h in hw)
          if (h.classIds.contains(c.id) || (h.teacherId == c.teacherId && h.studentIds.contains(sid))) h,
      ];

  Widget _hint(SchoolClass c) {
    final (_, meUnseated) = _seating(c);
    final String text;
    if (widget.teacher) {
      text = c.members.isEmpty ? 'Băncile sunt goale. Trimite linkul clasei ca să vină elevii.' : 'Apasă pe banca unui elev ca să vezi cum stă cu temele, sau pe catedră.';
    } else {
      text = meUnseated ? 'Alege-ți un loc: apasă pe un scaun liber.' : 'Apasă pe banca ta ca să-ți vezi temele.';
    }
    return Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: inkColor.withOpacity(0.5)));
  }

  // ---------------------------------------------------------------- the desk
  Widget _desk(_Focus f, List<SchoolClass> classes, SchoolClass c, List<Homework> hw, Set<String> solved) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final sid = f.studentId;
    final member = sid == null ? null : c.members.where((m) => m.id == sid).firstOrNull;
    final title = sid == null
        ? 'Catedra · ${c.displayName}'
        : (sid == widget.uid ? 'Banca ta · ${c.displayName}' : 'Banca lui ${member?.name ?? 'Elev'}');

    final List<Widget> papers;
    if (sid == null) {
      papers = _catedraPapers(c, hw);
    } else if (sid == widget.uid) {
      papers = _myPapers(_homeworkOf(c, hw, sid), solved);
    } else {
      papers = [_StudentDesk(sid: sid, teacherId: widget.uid, homework: _homeworkOf(c, hw, sid), sent: _sentNow[sid] ?? const {})];
    }

    return CustomPaint(
      painter: _DeskTop(ink: inkColor, wood: Color.lerp(paperColor, wcWood, AppColors.isDark ? 0.1 : 0.22)!),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 14, isMobile ? 12 : 24, 6),
              child: Row(
                children: [
                  ChalkButton(text: 'Înapoi în clasă', icon: Icons.arrow_back, onTap: _close),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 17 : 20, fontWeight: FontWeight.w600, color: inkColor),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 12, isMobile ? 12 : 24, 110),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 940),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: papers),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The student's desk: one notebook with every exercise the teacher gave,
  /// soonest deadline first. Solved ones are crossed off.
  List<Widget> _myPapers(List<Homework> mine, Set<String> solved) {
    return [const SizedBox(height: 8), _Notebook(problems: _problemsOf(mine), solved: solved)];
  }

  /// The catedra: the notebook with every exercise given to the class.
  List<Widget> _catedraPapers(SchoolClass c, List<Homework> hw) {
    final mine = [
      for (final h in hw)
        if (h.classIds.contains(c.id) || h.studentIds.any(c.hasMember)) h,
    ];
    return [const SizedBox(height: 8), _Notebook(problems: _problemsOf(mine), teacher: true)];
  }

  Future<void> _deleteClass(SchoolClass c) async {
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
      await _close();
      await Classes.deleteClass(c.id);
      if (mounted) setState(() => _selected = null);
    } catch (_) {
      if (mounted) _toast(context, 'Nu am putut șterge clasa.');
    }
  }
}

// ---------------------------------------------------------------- furniture
/// One half of a bench: a chair, maybe someone on it, maybe papers.
class _Side {
  final bool empty;
  final bool pickable; // the viewing student can sit here
  final String name;
  final bool me;
  final String? paper; // text on the paper on the desk
  final bool paperLate;
  final bool fresh; // sent something the teacher hasn't opened yet
  final VoidCallback? onTap;
  const _Side({this.empty = false, this.pickable = false, this.name = '', this.me = false, this.paper, this.paperLate = false, this.fresh = false, this.onTap});

  String get look => '$empty$pickable$me$name';
}

/// A double school desk with its two chairs, seen from the back of the room.
class _Bench extends StatelessWidget {
  final double width;
  final List<_Side> sides;
  const _Bench({super.key, required this.width, required this.sides});

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = w * 0.86;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _BenchSketch(sides, ink: inkColor, paper: paperColor, accent: Pb.primary)),
            ),
          ),
          for (var i = 0; i < 2; i++) ..._sideWidgets(context, sides[i], w * (0.25 + 0.5 * i), w, h),
        ],
      ),
    );
  }

  List<Widget> _sideWidgets(BuildContext context, _Side s, double cx, double w, double h) {
    final first = s.name.split(' ').first;
    return [
      // a sheet of paper on the desk
      if (s.paper != null)
        Positioned(
          left: cx - w * 0.08,
          top: h * 0.035,
          child: Transform.rotate(
            angle: -0.07,
            child: Container(
              width: w * 0.16,
              height: h * 0.15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Pb.surface,
                border: Border.all(color: (s.paperLate ? hwRed : inkColor).withOpacity(0.7), width: 0.9),
              ),
              child: Text(s.paper!,
                  style: TextStyle(fontSize: math.max(10, w * 0.05), fontWeight: FontWeight.w600, color: s.paperLate ? hwRed : inkColor)),
            ),
          ),
        ),
      // something new to read on this desk
      if (s.fresh)
        Positioned(
          left: cx + w * 0.06,
          top: h * 0.01,
          child: Container(
            width: math.max(9, w * 0.045),
            height: math.max(9, w * 0.045),
            decoration: BoxDecoration(color: Pb.primary, shape: BoxShape.circle, border: Border.all(color: paperColor, width: 1.5)),
          ),
        ),
      // the name, written under the chair
      Positioned(
        left: cx - w * 0.24,
        width: w * 0.48,
        top: h * 0.88,
        child: Center(
          child: s.empty && !s.pickable
              ? const SizedBox.shrink()
              : Text(
                  s.pickable ? 'Stai aici' : (s.me ? 'Tu' : first),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: math.max(11, w * 0.054),
                    fontWeight: s.me || s.pickable ? FontWeight.w700 : FontWeight.w500,
                    fontStyle: s.pickable ? FontStyle.italic : null,
                    color: s.me || s.pickable ? Pb.primary : inkColor.withOpacity(0.75),
                  ),
                ),
        ),
      ),
      // the whole half is the tap target
      Positioned(
        left: cx - w * 0.25,
        width: w * 0.5,
        top: 0,
        height: h,
        child: Semantics(
          button: s.onTap != null,
          label: s.empty ? (s.pickable ? 'Stai aici' : 'Loc liber') : (s.me ? 'Banca ta' : 'Banca lui ${s.name}'),
          child: CkHover(
            onTap: s.onTap,
            builder: (hv) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: hv && s.onTap != null ? inkColor.withOpacity(0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// The bench in ink and watercolour: the desk top a little wider at the front, its legs, and
/// for each half a chair, with the student on it seen from behind.
class _BenchSketch extends CustomPainter {
  final List<_Side> sides;
  final Color ink, paper, accent;
  _BenchSketch(this.sides, {required this.ink, required this.paper, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pen = Pen(canvas, color: ink, seed: sides.map((s) => s.look).join().hashCode);
    final faint = ink.withOpacity(0.35);

    // legs: the far ones shorter and lighter
    for (final x in [0.12, 0.88]) {
      pen.line(Offset(w * x, h * 0.3), Offset(w * x, h * 0.54), color: faint, width: 1);
    }
    for (final x in [0.035, 0.965]) {
      pen.line(Offset(w * x, h * 0.33), Offset(w * x, h * 0.64), over: 1);
    }
    // the desk top and its front edge
    pen.shape([Offset(w * 0.05, h * 0.03), Offset(w * 0.95, h * 0.03), Offset(w * 0.99, h * 0.27), Offset(w * 0.01, h * 0.27)], fill: paper, wash: wcWood, over: 4);
    pen.shape([Offset(w * 0.01, h * 0.27), Offset(w * 0.99, h * 0.27), Offset(w * 0.99, h * 0.33), Offset(w * 0.01, h * 0.33)], fill: paper, wash: wcWoodDeep, over: 3);
    pen.hatch(Path()..addRect(Rect.fromLTRB(w * 0.01, h * 0.27, w * 0.99, h * 0.33)), gap: 3.4, color: ink.withOpacity(0.22), width: 0.7);
    // the groove for pens, along the far edge
    pen.line(Offset(w * 0.1, h * 0.075), Offset(w * 0.9, h * 0.075), color: ink.withOpacity(0.2), width: 0.8);

    for (var i = 0; i < 2; i++) {
      _side(canvas, pen, sides[i], w * (0.25 + 0.5 * i), w, h);
    }
  }

  void _side(Canvas canvas, Pen pen, _Side s, double cx, double w, double h) {
    final chair = s.pickable ? accent : (s.empty ? ink.withOpacity(0.32) : ink);
    final blue = wcBlue.withOpacity(s.empty && !s.pickable ? 0.35 : 1);
    // the seat, mostly hidden
    pen.shape([Offset(cx - w * 0.13, h * 0.52), Offset(cx + w * 0.13, h * 0.52), Offset(cx + w * 0.15, h * 0.6), Offset(cx - w * 0.15, h * 0.6)],
        wash: blue, color: chair.withOpacity(chair.opacity * 0.6), width: 1, over: 1.5);
    if (!s.empty) _person(pen, s, cx, w, h);
    // the chair back, closest to us, and its legs
    final back = Rect.fromLTRB(cx - w * 0.17, h * 0.64, cx + w * 0.17, h * 0.78);
    pen.rect(back, fill: paper, wash: blue, color: chair, over: 3, width: s.pickable ? 1.6 : null);
    pen.line(Offset(back.left + 6, back.center.dy), Offset(back.right - 6, back.center.dy), color: chair.withOpacity(chair.opacity * 0.45), width: 0.8);
    for (final x in [-0.13, 0.13]) {
      pen.line(Offset(cx + w * x, h * 0.78), Offset(cx + w * x, h * 0.86), color: chair);
    }
  }

  /// A student from behind: shoulders and the back of the head, all hair.
  void _person(Pen pen, _Side s, double cx, double w, double h) {
    final c = s.me ? accent : ink;
    final seed = s.name.hashCode.abs();
    final shoulders = Path()
      ..moveTo(cx - w * 0.18, h * 0.72)
      ..cubicTo(cx - w * 0.18, h * 0.53, cx - w * 0.12, h * 0.48, cx, h * 0.48)
      ..cubicTo(cx + w * 0.12, h * 0.48, cx + w * 0.18, h * 0.53, cx + w * 0.18, h * 0.72);
    pen.path(shoulders, fill: paper, wash: wcShirts[seed % wcShirts.length], color: c);
    final hairColor = wcHair[(seed ~/ 7) % wcHair.length];
    final head = Offset(cx, h * 0.37);
    final r = w * 0.068;
    for (final x in [-0.028, 0.028]) {
      pen.line(Offset(cx + w * x, head.dy + r * 0.8), Offset(cx + w * x * 1.2, h * 0.49), color: c, width: 1);
    }
    if (seed % 3 == 1) {
      // a bun
      final bun = head - Offset(0, r * 1.05);
      pen.ring(bun, r * 0.36, fill: paper, wash: hairColor, color: c, width: 1.1);
      pen.hatch(Path()..addOval(Rect.fromCircle(center: bun, radius: r * 0.36)), gap: 2.2, angle: 0.6, color: c.withOpacity(0.6));
    }
    pen.ring(head, r, fill: paper, wash: hairColor, color: c);
    // hair over the whole head, or short with the nape showing
    final clip = Path.combine(PathOperation.difference, Path()..addOval(Rect.fromCircle(center: head, radius: r)),
        seed % 3 == 2 ? (Path()..addRect(Rect.fromLTRB(head.dx - r, head.dy + r * 0.45, head.dx + r, head.dy + r))) : Path());
    pen.hatch(clip, gap: seed % 2 == 0 ? 2.8 : 3.6, angle: seed % 2 == 0 ? -1.2 : -0.7, color: c.withOpacity(0.4));
  }

  @override
  bool shouldRepaint(covariant _BenchSketch old) =>
      old.ink != ink || old.paper != paper || old.accent != accent || old.sides.map((s) => s.look).join('|') != sides.map((s) => s.look).join('|');
}

/// The teacher's desk at the front, with the teacher behind it.
class _Catedra extends StatelessWidget {
  final String name;
  final bool teacher;
  final int papers;
  final VoidCallback onTap;
  const _Catedra({super.key, required this.name, required this.teacher, required this.papers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const w = 250.0;
    const h = 190.0;
    return Semantics(
      button: true,
      label: 'Catedra',
      child: CkHover(
        onTap: onTap,
        builder: (hv) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.translationValues(0, hv ? -3 : 0, 0),
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _CatedraSketch(name, ink: inkColor, paper: paperColor))),
              if (papers > 0)
                Positioned(
                  right: 62,
                  top: 74,
                  child: Transform.rotate(
                    angle: 0.06,
                    child: Container(
                      width: 34,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Pb.surface, border: Border.all(color: inkColor.withOpacity(0.7), width: 0.9)),
                      child: Text('$papers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: inkColor)),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                top: 110,
                height: 48,
                child: Center(
                  child: Text('CATEDRA',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 4, color: hv ? Pb.primary : inkColor.withOpacity(0.5))),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 166,
                child: Center(
                  child: Text(teacher ? 'Tu · $name' : name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: inkColor.withOpacity(0.75))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The catedra in ink and watercolour: the teacher behind it, two books and a cup of tea
/// on it, a panel at the front.
class _CatedraSketch extends CustomPainter {
  final String name;
  final Color ink, paper;
  _CatedraSketch(this.name, {required this.ink, required this.paper});

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Pen(canvas, color: ink, seed: 5);
    final faint = ink.withOpacity(0.4);
    // the teacher, facing the class
    final shoulders = Path()
      ..moveTo(92, 88)
      ..cubicTo(92, 62, 106, 54, 125, 54)
      ..cubicTo(144, 54, 158, 62, 158, 88);
    final seed = name.hashCode.abs();
    pen.path(shoulders, fill: paper, wash: wcShirts[(seed + 2) % wcShirts.length]);
    pen.line(const Offset(125, 54), const Offset(125, 84), color: faint, width: 0.8); // the collar
    const head = Offset(125, 32);
    pen.ring(head, 16, fill: paper, wash: wcSkin);
    final hair = Path.combine(PathOperation.difference, Path()..addOval(Rect.fromCircle(center: head, radius: 16)),
        Path()..addOval(Rect.fromCircle(center: head + const Offset(0, 9), radius: 14)));
    pen.wash(hair, wcHair[(seed ~/ 7) % wcHair.length]);
    pen.hatch(hair, gap: 2.4, angle: name.hashCode.isEven ? -1.0 : -0.6, color: ink.withOpacity(0.6));
    // the desk top and the front panel
    pen.shape(const [Offset(6, 86), Offset(244, 86), Offset(250, 110), Offset(0, 110)], fill: paper, wash: wcWood, over: 5);
    pen.rect(const Rect.fromLTRB(8, 110, 242, 158), fill: paper, wash: wcWoodDeep, over: 4);
    pen.rect(const Rect.fromLTRB(18, 118, 232, 150), color: ink.withOpacity(0.25), width: 0.8, over: 1);
    pen.hatch(Path()..addRect(const Rect.fromLTRB(232, 110, 242, 158)), gap: 3, color: ink.withOpacity(0.3), width: 0.7);
    // two books
    pen.rect(const Rect.fromLTWH(22, 80, 50, 10), fill: paper, wash: wcTerracotta, over: 1.5);
    pen.rect(const Rect.fromLTWH(28, 70, 40, 10), fill: paper, wash: wcBlue, over: 1.5);
    pen.line(const Offset(64, 80), const Offset(64, 90), color: faint, width: 0.8);
    pen.line(const Offset(31, 70), const Offset(31, 80), color: faint, width: 0.8);
    // a cup of tea, still warm
    pen.shape(const [Offset(198, 74), Offset(216, 74), Offset(214, 92), Offset(200, 92)], fill: paper, wash: wcMustard, over: 1);
    pen.path(Path()..addArc(const Rect.fromLTWH(210, 77, 11, 10), -math.pi / 2, math.pi), width: 1);
    pen.wave(const Offset(203, 69), const Offset(201, 52), amp: 1.8, waves: 1.2, color: faint, width: 0.9);
    pen.wave(const Offset(210, 68), const Offset(212, 55), amp: 1.5, waves: 1, color: faint, width: 0.9);
  }

  @override
  bool shouldRepaint(covariant _CatedraSketch old) => old.name != name || old.ink != ink || old.paper != paper;
}

/// The zoomed-in desk top: plain light wood, a few lines of grain.
class _DeskTop extends CustomPainter {
  final Color ink, wood;
  _DeskTop({required this.ink, required this.wood});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = wood);
    final pen = Pen(canvas, color: ink, seed: 3);
    final rnd = math.Random(3);
    for (var i = 0; i < 14; i++) {
      final y = rnd.nextDouble() * size.height;
      final x = rnd.nextDouble() * size.width * 0.5;
      pen.wave(Offset(x, y), Offset(x + size.width * (0.3 + rnd.nextDouble() * 0.5), y + rnd.nextDouble() * 6),
          amp: 1 + rnd.nextDouble() * 3, waves: 1 + rnd.nextDouble() * 2, color: ink.withOpacity(0.04 + rnd.nextDouble() * 0.04), width: 0.8);
    }
  }

  @override
  bool shouldRepaint(covariant _DeskTop old) => old.ink != ink || old.wood != wood;
}

/// A hand-drawn line under a word.
class _Underline extends CustomPainter {
  final Color color;
  final int seed;
  _Underline(this.color, {required this.seed});

  @override
  void paint(Canvas canvas, Size size) =>
      Pen(canvas, color: color, width: 1.6, seed: seed).line(Offset(0, size.height - 2), Offset(size.width, size.height - 3.5), over: 3);

  @override
  bool shouldRepaint(covariant _Underline old) => old.color != color || old.seed != seed;
}

/// A student's desk as the teacher sees it: the notebook with what the
/// student solved, and for each exercise the code or answer they sent.
class _StudentDesk extends StatefulWidget {
  final String sid;
  final String teacherId;
  final List<Homework> homework;
  final Map<String, Solution> sent;
  const _StudentDesk({required this.sid, required this.teacherId, required this.homework, required this.sent});

  @override
  State<_StudentDesk> createState() => _StudentDeskState();
}

class _StudentDeskState extends State<_StudentDesk> {
  late final Stream<Set<String>> _solved = Classes.solvedBy(widget.sid);

  @override
  Widget build(BuildContext context) => StreamBuilder<Set<String>>(
        stream: _solved,
        builder: (context, s) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _Notebook(
            problems: _problemsOf(widget.homework),
            solved: s.data ?? const <String>{},
            sent: widget.sent,
            student: widget.sid,
            viewer: widget.teacherId,
          ),
        ),
      );
}

/// Every exercise in [homework], soonest deadline first, each once.
List<HwProblem> _problemsOf(List<Homework> homework) {
  final seen = <String>{};
  return [
    for (final h in [...homework]..sort(_byDue))
      for (final p in h.problems)
        if (seen.add(p.progressKey)) p,
  ];
}

/// A spiral notebook lying on the desk, drawn plainly: the exercises on
/// ruled lines, each one opens the problem, solved ones crossed off.
class _Notebook extends StatelessWidget {
  final List<HwProblem> problems;
  final Set<String> solved;
  final bool teacher; // the teacher's own list: nothing to cross off
  final Map<String, Solution>? sent; // a student's notebook as the teacher reads it: what they sent
  final String student; // whose notebook, with [sent]
  final String viewer; // the teacher reading it, with [sent]
  const _Notebook({required this.problems, this.solved = const {}, this.teacher = false, this.sent, this.student = '', this.viewer = ''});
  static Color get _ink => inkColor;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final left = isMobile ? 50.0 : 72.0; // the red margin
    final line = isMobile ? 56.0 : 66.0; // one ruled line per exercise
    final done = problems.where((p) => solved.contains(p.progressKey)).length;
    return Transform.rotate(
      angle: isMobile ? 0 : -0.012,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // the page underneath, a little askew
          Positioned(
            left: 6,
            right: -6,
            top: 20,
            bottom: -6,
            child: DecoratedBox(decoration: BoxDecoration(color: paperColor, border: Border.all(color: _ink.withOpacity(0.18), width: 0.8))),
          ),
          Container(
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              color: paperColor,
              border: Border.all(color: _ink.withOpacity(0.3), width: 0.9),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: CustomPaint(
              painter: _NotebookLines(left: left, top: line * 1.6, line: line),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, line * 0.5, 0, line * 0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: line * 1.1,
                      child: Padding(
                        padding: EdgeInsets.only(left: left + 14, right: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text('Exerciții', style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: _ink)),
                            ),
                            if (problems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(teacher ? '${problems.length} ${problems.length == 1 ? 'exercițiu' : 'exerciții'}' : '$done din ${problems.length} rezolvate',
                                    style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: !teacher && done == problems.length ? hwGreen : _ink.withOpacity(0.6))),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (problems.isEmpty)
                      SizedBox(
                        height: line * 2,
                        child: Padding(
                          padding: EdgeInsets.only(left: left + 14, right: 18),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(teacher ? 'Încă n-ai dat exerciții clasei. Apasă „Temă nouă” pe tablă.' : 'Niciun exercițiu de la profesor deocamdată.',
                                style: TextStyle(fontSize: isMobile ? 16 : 18, color: _ink.withOpacity(0.7))),
                          ),
                        ),
                      ),
                    for (var i = 0; i < problems.length; i++) _row(context, i + 1, problems[i], left, line, isMobile),
                    // blank lines, so it reads as a page
                    SizedBox(height: line * math.max(2, 7 - math.max(problems.length, 2))),
                  ],
                ),
              ),
            ),
          ),
          // the spiral
          Positioned(
            top: 0,
            left: 18,
            right: 18,
            child: LayoutBuilder(
              builder: (context, box) {
                final n = (box.maxWidth / 34).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < n; i++) CustomPaint(size: const Size(10, 28), painter: _Ring(_ink, seed: i)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int n, HwProblem p, double left, double line, bool isMobile) {
    final ok = !teacher && solved.contains(p.progressKey);
    final c = ckSubjectColor(p.subject);
    final sol = sent?[p.progressKey];
    final subject = '${p.subject}${p.grade.isEmpty ? '' : ', a ${p.grade}-a'}';
    final titleStyle = TextStyle(
      fontSize: isMobile ? 17 : 22,
      fontWeight: FontWeight.w600,
      color: ok ? _ink.withOpacity(0.45) : _ink,
      decoration: ok ? TextDecoration.lineThrough : null,
      decorationColor: hwRed,
      decorationThickness: 2.2,
    );

    // where it stands: solved, new, what to tap
    Widget status(bool h) {
      final link = h ? c : Pb.primary;
      final small = isMobile ? 13.5 : 15.5;
      Widget go(String text) => Row(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: TextStyle(fontSize: isMobile ? 14 : 17, fontWeight: FontWeight.w700, color: link)),
            if (!isMobile) Icon(Icons.chevron_right, size: 22, color: link),
          ]);
      final solvedMark = [
        Icon(Icons.check_circle, size: isMobile ? 16 : 20, color: hwGreen),
        const SizedBox(width: 5),
        Text('Rezolvată', style: TextStyle(fontSize: small, fontWeight: FontWeight.w700, color: hwGreen)),
      ];
      if (sent != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ok) ...[...solvedMark, const SizedBox(width: 12)],
            if (sol != null && sol.isNewFor(viewer)) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: Pb.primary, borderRadius: BorderRadius.circular(99)),
                child: const Text('nou', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 10),
            ],
            if (sol != null)
              go(ok || sol.passed != null ? 'Vezi soluția' : 'Vezi încercarea')
            else if (!ok)
              Text('Netrimisă', style: TextStyle(fontSize: small, fontStyle: FontStyle.italic, color: _ink.withOpacity(0.45))),
          ],
        );
      }
      if (ok) return Row(mainAxisSize: MainAxisSize.min, children: solvedMark);
      return go(teacher ? 'Deschide' : 'Rezolvă');
    }

    final number = SizedBox(
      width: left,
      child: Text('$n.', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 17 : 20, fontWeight: FontWeight.w700, color: _ink.withOpacity(0.55))),
    );
    return Semantics(
      button: true,
      label: p.title,
      child: CkHover(
        onTap: () => sol != null ? _showSolution(context, p, sol, student: student, viewer: viewer) : GoRouter.of(context).push(p.path),
        builder: (h) => Container(
          height: line,
          color: h ? c.withOpacity(0.06) : Colors.transparent,
          child: isMobile
              // a phone: the title gets the whole line, where it stands goes under it
              ? Row(
                  children: [
                    number,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title.isEmpty ? p.id : p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
                          const SizedBox(height: 3),
                          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: status(h)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 22, color: _ink.withOpacity(0.35)),
                    const SizedBox(width: 8),
                  ],
                )
              : Row(
                  children: [
                    number,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: p.title.isEmpty ? p.id : p.title, style: titleStyle),
                          TextSpan(text: '   $subject', style: TextStyle(fontSize: 15, color: _ink.withOpacity(0.45))),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    status(h),
                    const SizedBox(width: 14),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The code or answer a student sent on [p]: the last version that passed,
/// and the last attempt too if it came after and doesn't pass.
void _showSolution(BuildContext context, HwProblem p, Solution s, {required String student, required String viewer}) {
  if (s.isNewFor(viewer)) Classes.markSeen(student, p.progressKey, viewer).catchError((_) {});
  String when(DateTime? d) => d == null ? '' : ' · ${d.day}.${d.month}.${d.year}, ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  final late = s.lateFor(viewer) ? ' · după termen' : '';
  Widget part(String label, Color color, String text, String? lang) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 6),
          PbCodeBox(text, lang: lang, fontSize: 13.5),
        ],
      );
  final failedAfter = !s.lastPassed && s.passed != null && s.last != s.passed;
  showPbModal<void>(
    context,
    title: p.title.isEmpty ? p.id : p.title,
    body: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.passed != null) part('A trecut toate testele${when(s.passedAt)}$late', hwGreen, s.passed!, s.passedLang),
            if (failedAfter) const SizedBox(height: 16),
            if (s.passed == null || failedAfter) part('${failedAfter ? 'Ultima încercare, ' : ''}nu trece încă testele${when(s.lastAt)}${s.passed == null ? late : ''}', hwRed, s.last, s.lastLang),
          ],
        ),
      ),
    ),
    actions: (d) => [
      PbButton(text: 'Deschide problema', variant: PbVariant.secondary, onPressed: () {
        Navigator.of(d).pop();
        GoRouter.of(context).push(p.path);
      }),
      PbButton(text: 'Închide', onPressed: () => Navigator.of(d).pop()),
    ],
  );
}

class _NotebookLines extends CustomPainter {
  final double left;
  final double top;
  final double line;
  _NotebookLines({required this.left, required this.top, required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final ruled = Paint()
      ..color = inkColor.withOpacity(0.1)
      ..strokeWidth = 0.8;
    for (var y = top; y < size.height - 4; y += line) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ruled);
    }
    canvas.drawLine(
      Offset(left, 0),
      Offset(left, size.height),
      Paint()
        ..color = hwRed.withOpacity(0.4)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _NotebookLines old) => old.left != left || old.top != top || old.line != line;
}

/// One ring of the spiral: a loop of wire through a hole in the page.
class _Ring extends CustomPainter {
  final Color ink;
  final int seed;
  _Ring(this.ink, {required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w / 2, h - 5), 2.6, Paint()..color = ink.withOpacity(0.7));
    Pen(canvas, color: ink.withOpacity(0.75), width: 1.3, seed: seed).path(
      Path()
        ..moveTo(w / 2 - 1, h - 5)
        ..cubicTo(-2, h * 0.6, -1, 1, w / 2, 1)
        ..cubicTo(w + 1, 1, w + 2, h * 0.5, w / 2 + 1, h - 8),
    );
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.ink != ink || old.seed != seed;
}
