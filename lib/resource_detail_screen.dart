import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Map<String, dynamic>? _getArticleData() {
    if (ResourcesData.curatedLectures.containsKey(widget.articleId)) {
      return ResourcesData.curatedLectures[widget.articleId];
    }

    final meta = ResourcesData.allArticles.firstWhere((a) => a['id'] == widget.articleId, orElse: () => {});
    if (meta.isEmpty) return null;

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
  // CLEAN — pbinfo-style article
  // ===========================================================================
  Widget _buildClean(Map<String, dynamic> data, bool isMobile) {
    final List<dynamic> sections = data['sections'] ?? [];
    _ensureKeys(sections);

    final tagParts = (data['tag']?.toString() ?? '')
        .split('//')
        .map(AppStyle.sentence)
        .where((p) => p.isNotEmpty)
        .toList();
    final title = data['title']?.toString() ?? 'Lecție';

    final toc = PbCard(
      title: 'Cuprins',
      padding: EdgeInsets.zero,
      child: PbListGroup(
        flush: true,
        items: [
          for (var i = 0; i < sections.length; i++)
            PbListItem(
              (sections[i]['heading']?.toString() ?? 'Secțiunea ${i + 1}').replaceFirst(RegExp(r'^\d+\.\s*'), ''),
              onTap: () => _scrollToSection(i),
            ),
        ],
      ),
    );

    final practice = PbCard(
      title: 'Exersează',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rezolvă probleme pe aceeași temă, evaluate automat.', style: TextStyle(color: Pb.muted, fontSize: 15, height: 1.5)),
          const SizedBox(height: 12),
          PbButton(text: 'Deschide problemele', fullWidth: true, onPressed: () => context.go('/exercitii')),
        ],
      ),
    );

    final article = _cleanArticle(data, sections, tagParts, title, isMobile, mobileToc: isMobile ? toc : null);

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: PbContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Pb.surface, borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
                        child: PbBreadcrumb(items: [
                          PbCrumb('Lecții', () => context.go('/resurse')),
                          if (tagParts.isNotEmpty) PbCrumb(tagParts.first, () => context.go('/resurse')),
                          if (tagParts.length > 1) PbCrumb(tagParts[1], () => context.go('/resurse')),
                          PbCrumb(title),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      if (isMobile) ...[
                        article,
                        const SizedBox(height: 24),
                        practice,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 260,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [toc, const SizedBox(height: 16), practice],
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 760),
                                  child: article,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanArticle(
    Map<String, dynamic> data,
    List<dynamic> sections,
    List<String> tagParts,
    String title,
    bool isMobile, {
    Widget? mobileToc,
  }) {
    final author = data['author']?.toString() ?? ResourcesData.defaultAuthor;
    final date = data['date']?.toString() ?? ResourcesData.defaultDate;
    final meta = TextStyle(fontSize: 14, color: Pb.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: TextStyle(fontSize: isMobile ? 28 : 38, color: Pb.text, height: 1.2)),
        const SizedBox(height: 10),
        Text(
          data['subtitle']?.toString() ?? '',
          style: TextStyle(fontSize: isMobile ? 17 : 20, color: Pb.muted, fontWeight: FontWeight.w300, height: 1.45),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: Pb.postMeta, borderRadius: Pb.radius),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text('Scris de', style: meta),
              CircleAvatar(
                radius: 10,
                backgroundColor: Pb.secondary,
                child: Text(author.isNotEmpty ? author[0] : 'A', style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
              Text(author, style: meta.copyWith(color: Pb.link, fontWeight: FontWeight.w700)),
              Text('•', style: meta),
              Icon(Icons.event, size: 15, color: Pb.text),
              Text(date, style: meta.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (tagParts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final t in tagParts) PbBadge(text: t, fontSize: 12.5)],
          ),
        ],
        if (mobileToc != null) ...[const SizedBox(height: 20), mobileToc],
        const SizedBox(height: 8),
        ...List.generate(sections.length, (i) {
          final sec = sections[i];
          final heading = (sec['heading']?.toString() ?? '').replaceFirst(RegExp(r'^\d+\.\s*'), '');
          final text = sec['text']?.toString() ?? '';
          final code = sec['code']?.toString();
          final lang = sec['lang']?.toString() ?? 'cpp';
          final callout = sec['callout']?.toString();

          return Container(
            key: _sectionKeys[i],
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (heading.isNotEmpty) PbHeading(heading, size: isMobile ? 24 : 28),
                if (text.isNotEmpty) PbRichText(text, fontSize: isMobile ? 16 : 17, height: 1.7),
                if (code != null && code.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PbCodeBlock(code: code, lang: lang, onCopy: () => _copyToClipboard(code)),
                ],
                if (callout != null && callout.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _cleanCallout(callout),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  /// "TITLU:\ncorp" -> bold sentence-case title + body, as a Bootstrap warning alert.
  Widget _cleanCallout(String raw) {
    String? title;
    var body = raw;
    final nl = raw.indexOf('\n');
    if (nl > 0 && raw.substring(0, nl).trim().endsWith(':')) {
      final first = raw.substring(0, nl).trim();
      title = AppStyle.sentence(first.substring(0, first.length - 1));
      body = raw.substring(nl + 1).trim();
    }
    return PbAlert(
      type: PbAlertType.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5)),
            const SizedBox(height: 4),
          ],
          PbRichText(body, fontSize: 16, height: 1.6, color: Pb.warningText),
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(Map<String, dynamic> data, bool isMobile) {
    final List<dynamic> sections = data['sections'] ?? [];
    _ensureKeys(sections);

    final String author = data['author'] ?? ResourcesData.defaultAuthor;
    final String date = data['date'] ?? ResourcesData.defaultDate;

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
                        child: Text(heading,
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
          child: Text(data['tag'] ?? "RESURSĂ TEORETICĂ",
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ),
        const SizedBox(height: 14),
        Text(data['title'] ?? 'LECTURE',
            style: TextStyle(fontSize: isMobile ? 26 : 38, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.15, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(data['subtitle'] ?? '',
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