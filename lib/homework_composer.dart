import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'clean_kit.dart';
import 'classes_models.dart';
import 'homework_dock.dart' show hwDueLabel;
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize;
import 'workspace_models.dart';
import 'workspace_screen.dart' show wsDialogShell, wsDocColor, wsDocIcon;

// =============================================================================
// HOMEWORK COMPOSER — one dialog: who gets it, what to do, until when, and
// optionally problems from the bank and a page from the Atelier.
// =============================================================================

/// Returns true when the homework was sent.
Future<bool?> showHomeworkComposer(
  BuildContext context, {
  required String teacherId,
  required String teacherName,
  required List<SchoolClass> classes,
  Set<String> preselectClasses = const {},
  Set<String> preselectStudents = const {},
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _Composer(
        teacherId: teacherId,
        teacherName: teacherName,
        classes: classes,
        preselectClasses: preselectClasses,
        preselectStudents: preselectStudents,
      ),
    );

class _Composer extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final List<SchoolClass> classes;
  final Set<String> preselectClasses;
  final Set<String> preselectStudents;

  const _Composer({
    required this.teacherId,
    required this.teacherName,
    required this.classes,
    required this.preselectClasses,
    required this.preselectStudents,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  late final Set<String> _classes = {...widget.preselectClasses};
  late final Set<String> _students = {...widget.preselectStudents};
  List<HwStudent>? _allStudents;
  bool _pickStudents = false;
  String _studentQuery = '';

  DateTime? _due;
  final List<HwProblem> _problems = [];
  HwMaterial? _material;
  List<WsDoc>? _docs;

  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pickStudents = widget.preselectStudents.isNotEmpty || widget.classes.isEmpty;
    Classes.studentsOf(widget.teacherId, widget.classes).then((s) {
      if (mounted) setState(() => _allStudents = s);
    });
    Workspace.myDocs(widget.teacherId).first.then((d) {
      if (mounted) setState(() => _docs = d);
    }).catchError((_) {
      if (mounted) setState(() => _docs = const []);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  int get _recipientCount {
    final ids = <String>{..._students};
    for (final c in widget.classes) {
      if (_classes.contains(c.id)) ids.addAll(c.members.map((m) => m.id));
    }
    return ids.length;
  }

  Future<void> _send() async {
    if (_classes.isEmpty && _students.isEmpty) {
      setState(() => _error = 'Alege cel puțin o clasă sau un elev.');
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Dă-i temei un titlu, ca elevii să o recunoască.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final byId = {for (final s in _allStudents ?? const <HwStudent>[]) s.id: s};
      await Classes.assign(
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        title: _title.text,
        instructions: _text.text,
        dueAt: _due,
        toClasses: widget.classes.where((c) => _classes.contains(c.id)).toList(),
        toStudents: [for (final id in _students) byId[id] ?? HwStudent(id, 'Elev')],
        problems: _problems,
        material: _material,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Nu am putut trimite tema. Verifică conexiunea și încearcă din nou.';
        });
      }
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final n = _recipientCount;
    return wsDialogShell(
      title: 'Temă nouă',
      subtitle: 'Elevii o văd imediat, pe orice pagină a site-ului.',
      maxWidth: 600,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Pentru cine'),
            _recipients(),
            const SizedBox(height: 18),
            _label('Ce au de făcut'),
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 120,
              style: TextStyle(fontSize: 15, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: Pb.input(hint: 'Titlu, de ex. „Ecuații de gradul II”').copyWith(counterText: ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 8,
              maxLength: 4000,
              style: TextStyle(fontSize: 14.5, color: Pb.text, height: 1.45),
              cursorColor: Pb.primary,
              decoration: Pb.input(hint: 'Cerința (opțional): ce exerciții din manual, ce să predea, cum…').copyWith(counterText: ''),
            ),
            const SizedBox(height: 18),
            _label('Termen'),
            _dueChips(),
            const SizedBox(height: 18),
            _label('Atașează (opțional)'),
            _attachments(),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(fontSize: 13.5, color: Color(0xFFE5484D), fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      actions: [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: _sending ? null : () => Navigator.of(context).pop()),
        PbButton(
          text: n == 0 ? 'Trimite tema' : (n == 1 ? 'Trimite la un elev' : 'Trimite la $n elevi'),
          icon: Icons.send,
          loading: _sending,
          onPressed: _send,
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.5)),
      );

  Widget _chip(String text, bool sel, VoidCallback onTap, {IconData? icon, String? sub}) => CkHover(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? Pb.primary.withOpacity(0.10) : (h ? Pb.hoverBg : Pb.surface),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sel ? Pb.primary : Pb.inputBorder, width: sel ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sel ? Icons.check : (icon ?? Icons.add), size: 15, color: sel ? Pb.primary : Pb.muted),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: sel ? Pb.primary : Pb.text)),
              if (sub != null) ...[
                const SizedBox(width: 5),
                Text(sub, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ],
            ],
          ),
        ),
      );

  Widget _recipients() {
    final students = _allStudents;
    final q = _studentQuery.trim().toLowerCase();
    final shown = students == null ? const <HwStudent>[] : (q.isEmpty ? students : students.where((s) => s.name.toLowerCase().contains(q)).toList());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in widget.classes)
              _chip(
                c.displayName,
                _classes.contains(c.id),
                () => setState(() => _classes.contains(c.id) ? _classes.remove(c.id) : _classes.add(c.id)),
                icon: Icons.groups_outlined,
                sub: '${c.members.length}',
              ),
            _chip(
              _students.isEmpty ? 'Elevi anume' : (_students.length == 1 ? '1 elev' : '${_students.length} elevi'),
              _students.isNotEmpty || _pickStudents,
              () => setState(() => _pickStudents = !_pickStudents),
              icon: Icons.person_add_alt,
            ),
          ],
        ),
        if (widget.classes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Nu ai încă nicio clasă. Poți trimite elevilor tăi pe nume, sau creezi o clasă și le dai linkul.',
                style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.4)),
          ),
        if (_pickStudents) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Pb.border), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    onChanged: (v) => setState(() => _studentQuery = v),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: students == null
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary))))
                      : (shown.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                students.isEmpty
                                    ? 'Aici apar elevii din clasele tale și cei cu care ai o conversație.'
                                    : 'Niciun elev cu acest nume.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13.5, color: Pb.muted),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                              children: [for (final s in shown) _studentRow(s)],
                            )),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _studentRow(HwStudent s) {
    final sel = _students.contains(s.id);
    final viaClass = widget.classes.where((c) => _classes.contains(c.id) && c.hasMember(s.id)).map((c) => c.displayName).toList();
    return CkHover(
      onTap: () => setState(() => sel ? _students.remove(s.id) : _students.add(s.id)),
      builder: (h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? Pb.primary.withOpacity(0.07) : (h ? Pb.hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _check(sel),
            const SizedBox(width: 10),
            CkAvatar(name: s.name, image: '', size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text))),
            if (viaClass.isNotEmpty) Text('deja prin ${viaClass.first}', style: TextStyle(fontSize: 12, color: Pb.muted)),
          ],
        ),
      ),
    );
  }

  Widget _check(bool sel) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: sel ? Pb.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: sel ? Pb.primary : Pb.inputBorder, width: 1.6),
        ),
        child: sel ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
      );

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59);

  Widget _dueChips() {
    final now = DateTime.now();
    final options = <(String, DateTime?)>[
      ('Fără termen', null),
      ('Mâine', _endOfDay(now.add(const Duration(days: 1)))),
      ('Peste 3 zile', _endOfDay(now.add(const Duration(days: 3)))),
      ('Peste o săptămână', _endOfDay(now.add(const Duration(days: 7)))),
    ];
    bool same(DateTime? a, DateTime? b) => a == null || b == null ? a == b : a.isAtSameMomentAs(b);
    final custom = _due != null && !options.any((o) => same(o.$2, _due));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options) _chip(o.$1, same(o.$2, _due), () => setState(() => _due = o.$2), icon: Icons.event_outlined),
        _chip(
          custom ? hwDueLabel(_due!) : 'Altă zi…',
          custom,
          () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _due ?? now.add(const Duration(days: 1)),
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: now.add(const Duration(days: 365)),
              helpText: 'Termenul temei',
              cancelText: 'Renunță',
              confirmText: 'Alege',
            );
            if (picked != null && mounted) setState(() => _due = _endOfDay(picked));
          },
          icon: Icons.calendar_month_outlined,
        ),
        if (_due != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text('până ${hwDueLabel(_due!)}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
          ),
      ],
    );
  }

  Widget _attachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in _problems)
          _attachedRow(
            icon: ckSubjectIcon(p.subject),
            color: ckSubjectColor(p.subject),
            title: p.title,
            sub: '${p.subject}, clasa a ${p.grade}-a',
            onRemove: () => setState(() => _problems.remove(p)),
          ),
        if (_material != null)
          _attachedRow(
            icon: wsDocIcon(_material!.type),
            color: wsDocColor(_material!.type, _material!.lang),
            title: _material!.displayTitle,
            sub: 'din Atelier, fiecare elev primește copia lui',
            onRemove: () => setState(() => _material = null),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PbButton(
              text: _problems.isEmpty ? 'Probleme din bancă' : 'Mai adaugă probleme',
              icon: Icons.functions,
              size: PbSize.sm,
              variant: PbVariant.outlinePrimary,
              onPressed: () async {
                final picked = await showDialog<List<HwProblem>>(
                  context: context,
                  builder: (_) => _ProblemPicker(already: {for (final p in _problems) '${p.subject}/${p.id}'}),
                );
                if (picked != null && mounted) setState(() => _problems.addAll(picked));
              },
            ),
            if (_material == null)
              PbButton(
                text: 'Pagină din Atelier',
                icon: Icons.auto_stories_outlined,
                size: PbSize.sm,
                variant: PbVariant.outlineSecondary,
                onPressed: _docs == null || _docs!.isEmpty
                    ? null
                    : () async {
                        final d = await showDialog<WsDoc>(context: context, builder: (_) => _DocPicker(docs: _docs!));
                        if (d != null && mounted) {
                          setState(() => _material = HwMaterial(docId: d.id, type: d.type, title: d.title, lang: d.lang));
                        }
                      },
              ),
          ],
        ),
      ],
    );
  }

  Widget _attachedRow({required IconData icon, required Color color, required String title, required String sub, required VoidCallback onRemove}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Pb.muted)),
                ],
              ),
            ),
            IconButton(icon: Icon(Icons.close, size: 17, color: Pb.muted), splashRadius: 16, tooltip: 'Scoate', onPressed: onRemove),
          ],
        ),
      );
}

// ----------------------------------------------------------------- problem picker
class _ProblemPicker extends StatefulWidget {
  final Set<String> already; // "subject/id"
  const _ProblemPicker({required this.already});

  @override
  State<_ProblemPicker> createState() => _ProblemPickerState();
}

class _ProblemPickerState extends State<_ProblemPicker> {
  Map<String, dynamic>? _bank; // subject -> grade -> category -> [{id,title,difficulty}]
  String? _subject;
  String? _grade;
  String _q = '';
  final Map<String, HwProblem> _sel = {};

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/data/exercises.json').then((raw) {
      final bank = json.decode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _subject = bank.keys.contains('Matematică') ? 'Matematică' : bank.keys.first;
        _grade = (bank[_subject] as Map).keys.first.toString();
      });
    }).catchError((_) {
      if (mounted) setState(() => _bank = const {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final bank = _bank;
    Widget body;
    if (bank == null) {
      body = const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));
    } else if (bank.isEmpty) {
      body = Padding(padding: const EdgeInsets.all(24), child: Text('Nu am putut încărca banca de probleme.', style: TextStyle(color: Pb.muted)));
    } else {
      final grades = ((bank[_subject] as Map?) ?? const {}).cast<String, dynamic>();
      final q = _q.trim().toLowerCase();
      final rows = <Widget>[];
      final cats = ((grades[_grade] as Map?) ?? const {}).cast<String, dynamic>();
      for (final cat in cats.entries) {
        final items = [
          for (final e in (cat.value as List))
            if (q.isEmpty || '${e['title']}'.toLowerCase().contains(q)) e as Map,
        ];
        if (items.isEmpty) continue;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
          child: Text(cat.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Pb.muted)),
        ));
        for (final e in items) {
          final key = '$_subject/${e['id']}';
          final had = widget.already.contains(key);
          final sel = _sel.containsKey(key);
          rows.add(CkHover(
            onTap: had
                ? null
                : () => setState(() => sel
                    ? _sel.remove(key)
                    : _sel[key] = HwProblem(id: '${e['id']}', title: '${e['title']}', subject: _subject!, grade: _grade!)),
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? Pb.primary.withOpacity(0.07) : (h && !had ? Pb.hoverBg : Colors.transparent),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Opacity(
                opacity: had ? 0.5 : 1,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: sel || had ? Pb.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: sel || had ? Pb.primary : Pb.inputBorder, width: 1.6),
                      ),
                      child: sel || had ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${e['title']}', style: TextStyle(fontSize: 14, color: Pb.text))),
                    Text('${e['difficulty'] ?? ''}', style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ],
                ),
              ),
            ),
          ));
        }
      }
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in bank.keys)
                  _seg(s, s == _subject, () => setState(() {
                        _subject = s;
                        final gs = (bank[s] as Map).keys.map((k) => '$k').toList();
                        if (!gs.contains(_grade)) _grade = gs.first;
                      })),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                for (final g in grades.keys) Padding(padding: const EdgeInsets.only(right: 6), child: _seg('a $g-a', g == _grade, () => setState(() => _grade = g))),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    style: TextStyle(fontSize: 14, color: Pb.text),
                    cursorColor: Pb.primary,
                    decoration: Pb.input(hint: 'Caută').copyWith(
                      hintStyle: TextStyle(fontSize: 14, color: Pb.muted),
                      prefixIcon: Icon(Icons.search, size: 17, color: Pb.muted),
                      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: rows.isEmpty
                ? Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Nicio problemă găsită.', style: TextStyle(color: Pb.muted))))
                : ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(6, 0, 6, 10), children: rows),
          ),
        ],
      );
    }
    final n = _sel.length;
    return wsDialogShell(
      title: 'Probleme din bancă',
      subtitle: 'Bifează câte vrei. Elevul le deschide direct din temă.',
      maxWidth: 560,
      body: body,
      actions: [
        PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(context).pop()),
        PbButton(
          text: n == 0 ? 'Alege problemele' : (n == 1 ? 'Adaugă o problemă' : 'Adaugă $n probleme'),
          icon: Icons.add,
          onPressed: n == 0 ? null : () => Navigator.of(context).pop(_sel.values.toList()),
        ),
      ],
    );
  }

  Widget _seg(String text, bool sel, VoidCallback onTap) => CkHover(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? Pb.primary : (h ? Pb.hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? Pb.primary : Pb.border),
          ),
          child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Pb.text)),
        ),
      );
}

// ----------------------------------------------------------------- atelier picker
class _DocPicker extends StatelessWidget {
  final List<WsDoc> docs;
  const _DocPicker({required this.docs});

  @override
  Widget build(BuildContext context) => wsDialogShell(
        title: 'Pagină din Atelier',
        subtitle: 'Fiecare elev primește copia lui când deschide tema.',
        body: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          children: [
            for (final d in docs)
              CkHover(
                onTap: () => Navigator.of(context).pop(d),
                builder: (h) {
                  final c = wsDocColor(d.type, d.lang);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(color: h ? c.withOpacity(0.07) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(wsDocIcon(d.type), size: 19, color: c),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(d.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: h ? c : Pb.text)),
                        ),
                        if (d.section.trim().isNotEmpty) Text(d.section.trim(), style: TextStyle(fontSize: 12, color: Pb.muted)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        actions: [PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(context).pop())],
      );
}
