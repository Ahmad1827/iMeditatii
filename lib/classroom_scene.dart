part of 'classes_screen.dart';

// =============================================================================
// THE CLASSROOM
//   A room on the meadow: the board and the teacher's desk (catedra) at the
//   front, double school desks (bănci) with chairs, empty until students come.
//   A student picks a free chair once; tapping their desk zooms in and the
//   homework is on the desk. The teacher taps a student's desk to see how
//   that student is doing, or the catedra for the link and all homework.
// =============================================================================

const Color _woodTop = Color(0xFFC8925A);
const Color _woodEdge = Color(0xFF9C6A3A);
const Color _woodLeg = Color(0xFF6E4A2A);
const Color _chair = Color(0xFF4F7FC9);
const Color _chairBack = Color(0xFF3E68AC);

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
    // papers appear on it.
    final r = box.localToGlobal(Offset.zero, ancestor: vp) & box.size;
    setState(() {
      _from = f.studentId == null
          ? Rect.fromLTWH(r.left + 8, r.top + 84, r.width - 16, 26)
          : Rect.fromLTWH(r.left + r.width * 0.1, r.top + r.height * 0.02, r.width * 0.8, r.height * 0.26);
      _focus = f;
    });
    _zoom.forward(from: 0);
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
          builder: (context, ss) {
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
    );
  }

  // ---------------------------------------------------------------- the room
  Widget _room(List<SchoolClass> classes, SchoolClass? c, List<Homework> hw, double width) {
    final narrow = width < 760;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 24, 16, narrow ? 12 : 24, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _signs(classes, c),
              const SizedBox(height: 18),
              _front(classes, c, hw, narrow),
              const SizedBox(height: 26),
              if (c != null) ...[
                _benches(c, hw, narrow, width),
                const SizedBox(height: 18),
                Center(child: _hint(c)),
              ] else
                _benches(null, hw, narrow, width),
            ],
          ),
        ),
      ),
    );
  }

  /// The classes as wooden signs, to switch between them.
  Widget _signs(List<SchoolClass> classes, SchoolClass? c) {
    Widget sign(String text, {bool on = false, IconData? icon, VoidCallback? onTap, bool paper = false}) => CkHover(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: paper ? null : LinearGradient(colors: on ? const [Color(0xFFD9A066), _woodTop] : const [_woodEdge, Color(0xFF8A5C32)]),
              color: paper ? Pb.surface.withOpacity(0.92) : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? Colors.white : Colors.black.withOpacity(0.12), width: on ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: paper ? Pb.primary : Colors.white), const SizedBox(width: 6)],
                Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: paper ? Pb.primary : Colors.white)),
              ],
            ),
          ),
        );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final x in classes) sign(x.displayName, on: x.id == c?.id, onTap: () => setState(() => _selected = x.id)),
        if (widget.teacher)
          sign('Clasă nouă', icon: Icons.add, paper: true, onTap: _newClass)
        else
          sign(classes.isEmpty ? 'Am un cod de clasă' : 'Altă clasă', icon: Icons.vpn_key_outlined, paper: true, onTap: _joinByCode),
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
              style: chalk(narrow ? 20 : 23, color: chalkWhite.withOpacity(0.8), weight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ChalkButton(
              text: widget.teacher ? 'Creează clasa' : 'Am un cod de clasă',
              icon: widget.teacher ? Icons.group_add_outlined : Icons.vpn_key_outlined,
              filled: true,
              onTap: widget.teacher ? _newClass : _joinByCode,
            ),
          ] else ...[
            Text(c.subject.isEmpty ? 'Clasa' : c.subject, style: chalk(narrow ? 22 : 25, color: chalkYellow)),
            Text(c.displayName, style: chalk(narrow ? 40 : 52, height: 1.1)),
            const SizedBox(height: 4),
            Text(
              widget.teacher
                  ? '${c.members.isEmpty ? 'Niciun elev încă' : (c.members.length == 1 ? '1 elev' : '${c.members.length} elevi')} · cod ${c.id}'
                  : 'cu ${c.teacherName}',
              style: chalk(narrow ? 20 : 23, color: chalkWhite.withOpacity(0.8), weight: FontWeight.w500),
            ),
            if (widget.teacher) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChalkButton(text: 'Temă nouă', icon: Icons.assignment_add, filled: true, onTap: () => _newHomework(classes, c)),
                  ChalkButton(text: 'Copiază linkul', icon: Icons.link, onTap: () => copyClassLink(context, c.id)),
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
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [board, const SizedBox(height: 18), Center(child: catedra)]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Expanded(child: board), const SizedBox(width: 28), catedra],
    );
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
    final avail = math.min(1000.0, width - (narrow ? 24 : 48));
    final gapX = narrow ? 14.0 : 34.0;
    final w = math.min(240.0, (avail - gapX * (cols - 1)) / cols);
    final benches = <Widget>[];
    for (var b = 0; b < seats.length ~/ 2; b++) {
      benches.add(_Bench(
        key: _key('bench_$b'),
        width: w,
        sides: [for (final i in [b * 2, b * 2 + 1]) _side(c, hw, seats[i], i, meUnseated, b)],
      ));
    }
    return Wrap(alignment: WrapAlignment.center, spacing: gapX, runSpacing: narrow ? 18 : 30, children: benches);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Pb.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
    );
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
      papers = _catedraPapers(classes, c, hw);
    } else if (sid == widget.uid) {
      papers = _myPapers(_homeworkOf(c, hw, sid), solved);
    } else {
      papers = [_StudentDesk(c: c, sid: sid, name: member?.name ?? 'Elev', homework: _homeworkOf(c, hw, sid))];
    }

    return CustomPaint(
      painter: _WoodGrain(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 14, isMobile ? 12 : 24, 6),
              child: Row(
                children: [
                  CkHover(
                    onTap: _close,
                    builder: (h) => AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(h ? 1 : 0.92),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 17, color: Color(0xFF3D3A2A)),
                          SizedBox(width: 6),
                          Text('Înapoi în clasă', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3D3A2A))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 17 : 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
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
                      constraints: const BoxConstraints(maxWidth: 820),
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

  List<Widget> _catedraPapers(List<SchoolClass> classes, SchoolClass c, List<Homework> hw) {
    final mine = [
      for (final h in hw)
        if (h.classIds.contains(c.id) || h.studentIds.any(c.hasMember)) h,
    ];
    return [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          PbButton(text: 'Temă nouă', icon: Icons.assignment_add, onPressed: () => _newHomework(classes, c)),
          PbButton(
            text: 'Redenumește',
            icon: Icons.edit_outlined,
            variant: PbVariant.light,
            onPressed: () => showDialog<String>(context: context, builder: (_) => _ClassNameDialog(uid: widget.uid, teacherName: c.teacherName, existing: c)),
          ),
          PbButton(text: 'Șterge clasa', icon: Icons.delete_outline, variant: PbVariant.danger, onPressed: () => _deleteClass(c)),
        ],
      ),
      const SizedBox(height: 22),
      _linkNote(context, c),
      const SizedBox(height: 10),
      paperLabel('Teme date', count: '${mine.length}'),
      _TeacherHomeworkList(
        homework: mine,
        classes: [c],
        showClass: false,
        empty: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _emptyBox(Icons.assignment_outlined, 'Nicio temă pentru clasa asta', 'Elevii văd tema imediat, pe bancă și în colțul ecranului.',
              action: PbButton(text: 'Dă prima temă', icon: Icons.assignment_add, onPressed: () => _newHomework(classes, c))),
        ),
      ),
    ];
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

/// The invite link, on a sticky note.
Widget _linkNote(BuildContext context, SchoolClass c) => StickyNote(
      angle: -0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.link, size: 20, color: StickyNote.ink),
                const SizedBox(width: 8),
                Flexible(child: Text('Linkul clasei', maxLines: 1, overflow: TextOverflow.ellipsis, style: chalk(26, color: StickyNote.ink))),
              ],
            ),
            Text(
              'Cine îl deschide își face cont (sau intră în cont), ajunge în clasă și își alege o bancă.',
              style: TextStyle(fontSize: 13, color: StickyNote.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Pb.surface.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
              child: SelectableText(classLink(c.id), style: TextStyle(fontSize: 13.5, fontFamily: 'monospace', color: Pb.text)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PbButton(text: 'Copiază linkul', icon: Icons.copy, size: PbSize.sm, onPressed: () => copyClassLink(context, c.id)),
                PbButton(text: 'WhatsApp', icon: Icons.chat_outlined, size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => shareClassOnWhatsApp(c)),
                Text('sau codul ', style: TextStyle(fontSize: 13, color: StickyNote.inkMuted)),
                SelectableText(c.id, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2, color: StickyNote.ink)),
              ],
            ),
          ],
        ),
      ),
    );

// ---------------------------------------------------------------- furniture
/// One half of a bench: a chair, maybe someone on it, maybe papers.
class _Side {
  final bool empty;
  final bool pickable; // the viewing student can sit here
  final String name;
  final bool me;
  final String? paper; // text on the paper on the desk
  final bool paperLate;
  final VoidCallback? onTap;
  const _Side({this.empty = false, this.pickable = false, this.name = '', this.me = false, this.paper, this.paperLate = false, this.onTap});
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
          // legs
          for (final x in [0.05, 0.93]) Positioned(left: w * x, top: h * 0.3, child: Container(width: w * 0.025, height: h * 0.3, color: _woodLeg)),
          // desk top and its front edge
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Column(
              children: [
                Container(
                  height: h * 0.3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7A36B), _woodTop]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                ),
                Container(
                  height: h * 0.07,
                  decoration: BoxDecoration(
                    color: _woodEdge,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6))],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < 2; i++) ..._sideWidgets(context, sides[i], w * (0.25 + 0.5 * i), w, h),
        ],
      ),
    );
  }

  List<Widget> _sideWidgets(BuildContext context, _Side s, double cx, double w, double h) {
    final chairW = w * 0.3;
    final body = w * 0.25;
    final first = s.name.split(' ').first;
    return [
      // paper on the desk
      if (s.paper != null)
        Positioned(
          left: cx - w * 0.09,
          top: h * 0.04,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: w * 0.18,
              height: h * 0.2,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border(left: BorderSide(color: s.paperLate ? hwRed : const Color(0xFFE5484D), width: 2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(1, 2))],
              ),
              child: Text(s.paper!, style: TextStyle(fontSize: math.max(10, w * 0.055), fontWeight: FontWeight.w800, color: s.paperLate ? hwRed : const Color(0xFF3D3A2A))),
            ),
          ),
        ),
      // chair seat
      Positioned(
        left: cx - chairW / 2,
        top: h * 0.5,
        child: Container(
          width: chairW,
          height: h * 0.13,
          decoration: BoxDecoration(color: _chair.withOpacity(s.empty ? 0.85 : 1), borderRadius: BorderRadius.circular(6)),
        ),
      ),
      // the student: shoulders and head, between the desk and the chair back
      if (!s.empty)
        Positioned(
          left: cx - body * 0.6,
          top: h * 0.2,
          child: CustomPaint(size: Size(body * 1.2, h * 0.5), painter: _Person(s.name, back: true, ring: s.me ? Pb.primary : null)),
        ),
      // chair back, closest to us
      Positioned(
        left: cx - chairW * 0.56,
        top: h * 0.64,
        child: Container(
          width: chairW * 1.12,
          height: h * 0.15,
          decoration: BoxDecoration(
            color: _chairBack,
            borderRadius: BorderRadius.circular(8),
            border: s.pickable ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: [
              if (s.pickable) BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 12, spreadRadius: 1),
              BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 4)),
            ],
          ),
        ),
      ),
      for (final x in [-0.4, 0.36])
        Positioned(left: cx + chairW * x, top: h * 0.79, child: Container(width: w * 0.02, height: h * 0.07, color: const Color(0xFF2E3A4A))),
      // name tag
      Positioned(
        left: cx - w * 0.24,
        width: w * 0.48,
        top: h * 0.88,
        child: Center(
          child: s.empty && !s.pickable
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: s.me ? Pb.primary : (s.pickable ? Colors.white : Pb.surface.withOpacity(0.95)),
                    borderRadius: BorderRadius.circular(99),
                    border: s.pickable ? Border.all(color: Pb.primary) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    s.pickable ? 'Stai aici' : (s.me ? 'Tu' : first),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: math.max(10.5, w * 0.052), fontWeight: FontWeight.w700, color: s.me ? Colors.white : (s.pickable ? Pb.primary : Pb.text)),
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
          child: CkHover(onTap: s.onTap, builder: (hv) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: hv && s.onTap != null ? Colors.white.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          )),
        ),
      ),
    ];
  }
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
              // the teacher, behind the desk, facing the class
              Positioned(left: w / 2 - 45, top: 0, child: CustomPaint(size: const Size(90, 100), painter: _Person(name, back: false))),
              // desk top
              Positioned(
                left: 0,
                right: 0,
                top: 84,
                child: Container(
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7A36B), _woodTop]),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: hv ? Colors.white : Colors.black.withOpacity(0.08), width: hv ? 2 : 1),
                  ),
                ),
              ),
              // things on the desk: books, an apple, the papers
              Positioned(left: 24, top: 70, child: _book(const Color(0xFF3B82F6), 46)),
              Positioned(left: 30, top: 62, child: _book(const Color(0xFFE5484D), 38)),
              Positioned(
                right: 30,
                top: 66,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
                  child: const Align(alignment: Alignment(0.1, -1.4), child: SizedBox(width: 3, height: 7, child: ColoredBox(color: Color(0xFF6E4A2A)))),
                ),
              ),
              if (papers > 0)
                Positioned(
                  right: 62,
                  top: 72,
                  child: Transform.rotate(
                    angle: 0.06,
                    child: Container(
                      width: 34,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2), boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(1, 2)),
                      ]),
                      child: Text('$papers', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3D3A2A))),
                    ),
                  ),
                ),
              // the front panel
              Positioned(
                left: 8,
                right: 8,
                top: 108,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_woodEdge, Color(0xFF85582F)]),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 8))],
                  ),
                  alignment: Alignment.center,
                  child: Text('CATEDRA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white.withOpacity(0.75))),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 166,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Pb.surface.withOpacity(0.95), borderRadius: BorderRadius.circular(99)),
                    child: Text(teacher ? 'Tu · $name' : name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Pb.text)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _book(Color c, double w) => Container(
        width: w,
        height: 9,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2), border: Border(right: BorderSide(color: Colors.white.withOpacity(0.8), width: 3))),
      );
}

/// Wood for the zoomed-in desk top.
class _WoodGrain extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFC99560), Color(0xFFB07B47), Color(0xFFC08A55)]).createShader(rect),
    );
    final rnd = math.Random(3);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final y = rnd.nextDouble() * size.height;
      final amp = 2 + rnd.nextDouble() * 6;
      final len = 40 + rnd.nextDouble() * 120;
      p
        ..color = const Color(0xFF7A4E26).withOpacity(0.05 + rnd.nextDouble() * 0.09)
        ..strokeWidth = 0.8 + rnd.nextDouble() * 1.6;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 24) {
        path.lineTo(x, y + math.sin(x / len + i) * amp);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A student's desk as the teacher sees it: each homework with how far the
/// student got.
class _StudentDesk extends StatefulWidget {
  final SchoolClass c;
  final String sid;
  final String name;
  final List<Homework> homework;
  const _StudentDesk({required this.c, required this.sid, required this.name, required this.homework});

  @override
  State<_StudentDesk> createState() => _StudentDeskState();
}

class _StudentDeskState extends State<_StudentDesk> {
  late final Stream<Set<String>> _solved = Classes.solvedBy(widget.sid);

  @override
  Widget build(BuildContext context) {
    final list = [...widget.homework]..sort(_byDue);
    final done = list.where((h) => h.isDone(widget.sid)).length;
    return StreamBuilder<Set<String>>(
      stream: _solved,
      builder: (context, s) {
        final solved = s.data ?? const <String>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StickyNote(
              angle: 0.8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                child: Row(
                  children: [
                    CkAvatar(name: widget.name, image: '', size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name, style: chalk(28, color: StickyNote.ink)),
                          Text(list.isEmpty ? 'Nicio temă încă' : '$done din ${list.length} teme terminate',
                              style: TextStyle(fontSize: 13.5, color: StickyNote.inkMuted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    PbButton(text: 'Profil', size: PbSize.sm, variant: PbVariant.outlineSecondary, onPressed: () => context.go('/elev/${widget.sid}')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Notebook(problems: _problemsOf(list), solved: solved),
          ],
        );
      },
    );
  }

}


/// A person drawn simply: a student from behind (hair, ears, shoulders) or
/// the teacher facing the class. Hair, skin and shirt come from the name, so
/// everyone keeps their look.
class _Person extends CustomPainter {
  final String name;
  final bool back;
  final Color? ring;
  _Person(this.name, {required this.back, this.ring});

  static const _hair = [Color(0xFF2B1D14), Color(0xFF4A2F1E), Color(0xFF7A4B2A), Color(0xFFC9A063), Color(0xFF8E3B1F), Color(0xFF1C1C1C)];
  static const _skin = [Color(0xFFF1C7A5), Color(0xFFE0AC85), Color(0xFFC68A62), Color(0xFF8D5A3C)];

  @override
  void paint(Canvas canvas, Size size) {
    final seed = name.hashCode.abs();
    final hair = _hair[seed % _hair.length];
    final skin = _skin[(seed ~/ 7) % _skin.length];
    final shirt = ckColorFor(name);
    final w = size.width, h = size.height;
    final r = w * 0.24; // head radius
    final head = Offset(w / 2, h * 0.3);

    // shoulders
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.08, h * 0.55, w * 0.84, h * 0.6),
      topLeft: Radius.circular(w * 0.36),
      topRight: Radius.circular(w * 0.36),
    );
    canvas.drawRRect(body, Paint()..color = shirt);
    // neck
    canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, h * 0.53), width: r * 0.8, height: h * 0.14), Paint()..color = Color.lerp(skin, Colors.black, 0.08)!);

    if (back) {
      // ears, then the back of the head: all hair
      final ear = Paint()..color = skin;
      canvas.drawCircle(head + Offset(-r * 0.98, r * 0.15), r * 0.22, ear);
      canvas.drawCircle(head + Offset(r * 0.98, r * 0.15), r * 0.22, ear);
      canvas.drawCircle(head, r, Paint()..color = hair);
      canvas.drawCircle(head + Offset(-r * 0.3, -r * 0.35), r * 0.35, Paint()..color = Colors.white.withOpacity(0.12));
      if (seed % 3 == 0) {
        // a ponytail
        canvas.drawOval(Rect.fromCenter(center: head + Offset(0, r * 1.15), width: r * 0.55, height: r * 0.9), Paint()..color = hair);
      }
    } else {
      // hair behind the face, the face, then the fringe
      canvas.drawCircle(head + Offset(0, -r * 0.08), r * 1.12, Paint()..color = hair);
      canvas.drawCircle(head, r, Paint()..color = skin);
      final fringe = Path()
        ..addArc(Rect.fromCircle(center: head + Offset(0, -r * 0.08), radius: r * 1.12), math.pi * 1.05, math.pi * 0.9)
        ..quadraticBezierTo(head.dx + r * 0.2, head.dy - r * 0.35, head.dx - r * 1.05, head.dy - r * 0.2);
      canvas.drawPath(fringe, Paint()..color = hair);
      final ink = Paint()..color = const Color(0xFF2B1D14);
      canvas.drawCircle(head + Offset(-r * 0.36, r * 0.08), r * 0.1, ink);
      canvas.drawCircle(head + Offset(r * 0.36, r * 0.08), r * 0.1, ink);
      canvas.drawArc(
        Rect.fromCenter(center: head + Offset(0, r * 0.3), width: r * 0.8, height: r * 0.55),
        0.2,
        math.pi - 0.4,
        false,
        Paint()
          ..color = const Color(0xFF8A3B2E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.09
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(head + Offset(-r * 0.6, r * 0.38), r * 0.14, Paint()..color = const Color(0x33E5484D));
      canvas.drawCircle(head + Offset(r * 0.6, r * 0.38), r * 0.14, Paint()..color = const Color(0x33E5484D));
    }
    if (ring != null) {
      canvas.drawCircle(
        head,
        r * 1.22,
        Paint()
          ..color = ring!
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.5, r * 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Person old) => old.name != name || old.back != back || old.ring != ring;
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

/// A spiral notebook lying on the desk: the exercises on ruled lines, each
/// one opens the problem, solved ones crossed off.
class _Notebook extends StatelessWidget {
  final List<HwProblem> problems;
  final Set<String> solved;
  const _Notebook({required this.problems, required this.solved});

  static const double line = 46; // one ruled line per exercise
  static const Color _ink = Color(0xFF2B3A55);
  static const Color _paper = Color(0xFFFFFEF8);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final left = isMobile ? 46.0 : 64.0; // the red margin
    final done = problems.where((p) => solved.contains(p.progressKey)).length;
    return Transform.rotate(
      angle: isMobile ? 0 : -0.012,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 12)),
                // the pages underneath
                const BoxShadow(color: Color(0xFFEDE8DA), offset: Offset(3, 4)),
                const BoxShadow(color: Color(0xFFE2DCCB), offset: Offset(6, 8)),
              ],
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
                              child: Text('Exerciții', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w800, color: _ink)),
                            ),
                            if (problems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('$done din ${problems.length} rezolvate',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: done == problems.length ? hwGreen : _ink.withOpacity(0.6))),
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
                            child: Text('Niciun exercițiu de la profesor deocamdată.', style: TextStyle(fontSize: 15.5, color: _ink.withOpacity(0.7))),
                          ),
                        ),
                      ),
                    for (var i = 0; i < problems.length; i++) _row(context, i + 1, problems[i], left, isMobile),
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
                    for (var i = 0; i < n; i++)
                      Container(
                        width: 10,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8D96A0), Color(0xFFE3E7EB), Color(0xFF8D96A0)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int n, HwProblem p, double left, bool isMobile) {
    final ok = solved.contains(p.progressKey);
    final c = ckSubjectColor(p.subject);
    return Semantics(
      button: true,
      label: p.title,
      child: CkHover(
        onTap: () => GoRouter.of(context).push(p.path),
        builder: (h) => Container(
          height: line,
          color: h ? c.withOpacity(0.06) : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: left,
                child: Text('$n.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink.withOpacity(0.55))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: p.title.isEmpty ? p.id : p.title,
                      style: TextStyle(
                        fontSize: isMobile ? 15.5 : 17,
                        fontWeight: FontWeight.w600,
                        color: ok ? _ink.withOpacity(0.45) : _ink,
                        decoration: ok ? TextDecoration.lineThrough : null,
                        decorationColor: hwRed,
                        decorationThickness: 2.2,
                      ),
                    ),
                    if (!isMobile)
                      TextSpan(
                        text: '   ${p.subject}${p.grade.isEmpty ? '' : ', a ${p.grade}-a'}',
                        style: TextStyle(fontSize: 12.5, color: _ink.withOpacity(0.45)),
                      ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (ok)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: hwGreen),
                    SizedBox(width: 4),
                    Text('Rezolvată', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hwGreen)),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rezolvă', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: h ? c : Pb.primary)),
                    Icon(Icons.chevron_right, size: 19, color: h ? c : Pb.primary),
                  ],
                ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookLines extends CustomPainter {
  final double left;
  final double top;
  final double line;
  _NotebookLines({required this.left, required this.top, required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFF8BB4E8).withOpacity(0.55)
      ..strokeWidth = 1;
    for (var y = top; y < size.height - 4; y += line) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), blue);
    }
    final red = Paint()
      ..color = const Color(0xFFE5484D).withOpacity(0.6)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(left, 0), Offset(left, size.height), red);
    canvas.drawLine(Offset(left + 3, 0), Offset(left + 3, size.height), red..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant _NotebookLines old) => old.left != left || old.top != top || old.line != line;
}
