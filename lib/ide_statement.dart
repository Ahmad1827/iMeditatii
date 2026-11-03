import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'exercise_details.dart';
import 'app_link.dart';
import 'problem_statement.dart';
import 'ui_components.dart';
import 'grade_label.dart';

// =============================================================================
// THE STATEMENT BESIDE THE CODE, IN THE IDE
//   The number of a problem or a few words of its name, and its statement stays
//   next to the program. The numbers are the ones on the problems' list; they
//   restart for each subject, so "12" finds one in Informatică and one in Matematică.
// =============================================================================

/// A problem that can be looked up: from the app's files or added by a teacher.
class ProblemRef {
  final String subject;
  final String grade;
  final String id;
  final Map data;

  const ProblemRef({required this.subject, required this.grade, required this.id, required this.data});

  String get title => '${data['title'] ?? 'Fără titlu'}';
  String get key => '$subject|$grade|$id';
  String get path => '/exercitiu/${Uri.encodeComponent(id)}?materie=${Uri.encodeComponent(subject)}&clasa=${Uri.encodeComponent(grade)}';

  /// Lowercase and without diacritics, so "sesiunea speciala" finds "Sesiunea specială".
  static String fold(String s) {
    const from = 'ăâîșşțţ', to = 'aaissstt';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final k = from.indexOf(ch);
      b.write(k < 0 ? ch : to[k]);
    }
    return b.toString();
  }

  String get _hay => fold('$id $title ${data['category'] ?? ''} ${data['sursa'] ?? ''} $subject');
}

class ProblemIndex {
  static Future<List<ProblemRef>>? _all;

  /// Every problem, read once. Informatică comes first: it's what gets written here.
  static Future<List<ProblemRef>> load() => _all ??= _load();

  static Future<List<ProblemRef>> _load() async {
    final out = <ProblemRef>[];
    try {
      out.addAll(fromDetails(await loadAllDetails()));
    } catch (e) {
      debugPrint('Problems file: $e');
    }
    try {
      final known = {for (final p in out) p.key};
      final snap = await FirebaseFirestore.instance.collection('exercises').where('approved', isEqualTo: true).get();
      for (final d in snap.docs) {
        final p = ProblemRef(subject: '${d.data()['subject'] ?? ''}', grade: '${d.data()['grade'] ?? ''}', id: d.id, data: d.data());
        if (p.subject.isNotEmpty && known.add(p.key)) out.add(p);
      }
    } catch (e) {
      debugPrint('Teachers\' problems: $e'); // offline: the app's own problems are still here
    }
    return out;
  }

  static List<ProblemRef> fromDetails(Map details) {
    final subjects = details.keys.toList()..sort((a, b) => a == 'Informatică' ? -1 : (b == 'Informatică' ? 1 : 0));
    return [
      for (final s in subjects)
        for (final MapEntry(key: g, value: problems) in (details[s] as Map).entries)
          for (final MapEntry(key: id, value: p) in (problems as Map).entries)
            ProblemRef(subject: '$s', grade: '$g', id: '$id', data: p as Map),
    ];
  }

  /// [query] is a number or words: the problem with exactly that number comes
  /// first, then the ones with every word in the name, the chapter or the source.
  static List<ProblemRef> search(List<ProblemRef> all, String query, {int limit = 30}) {
    var q = query.trim();
    if (q.startsWith('#')) q = q.substring(1).trim();
    if (q.isEmpty) return const [];
    final words = ProblemRef.fold(q).split(RegExp(r'\s+'));
    final exact = <ProblemRef>[], named = <ProblemRef>[], other = <ProblemRef>[];
    for (final p in all) {
      if (p.id == q) {
        exact.add(p);
      } else if (words.every(ProblemRef.fold(p.title).contains)) {
        named.add(p);
      } else if (words.every(p._hay.contains)) {
        other.add(p);
      }
    }
    return [...exact, ...named, ...other].take(limit).toList();
  }
}

class IdeStatementPanel extends StatefulWidget {
  final ValueNotifier<ProblemRef?> picked;
  final ValueChanged<ProblemRef> onPick;
  final VoidCallback onClose;

  const IdeStatementPanel({super.key, required this.picked, required this.onPick, required this.onClose});

  @override
  State<IdeStatementPanel> createState() => _IdeStatementPanelState();
}

class _IdeStatementPanelState extends State<IdeStatementPanel> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  List<ProblemRef>? _all;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    ProblemIndex.load().then((all) {
      if (mounted) setState(() => _all = all);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<ProblemRef> get _results => ProblemIndex.search(_all ?? const [], _query.text);

  void _pick(ProblemRef p) {
    _query.clear();
    widget.onPick(p);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Widget _message(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: Pb.muted),
              const SizedBox(height: 10),
              Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.45)),
            ],
          ),
        ),
      );

  String _where(ProblemRef p) => [p.subject, if (p.grade.isNotEmpty) gradeInline(p.grade), if ('${p.data['category'] ?? ''}'.isNotEmpty) '${p.data['category']}'].join(' · ');

  Widget _resultsList() {
    final results = _results;
    if (_all == null) return const Center(child: CircularProgressIndicator(color: Pb.primary));
    if (results.isEmpty) return _message(Icons.search_off, 'Nicio problemă pentru „${_query.text.trim()}”.');
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return AppLink(
          to: p.path,
          child: InkWell(
            onTap: () => _pick(p),
            child: Container(
              // the first one is what Enter opens
              color: i == 0 ? Pb.primary.withOpacity(0.08) : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 44, child: Text('#${p.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Pb.mono(13, color: Pb.muted))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
                        const SizedBox(height: 2),
                        Text(_where(p), style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statement(ProblemRef p) => Scrollbar(
        controller: _scroll,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('#${p.id}. ${p.title}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Pb.text, height: 1.3)),
              const SizedBox(height: 3),
              Text(_where(p), style: TextStyle(fontSize: 13, color: Pb.muted)),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: AppLink(
                  to: p.path,
                  child: PbLink(text: 'Deschide pagina problemei', fontSize: 13.5, onTap: () => launchInNewTab(p.path)),
                ),
              ),
              const SizedBox(height: 14),
              ProblemStatement(key: ValueKey(p.key), problem: p.data, showOptions: true),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final searching = _query.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(left: BorderSide(color: Pb.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 6),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 18, color: Pb.primary),
                const SizedBox(width: 7),
                Expanded(child: Text('Cerință', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text))),
                IconButton(
                  tooltip: 'Închide',
                  icon: Icon(Icons.close, size: 18, color: Pb.muted),
                  splashRadius: 17,
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              key: const Key('ide-problem-search'),
              controller: _query,
              style: TextStyle(fontSize: 14, color: Pb.text),
              onSubmitted: (_) {
                final r = _results;
                if (r.isNotEmpty) _pick(r.first);
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Numărul sau numele problemei',
                hintStyle: TextStyle(fontSize: 14, color: Pb.muted),
                prefixIcon: Icon(Icons.search, size: 18, color: Pb.muted),
                suffixIcon: searching
                    ? IconButton(tooltip: 'Șterge', icon: Icon(Icons.clear, size: 16, color: Pb.muted), splashRadius: 16, onPressed: _query.clear)
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Pb.inputBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Pb.primary, width: 1.5)),
              ),
            ),
          ),
          Container(height: 1, color: Pb.border),
          Expanded(
            child: searching
                ? _resultsList()
                : ValueListenableBuilder<ProblemRef?>(
                    valueListenable: widget.picked,
                    builder: (_, p, __) => p == null
                        ? _message(Icons.menu_book_outlined, 'Scrie numărul problemei, de exemplu 12, sau o parte din nume, și cerința rămâne aici lângă cod.')
                        : _statement(p),
                  ),
          ),
        ],
      ),
    );
  }
}
