import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String articleId;
  const ResourceDetailScreen({super.key, required this.articleId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  final Map<String, Map<String, dynamic>> _curatedLectures = {
    "py-intro": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Introducere în limbajul Python",
      "subtitle": "Ghidul de start conform noii programe de liceu pentru clasa a 9-a.",
      "author": "Ahmad Arnaoute",
      "date": "18.09.2026",
      "sections": [
        {
          "heading": "1. De ce Python în liceu?",
          "text": "Spre deosebire de C++, care impune o sintaxă rigidă cu acolade, punct și virgulă și specificarea strictă a tipurilor de date, Python oferă o sintaxă curată, apropiată de limba engleză. În clasa a 9-a, Python este utilizat pentru a înțelege structura algoritmilor fără barieră sintactică.",
        },
        {
          "heading": "2. Compilare vs. Interpretare",
          "text": "În C++, codul sursă este compilat direct în binar executabil pe procesor. În Python, fișierele .py sunt interpretate linie cu linie de către interpretorul Python, permițând testare rapidă și prototipare dinamică.",
          "code": "# Primul tău program în Python:\nprint(\"Nivelul 1 a început!\")\n\n# Citire de la tastatură:\nnume = input(\"Introdu numele tău de aventurier: \")\nprint(f\"Bun venit în breaslă, {nume}!\")",
          "lang": "python"
        },
        {
          "heading": "3. Regula de Aur: Indentarea PEP 8",
          "text": "În Python NU există acolade { } pentru delimitarea blocurilor! Structurile (if, for, while, funcții) sunt definite exclusiv prin indentare (exact 4 spații). O aliniere incorectă generează un IndentationError.",
          "callout": "ATENȚIE:\nNu amesteca tab-urile cu spațiile! Folosește întotdeauna 4 spații pentru fiecare nivel de indentare conform standardului oficial PEP 8."
        },
      ]
    },
    "py-vars": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Variabile, Tipuri Primitive & input()",
      "subtitle": "Cum stocăm și manipulăm datele în memoria programului.",
      "author": "Ahmad Arnaoute",
      "date": "18.09.2026",
      "sections": [
        {
          "heading": "1. Tipare dinamică în Python",
          "text": "Nu este nevoie să declari tipul unei variabile în avans (ca în C++: int x;). Python asociază tipul automat în funcție de valoarea atribuită.",
        },
        {
          "heading": "2. Tipuri fundamentale de date",
          "text": "• int: Numere întregi pozitive sau negative (fără limită fixă de 32 de biți ca în C++).\n• float: Numere cu virgulă mobilă (reale).\n• str: Șiruri de caractere delimitate prin ghilimele simple sau duble.\n• bool: Valori de adevăr (True sau False).",
          "code": "varsta = 15          # int\ninaltime = 1.75      # float\nnume = \"Alex\"        # str\neste_elev = True     # bool",
          "lang": "python"
        },
        {
          "heading": "3. Funcția input() și conversia de tip (Casting)",
          "text": "Funcția input() returnează întotdeauna un șir de caractere (str). Pentru a face calcule matematice, este obligatoriu să convertim rezultatul cu int() sau float().",
          "code": "a = int(input(\"Introdu a: \"))\nb = int(input(\"Introdu b: \"))\nsuma = a + b\nprint(\"Suma este:\", suma)",
          "lang": "python",
          "callout": "EROARE FRECVENTĂ:\nDacă scrii `a = input()` și `b = input()`, `a + b` va concatena textele (ex: '3' + '5' = '35'), în loc să adune valorile!"
        }
      ]
    },
    "py-if": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Instrucțiunea Decizională: if, elif & else",
      "subtitle": "Cum controlăm fluxul programului folosind decizii logice.",
      "author": "Ahmad Arnaoute",
      "date": "18.09.2026",
      "sections": [
        {
          "heading": "1. Structura if - elif - else",
          "text": "Permite executarea diferitelor blocuri de instrucțiuni în funcție de evaluarea unei expresii booleene.",
          "code": "nota = int(input(\"Introdu nota obținută: \"))\n\nif nota >= 9:\n    print(\"Excelent! Rang aur.\")\nelif nota >= 7:\n    print(\"Bun! Rang argint.\")\nelif nota >= 5:\n    print(\"Ai trecut examenul.\")\nelse:\n    print(\"Trebuie să reiei quest-ul!\")",
          "lang": "python"
        },
        {
          "heading": "2. Operatori de comparare și logici",
          "text": "Operatorii sunt scriși simplu și lizibil:\n• `and`: și logic\n• `or`: sau logic\n• `not`: negație\n• `==` (egalitate), `!=` (diferit), `>=`, `<=`, `>`, `<`",
          "code": "if varsta >= 14 and are_buletin:\n    print(\"Acces autorizat în arenă.\")",
          "lang": "python"
        }
      ]
    },
    "cpp-intro": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Structura unui Program C++ & iostream",
      "subtitle": "Directiva #include, funcția main() și fluxurile de intrare/ieșire.",
      "author": "Ahmad Arnaoute",
      "date": "18.09.2026",
      "sections": [
        {
          "heading": "1. Scheletul programului",
          "text": "Fiecare program C++ începe cu includerea bibliotecilor necesare și definirea funcției `main()`, punctul de pornire al execuției.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << \"Nivel 1 C++ activat!\" << endl;\n    return 0;\n}",
          "lang": "cpp"
        },
        {
          "heading": "2. Fluxul cin și cout",
          "text": "Pentru afișare folosim operatorul de inserție `<<` cu `cout`, iar pentru citire operatorul de extracție `>>` cu `cin`.",
          "code": "int x, y;\ncin >> x >> y;\ncout << \"Produsul este: \" << x * y << \"\\n\";",
          "lang": "cpp"
        }
      ]
    },
    "cpp-vectors": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Tablouri Unidimensionale (Vectori)",
      "subtitle": "Gestiunea colecțiilor omogene de date indexate de la 0 la n-1.",
      "author": "Ahmad Arnaoute",
      "date": "18.09.2026",
      "sections": [
        {
          "heading": "1. Ce este un vector?",
          "text": "Un vector este o zonă contiguă de memorie ce conține elemente de același tip. În C++, elementele sunt numerotate începând cu indicele 0.",
          "code": "int v[100]; // declarăm un vector cu maximum 100 de elemente\nint n;\ncin >> n;   // numărul real de elemente\n\nfor (int i = 0; i < n; i++) {\n    cin >> v[i];\n}",
          "lang": "cpp"
        },
        {
          "heading": "2. Maximul dintr-un vector",
          "text": "Inițializăm maximul cu primul element și comparăm secvențial cu restul elementelor.",
          "code": "int maxim = v[0];\nfor (int i = 1; i < n; i++) {\n    if (v[i] > maxim) {\n        maxim = v[i];\n    }\n}\ncout << \"Maximul este: \" << maxim;",
          "lang": "cpp",
          "callout": "SFAT DE COD:\nNu inițializa niciodată maximul cu 0 dacă vectorul poate conține și numere negative! Folosește primul element `v[0]`."
        }
      ]
    },
    "cpp-matrix": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Tablouri Bidimensionale (Matrice)",
      "subtitle": "Tabele structurate pe linii și coloane.",
      "author": "Ahmad Arnaoute",
      "date": "18.09.2026",
      "sections": [
        {
          "heading": "1. Declarare și Parcurgere",
          "text": "O matrice are nevoie de doi indici: primul pentru linie (i) și al doilea pentru coloană (j).",
          "code": "int a[100][100];\nint n, m;\ncin >> n >> m; // n linii, m coloane\n\nfor (int i = 0; i < n; i++) {\n    for (int j = 0; j < m; j++) {\n        cin >> a[i][j];\n    }\n}",
          "lang": "cpp"
        },
        {
          "heading": "2. Diagonalele unei matrice pătratice (n == m)",
          "text": "• Diagonala principală: elementele unde `i == j`\n• Diagonala secundară: elementele unde `i + j == n - 1`",
          "code": "for (int i = 0; i < n; i++) {\n    cout << a[i][i] << \" \"; // Afișează diagonala principală\n}",
          "lang": "cpp"
        }
      ]
    },
  };

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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final lecture = _curatedLectures[widget.articleId];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        if (lecture == null) {
          // Check if article exists in Firestore
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

    final String author = data['author'] ?? "Ahmad Arnaoute";
    final String date = data['date'] ?? "18.09.2026";

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
                    // LEFT COLUMN: Sticky Cuprins
                    SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _buildTableOfContents(sections),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // RIGHT COLUMN: Main lesson text
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
        // Topic Title Badge
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

        // Author bar
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

        // Render Dynamic Sections
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
        // Practice action
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