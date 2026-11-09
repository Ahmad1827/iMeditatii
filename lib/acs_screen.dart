// =============================================================================
// ACS: problems for the Faculty of Automatic Control and Computers (UPB)
//   A section of its own, with its own look: a terminal, or a notebook page,
//   each in light and dark, all set in Iosevka (acs/acs_kit.dart). Each
//   course opens its own list (/acs/<code>) and each problem its workspace:
//   a shell, an x86 emulator, a C editor, a circuit... (acs/).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'acs/acs_data.dart';
import 'acs/acs_kit.dart';
import 'app_link.dart';

/// A course of the section; its problems are in assets/data/acs/<code>.json.
/// A course with no semester is still to come.
class AcsSubject {
  final String code; // the folder name in the terminal, and the file's name: "pclp"
  final String short; // "PCLP"
  final String name;
  final String about;
  final int semester; // 1 or 2 of the first year, -1 the admission exam; 0: coming later
  const AcsSubject(this.code, this.short, this.name, this.about, {this.semester = 0});

  bool get ready => semester != 0;
  String get route => '/acs/$code';
}

/// The first year of the CD series; the electives (history, philosophy...) have no problems here.
const List<AcsSubject> acsSubjects = [
  AcsSubject('admitere', 'ADM', 'Admitere ACS', 'Testul grilă: matematică (algebră, analiză) și informatică (C++)', semester: -1),
  AcsSubject('am', 'AM', 'Analiză Matematică', 'Serii Taylor, derivate parțiale, extreme, integrale — cu grafice', semester: 1),
  AcsSubject('algaed', 'ALGAED', 'Algebră, Geometrie și Ecuații Diferențiale', 'Operații pe linii, valori proprii, ecuații diferențiale', semester: 1),
  AcsSubject('pclp', 'PCLP', 'Programarea Calculatoarelor', 'C cu teste: pointeri, șiruri, biți, structuri, alocare dinamică', semester: 1),
  AcsSubject('uso', 'USO', 'Utilizarea Sistemelor de Operare', 'Un shell adevărat: fișiere, permisiuni, filtre, scripturi', semester: 1),
  AcsSubject('pl', 'PL', 'Proiectare Logică', 'Expresii booleene, Karnaugh, multiplexoare, automate', semester: 1),
  AcsSubject('ms', 'MS', 'Matematici Speciale', 'Laplace și Z, serii Fourier, probabilități — cu grafice', semester: 2),
  AcsSubject('elth', 'ELTH', 'Electrotehnică', 'Circuite de c.c. și c.a. rezolvate pe schemă, simulate', semester: 2),
  AcsSubject('fizica', 'Fizică', 'Fizică (Mecanică)', 'Simulări: aruncări, plan înclinat, ciocniri, oscilații', semester: 2),
  AcsSubject('mn', 'MN', 'Metode Numerice', 'Un Octave în browser: LU, iterații, interpolare, Newton', semester: 2),
  AcsSubject('iocla', 'IOCLA', 'Calculatoare și Limbaje de Asamblare', 'Asamblare x86 pe un emulator: registre, stivă, apeluri', semester: 2),
  AcsSubject('sd', 'SD', 'Structuri de Date', 'C cu teste și structuri construite pas cu pas', semester: 2),
  AcsSubject('poo', 'POO', 'Programare Orientată pe Obiecte', 'Anul II: clase, moștenire, polimorfism'),
  AcsSubject('pa', 'PA', 'Proiectarea Algoritmilor', 'Anul II: divide et impera, programare dinamică, greedy'),
];

AcsSubject? acsSubject(String code) {
  for (final s in acsSubjects) {
    if (s.code == code) return s;
  }
  return null;
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

class AcsScreen extends StatefulWidget {
  const AcsScreen({super.key});

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

  @override
  Widget build(BuildContext context) => AcsPage(
        builder: (context, ink, narrow) =>
            ink.terminal ? _Terminal(ink: ink, narrow: narrow, counts: _counts) : _Notebook(ink: ink, narrow: narrow, counts: _counts),
      );
}

/// "██████░░░░ 61%", or "în curând" while a course has no problems.
int _filled(AcsCount c) => c.problems == 0 ? 0 : (c.solved * 10 / c.problems).round().clamp(0, 10);

String _bar(AcsCount c) => '█' * _filled(c);

String _barRest(AcsCount c) => c.problems == 0 ? '' : '█' * (10 - _filled(c));

String _pct(AcsCount c) => c.problems == 0 ? 'în curând' : '${(c.solved * 100 / c.problems).round()}%'.padLeft(4);

const AcsCount _none = (problems: 0, solved: 0);

/// The courses in groups: the admission exam, first-year semesters, then those still to come.
const List<(String, String, int)> _groups = [
  ('pregatire', 'Înainte de anul I · admiterea', -1),
  ('anul-1/sem-1', 'Anul I · semestrul 1', 1),
  ('anul-1/sem-2', 'Anul I · semestrul 2', 2),
  ('in-curand', 'În curând', 0),
];

/// A course opens its problems; one coming soon does nothing.
Widget _courseLink(BuildContext context, AcsSubject s, Widget Function(bool hover) builder) {
  if (!s.ready) return builder(false);
  return AppLink(
    to: s.route,
    child: AcsTap(label: s.name, onTap: () => context.go(s.route), builder: builder),
  );
}

// ---------------------------------------------------------------- terminal
class _Terminal extends StatelessWidget {
  final AcsInk ink;
  final bool narrow;
  final Map<String, AcsCount> counts;
  const _Terminal({required this.ink, required this.narrow, required this.counts});

  @override
  Widget build(BuildContext context) {
    Widget prompt(String cmd) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
            TextSpan(text: ':', style: TextStyle(color: ink.muted)),
            TextSpan(text: '~', style: TextStyle(color: ink.muted)),
            TextSpan(text: '\$ ', style: TextStyle(color: ink.accent)),
            TextSpan(text: cmd, style: TextStyle(color: ink.fg)),
          ])),
        );

    final cells = TextStyle(fontSize: narrow ? 13 : 14, color: ink.fg);
    // one line per course: the folder opens its problems
    Widget row(AcsSubject s) {
      final c = counts[s.code] ?? _none;
      return _courseLink(
        context,
        s,
        (h) => Container(
          color: h ? ink.hover : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (!narrow) SizedBox(width: 104, child: Text(s.ready ? 'drwxr-xr-x' : 'd---------', style: cells.copyWith(color: ink.dim))),
              SizedBox(
                width: narrow ? 72 : 84,
                child: Text('${s.code}/',
                    style: cells.copyWith(
                        color: s.ready ? ink.accent : ink.muted,
                        fontWeight: FontWeight.w700,
                        decoration: h ? TextDecoration.underline : null,
                        decorationColor: ink.accent)),
              ),
              Expanded(child: Text(s.name, style: cells.copyWith(color: s.ready ? ink.fg : ink.muted), overflow: TextOverflow.ellipsis)),
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
                TextSpan(text: 'acs', style: TextStyle(color: ink.strong)),
              ]), style: TextStyle(fontSize: narrow ? 28 : 34, fontWeight: FontWeight.w700, height: 1.1)),
              const SizedBox(height: 4),
              Text('probleme pentru Automatică și Calculatoare · UPB', style: TextStyle(color: ink.muted, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AcsNav(ink: ink),
        for (final (dir, _, sem) in _groups) ...[
          prompt('ls -l $dir/'),
          for (final s in acsSubjects.where((s) => s.ready ? s.semester == sem : sem == 0)) row(s),
        ],
        prompt('cat README'),
        Text('Admiterea: testul grilă de matematică și informatică, cu câte șase variante.\nSeria CD, anul I: probleme din examenele, testele și laboratoarele fiecărei materii, rezolvate\nîn unealta materiei: un shell la USO, un emulator x86 la IOCLA, Octave la MN, circuite la ELTH...\nMateriile opționale nu sunt incluse.',
            style: TextStyle(color: ink.muted, fontSize: 14)),

        const SizedBox(height: 18),
        Row(children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
            TextSpan(text: ':~', style: TextStyle(color: ink.muted)),
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
  final Map<String, AcsCount> counts;
  const _Notebook({required this.ink, required this.narrow, required this.counts});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (n, c) => n + c.problems);
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
          child: AcsNav(ink: ink, size: narrow ? 15 : 17),
        ),
        const SizedBox(height: 26),
        Text('Admitere și anul I',
            style: TextStyle(fontSize: narrow ? 24 : 32, fontWeight: FontWeight.w700, color: ink.strong, height: 1.15)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: '${acsSubjects.where((s) => s.ready).length} materii', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(
              text: total == 0 ? ' • problemele vin în curând' : ' • $total probleme',
              style: TextStyle(color: ink.muted)),
        ]), style: TextStyle(fontSize: 14, color: ink.fg)),
        const SizedBox(height: 22),
        for (final (_, title, sem) in _groups) ...[
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: narrow ? 18 : 21, fontWeight: FontWeight.w700, color: ink.strong)),
          const SizedBox(height: 14),
          for (final s in acsSubjects.where((s) => s.ready ? s.semester == sem : sem == 0)) ...[
            _NotebookRow(ink: ink, s: s, c: counts[s.code] ?? _none, narrow: narrow),
            const SizedBox(height: 18),
          ],
        ],
      ],
    );
  }
}

class _NotebookRow extends StatelessWidget {
  final AcsInk ink;
  final AcsSubject s;
  final AcsCount c;
  final bool narrow;
  const _NotebookRow({required this.ink, required this.s, required this.c, required this.narrow});

  @override
  Widget build(BuildContext context) => _courseLink(context, s, (h) => _row(h));

  Widget _row(bool h) {
    final code = Text('[${s.code.toUpperCase()}]',
        style: TextStyle(fontWeight: FontWeight.w700, color: s.ready ? ink.accent : ink.muted, fontSize: 15));
    final pct = Text(c.problems == 0 ? 'în curând' : _pct(c).trim(),
        style: TextStyle(color: ink.muted, fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]));
    final title = Text(s.name,
        style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: s.ready ? ink.strong : ink.muted,
            decoration: h ? TextDecoration.underline : null,
            decorationColor: ink.strong));
    final about = Text(
        c.problems == 0 ? s.about : '${s.about} · ${c.problems} probleme',
        style: TextStyle(color: ink.muted, fontSize: 14));

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
        SizedBox(width: 120, child: Padding(padding: const EdgeInsets.only(top: 2), child: code)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, about])),
        const SizedBox(width: 16),
        Padding(padding: const EdgeInsets.only(top: 2), child: pct),
      ],
    );
  }
}
