import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String articleId;
  const ResourceDetailScreen({super.key, required this.articleId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
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
                      child: _buildLectureContent(isMobile),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Table of Contents (Cuprins)
                        SizedBox(
                          width: 280,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: _buildTableOfContents(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Reading Body
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                              child: _buildLectureContent(isMobile),
                            ),
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

  Widget _buildTableOfContents() {
    final chapters = [
      "1. De ce Python?",
      "2. Compilat vs. Interpretat",
      "3. Primul program (Hello World)",
      "4. Comentarii & Bune Practici",
      "5. Antrenament în Arenă",
    ];

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
          const SizedBox(height: 14),
          ...chapters.map((ch) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                ch,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLectureContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Title Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.forest,
          child: const Text(
            "INFORMATICĂ // CLASA A 9-A // PYTHON",
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Introducere în limbajul Python[cite: 4, 5]",
          style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          "Ghidul de start conform noii programe de liceu pentru clasa a 9-a.",
          style: TextStyle(fontSize: isMobile ? 13 : 15, color: AppColors.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(height: 2, color: AppColors.border),
        const SizedBox(height: 20),

        // Section 1
        _buildSectionHeader("1. De ce Python în liceu?"),
        _buildParagraph(
          "Spre deosebire de C++, care impune o sintaxă rigidă cu acolade, punct și virgulă și specificarea strictă a tipurilor de date încă din prima zi, Python oferă o sintaxă curată, apropiată de limba engleză[cite: 5]. În clasa a 9-a, Python este folosit pentru a învăța logica algoritmilor fără barieră sintactică.",
        ),

        // Section 2
        _buildSectionHeader("2. Compilare vs. Interpretare[cite: 5]"),
        _buildParagraph(
          "În C++, codul sursă este compilat direct în cod mașină (binar) executat de procesor[cite: 5]. În Python, fișierele .py sunt interpretate linie cu linie de către interpretorul Python, ceea ce face testarea mult mai rapidă, dar execuția ceva mai lentă comparativ cu limbajele compilate[cite: 5].",
        ),

        // Code block example
        _buildCodeBlock(
          "# Primul tău program în Python:\nprint(\"Nivelul 1 a început!\")\n\n# Citirea unui număr întreg de la tastatură:\nn = int(input(\"Introdu un număr: \"))\nprint(\"Dublul numărului este:\", n * 2)",
          "python",
        ),

        // Section 3
        _buildSectionHeader("3. Regula de Aur: Indentarea PEP 8[cite: 4]"),
        _buildCallout(
          "ATENȚIE LA SPAȚII:\nÎn Python NU există acolade { } pentru blocuri de instrucțiuni! Structurile (if, for, while, funcții) sunt definite exclusiv prin indentare (exact 4 spații). O aliniere greșită generează un 'IndentationError'.",
          AppColors.sunset,
        ),

        const SizedBox(height: 28),
        // Action Deck
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
                "Ai înțeles conceptele? Intră în arenă și rezolvă primele exerciții interactive pentru clasa a 9-a.",
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
                  final encoded = Uri.encodeComponent("Informatică");
                  context.go('/lista-exercitii?materie=$encoded');
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
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.6),
      ),
    );
  }

  Widget _buildCodeBlock(String code, String language) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
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
      margin: const EdgeInsets.symmetric(vertical: 14),
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