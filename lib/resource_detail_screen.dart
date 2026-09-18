import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'resources_data.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String articleId;
  const ResourceDetailScreen({super.key, required this.articleId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("COD COPIAT ÎN CLIPBOARD!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
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
            // NO CODE FOR MATH!
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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        if (lecture == null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('resources').doc(widget.articleId).get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppColors.bg,
                  body: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
                );
              }
              if (!snap.hasData || !snap.data!.exists) {
                return Scaffold(
                  backgroundColor: AppColors.bg,
                  appBar: AppBar(backgroundColor: AppColors.bg, iconTheme: IconThemeData(color: AppColors.ink)),
                  body: Center(
                    child: Text("LECȚIE NEIDENTIFICATĂ ÎN CODEX.", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
                  ),
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>;
              return _buildScreenBody(data, isMobile);
            },
          );
        }

        return _buildScreenBody(lecture, isMobile);
      },
    );
  }

  Widget _buildScreenBody(Map<String, dynamic> data, bool isMobile) {
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
          "CODEX // LECȚIE",
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: isMobile ? 15 : 18),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(color: AppColors.border, height: 2.5),
        ),
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
                  child: _buildLectureContent(data, sections, isMobile, author, date),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Table of Contents
                    SizedBox(
                      width: 290,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: _buildTableOfContents(sections),
                      ),
                    ),
                    const SizedBox(width: 28),
                    // Main Article Reading View
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
                          child: _buildLectureContent(data, sections, isMobile, author, date),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTableOfContents(List<dynamic> sections) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                "CUPRINS LECȚIE",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Apasă pentru salt la secțiune:",
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
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
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
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

  Widget _buildLectureContent(Map<String, dynamic> data, List<dynamic> sections, bool isMobile, String author, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.forest,
          child: Text(
            data['tag'] ?? "RESURSĂ TEORETICĂ",
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ),
        const SizedBox(height: 14),
        // Title (Bigger Text)
        Text(
          data['title'] ?? 'LECTURE',
          style: TextStyle(
            fontSize: isMobile ? 26 : 38,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            height: 1.15,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle (Bigger Text)
        Text(
          data['subtitle'] ?? '',
          style: TextStyle(
            fontSize: isMobile ? 14 : 17,
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),

        // Author & Date
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.mustard,
                border: Border.all(color: AppColors.border, width: 1.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                author.isNotEmpty ? author[0].toUpperCase() : 'A',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
              ),
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

        // Dynamic Section Renderer
        ...List.generate(sections.length, (i) {
          final s = sections[i];
          final heading = s['heading'] ?? '';
          final text = s['text'] ?? '';
          final code = s['code'];
          final lang = s['lang'] ?? 'code';
          final callout = s['callout'];

          return Container(
            key: _sectionKeys[i],
            margin: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty) _buildSectionHeader(heading, isMobile),
                if (text.isNotEmpty) _buildParagraph(text, isMobile),
                // Render code ONLY IF PRESENT (Informatics has code, Math does not)
                if (code != null && code.toString().isNotEmpty) _buildCodeBlock(code, lang, isMobile),
                if (callout != null && callout.toString().isNotEmpty) _buildCallout(callout, AppColors.sunset, isMobile),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Bottom Action Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.mustard,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "APLICĂ TEORIA ÎN PRACTICĂ",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                "Fixează-ți conceptele teoretice rezolvând exercițiile interactive din arena de antrenament.",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text("DESCHIDE ARENA DE EXERCIȚII", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8)),
                onPressed: () => context.go('/exercitii'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 21 : 26,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 16 : 18.5,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          height: 1.75,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String code, String language, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B242B),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3.5, 3.5))],
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
                    Text(
                      language.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(code),
                  child: Row(
                    children: const [
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

  Widget _buildCallout(String text, Color accentColor, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        border: Border(left: BorderSide(color: accentColor, width: 4.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 14.5 : 16.5,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
          height: 1.55,
        ),
      ),
    );
  }
}