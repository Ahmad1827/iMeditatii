import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. IMPORT NOU

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
  bool codePassed = false;
  bool subjectPassed = false;
  bool isRunningCode = false;

  @override
  void initState() {
    super.initState();
    _loadExerciseDetails();
  }

  Future<void> _loadExerciseDetails() async {
    final String response =
    await rootBundle.loadString('assets/data/exercise_details.json');
    final data = json.decode(response);

    final subjectData = data[widget.subject]?[widget.grade]?[widget.id];

    setState(() {
      exerciseData = subjectData;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (exerciseData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tabs = ["enunt", "indicatii", "teste", "solutie"];

    return Scaffold(
      backgroundColor: const Color(0xfff4f4f4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "iMeditatii",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: Center(
        child: Container(
          width: 950,
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(tabs.length, (index) {
                  final isActive = selectedTab == tabs[index];
                  return GestureDetector(
                    onTap: () => setState(() => selectedTab = tabs[index]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blueAccent : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Text(
                        tabs[index][0].toUpperCase() + tabs[index].substring(1),
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
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
  Future<void> _markExerciseAsDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${widget.grade}_${widget.id}";

    // Salvăm ca "true"
    await prefs.setBool(key, true);
  }

  Future<bool> _isExerciseDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${widget.grade}_${widget.id}";
    return prefs.getBool(key) ?? false;
  }
  Widget _buildProblemStatement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _problemHeader(),
        const SizedBox(height: 24),
        _sectionTitle("Cerința"),
        Text(
          exerciseData!["description"],
          style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.5),
        ),
        const SizedBox(height: 20),
        _section("Date de intrare", exerciseData!["input"]),
        _section("Date de ieșire", exerciseData!["output"]),
        _sectionList(
          "Restricții și precizări",
          List<String>.from(exerciseData!["constraints"] ?? []),
        ),
        _exampleSection(),
        const SizedBox(height: 30),
        _uploadSolutionSection(),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "#${widget.id}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                exerciseData!["title"],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isDone)
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ],
        );
      },
    );
  }

  Widget _buildHints() {
    final hints = List<String>.from(exerciseData!["hints"] ?? []);
    if (hints.isEmpty) return const Text("Nu există indicații disponibile.");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Indicații de rezolvare"),
        ...hints.map((h) => _sectionBody("• $h")).toList(),
      ],
    );
  }

  Widget _buildTests() {
    final tests = exerciseData?["tests"] as List<dynamic>? ?? [];
    if (tests.isEmpty) return const Text("Nu există teste disponibile.");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Teste de evaluare"),
        const SizedBox(height: 12),
        ...tests.map((t) => _testBox(
          t["input"]?.toString() ?? "",
          t["output"]?.toString() ?? "",
        )),
      ],
    );
  }

  Widget _buildOfficialSolution() {
    final sol = exerciseData!["official_solution"];
    if (sol == null) return const Text("Nu există soluție oficială.");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Soluție oficială (${sol["language"] ?? "necunoscut"})"),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            sol["code"] ?? "",
            style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _uploadSolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Încarcă soluția ta"),
        const SizedBox(height: 10),
        TextField(
          controller: _answerController,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: "Scrie codul sau algoritmul tău aici...",
            filled: true,
            fillColor: const Color(0xfffafafa),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: isRunningCode ? null : _runJudge0Checker,
            icon: const Icon(Icons.play_arrow),
            label: Text(isRunningCode ? "Se rulează..." : "Rulează checker"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // === Aici adaugi debug logs ===
        if (debugLogs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: debugLogs
                  .map((log) => Text(
                log,
                style: const TextStyle(
                    fontSize: 14, fontFamily: 'monospace'),
              ))
                  .toList(),
            ),
          ),

        if (solutionChecked)
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: solutionOk ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: solutionOk ? Colors.green : Colors.redAccent,
                ),
              ),
              child: Text(
                solutionOk
                    ? "✅ Soluția ta a trecut testele!"
                    : "❌ Soluția ta este incorectă. Încearcă din nou.",
                style: TextStyle(
                  color: solutionOk ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 6),
    child: Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    ),
  );

  Widget _section(String title, String? text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(text ?? ""),
      ],
    ),
  );

  Widget _sectionList(String title, List<String> items) => _section(
      title, items.isNotEmpty ? items.join("\n• ") : "Nu sunt disponibile.");

  Widget _sectionBody(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
  );

  Widget _exampleSection() {
    final example = exerciseData!["examples"];
    if (example == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Exemplu"),
        _testBox(example["input"]?.toString() ?? "",
            example["output"]?.toString() ?? ""),
      ],
    );
  }

  Widget _testBox(String input, String output) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xfff9f9f9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Input: $input",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Output așteptat: $output",
            style: const TextStyle(fontFamily: 'monospace')),
      ],
    ),
  );

  // ------------------- JUDGE0 CHECKER -------------------
  Future<void> _runJudge0Checker() async {
    // 2. VERIFICARE AUTENTIFICARE
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚨 Trebuie să fii autentificat pentru a trimite soluții! Te rugăm să te loghezi."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; // Oprește execuția funcției
    }

    final code = _answerController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduceți codul sursă înainte de a rula checker-ul.")),
      );
      return;
    }

    setState(() {
      solutionChecked = false; // afișăm rezultatul doar la final
      solutionOk = false;
      debugLogs.clear(); // resetăm logurile
      isRunningCode = true; // Setează loading state
    });

    try {
      // 🔹 Adunăm toate testele
      final List<Map<String, dynamic>> tests = [];

      if (exerciseData?["examples"] != null) {
        tests.add({
          "input": exerciseData!["examples"]["input"]?.toString() ?? "",
          "output": exerciseData!["examples"]["output"]?.toString() ?? "",
        });
      }

      if (exerciseData?["tests"] != null) {
        for (var t in exerciseData!["tests"]) {
          tests.add({
            "input": t["input"]?.toString() ?? "",
            "output": t["output"]?.toString() ?? "",
          });
        }
      }

      bool allPassed = true;

      for (var test in tests) {
        final inputData = test["input"] ?? "";
        final expectedOutput = test["output"] ?? "";

        // 🔹 Request către Judge0
        final body = jsonEncode({
          "language_id": 52, // C++ (GCC 9.2.0)
          "source_code": code,
          "stdin": inputData,
        });

        final uri = Uri.parse("https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true");
        final response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
            "X-RapidAPI-Key": "294fe520c5mshfbf92d785fe54bap19ee97jsn72feecf8b60c",
            "X-RapidAPI-Host": "judge0-ce.p.rapidapi.com",
          },
          body: body,
        );

        final result = jsonDecode(response.body);
        final output = (result["stdout"] ?? "").toString();

        // 🔹 Normalizare output (eliminăm whitespace și \r)
        String normalize(String s) => s.replaceAll('\r', '').trim();

        final normOutput = normalize(output);
        final normExpected = normalize(expectedOutput);

        if (normOutput != normExpected) {
          allPassed = false;
          debugLogs.add("=== TEST EȘUAT ===");
          debugLogs.add("Input: $inputData");
          debugLogs.add("Așteptat: [$expectedOutput]");
          debugLogs.add("Obținut: [$output]");
          debugLogs.add("==================");
        } else {
          debugLogs.add("✅ Test trecut: $inputData -> $normOutput");
        }

        setState(() {}); // pentru a actualiza logurile pe ecran imediat
      }

      setState(() {
        solutionChecked = true;
        solutionOk = allPassed;
      });
      if (allPassed) {
        await _markExerciseAsDone(); // marchează problema ca rezolvată
        // Nu mai afișăm SnackBar aici, deoarece rezultatul vizual este cel mai important
      }
    } catch (e) {
      debugLogs.add("❌ Eroare la Judge0: $e");
      setState(() => solutionChecked = true);
    } finally {
      setState(() {
        isRunningCode = false; // Oprește loading state
      });
    }
  }


  Future<String> _runCodeOnJudge0(String code, String input) async {
    const url = 'https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true';
    final languageId = 54; // 54 = C++ (poți face dropdown pentru alte limbaje)

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': '294fe520c5mshfbf92d785fe54bap19ee97jsn72feecf8b60c', // pune cheia ta RapidAPI
        'X-RapidAPI-Host': 'judge0-ce.p.rapidapi.com',
      },
      body: jsonEncode({
        "source_code": code,
        "language_id": languageId,
        "stdin": input,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['stdout'] ?? "";
    } else {
      return "";
    }
  }
}