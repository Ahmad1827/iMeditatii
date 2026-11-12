// =============================================================================
// ACS: problems for the Faculty of Automatic Control and Computers (UPB)
//   A section of its own, with its own look: a terminal, or a notebook page,
//   each in light and dark, all set in Iosevka (acs/acs_kit.dart). Each
//   first page lists folders (the admission exam, each semester: /acs/<folder>),
//   a folder its courses (/acs/<code>) and each problem opens its workspace:
//   a shell, an x86 emulator, a C editor, a circuit... (acs/).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'acs/acs_data.dart';
import 'acs/acs_kit.dart';
import 'app_link.dart';

/// A course of the section; its problems are in assets/data/acs/<code>.json.
class AcsSubject {
  final String code; // the folder name in the terminal, and the file's name: "pclp"
  final String short; // "PCLP"
  final String name;
  final String about;
  final String group; // the folder it is in: an [AcsGroup.slug]
  final bool ready; // false: still to come, no problems yet
  const AcsSubject(this.code, this.short, this.name, this.about, {required this.group, this.ready = true});

  String get route => '/acs/$code';
}

/// A folder of the section's first page: the admission exam, or a semester.
class AcsGroup {
  final String slug; // in the address and in the terminal: "an3-sem1"
  final String title;
  final String about;
  const AcsGroup(this.slug, this.title, this.about);

  String get route => '/acs/$slug';
  List<AcsSubject> get subjects => [for (final s in acsSubjects) if (s.group == slug) s];
}

const List<AcsGroup> acsGroups = [
  AcsGroup('admitere', 'Admitere', 'Înainte de anul I: testul grilă de matematică și informatică'),
  AcsGroup('an1-sem1', 'Anul I · semestrul 1', 'Analiză, algebră, programare în C, shell, proiectare logică'),
  AcsGroup('an1-sem2', 'Anul I · semestrul 2', 'Matematici speciale, electrotehnică, fizică, metode numerice, asamblare, structuri de date'),
  AcsGroup('an2', 'Anul II', 'Programare orientată pe obiecte, proiectarea algoritmilor'),
  AcsGroup('an3-sem1', 'Anul III · semestrul 1', 'Limbaje formale, algoritmi paraleli, grafică, rețele, securitate, economie'),
];

AcsGroup? acsGroup(String slug) {
  for (final g in acsGroups) {
    if (g.slug == slug) return g;
  }
  return null;
}

/// The CD series; the electives (history, philosophy...) have no problems here.
const List<AcsSubject> acsSubjects = [
  AcsSubject('admitere', 'ADM', 'Admitere ACS', 'Testul grilă: matematică (algebră, analiză) și informatică (C++)', group: 'admitere'),
  AcsSubject('am', 'AM', 'Analiză Matematică', 'Serii Taylor, derivate parțiale, extreme, integrale — cu grafice', group: 'an1-sem1'),
  AcsSubject('algaed', 'ALGAED', 'Algebră, Geometrie și Ecuații Diferențiale', 'Operații pe linii, valori proprii, ecuații diferențiale', group: 'an1-sem1'),
  AcsSubject('pclp', 'PCLP', 'Programarea Calculatoarelor', 'C cu teste: pointeri, șiruri, biți, structuri, alocare dinamică', group: 'an1-sem1'),
  AcsSubject('uso', 'USO', 'Utilizarea Sistemelor de Operare', 'Un shell adevărat: fișiere, permisiuni, filtre, scripturi', group: 'an1-sem1'),
  AcsSubject('pl', 'PL', 'Proiectare Logică', 'Expresii booleene, Karnaugh, multiplexoare, automate', group: 'an1-sem1'),
  AcsSubject('ms', 'MS', 'Matematici Speciale', 'Laplace și Z, serii Fourier, probabilități — cu grafice', group: 'an1-sem2'),
  AcsSubject('elth', 'ELTH', 'Electrotehnică', 'Circuite de c.c. și c.a. rezolvate pe schemă, simulate', group: 'an1-sem2'),
  AcsSubject('fizica', 'Fizică', 'Fizică (Mecanică)', 'Simulări: aruncări, plan înclinat, ciocniri, oscilații', group: 'an1-sem2'),
  AcsSubject('mn', 'MN', 'Metode Numerice', 'Un Octave în browser: LU, iterații, interpolare, Newton', group: 'an1-sem2'),
  AcsSubject('iocla', 'IOCLA', 'Calculatoare și Limbaje de Asamblare', 'Asamblare x86 pe un emulator: registre, stivă, apeluri', group: 'an1-sem2'),
  AcsSubject('sd', 'SD', 'Structuri de Date', 'C cu teste și structuri construite pas cu pas', group: 'an1-sem2'),
  AcsSubject('poo', 'POO', 'Programare Orientată pe Obiecte', 'Clase, moștenire, polimorfism', group: 'an2', ready: false),
  AcsSubject('pa', 'PA', 'Proiectarea Algoritmilor', 'Divide et impera, programare dinamică, greedy', group: 'an2', ready: false),
  AcsSubject('lfa', 'LFA', 'Limbaje Formale și Automate', 'Automate, expresii regulate și gramatici verificate cu un contraexemplu', group: 'an3-sem1'),
  AcsSubject('apd', 'APD', 'Algoritmi Paraleli și Distribuiți', 'Fire rulate pas cu pas; toate întrețeserile căutate după curse și blocaje', group: 'an3-sem1'),
  AcsSubject('egc', 'EGC', 'Elemente de Grafică pe Calculator', 'Transformări compuse pe desen, rasterizare pixel cu pixel', group: 'an3-sem1'),
  AcsSubject('rl', 'RL', 'Rețele Locale', 'Adrese IP pe biți: subrețele, VLSM, tabele de rutare', group: 'an3-sem1'),
  AcsSubject('isc', 'ISC', 'Introducere în Securitatea Cibernetică', 'Un banc de decodare: hex, base64, Cezar, XOR, Vigenère', group: 'an3-sem1'),
  AcsSubject('eg', 'EG', 'Economie Generală', 'Cerere și ofertă pe grafic: echilibru, elasticitate, costuri', group: 'an3-sem1'),
];

AcsSubject? acsSubject(String code) {
  for (final s in acsSubjects) {
    if (s.code == code) return s;
  }
  return null;
}

/// The links after "materii" for a course's pages: its folder, then the course.
List<(String, String)> acsTrail(String code) {
  final g = acsGroup(acsSubject(code)?.group ?? '');
  return [if (g != null) (g.slug, g.route), (code, '/acs/$code')];
}

/// How many problems a course has, and how many of them are solved on this device.
typedef AcsCount = ({int problems, int solved});

/// Every ready course's count, by its code.
Future<Map<String, AcsCount>> loadAcsCounts() async {
  final out = <String, AcsCount>{};
  for (final s in acsSubjects.where((s) => s.ready)) {
    final data = await loadAcsCourse(s.code);
    if (data == null) continue;
    final done = await AcsProgress.solvedIds(s.code);
    out[s.code] = (problems: data.problems.length, solved: data.problems.where((p) => done.contains(p.id)).length);
  }
  return out;
}

/// The first page: the folders. With [group], that folder's courses.
class AcsScreen extends StatefulWidget {
  final String? group;
  const AcsScreen({super.key, this.group});

  @override
  State<AcsScreen> createState() => _AcsScreenState();
}

class _AcsScreenState extends State<AcsScreen> {
  Map<String, AcsCount> _counts = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await loadAcsCounts();
      if (mounted) setState(() => _counts = c);
    } catch (e) {
      debugPrint('ACS counts: $e');
    }
  }

  AcsCount _of(AcsGroup g) {
    var p = 0, s = 0;
    for (final x in g.subjects) {
      final c = _counts[x.code] ?? _none;
      p += c.problems;
      s += c.solved;
    }
    return (problems: p, solved: s);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group == null ? null : acsGroup(widget.group!);
    final rows = g == null
        ? [
            for (final x in acsGroups)
              _Entry(x.slug, x.title, '${x.about} · ${x.subjects.length == 1 ? 'o materie' : '${x.subjects.length} materii'}', x.route, _of(x),
                  x.subjects.any((s) => s.ready)),
          ]
        : [for (final s in g.subjects) _Entry(s.code, s.name, s.about, s.route, _counts[s.code] ?? _none, s.ready)];
    return AcsPage(
      builder: (context, ink, narrow) =>
          ink.terminal ? _Terminal(ink: ink, narrow: narrow, group: g, rows: rows) : _Notebook(ink: ink, narrow: narrow, group: g, rows: rows),
    );
  }
}

/// A line of the page: a folder of courses, or a course.
class _Entry {
  final String dir, title, about, route;
  final AcsCount count;
  final bool ready;
  const _Entry(this.dir, this.title, this.about, this.route, this.count, this.ready);
}

/// "██████░░░░ 61%", or "în curând" while there are no problems.
int _filled(AcsCount c) => c.problems == 0 ? 0 : (c.solved * 10 / c.problems).round().clamp(0, 10);

String _bar(AcsCount c) => '█' * _filled(c);

String _barRest(AcsCount c) => c.problems == 0 ? '' : '█' * (10 - _filled(c));

String _pct(AcsCount c) => c.problems == 0 ? 'în curând' : '${(c.solved * 100 / c.problems).round()}%'.padLeft(4);

const AcsCount _none = (problems: 0, solved: 0);

/// A line opens its page; one coming soon does nothing.
Widget _entryLink(BuildContext context, _Entry e, Widget Function(bool hover) builder) {
  if (!e.ready) return builder(false);
  return AppLink(
    to: e.route,
    child: AcsTap(label: e.title, onTap: () => context.go(e.route), builder: builder),
  );
}

// ---------------------------------------------------------------- terminal
class _Terminal extends StatelessWidget {
  final AcsInk ink;
  final bool narrow;
  final AcsGroup? group;
  final List<_Entry> rows;
  const _Terminal({required this.ink, required this.narrow, required this.group, required this.rows});

  @override
  Widget build(BuildContext context) {
    final here = group == null ? '~' : '~/${group!.slug}';
    Widget prompt(String cmd) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
            TextSpan(text: ':', style: TextStyle(color: ink.muted)),
            TextSpan(text: here, style: TextStyle(color: ink.muted)),
            TextSpan(text: '\$ ', style: TextStyle(color: ink.accent)),
            TextSpan(text: cmd, style: TextStyle(color: ink.fg)),
          ])),
        );

    final cells = TextStyle(fontSize: narrow ? 13 : 14, color: ink.fg);
    final dirW = (rows.fold<int>(6, (m, e) => e.dir.length > m ? e.dir.length : m) + 2) * (narrow ? 7.4 : 8.0);
    // one line per folder or course
    Widget row(_Entry e) {
      final c = e.count;
      return _entryLink(
        context,
        e,
        (h) => Container(
          color: h ? ink.hover : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (!narrow) SizedBox(width: 104, child: Text(e.ready ? 'drwxr-xr-x' : 'd---------', style: cells.copyWith(color: ink.dim))),
              SizedBox(
                width: dirW,
                child: Text('${e.dir}/',
                    style: cells.copyWith(
                        color: e.ready ? ink.accent : ink.muted,
                        fontWeight: FontWeight.w700,
                        decoration: h ? TextDecoration.underline : null,
                        decorationColor: ink.accent)),
              ),
              Expanded(child: Text(e.title, style: cells.copyWith(color: e.ready ? ink.fg : ink.muted), overflow: TextOverflow.ellipsis)),
              if (!narrow)
                SizedBox(
                  width: 44,
                  child: Text(c.problems == 0 ? '' : '${c.problems}',
                      textAlign: TextAlign.right, style: cells.copyWith(color: ink.muted, fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              const SizedBox(width: 14),
              SizedBox(
                width: narrow ? 92 : 128,
                child: Text.rich(
                    TextSpan(children: [
                      if (!narrow) TextSpan(text: _bar(c), style: TextStyle(color: ink.accent)),
                      if (!narrow) TextSpan(text: _barRest(c), style: TextStyle(color: ink.line)),
                      TextSpan(text: c.problems == 0 || narrow ? _pct(c).trim() : ' ${_pct(c)}', style: TextStyle(color: ink.muted)),
                    ]),
                    style: cells,
                    textAlign: narrow ? TextAlign.right : TextAlign.left),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '~/', style: TextStyle(color: ink.accent)),
                TextSpan(text: group == null ? 'acs' : 'acs/${group!.slug}', style: TextStyle(color: ink.strong)),
              ]), style: TextStyle(fontSize: narrow ? 26 : 34, fontWeight: FontWeight.w700, height: 1.1)),
              const SizedBox(height: 4),
              Text(group == null ? 'probleme pentru Automatică și Calculatoare · UPB' : '${group!.title} · ${group!.about}',
                  style: TextStyle(color: ink.muted, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AcsNav(ink: ink, trail: [if (group != null) (group!.slug, group!.route)]),
        prompt('ls -l'),
        for (final e in rows) row(e),
        if (group == null) ...[
          prompt('cat README'),
          Text('Alege un dosar: admiterea sau un semestru. Înăuntru sunt materiile lui, fiecare cu probleme din\nexamene, teste și laboratoare, rezolvate în unealta materiei: un shell la USO, un emulator x86 la\nIOCLA, automate la LFA, fire de execuție la APD, adrese pe biți la RL... Seria CD; opționalele lipsesc.',
              style: TextStyle(color: ink.muted, fontSize: 14)),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
            TextSpan(text: ':$here', style: TextStyle(color: ink.muted)),
            TextSpan(text: '\$ ', style: TextStyle(color: ink.accent)),
          ])),
          AcsCursor(color: ink.accent),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- notebook
class _Notebook extends StatelessWidget {
  final AcsInk ink;
  final bool narrow;
  final AcsGroup? group;
  final List<_Entry> rows;
  const _Notebook({required this.ink, required this.narrow, required this.group, required this.rows});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (n, e) => n + e.count.problems);
    final ready = rows.where((e) => e.ready).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.memory, size: 58, color: ink.strong),
        const SizedBox(height: 4),
        Text('ACS', textAlign: TextAlign.center,
            style: TextStyle(fontSize: narrow ? 34 : 42, fontWeight: FontWeight.w700, color: ink.strong, height: 1.05)),
        const SizedBox(height: 4),
        Text('Probleme pentru Automatică și Calculatoare...', textAlign: TextAlign.center,
            style: TextStyle(fontSize: narrow ? 16 : 19, color: ink.muted)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line, width: 2))),
          child: AcsNav(ink: ink, size: narrow ? 15 : 17, trail: [if (group != null) (group!.slug, group!.route)]),
        ),
        const SizedBox(height: 26),
        Text(group?.title ?? 'Admitere și semestre',
            style: TextStyle(fontSize: narrow ? 24 : 32, fontWeight: FontWeight.w700, color: ink.strong, height: 1.15)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: group == null ? '$ready dosare' : (ready == 1 ? 'o materie' : '$ready materii'), style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(
              text: total == 0 ? ' • problemele vin în curând' : ' • $total probleme',
              style: TextStyle(color: ink.muted)),
        ]), style: TextStyle(fontSize: 14, color: ink.fg)),
        const SizedBox(height: 26),
        for (final e in rows) ...[
          _NotebookRow(ink: ink, e: e, narrow: narrow),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _NotebookRow extends StatelessWidget {
  final AcsInk ink;
  final _Entry e;
  final bool narrow;
  const _NotebookRow({required this.ink, required this.e, required this.narrow});

  @override
  Widget build(BuildContext context) => _entryLink(context, e, (h) => _row(h));

  Widget _row(bool h) {
    final c = e.count;
    final code = Text('[${e.dir.toUpperCase()}]',
        style: TextStyle(fontWeight: FontWeight.w700, color: e.ready ? ink.accent : ink.muted, fontSize: 15));
    final pct = Text(c.problems == 0 ? 'în curând' : _pct(c).trim(),
        style: TextStyle(color: ink.muted, fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]));
    final title = Text(e.title,
        style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: e.ready ? ink.strong : ink.muted,
            decoration: h ? TextDecoration.underline : null,
            decorationColor: ink.strong));
    final about = Text(c.problems == 0 ? e.about : '${e.about} · ${c.problems} probleme', style: TextStyle(color: ink.muted, fontSize: 14));

    if (narrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [code, const Spacer(), pct]),
        title,
        about,
      ]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Padding(padding: const EdgeInsets.only(top: 2), child: code)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, about])),
        const SizedBox(width: 16),
        Padding(padding: const EdgeInsets.only(top: 2), child: pct),
      ],
    );
  }
}
