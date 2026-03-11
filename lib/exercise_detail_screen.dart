import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; // 🚀 Importul necesar pentru navigare

import 'login_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String subject;
  final String grade;
  final String id;

  const ExerciseDetailScreen({
    super.key,
    required this.subject,
    required this.grade,
    required this.id,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  Map<String, dynamic>? exerciseData;
  String selectedTab = "enunt";
  final TextEditingController _answerController = TextEditingController();
  List<String> debugLogs = [];
  bool solutionChecked = false;
  bool solutionOk = false;
  bool isRunningCode = false;

  String? _selectedGrilaOption;

  @override
  void initState() {
    super.initState();
    _loadExerciseDetailsFromFirebase();
  }

  // --------------------------------------------------------------------------
  // DATA LOADING & AUTH
  // --------------------------------------------------------------------------

  Future<void> _loadExerciseDetailsFromFirebase() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('exercises')
          .doc(widget.id)
          .get();
      if (docSnap.exists) {
        setState(() => exerciseData = docSnap.data());
      } else {
        setState(() => exerciseData = {});
      }
    } catch (e) {
      debugPrint("Eroare la încărcarea exercițiului: $e");
      setState(() => exerciseData = {});
    }
  }

  Future<void> _markExerciseAsDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${widget.grade}_${widget.id}";
    await prefs.setBool(key, true);
  }

  Future<bool> _isExerciseDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${widget.grade}_${widget.id}";
    return prefs.getBool(key) ?? false;
  }

  void _checkAuthAndExecute(VoidCallback action) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      action();
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.lock_outline, color: Colors.black87, size: 28),
                SizedBox(width: 10),
                Text("Autentificare necesară",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Pentru a trimite soluții și a-ți salva progresul, trebuie să te conectezi în contul tău de elev.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => context.pop(), // 🚀 Modificat cu GoRouter
                child: const Text("Înapoi",
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () {
                  context.pop(); // 🚀 Modificat cu GoRouter
                  context.go('/login'); // 🚀 Trimitere către pagina de login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Mergi la Login",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (exerciseData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (exerciseData!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Eroare", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: Text("Exercițiul nu a fost găsit.")),
      );
    }

    final tip = exerciseData!["tip_exercitiu"] ?? "cod";
    List<String> tabs = ["enunt"];
    if (tip == "cod") {
      tabs = ["enunt", "indicatii", "teste", "solutie"];
    } else if (exerciseData!["hints"] != null) {
      tabs.add("indicatii");
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'iMeditatii',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Center(
        child: Container(
          width: isWide ? 950 : double.infinity,
          margin: EdgeInsets.symmetric(
            vertical: isWide ? 40 : 0,
            horizontal: isWide ? 20 : 0,
          ),
          padding: EdgeInsets.all(isWide ? 40 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isWide ? 24 : 0),
            border: isWide ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow: isWide
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernTabs(tabs),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTabContent(selectedTab),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB SYSTEM
  // --------------------------------------------------------------------------

  Widget _buildModernTabs(List<String> tabs) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        children: tabs.map((tab) {
          final isActive = selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => selectedTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
                    : [],
              ),
              child: Text(
                tab[0].toUpperCase() + tab.substring(1),
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(String tab) {
    switch (tab) {
      case "enunt":
        return _buildProblemStatement();
      case "indicatii":
        return _buildHints();
      case "teste":
        return _buildTests();
      case "solutie":
        return _buildOfficialSolution();
      default:
        return const SizedBox();
    }
  }

  // --------------------------------------------------------------------------
  // PROBLEM STATEMENT & SECTIONS
  // --------------------------------------------------------------------------

  Widget _buildProblemStatement() {
    final tip = exerciseData!["tip_exercitiu"] ?? "cod";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _problemHeader(),
        const SizedBox(height: 32),
        const Text("CERINȚA",
            style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 12),
        Text(
          exerciseData!["description"] ?? "Fără descriere.",
          style: TextStyle(
              fontSize: 17,
              color: Colors.grey.shade800,
              height: 1.6,
              letterSpacing: 0.2),
        ),
        const SizedBox(height: 40),
        if (tip == "cod") ...[
          if (exerciseData!["input"] != null)
            _section("Date de intrare", exerciseData!["input"]),
          if (exerciseData!["output"] != null)
            _section("Date de ieșire", exerciseData!["output"]),
          if (exerciseData!["constraints"] != null)
            _sectionList("Restricții și precizări",
                List<String>.from(exerciseData!["constraints"])),
          _exampleSection(),
          const SizedBox(height: 40),
          _uploadSolutionSectionForCode(),
        ] else if (tip == "grila") ...[
          _buildGrilaSection(),
        ] else if (tip == "text") ...[
          _buildTextAnswerSection(),
        ],
      ],
    );
  }

  Widget _problemHeader() {
    return FutureBuilder<bool>(
      future: _isExerciseDone(),
      builder: (context, snapshot) {
        final isDone = snapshot.data ?? false;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text("Clasa ${widget.grade}",
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                exerciseData!["title"] ?? "Exercițiu",
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5),
              ),
            ),
            if (isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 6),
                    Text("Rezolvat",
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // INPUT TYPES (GRILA & TEXT)
  // --------------------------------------------------------------------------

  Widget _buildGrilaSection() {
    final List<String> variante = List<String>.from(exerciseData!["variante"] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 32),
        const Text("ALEGE VARIANTA CORECTĂ",
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 16),
        ...variante.map((varianta) {
          final isSelected = _selectedGrilaOption == varianta;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                _checkAuthAndExecute(() {
                  setState(() => _selectedGrilaOption = varianta);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                      width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        varianta,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.blueAccent.shade700 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedGrilaOption == null
                ? null
                : () => _checkAuthAndExecute(_checkSimpleAnswer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: Colors.grey.shade200,
            ),
            child: const Text("Verifică Răspunsul",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        _buildResultBox(),
      ],
    );
  }

  Widget _buildTextAnswerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 32),
        const Text("RĂSPUNSUL TĂU",
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: "Scrie răspunsul aici...",
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _checkAuthAndExecute(_checkSimpleAnswer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Verifică Răspunsul",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        _buildResultBox(),
      ],
    );
  }

  void _checkSimpleAnswer() async {
    final raspunsCorect =
    exerciseData!["raspuns_corect"]?.toString().trim().toLowerCase();
    String raspunsElev = "";

    if (exerciseData!["tip_exercitiu"] == "grila") {
      raspunsElev = _selectedGrilaOption?.trim().toLowerCase() ?? "";
    } else {
      raspunsElev = _answerController.text.trim().toLowerCase();
    }

    setState(() {
      solutionChecked = true;
      solutionOk = (raspunsElev == raspunsCorect);
    });

    if (solutionOk) await _markExerciseAsDone();
  }

  // --------------------------------------------------------------------------
  // CODE EDITOR & JUDGE0
  // --------------------------------------------------------------------------

  Widget _uploadSolutionSectionForCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 32),
        const Text("EDITOR DE COD (C++)",
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _answerController,
            maxLines: 15,
            style: const TextStyle(
                fontFamily: 'monospace', color: Colors.white, fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText:
              "// Scrie codul tău aici...\n#include <iostream>\nusing namespace std;\n\nint main() {\n    return 0;\n}",
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRunningCode ? null : () => _checkAuthAndExecute(_runJudge0Checker),
            icon: isRunningCode
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(isRunningCode ? "Se evaluează..." : "Rulează și Evaluează",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (debugLogs.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
                color: Colors.black87, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CONSOLE OUTPUT",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                ...debugLogs.map((log) => Text(log,
                    style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: log.contains("❌") || log.contains("EȘUAT")
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        height: 1.5))),
              ],
            ),
          ),
        _buildResultBox(),
      ],
    );
  }

  Future<void> _runJudge0Checker() async {
    final code = _answerController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      solutionChecked = false;
      solutionOk = false;
      debugLogs.clear();
      isRunningCode = true;
    });

    try {
      final List<Map<String, dynamic>> tests = [];
      if (exerciseData?["examples"] != null) {
        tests.add({
          "input": exerciseData!["examples"]["input"]?.toString() ?? "",
          "output": exerciseData!["examples"]["output"]?.toString() ?? ""
        });
      }
      if (exerciseData?["tests"] != null) {
        for (var t in exerciseData!["tests"]) {
          tests.add(
              {"input": t["input"]?.toString() ?? "", "output": t["output"]?.toString() ?? ""});
        }
      }

      bool allPassed = true;
      for (int i = 0; i < tests.length; i++) {
        final test = tests[i];
        final inputData = test["input"] ?? "";
        final expectedOutput = test["output"] ?? "";

        final body =
        jsonEncode({"language_id": 52, "source_code": code, "stdin": inputData});
        final uri =
        Uri.parse("https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true");
        final response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
            "X-RapidAPI-Key": "YOUR_API_KEY",
            "X-RapidAPI-Host": "judge0-ce.p.rapidapi.com"
          },
          body: body,
        );

        final result = jsonDecode(response.body);
        final output = (result["stdout"] ?? "").toString();

        String normalize(String s) => s.replaceAll('\r', '').trim();
        final normOutput = normalize(output);
        final normExpected = normalize(expectedOutput);

        if (normOutput != normExpected) {
          allPassed = false;
          debugLogs.add("❌ Testul ${i + 1} a eșuat.");
          debugLogs.add("   Expected: $normExpected");
          debugLogs.add("   Got:      $normOutput\n");
        } else {
          debugLogs.add("✅ Testul ${i + 1} trecut cu succes.");
        }
        setState(() {});
      }

      setState(() {
        solutionChecked = true;
        solutionOk = allPassed;
      });
      if (allPassed) await _markExerciseAsDone();
    } catch (e) {
      debugLogs.add("❌ Eroare la Judge0: $e");
      setState(() => solutionChecked = true);
    } finally {
      setState(() => isRunningCode = false);
    }
  }

  // --------------------------------------------------------------------------
  // SECONDARY TABS & HELPERS
  // --------------------------------------------------------------------------

  Widget _buildResultBox() {
    if (!solutionChecked) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: solutionOk ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: solutionOk ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(solutionOk ? Icons.check_circle : Icons.error,
              color: solutionOk ? Colors.green : Colors.red, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              solutionOk
                  ? "Excelent! Răspunsul este corect."
                  : "Răspuns incorect. Mai încearcă o dată.",
              style: TextStyle(
                  color: solutionOk ? Colors.green.shade800 : Colors.red.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHints() {
    final hints = List<String>.from(exerciseData!["hints"] ?? []);
    if (hints.isEmpty)
      return const Text("Nu există indicații disponibile.",
          style: TextStyle(color: Colors.grey));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("INDICAȚII",
            style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 16),
        ...hints.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("💡", style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(h,
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade800, height: 1.5))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTests() {
    final tests = exerciseData?["tests"] as List<dynamic>? ?? [];
    if (tests.isEmpty)
      return const Text("Nu există teste disponibile.", style: TextStyle(color: Colors.grey));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TESTE DE EVALUARE",
            style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 16),
        ...tests.map((t) => _testBox(t["input"]?.toString() ?? "", t["output"]?.toString() ?? "")),
      ],
    );
  }

  Widget _buildOfficialSolution() {
    final sol = exerciseData!["official_solution"];
    if (sol == null)
      return const Text("Nu există soluție oficială.", style: TextStyle(color: Colors.grey));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SOLUȚIE OFICIALĂ (${(sol["language"] ?? "Necunoscut").toString().toUpperCase()})",
            style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
          child: SelectableText(sol["code"] ?? "",
              style: const TextStyle(
                  fontFamily: 'monospace', color: Colors.white, fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }

  Widget _section(String title, String? text) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12)),
        const SizedBox(height: 8),
        Text(text ?? "",
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
    ),
  );

  Widget _sectionList(String title, List<String> items) =>
      _section(title, items.isNotEmpty ? items.join("\n• ") : "Nu sunt disponibile.");

  Widget _exampleSection() {
    final example = exerciseData!["examples"];
    if (example == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EXEMPLU",
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12)),
        const SizedBox(height: 12),
        _testBox(example["input"]?.toString() ?? "", example["output"]?.toString() ?? ""),
      ],
    );
  }

  Widget _testBox(String input, String output) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("INPUT",
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(input,
                    style:
                    const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ),
        Container(width: 1, height: 60, color: Colors.grey.shade200),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OUTPUT",
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(output,
                    style:
                    const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}