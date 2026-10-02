import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
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

  static const Map<String, String> _langLabels = {'cpp': 'C++', 'python': 'Python', 'code': 'Cod'};

  void _copyToClipboard(String code) {
    final s = AppStyle.current;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.pick("COD COPIAT ÎN CLIPBOARD!", "Codul a fost copiat."),
          style: TextStyle(fontWeight: s.pick(FontWeight.bold, FontWeight.w500), color: Colors.white),
        ),
        backgroundColor: s.pick(AppColors.forest, AppStyle.codeBg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: s.rButton,
          side: s.isClean ? BorderSide.none : BorderSide(color: AppColors.border, width: 2),
        ),
      ),
    );
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getArticleData() {
    // 1. Direct match in curated high-depth lecture dictionary
    if (ResourcesData.curatedLectures.containsKey(widget.articleId)) {
      return ResourcesData.curatedLectures[widget.articleId];
    }

    // 2. Fallback: structured generation from curriculum catalog
    final meta = ResourcesData.allArticles.firstWhere(
      (a) => a['id'] == widget.articleId,
      orElse: () => {},
    );

    if (meta.isNotEmpty) {
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

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final lecture = _getArticleData();

    return StyleBuilder(
      builder: (context, s) {
        if (lecture == null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('resources').doc(widget.articleId).get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppColors.bg,
                  body: Center(child: CircularProgressIndicator(color: s.pick(AppColors.sunset, AppColors.sky))),
                );
              }
              if (!snap.hasData || !snap.data!.exists) {
                return Scaffold(
                  backgroundColor: AppColors.bg,
                  appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, iconTheme: IconThemeData(color: AppColors.ink)),
                  body: Center(
                    child: Text(s.pick("LECȚIE NEIDENTIFICATĂ ÎN CODEX.", "Lecția nu a fost găsită."), style: s.heading(18)),
                  ),
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>;
              return _buildScreenBody(s, data, isMobile);
            },
          );
        }

        return _buildScreenBody(s, lecture, isMobile);
      },
    );
  }

  Widget _buildScreenBody(AppStyle s, Map<String, dynamic> data, bool isMobile) {
    final List<dynamic> sections = data['sections'] ?? [];

    for (int i = 0; i < sections.length; i++) {
      _sectionKeys.putIfAbsent(i, () => GlobalKey());
    }

    final String author = data['author'] ?? ResourcesData.defaultAuthor;
    final String date = data['date'] ?? ResourcesData.defaultDate;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          s.pick("CODEX // LECȚIE", "Lecții"),
          style: s.isClean
              ? TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: isMobile ? 15 : 16)
              : TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: isMobile ? 15 : 18),
        ),
        backgroundColor: s.pick(AppColors.bg, AppColors.cardBg),
        iconTheme: IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(s.isClean ? 1 : 2.5),
          child: Container(color: s.line, height: s.isClean ? 1 : 2.5),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.ink, size: isMobile ? 22 : s.pick(28.0, 24.0)),
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
                  child: _buildLectureContent(s, data, sections, isMobile, author, date),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 290,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: _buildTableOfContents(s, sections),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
                          child: s.isClean
                              // Clean keeps a readable line length.
                              ? Align(
                                  alignment: Alignment.topLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 760),
                                    child: _buildLectureContent(s, data, sections, isMobile, author, date),
                                  ),
                                )
                              : _buildLectureContent(s, data, sections, isMobile, author, date),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLE OF CONTENTS
  // ---------------------------------------------------------------------------
  Widget _buildTableOfContents(AppStyle s, List<dynamic> sections) {
    if (s.isClean) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        decoration: s.card(cleanLevel: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text("Cuprins", style: s.heading(15)),
            ),
            const SizedBox(height: 10),
            Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(sections.length, (i) {
                  final raw = sections[i]['heading']?.toString() ?? "Secțiunea ${i + 1}";
                  final label = raw.replaceFirst(RegExp(r'^\d+\.\s*'), '');
                  return InkWell(
                    borderRadius: s.rButton,
                    hoverColor: AppColors.ink.withOpacity(AppColors.isDark ? 0.08 : 0.05),
                    onTap: () => _scrollToSection(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text("${i + 1}", style: s.muted(13.5)),
                          ),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: s.hardShadow(4),
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
          const AppDivider(),
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
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, size: 18, color: AppColors.sunset),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          heading,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  // ---------------------------------------------------------------------------
  // LECTURE
  // ---------------------------------------------------------------------------
  Widget _buildTags(AppStyle s, String? tag) {
    if (s.isRetro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        color: AppColors.forest,
        child: Text(
          tag ?? "RESURSĂ TEORETICĂ",
          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      );
    }
    final parts = (tag ?? "Resursă teoretică").split('//').map(AppStyle.sentence).where((p) => p.isNotEmpty).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < parts.length; i++)
          AppBadge(text: parts[i], color: i == 0 ? AppColors.forest : AppColors.sky, fontSize: 11.5),
      ],
    );
  }

  Widget _buildLectureContent(
    AppStyle s,
    Map<String, dynamic> data,
    List<dynamic> sections,
    bool isMobile,
    String author,
    String date,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTags(s, data['tag']?.toString()),
        SizedBox(height: s.pick(14.0, 16.0)),
        Text(
          data['title'] ?? 'Lecție',
          style: s.display(isMobile ? s.pick(26.0, 26.0) : s.pick(38.0, 34.0)),
        ),
        const SizedBox(height: 8),
        Text(
          data['subtitle'] ?? '',
          style: s.isClean
              ? s.muted(isMobile ? 15 : 18, height: 1.5)
              : TextStyle(fontSize: isMobile ? 14 : 17, color: AppColors.textMuted, fontWeight: FontWeight.bold, height: 1.45),
        ),
        const SizedBox(height: 16),

        // Author & date
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: s.isClean ? s.tint(AppColors.sky) : AppColors.mustard,
                border: s.isClean ? null : Border.all(color: AppColors.border, width: 1.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                author.isNotEmpty ? author[0].toUpperCase() : 'A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: s.pick(FontWeight.w900, FontWeight.w600),
                  color: s.isClean ? s.accentText(AppColors.sky) : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.pick("AUTOR: ${author.toUpperCase()}", author),
              style: s.isClean
                  ? TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.ink)
                  : TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Icon(s.pick(Icons.event_note, Icons.calendar_today_outlined), size: s.pick(15.0, 13.0), color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text(date, style: s.isClean ? s.muted(13) : TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
          ],
        ),

        const SizedBox(height: 20),
        const AppDivider(retroThickness: 2.5),
        const SizedBox(height: 20),

        ...List.generate(sections.length, (i) {
          final sec = sections[i];
          final heading = sec['heading']?.toString() ?? '';
          final text = sec['text']?.toString() ?? '';
          final code = sec['code'];
          final lang = sec['lang']?.toString() ?? 'code';
          final callout = sec['callout'];

          return Container(
            key: _sectionKeys[i],
            margin: EdgeInsets.only(bottom: s.pick(28.0, 32.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty) _buildSectionHeader(s, heading, isMobile),
                if (text.isNotEmpty) _buildParagraph(s, text, isMobile),
                if (code != null && code.toString().isNotEmpty) _buildCodeBlock(s, code.toString(), lang, isMobile),
                if (callout != null && callout.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: AppCallout(
                      text: callout.toString(),
                      color: AppColors.sunset,
                      icon: s.isClean ? Icons.info_outline : null,
                      fontSize: isMobile ? s.pick(14.5, 15.0) : s.pick(16.5, 16.0),
                    ),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
        _buildBottomBanner(s),
      ],
    );
  }

  Widget _buildBottomBanner(AppStyle s) {
    final title = s.pick("APLICĂ TEORIA ÎN PRACTICĂ", "Exersează ce ai citit");
    final text = s.pick(
      "Fixează-ți conceptele teoretice rezolvând exercițiile interactive din arena de antrenament.",
      "Rezolvă probleme pe aceeași temă. Fiecare soluție e verificată automat.",
    );

    if (s.isClean) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: s.card(cleanLevel: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: s.heading(18)),
            const SizedBox(height: 6),
            Text(text, style: s.muted(15)),
            const SizedBox(height: 16),
            RetroButton(
              text: "Deschide exercițiile",
              bgColor: s.primaryFill(AppColors.ink),
              textColor: s.primaryText(Colors.white),
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              onPressed: () => context.go('/exercitii'),
            ),
          ],
        ),
      );
    }

    final bannerInk = AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mustard,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: s.hardShadow(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: bannerInk)),
          const SizedBox(height: 6),
          Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: bannerInk)),
          const SizedBox(height: 16),
          RetroButton(
            text: "DESCHIDE ARENA DE EXERCIȚII",
            icon: Icons.play_arrow,
            bgColor: AppColors.ink,
            textColor: s.onInk,
            fontSize: 13,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            onPressed: () => context.go('/exercitii'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppStyle s, String title, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Text(
        title,
        style: s.isClean
            ? s.heading(isMobile ? 20 : 24)
            : TextStyle(fontSize: isMobile ? 21 : 26, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.4),
      ),
    );
  }

  Widget _buildParagraph(AppStyle s, String text, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: s.isClean
            ? s.body(isMobile ? 16 : 17, height: 1.75)
            : TextStyle(fontSize: isMobile ? 16 : 18.5, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.75, letterSpacing: 0.2),
      ),
    );
  }

  Widget _buildCodeBlock(AppStyle s, String code, String language, bool isMobile) {
    final label = s.pick(language.toUpperCase(), _langLabels[language] ?? language);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      clipBehavior: Clip.antiAlias,
      decoration: s.codeSurface(withShadow: s.isRetro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppStyle.codeGutter,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (s.isRetro) ...[
                      Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      label,
                      style: s.isClean
                          ? const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)
                          : const TextStyle(color: AppStyle.codeAccent, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _copyToClipboard(code),
                    child: Row(
                      children: [
                        Icon(s.pick(Icons.copy, Icons.content_copy_outlined), size: s.pick(15.0, 14.0), color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          s.pick("COPIAZĂ CODUL", "Copiază"),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: s.pick(11.0, 12.5),
                            fontWeight: s.pick(FontWeight.bold, FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: SelectableText(
              code,
              style: s.mono(
                isMobile ? s.pick(14.0, 13.5) : s.pick(15.5, 14.5),
                color: AppStyle.codeText,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}