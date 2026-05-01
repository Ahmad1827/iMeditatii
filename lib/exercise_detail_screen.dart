import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor = Colors.white,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;
  final bool isFullWidth;
  final bool isLoading;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => setState(() => isPressed = true),
        onTapUp: widget.isLoading ? null : (_) {
          setState(() => isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isLoading ? Colors.grey : widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: widget.isLoading
              ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
          )
              : Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

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
            backgroundColor: AppColors.bg,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.ink, width: 3)),
            title: const Row(
              children: [
                Icon(Icons.lock, color: AppColors.ink, size: 28),
                SizedBox(width: 10),
                Text("LOGIN REQUIRED", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
              ],
            ),
            content: const Text(
              "You must authenticate to submit solutions and save progress.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            actionsPadding: const EdgeInsets.all(24),
            actions: [
              RetroButton(
                text: "CANCEL",
                bgColor: AppColors.cloud,
                textColor: AppColors.ink,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 16),
              RetroButton(
                text: "LOGIN",
                bgColor: AppColors.sunset,
                onPressed: () {
                  context.pop();
                  context.go('/login');
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exerciseData == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
      );
    }

    if (exerciseData!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text("ERROR", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.bg,
          iconTheme: const IconThemeData(color: AppColors.ink),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(color: AppColors.ink, height: 3)),
        ),
        body: const Center(child: Text("QUEST NOT FOUND.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink))),
      );
    }

    final tip = exerciseData!["tip_exercitiu"] ?? "cod";
    List<String> tabs = ["enunt"];
    if (tip == "cod") {
      tabs = ["enunt", "indicatii", "teste", "solutie"];
    } else if (exerciseData!["hints"] != null) {
      tabs.add("indicatii");
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'QUEST TERMINAL',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: AppColors.ink, height: 3.0),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRetroTabs(tabs),
                const SizedBox(height: 32),
                Expanded(
                  child: RetroBlock(
                    bgColor: Colors.white,
                    padding: 32,
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildTabContent(selectedTab),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroTabs(List<String> tabs) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Wrap(
        spacing: 8,
        children: tabs.map((tab) {
          final isActive = selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => selectedTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.ink : AppColors.cloud,
                border: Border.all(color: AppColors.ink, width: 3),
              ),
              child: Text(
                tab.toUpperCase(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.2,
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

  Widget _buildProblemStatement() {
    final tip = exerciseData!["tip_exercitiu"] ?? "cod";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _problemHeader(),
        const SizedBox(height: 40),
        const Text("QUEST OBJECTIVE",
            style: TextStyle(
                color: AppColors.sunset,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 16),
        Text(
          exerciseData!["description"] ?? "No description provided.",
          style: const TextStyle(
              fontSize: 22,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.4),
        ),
        const SizedBox(height: 48),
        if (tip == "cod") ...[
          if (exerciseData!["input"] != null)
            _section("Input Format", exerciseData!["input"]),
          if (exerciseData!["output"] != null)
            _section("Output Format", exerciseData!["output"]),
          if (exerciseData!["constraints"] != null)
            _sectionList("Constraints",
                List<String>.from(exerciseData!["constraints"])),
          _exampleSection(),
          const SizedBox(height: 48),
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
                  color: AppColors.sky,
                  border: Border.all(color: AppColors.ink, width: 2)),
              child: Text("LEVEL ${widget.grade}",
                  style: const TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                (exerciseData!["title"] ?? "Quest").toUpperCase(),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 1.0),
              ),
            ),
            if (isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.forest,
                    border: Border.all(color: AppColors.ink, width: 2)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("CLEARED",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16, letterSpacing: 1.2)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGrilaSection() {
    final List<String> variante = List<String>.from(exerciseData!["variante"] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 3, color: AppColors.ink),
        const SizedBox(height: 32),
        const Text("SELECT CORRECT OPTION",
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 24),
        ...variante.map((varianta) {
          final isSelected = _selectedGrilaOption == varianta;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                _checkAuthAndExecute(() {
                  setState(() => _selectedGrilaOption = varianta);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                    color: isSelected ? AppColors.sky : Colors.white,
                    border: Border.all(color: AppColors.ink, width: 3),
                    boxShadow: [
                      if (!isSelected) const BoxShadow(color: AppColors.ink, offset: Offset(4, 4))
                    ]
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: AppColors.ink,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        varianta,
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 32),
        RetroButton(
          text: "VERIFY ANSWER",
          isFullWidth: true,
          bgColor: AppColors.ink,
          onPressed: _selectedGrilaOption == null
              ? () {}
              : () => _checkAuthAndExecute(_checkSimpleAnswer),
        ),
        _buildResultBox(),
      ],
    );
  }

  Widget _buildTextAnswerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 3, color: AppColors.ink),
        const SizedBox(height: 32),
        const Text("YOUR SOLUTION",
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: "Enter value...",
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: AppColors.cloud,
            contentPadding: const EdgeInsets.all(24),
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink, width: 3)),
            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink, width: 3)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
          ),
        ),
        const SizedBox(height: 32),
        RetroButton(
          text: "VERIFY ANSWER",
          isFullWidth: true,
          bgColor: AppColors.ink,
          onPressed: () => _checkAuthAndExecute(_checkSimpleAnswer),
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

  Widget _uploadSolutionSectionForCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 3, color: AppColors.ink),
        const SizedBox(height: 32),
        const Text("CODE EDITOR (C++)",
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.ink,
            border: Border.all(color: AppColors.ink, width: 3),
          ),
          child: TextField(
            controller: _answerController,
            maxLines: 15,
            style: const TextStyle(
                fontFamily: 'monospace', color: AppColors.sky, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
            decoration: const InputDecoration(
              hintText:
              "// Write code here...\n#include <iostream>\nusing namespace std;\n\nint main() {\n    return 0;\n}",
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(24),
            ),
          ),
        ),
        const SizedBox(height: 32),
        RetroButton(
          text: "COMPILE & RUN",
          isFullWidth: true,
          isLoading: isRunningCode,
          bgColor: AppColors.forest,
          onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
        ),
        if (debugLogs.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
                color: AppColors.ink, border: Border.all(color: AppColors.ink, width: 3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CONSOLE OUTPUT",
                    style: TextStyle(
                        color: AppColors.cloud,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0)),
                const SizedBox(height: 16),
                ...debugLogs.map((log) => Text(log,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        color: log.contains("FAIL") || log.contains("ERROR")
                            ? AppColors.sunset
                            : AppColors.mustard,
                        fontWeight: FontWeight.bold,
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
          debugLogs.add("> TEST ${i + 1}: FAILED");
          debugLogs.add("  EXPECTED: $normExpected");
          debugLogs.add("  GOT:      $normOutput\n");
        } else {
          debugLogs.add("> TEST ${i + 1}: SUCCESS");
        }
        setState(() {});
      }

      setState(() {
        solutionChecked = true;
        solutionOk = allPassed;
      });
      if (allPassed) await _markExerciseAsDone();
    } catch (e) {
      debugLogs.add("> ERROR: $e");
      setState(() => solutionChecked = true);
    } finally {
      setState(() => isRunningCode = false);
    }
  }

  Widget _buildResultBox() {
    if (!solutionChecked) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: solutionOk ? AppColors.forest : AppColors.sunset,
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(6, 6))],
      ),
      child: Row(
        children: [
          Icon(solutionOk ? Icons.check_circle : Icons.error,
              color: Colors.white, size: 36),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              solutionOk
                  ? "QUEST CLEARED! WELL DONE."
                  : "INCORRECT. TRY AGAIN.",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHints() {
    final hints = List<String>.from(exerciseData!["hints"] ?? []);
    if (hints.isEmpty)
      return const Text("NO HINTS AVAILABLE.",
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("HINTS",
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 24),
        ...hints.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RetroBlock(
            bgColor: AppColors.mustard,
            padding: 16,
            shadowOffset: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: AppColors.ink),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(h,
                        style: const TextStyle(
                            fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.bold, height: 1.4))),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTests() {
    final tests = exerciseData?["tests"] as List<dynamic>? ?? [];
    if (tests.isEmpty)
      return const Text("NO TESTS AVAILABLE.", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EVALUATION TESTS",
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 24),
        ...tests.map((t) => _testBox(t["input"]?.toString() ?? "", t["output"]?.toString() ?? "")),
      ],
    );
  }

  Widget _buildOfficialSolution() {
    final sol = exerciseData!["official_solution"];
    if (sol == null)
      return const Text("NO OFFICIAL SOLUTION AVAILABLE.", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("OFFICIAL SOLUTION (${(sol["language"] ?? "UNKNOWN").toString().toUpperCase()})",
            style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColors.ink, border: Border.all(color: AppColors.ink, width: 3)),
          child: SelectableText(sol["code"] ?? "",
              style: const TextStyle(
                  fontFamily: 'monospace', color: AppColors.sky, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5)),
        ),
      ],
    );
  }

  Widget _section(String title, String? text) => Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 14)),
        const SizedBox(height: 12),
        RetroBlock(
          bgColor: AppColors.cloud,
          padding: 16,
          shadowOffset: 4,
          child: SizedBox(
            width: double.infinity,
            child: Text(text ?? "",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
          ),
        ),
      ],
    ),
  );

  Widget _sectionList(String title, List<String> items) =>
      _section(title, items.isNotEmpty ? items.join("\n• ") : "N/A");

  Widget _exampleSection() {
    final example = exerciseData!["examples"];
    if (example == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EXAMPLE",
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 14)),
        const SizedBox(height: 16),
        _testBox(example["input"]?.toString() ?? "", example["output"]?.toString() ?? ""),
      ],
    );
  }

  Widget _testBox(String input, String output) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.ink, width: 3)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("INPUT",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(input,
                    style:
                    const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
              ],
            ),
          ),
        ),
        Container(width: 3, color: AppColors.ink),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OUTPUT",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(output,
                    style:
                    const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}