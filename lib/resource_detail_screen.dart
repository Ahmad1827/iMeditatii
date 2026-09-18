import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'resources_data.dart'; // <--- Import centralized dataset

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
    // 1. Direct match in curated lecture text
    if (ResourcesData.curatedLectures.containsKey(widget.articleId)) {
      return ResourcesData.curatedLectures[widget.articleId];
    }

    // 2. Generate structured lecture layout from metadata
    final meta = ResourcesData.allArticles.firstWhere(
      (a) => a['id'] == widget.articleId,
      orElse: () => {},
    );

    if (meta.isNotEmpty) {
      return {
        "tag": "${meta['subject']} // CLASA A ${meta['grade']}-A // ${meta['module']}",
        "title": meta['title'],
        "subtitle": meta['desc'],
        "author": meta['author'] ?? ResourcesData.defaultAuthor,
        "date": meta['date'] ?? ResourcesData.defaultDate,
        "sections": [
          {
            "heading": "1. Concepte Fundamentale",
            "text": "${meta['desc']} Această secțiune detaliază principiile teoretice conform cerințelor programei naționale de liceu pentru clasa a ${meta['grade']}-a.",
          },
          {
            "heading": "2. Structură & Implementare",
            "text": "Studiul aprofundat al noțiunii de ${meta['title']} implică respectarea standardelor de eficiență algoritmică și scrierea unui cod lizibil.",
            "code": meta['subject'] == 'PYTHON'
                ? "# Implementare în Python\ndef rezolvare():\n    print(\"Exemplu demonstrativ pentru: ${meta['title']}\")\n\nrezolvare()"
                : "// Implementare în C++\n#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << \"Studiu: ${meta['title']}\" << endl;\n    return 0;\n}",
            "lang": meta['subject'] == 'PYTHON' ? 'python' : 'cpp',
          },
          {
            "heading": "3. Recomandări de Studiu",
            "text": "Pentru a consolida aceste cunoștințe, rezolvă problemele dedicate din arena noastră interactivă.",
            "callout": "SFAT DE ANTRENAMENT:\nExersează scrierea codului direct în compilator fără să copiezi rezolvarea pentru a-ți fixa logica de programare."
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
          // Check Firestore
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
      if (!_sectionKeys.containsKey(i)) {
        _sectionKeys[i] = GlobalKey();
      }
    }

    final String author = data['author'] ?? ResourcesData.defaultAuthor;
    final String date = data['date'] ?? ResourcesData.defaultDate;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          "CODEX // LECȚIE",
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: isMobile ? 15 : 17),
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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isMobile
              ? SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildLectureContent(data, sections, isMobile, author, date),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _buildTableOfContents(sections),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3.5, 3.5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                "CUPRINS LECȚIE",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Apasă pentru salt la secțiune:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Container(height: 2, color: AppColors.border),
          const SizedBox(height: 12),
          ...List.generate(sections.length, (i) {
            final heading = sections[i]['heading'] ?? "Secțiunea ${i + 1}";
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _scrollToSection(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, size: 16, color: AppColors.sunset),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          heading,
                          style: TextStyle(
                            fontSize: 12,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.forest,
          child: Text(
            data['tag'] ?? "RESURSĂ TEORETICĂ",
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data['title'] ?? 'LECTURE',
          style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          data['subtitle'] ?? '',
          style: TextStyle(fontSize: isMobile ? 13 : 15, color: AppColors.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.mustard,
                border: Border.all(color: AppColors.border, width: 1.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(author[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
            const SizedBox(width: 8),
            Text("AUTOR: ${author.toUpperCase()}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.ink)),
            const SizedBox(width: 14),
            Icon(Icons.event_note, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted)),
          ],
        ),

        const SizedBox(height: 18),
        Container(height: 2, color: AppColors.border),
        const SizedBox(height: 18),

        ...List.generate(sections.length, (i) {
          final s = sections[i];
          final heading = s['heading'] ?? '';
          final text = s['text'] ?? '';
          final code = s['code'];
          final lang = s['lang'] ?? 'code';
          final callout = s['callout'];

          return Container(
            key: _sectionKeys[i],
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty) _buildSectionHeader(heading),
                if (text.isNotEmpty) _buildParagraph(text),
                if (code != null && code.toString().isNotEmpty) _buildCodeBlock(code, lang),
                if (callout != null && callout.toString().isNotEmpty) _buildCallout(callout, AppColors.sunset),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.mustard,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "VERIFICĂ-ȚI CUNOȘTINȚELE",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                "Ai înțeles conceptele? Intră în arenă și rezolvă primele exerciții interactive pentru această disciplină.",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text("ANTRENEAZĂ-TE ÎN ARENĂ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                onPressed: () {
                  context.go('/exercitii');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.6),
      ),
    );
  }

  Widget _buildCodeBlock(String code, String language) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B242B),
        border: Border.all(color: AppColors.border, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF141A1F),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(code),
                  child: Row(
                    children: const [
                      Icon(Icons.copy, size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text("COPY", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Color(0xFFECEFF4),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallout(String text, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.5),
      ),
    );
  }
}