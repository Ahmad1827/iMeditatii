import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart';
import 'sticky_footer.dart';
import 'resources_data.dart';
import 'ui_components.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String articleId;
  const ResourceDetailScreen({super.key, required this.articleId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  // ---- clean state
  static const String _readPrefix = 'lectie_citita:'; // same key as resources_screen.dart
  final ValueNotifier<double> _progress = ValueNotifier(0);
  final ValueNotifier<int> _active = ValueNotifier(0);
  int _sectionCount = 0;
  bool _isRead = false;
  bool _cHidden = false;
  final GlobalKey _cTopKey = GlobalKey();
  final GlobalKey _cMainKey = GlobalKey();
  final GlobalKey _cFootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _markRead(widget.articleId, true);
  }

  @override
  void didUpdateWidget(covariant ResourceDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.articleId != widget.articleId) {
      _active.value = 0;
      _progress.value = 0;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _markRead(widget.articleId, true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _progress.dispose();
    _active.dispose();
    super.dispose();
  }

  Future<void> _markRead(String id, bool value) async {
    if (mounted) setState(() => _isRead = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool('$_readPrefix$id', true);
      } else {
        await prefs.remove('$_readPrefix$id');
      }
    } catch (e) {
      debugPrint('Lecții citite: $e');
    }
  }

  /// Reading progress bar + which section is currently on screen.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    _progress.value = pos.maxScrollExtent <= 0 ? 1 : (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0).toDouble();
    var active = 0;
    for (var i = 0; i < _sectionCount; i++) {
      final ro = _sectionKeys[i]?.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize) {
        if (ro.localToGlobal(Offset.zero).dy < 240) active = i;
      }
    }
    if (pos.pixels >= pos.maxScrollExtent - 4 && _sectionCount > 0) active = _sectionCount - 1;
    if (active != _active.value) _active.value = active;
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    final clean = AppStyle.current.isClean;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clean ? 'Codul a fost copiat.' : 'COD COPIAT ÎN CLIPBOARD!',
          style: TextStyle(fontWeight: clean ? FontWeight.w400 : FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: clean ? const Color(0xFF212529) : AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: clean
            ? const RoundedRectangleBorder(borderRadius: Pb.radius)
            : RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
      ),
    );
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  Map<String, dynamic>? get _meta {
    for (final a in ResourcesData.allArticles) {
      if (a['id'] == widget.articleId) return a;
    }
    return null;
  }

  Map<String, dynamic>? _getArticleData() {
    if (ResourcesData.curatedLectures.containsKey(widget.articleId)) {
      return ResourcesData.curatedLectures[widget.articleId];
    }

    final meta = _meta;
    if (meta == null) return null;

    final bool isMath = meta['subject'] == 'MATEMATICĂ';
    return {
      "tag": "${meta['subject']} // CLASA A ${meta['grade']}-A // ${meta['module']}",
      "title": meta['title'],
      "subtitle": meta['desc'],
      "author": meta['author'] ?? ResourcesData.defaultAuthor,
      "date": meta['date'] ?? ResourcesData.defaultDate,
      "sections": [
        {
          "heading": "1. Concepte Fundamentale & Teorie",
          "text": "${meta['desc']}\n\nConform programei oficiale pentru clasa a ${meta['grade']}-a, aprofundarea acestui subiect dezvoltă raționamentul logic și pregătirea pentru examenele naționale. În această etapă de învățare, este vital să stăpânești terminologia de bază și structurile standard de rezolvare.",
        },
        {
          "heading": "2. Analiză Detaliată & Aplicații Practice",
          "text": isMath
              ? "În matematică, fiecare pas al deducției trebuie argumentat riguros:\n• Pasul 1: Identificarea ipotezei și stabilirea domeniului de definiție.\n• Pasul 2: Aplicarea formulelor fundamentale și a teoremelor specifice.\n• Pasul 3: Verificarea soluțiilor obținute și eliminarea soluțiilor străine."
              : "În programare, implementarea corectă presupune respectarea normelor de eficiență algoritmică (atât ca timp de execuție, cât și ca memorie utilizată) și lizibilitatea codului.",
          "code": isMath
              ? null
              : meta['subject'] == 'PYTHON'
                  ? "# Exemplu de implementare în Python\ndef rezolvare_problema():\n    print(\"--- Execuție algoritm: ${meta['title']} ---\")\n    # Scrie logica de rezolvare aici\n    valoare = 100\n    return valoare * 2\n\nrezultat = rezolvare_problema()\nprint(f\"Rezultat calculat: {rezultat}\")"
                  : "// Exemplu de implementare în C++\n#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << \"--- Studiu: ${meta['title']} ---\" << endl;\n    // Logica specifică algoritmului\n    int valoare = 100;\n    cout << \"Rezultat calculat: \" << valoare * 2 << \"\\n\";\n    return 0;\n}",
          "lang": isMath ? null : (meta['subject'] == 'PYTHON' ? 'python' : 'cpp'),
        },
        {
          "heading": "3. Recomandări & Sinteză de Examen",
          "text": "Pentru a reține pe termen lung aceste cunoștințe, nu te baza doar pe memorarea formulelor. Încearcă să le deduci singur și rezolvă probleme similare din lista noastră de exerciții.",
          "callout": isMath
              ? "REGULĂ DE AUR LA MATEMATICĂ:\nScrie întotdeauna formulele în forma lor generală înainte de a înlocui valorile numerice! La corectură se acordă punctaj parțial pentru cunoașterea teoriei, chiar dacă intervine o greșeală minoră de calcul aritmetic."
              : "SFAT PENTRU COD:\nTestează întotdeauna codul pe cazuri particulare (valori de frontieră): numere negative, valoarea zero sau tablouri cu un singur element!"
        }
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    final lecture = _getArticleData();

    return StyleBuilder(
      builder: (context, s) {
        final width = MediaQuery.of(context).size.width;
        Widget render(Map<String, dynamic> data) =>
            s.isClean ? _buildClean(data, width < 900) : _buildRetro(data, width < 900);

        if (lecture != null) return render(lecture);

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('resources').doc(widget.articleId).get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: s.isClean ? Pb.page : AppColors.bg,
                body: Center(child: CircularProgressIndicator(color: s.isClean ? Pb.primary : AppColors.sunset)),
              );
            }
            if (!snap.hasData || !snap.data!.exists) {
              if (s.isClean) {
                return Scaffold(
                  backgroundColor: Pb.page,
                  body: Column(
                    children: [
                      const CustomNavbar(),
                      const SizedBox(height: 24),
                      PbContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PbAlert(type: PbAlertType.danger, text: 'Lecția nu a fost găsită.'),
                            const SizedBox(height: 12),
                            PbLink(text: 'Înapoi la lecții', underline: true, onTap: () => context.go('/resurse')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Scaffold(
                backgroundColor: AppColors.bg,
                appBar: AppBar(backgroundColor: AppColors.bg, iconTheme: IconThemeData(color: AppColors.ink)),
                body: Center(
                  child: Text("LECȚIE NEIDENTIFICATĂ ÎN CODEX.",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
                ),
              );
            }
            return render(snap.data!.data() as Map<String, dynamic>);
          },
        );
      },
    );
  }

  void _ensureKeys(List<dynamic> sections) {
    for (int i = 0; i < sections.length; i++) {
      _sectionKeys.putIfAbsent(i, () => GlobalKey());
    }
  }

  // ===========================================================================
  // CLEAN — reading page: header card, sticky-feeling TOC with scroll-spy,
  // reading progress, coloured callouts, previous / next lesson.
  // ===========================================================================
  static const Color _cRose = Color(0xFFE5484D);
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cGreen = Color(0xFF10B981);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Map<String, String> _roman = {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'};

  String _subjectOf(Map<String, dynamic> data) {
    final meta = _meta;
    if (meta != null) return '${meta['subject']}'.toUpperCase();
    final t = '${data['tag'] ?? data['subject'] ?? ''}'.toUpperCase();
    if (t.contains('MATEMATIC')) return 'MATEMATICĂ';
    if (t.contains('PYTHON')) return 'PYTHON';
    return 'C++';
  }

  static String _subjName(String s) =>
      s == 'PYTHON' ? 'Python' : (s.startsWith('MATEMATIC') ? 'Matematică' : (s == 'C++' ? 'C++' : AppStyle.sentence(s)));

  static Color _subjColor(String s) {
    final l = s.toLowerCase();
    if (l.startsWith('mat')) return _cRose;
    if (l.contains('python')) return _cBlue;
    return Pb.primary;
  }

  static String _fixWords(String t) {
    var r = t.replaceAll(RegExp(r'c\+\+', caseSensitive: false), 'C++');
    const words = {'python': 'Python', 'sql': 'SQL', 'oop': 'OOP', 'bacalaureat': 'Bacalaureat', 'divide et impera': 'Divide et Impera'};
    for (final e in words.entries) {
      r = r.replaceAll(RegExp('(?<![\\w])${RegExp.escape(e.key)}(?![\\w])', caseSensitive: false), e.value);
    }
    return r;
  }

  static String _chapterName(String m) => _fixWords(AppStyle.sentence(m.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '')));

  static String _stripNum(String h) => h.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '');

  BoxDecoration _cDeco({double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  Widget _buildClean(Map<String, dynamic> data, bool isMobile) {
    final List<dynamic> sections = data['sections'] ?? [];
    _ensureKeys(sections);
    _sectionCount = sections.length;

    final meta = _meta;
    final subj = _subjectOf(data);
    final c = _subjColor(subj);

    Widget box(double max, Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24), child: child),
          ),
        );

    Widget slide(double dx, Widget child) => AnimatedSlide(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          offset: _cHidden ? Offset(dx, 0) : Offset.zero,
          child: IgnorePointer(ignoring: _cHidden, child: child),
        );

    final article = _cArticle(data, sections, meta, c, isMobile);

    final body = isMobile
        ? slide(-1.4, article)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 268,
                child: slide(
                  -3.2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_cToc(sections, c), const SizedBox(height: 14), _cPractice(subj, c)],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840), child: slide(1.6, article)),
                ),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              blockers: [_cTopKey, if (!_cHidden) _cMainKey, _cFootKey],
              cardsHidden: _cHidden,
              onToggleCards: () => setState(() => _cHidden = !_cHidden),
              hideLabel: 'Ascunde lecția',
              showLabel: 'Arată lecția',
              child: Stack(
                children: [
                  StickyFooterScroll(
                    controller: _scrollController,
                    body: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: isMobile ? 18 : 36),
                          box(1180, KeyedSubtree(key: _cTopKey, child: _DReveal(child: _cHeader(data, meta, subj, c, isMobile)))),
                          SizedBox(height: isMobile ? 14 : 20),
                          box(1180, KeyedSubtree(key: _cMainKey, child: _DReveal(delayMs: 140, child: body))),
                        ],
                      ),
                    footer: KeyedSubtree(key: _cFootKey, child: _cFooter(isMobile)),
                  ),
                  // reading progress
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _progress,
                        builder: (_, v, __) => Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 3, color: c),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _cHeader(Map<String, dynamic> data, Map<String, dynamic>? meta, String subj, Color c, bool isMobile) {
    final title = data['title']?.toString() ?? 'Lecție';
    final author = data['author']?.toString() ?? ResourcesData.defaultAuthor;
    final date = data['date']?.toString() ?? ResourcesData.defaultDate;
    final grade = '${meta?['grade'] ?? ''}';
    final complete = ResourcesData.curatedLectures.containsKey(widget.articleId);
    final minutes = int.tryParse(RegExp(r'\d+').firstMatch('${meta?['readTime'] ?? ''}')?.group(0) ?? '');

    Widget chip(String label, {Color? dot, IconData? icon, Color? fg}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: (fg ?? Pb.muted).withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[Icon(icon, size: 14, color: fg ?? Pb.muted), const SizedBox(width: 5)],
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: fg ?? Pb.text)),
            ],
          ),
        );

    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('/', style: TextStyle(fontSize: 13, color: Pb.muted)),
    );

    final readBtn = PbButton(
      text: _isRead ? 'Citită' : 'Marchează ca citită',
      icon: _isRead ? Icons.check_circle : Icons.check_circle_outline,
      variant: _isRead ? PbVariant.success : PbVariant.outlineSecondary,
      size: PbSize.sm,
      onPressed: () => _markRead(widget.articleId, !_isRead),
    );

    final byline = Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: c.withOpacity(0.15),
          child: Text(author.isNotEmpty ? author[0].toUpperCase() : 'A',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(author, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text)),
              Text(date, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ),
        if (!isMobile) readBtn,
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cDeco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: c),
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 18 : 28, isMobile ? 16 : 22, isMobile ? 18 : 28, isMobile ? 18 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PbLink(text: 'Lecții', fontSize: 13, onTap: () => context.go('/resurse')),
                    sep,
                    Text(_subjName(subj), style: TextStyle(fontSize: 13, color: Pb.muted)),
                    if (grade.isNotEmpty) ...[
                      sep,
                      Text('Clasa a ${_roman[grade] ?? grade}-a', style: TextStyle(fontSize: 13, color: Pb.muted)),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    chip(_subjName(subj), dot: c),
                    if (grade.isNotEmpty) chip('Clasa a ${_roman[grade] ?? grade}-a', icon: Icons.school_outlined),
                    if (meta?['module'] != null) chip(_chapterName('${meta!['module']}'), icon: Icons.view_list_outlined),
                    if (minutes != null) chip('$minutes min de citit', icon: Icons.schedule),
                    if (complete) chip('Lecție completă', icon: Icons.verified, fg: _cGreen),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 27 : 36, fontWeight: FontWeight.w700, color: Pb.text, height: 1.18, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  data['subtitle']?.toString() ?? '',
                  style: TextStyle(fontSize: isMobile ? 16 : 18, color: Pb.muted, height: 1.5),
                ),
                const SizedBox(height: 18),
                byline,
                if (isMobile) ...[const SizedBox(height: 12), Align(alignment: Alignment.centerLeft, child: readBtn)],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- sidebar
  Widget _cToc(List<dynamic> sections, Color c) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cDeco(r: 14),
      child: ValueListenableBuilder<int>(
        valueListenable: _active,
        builder: (_, active, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.toc, size: 19, color: Pb.muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Cuprins', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text))),
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (_, v, __) => Text('${(v * 100).round()}%', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < sections.length; i++)
              _DHover(
                onTap: () => _scrollToSection(i),
                builder: (h) {
                  final sel = i == active;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: sel ? c.withOpacity(0.08) : (h ? Pb.hoverBg : Colors.transparent),
                      border: Border(
                        top: BorderSide(color: Pb.border),
                        left: BorderSide(color: sel ? c : Colors.transparent, width: 3),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(13, 10, 14, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${i + 1}',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? c : Pb.muted, height: 1.45)),
                        ),
                        Expanded(
                          child: Text(
                            _stripNum(sections[i]['heading']?.toString() ?? 'Secțiunea ${i + 1}'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel || h ? Pb.text : Pb.muted,
                            ),
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
    );
  }

  Widget _cPractice(String subj, Color c) {
    final materie = subj.startsWith('MATEMATIC') ? 'Matematică' : 'Informatică';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 18, color: c),
              const SizedBox(width: 8),
              Text('Exersează', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Pb.text)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Probleme de $materie, evaluate automat.', style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45)),
          const SizedBox(height: 12),
          PbButton(
            text: 'Deschide problemele',
            icon: Icons.arrow_forward,
            size: PbSize.sm,
            fullWidth: true,
            onPressed: () => context.go('/lista-exercitii?materie=${Uri.encodeComponent(materie)}'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- article
  Widget _cArticle(Map<String, dynamic> data, List<dynamic> sections, Map<String, dynamic>? meta, Color c, bool isMobile) {
    final subj = _subjectOf(data);
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 18 : 34, isMobile ? 8 : 14, isMobile ? 18 : 34, isMobile ? 20 : 30),
      decoration: _cDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile && sections.length > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < sections.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _DHover(
                        onTap: () => _scrollToSection(i),
                        builder: (h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Pb.border),
                          ),
                          child: Text(
                            '${i + 1}. ${_stripNum(sections[i]['heading']?.toString() ?? '')}',
                            style: TextStyle(fontSize: 12.5, color: Pb.text),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          for (var i = 0; i < sections.length; i++) _cSection(i, sections[i], c, isMobile),
          const SizedBox(height: 26),
          Container(height: 1, color: Pb.border),
          const SizedBox(height: 18),
          _cNeighbours(meta, c, isMobile),
          if (isMobile) ...[const SizedBox(height: 14), _cPractice(subj, c)],
        ],
      ),
    );
  }

  Widget _cSection(int i, dynamic sec, Color c, bool isMobile) {
    final rawHeading = sec['heading']?.toString() ?? '';
    final heading = _stripNum(rawHeading);
    final num = RegExp(r'^\s*(\d+)\.').firstMatch(rawHeading)?.group(1) ?? '${i + 1}';
    final text = sec['text']?.toString() ?? '';
    final code = sec['code']?.toString();
    final lang = sec['lang']?.toString() ?? 'cpp';
    final callout = sec['callout']?.toString();

    return Container(
      key: _sectionKeys[i],
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(top: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                  child: Text(num, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    heading,
                    style: TextStyle(fontSize: isMobile ? 21 : 24, fontWeight: FontWeight.w700, color: Pb.text, height: 1.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (text.isNotEmpty) PbRichText(text, fontSize: isMobile ? 16 : 17, height: 1.75),
          if (code != null && code.isNotEmpty) ...[
            const SizedBox(height: 16),
            PbCodeBlock(code: code, lang: lang, onCopy: () => _copyToClipboard(code)),
          ],
          if (callout != null && callout.isNotEmpty) ...[
            const SizedBox(height: 16),
            _cCallout(callout),
          ],
        ],
      ),
    );
  }

  /// "TITLU:\ncorp" -> titled callout; colour/icon picked from the title.
  Widget _cCallout(String raw) {
    String? title;
    var body = raw;
    final nl = raw.indexOf('\n');
    if (nl > 0 && raw.substring(0, nl).trim().endsWith(':')) {
      final first = raw.substring(0, nl).trim();
      title = AppStyle.sentence(first.substring(0, first.length - 1));
      body = raw.substring(nl + 1).trim();
    }

    final up = (title ?? raw).toUpperCase();
    Color c;
    IconData icon;
    if (up.startsWith('PROBLEM')) {
      c = _cBlue;
      icon = Icons.edit_note;
    } else if (up.startsWith('EROARE') || up.contains('CAPCAN') || up.startsWith('ATENȚIE')) {
      c = _cRose;
      icon = Icons.report_gmailerrorred_outlined;
    } else if (up.contains('TIP') || up.startsWith('SFAT') || up.startsWith('REGUL')) {
      c = _cGreen;
      icon = Icons.tips_and_updates_outlined;
    } else {
      c = _cAmber;
      icon = Icons.lightbulb_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: Pb.text)),
                  const SizedBox(height: 4),
                ],
                PbRichText(body, fontSize: 15.5, height: 1.6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cNeighbours(Map<String, dynamic>? meta, Color c, bool isMobile) {
    if (meta == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: PbButton(
          text: 'Înapoi la lecții',
          icon: Icons.arrow_back,
          variant: PbVariant.outlineSecondary,
          size: PbSize.sm,
          onPressed: () => context.go('/resurse'),
        ),
      );
    }
    final list = ResourcesData.allArticles.where((a) => '${a['grade']}' == '${meta['grade']}').toList();
    final i = list.indexWhere((a) => a['id'] == meta['id']);
    final prev = i > 0 ? list[i - 1] : null;
    final next = i >= 0 && i < list.length - 1 ? list[i + 1] : null;

    Widget card(Map<String, dynamic>? a, bool isNext) {
      if (a == null) return const SizedBox.shrink();
      return _DHover(
        onTap: () => context.go('/resurse/${a['id']}'),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: h ? c.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: h ? c.withOpacity(0.5) : Pb.border),
          ),
          child: Column(
            crossAxisAlignment: isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNext) ...[Icon(Icons.arrow_back, size: 14, color: Pb.muted), const SizedBox(width: 4)],
                  Text(isNext ? 'Lecția următoare' : 'Lecția anterioară', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  if (isNext) ...[const SizedBox(width: 4), Icon(Icons.arrow_forward, size: 14, color: Pb.muted)],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${a['title']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isNext ? TextAlign.right : TextAlign.left,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: h ? c : Pb.text, height: 1.35),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prev != null) card(prev, false),
          if (prev != null && next != null) const SizedBox(height: 10),
          if (next != null) card(next, true),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: card(prev, false)),
        const SizedBox(width: 12),
        Expanded(child: card(next, true)),
      ],
    );
  }

  Widget _cFooter(bool isMobile) {
    final links = [
      PbLink(text: 'Termeni și condiții', fontSize: 14, onTap: () => context.go('/termeni-si-conditii')),
      PbLink(text: 'Politica de confidențialitate', fontSize: 14, onTap: () => context.go('/politica-confidentialitate')),
    ];
    final copy = Text('© 2026 iMeditații', style: TextStyle(color: Pb.muted, fontSize: 14));

    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: PbContainer(
        child: isMobile
            ? Column(children: [
                copy,
                const SizedBox(height: 10),
                Wrap(spacing: 18, runSpacing: 8, alignment: WrapAlignment.center, children: links),
              ])
            : Row(children: [copy, const Spacer(), ...links.expand((l) => [const SizedBox(width: 22), l])]),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(Map<String, dynamic> data, bool isMobile) {
    final List<dynamic> sections = data['sections'] ?? [];
    _ensureKeys(sections);
    _sectionCount = sections.length;

    final String author = '${data['author'] ?? ResourcesData.defaultAuthor}';
    final String date = '${data['date'] ?? ResourcesData.defaultDate}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("CODEX // LECȚIE",
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: isMobile ? 15 : 18)),
        backgroundColor: AppColors.bg,
        iconTheme: IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2.5), child: Container(color: AppColors.border, height: 2.5)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.ink, size: isMobile ? 22 : 28),
          onPressed: () => context.go('/resurse'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: isMobile
              ? SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: _retroContent(data, sections, isMobile, author, date),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 290,
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: _retroToc(sections)),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
                          child: _retroContent(data, sections, isMobile, author, date),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _retroToc(List<dynamic> sections) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: AppStyle.hardShadow(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text("CUPRINS LECȚIE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 6),
          Text("Apasă pentru salt la secțiune:", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Container(height: 2, color: AppColors.border),
          const SizedBox(height: 14),
          ...List.generate(sections.length, (i) {
            final heading = sections[i]['heading'] ?? "Secțiunea ${i + 1}";
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _scrollToSection(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 1.5)),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, size: 18, color: AppColors.sunset),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('$heading',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _retroContent(Map<String, dynamic> data, List<dynamic> sections, bool isMobile, String author, String date) {
    final bannerInk = AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.forest,
          child: Text('${data['tag'] ?? "RESURSĂ TEORETICĂ"}',
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ),
        const SizedBox(height: 14),
        Text('${data['title'] ?? 'LECTURE'}',
            style: TextStyle(fontSize: isMobile ? 26 : 38, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.15, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text('${data['subtitle'] ?? ''}',
            style: TextStyle(fontSize: isMobile ? 14 : 17, color: AppColors.textMuted, fontWeight: FontWeight.bold, height: 1.45)),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 1.5), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(author.isNotEmpty ? author[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
            const SizedBox(width: 8),
            Text("AUTOR: ${author.toUpperCase()}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.ink)),
            const SizedBox(width: 14),
            Icon(Icons.event_note, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 20),
        Container(height: 2.5, color: AppColors.border),
        const SizedBox(height: 20),
        ...List.generate(sections.length, (i) {
          final sec = sections[i];
          final heading = sec['heading']?.toString() ?? '';
          final text = sec['text']?.toString() ?? '';
          final code = sec['code']?.toString();
          final lang = sec['lang']?.toString() ?? 'code';
          final callout = sec['callout']?.toString();

          return Container(
            key: _sectionKeys[i],
            margin: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 12),
                    child: Text(heading,
                        style: TextStyle(fontSize: isMobile ? 21 : 26, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.4)),
                  ),
                if (text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(text,
                        style: TextStyle(
                            fontSize: isMobile ? 16 : 18.5, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.75, letterSpacing: 0.2)),
                  ),
                if (code != null && code.isNotEmpty) _retroCodeBlock(code, lang, isMobile),
                if (callout != null && callout.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                    decoration: BoxDecoration(
                      color: AppColors.sunset.withOpacity(0.12),
                      border: Border(left: BorderSide(color: AppColors.sunset, width: 4.5)),
                    ),
                    child: Text(callout,
                        style: TextStyle(fontSize: isMobile ? 14.5 : 16.5, fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.55)),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.mustard,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: AppStyle.hardShadow(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("APLICĂ TEORIA ÎN PRACTICĂ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: bannerInk)),
              const SizedBox(height: 6),
              Text("Fixează-ți conceptele teoretice rezolvând exercițiile interactive din arena de antrenament.",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: bannerInk)),
              const SizedBox(height: 16),
              RetroButton(
                text: "DESCHIDE ARENA DE EXERCIȚII",
                icon: Icons.play_arrow,
                bgColor: AppColors.ink,
                textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                fontSize: 13,
                onPressed: () => context.go('/exercitii'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _retroCodeBlock(String code, String language, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B242B),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: AppStyle.hardShadow(3.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF141A1F),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(language.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                  ],
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(code),
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 15, color: Colors.white70),
                      SizedBox(width: 4),
                      Text("COPIAZĂ CODUL", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isMobile ? 14 : 15.5,
                color: const Color(0xFFECEFF4),
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// small helpers (Clean)
// =============================================================================
class _DHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _DHover({required this.builder, this.onTap});

  @override
  State<_DHover> createState() => _DHoverState();
}

class _DHoverState extends State<_DHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(_hover),
      ),
    );
  }
}

class _DReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _DReveal({required this.child, this.delayMs = 0});

  @override
  State<_DReveal> createState() => _DRevealState();
}

class _DRevealState extends State<_DReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}