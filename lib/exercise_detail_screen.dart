import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
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
    _loadExerciseDetails();
  }

  Future<void> _loadExerciseDetails() async {
    try {
      final String response = await rootBundle.loadString('assets/data/exercise_details.json');
      final data = json.decode(response);

      if (data[widget.subject] != null &&
          data[widget.subject][widget.grade] != null &&
          data[widget.subject][widget.grade][widget.id] != null) {
        
        setState(() {
          exerciseData = data[widget.subject][widget.grade][widget.id];
        });
        return;
      }
    } catch (e) {
      debugPrint("Eroare JSON: $e");
    }

    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('exercises')
          .doc(widget.id)
          .get();
          
      if (docSnap.exists) {
        setState(() => exerciseData = docSnap.data());
        return;
      }
    } catch (e) {
      debugPrint("Eroare Firestore: $e");
    }
    
    setState(() => exerciseData = {});
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
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.ink, width: 3)),
            title: const Row(
              children: [
                Icon(Icons.lock, color: AppColors.ink, size: 28),
                SizedBox(width: 10),
                Text("LOGIN REQUIRED",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
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
          body: Center(child: CircularProgressIndicator(color: AppColors.sunset)));
    }

    if (exerciseData!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          iconTheme: const IconThemeData(color: AppColors.ink),
          elevation: 0,
        ),
        body: const Center(
          child: Text("QUEST NOT FOUND.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.subject.toUpperCase(),
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildContentPanel()),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: _buildInteractionPanel()),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildContentPanel(),
                            const SizedBox(height: 32),
                            _buildInteractionPanel(),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildTab("enunt", "PROBLEM"),
            const SizedBox(width: 8),
            _buildTab("solutie", "SOLUTION"),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(6, 6))],
          ),
          padding: const EdgeInsets.all(40),
          child: selectedTab == "enunt" ? _buildEnuntContent() : _buildSolutieContent(),
        ),
      ],
    );
  }

  Widget _buildTab(String tabKey, String label) {
    final isSelected = selectedTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mustard : AppColors.cloud,
          border: const Border(
            top: BorderSide(color: AppColors.ink, width: 3),
            left: BorderSide(color: AppColors.ink, width: 3),
            right: BorderSide(color: AppColors.ink, width: 3),
            bottom: BorderSide(color: Colors.transparent, width: 0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: 1.5,
              decoration: isSelected ? TextDecoration.none : TextDecoration.underline),
        ),
      ),
    );
  }

  Widget _buildEnuntContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exerciseData!["title"]?.toUpperCase() ?? "UNTITLED QUEST",
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2)),
        const SizedBox(height: 32),
        _buildSectionTitle("DESCRIPTION"),
        Text(exerciseData!["description"] ?? "Fără descriere.",
            style: const TextStyle(
                fontSize: 20, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.6)),
        
        if (exerciseData!["hint"] != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sky.withOpacity(0.2),
              border: Border.all(color: AppColors.sky, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: AppColors.sky, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    exerciseData!["hint"],
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],

        if (exerciseData!["tip_exercitiu"] == "cod" || exerciseData!["input"] != null) ...[
          const SizedBox(height: 48),
          Container(height: 3, color: AppColors.ink),
          const SizedBox(height: 32),
          _buildCodeSpecBlock("INPUT FORMAT", exerciseData!["input"] ?? "-"),
          const SizedBox(height: 24),
          _buildCodeSpecBlock("OUTPUT FORMAT", exerciseData!["output"] ?? "-"),
        ],
      ],
    );
  }

  Widget _buildSolutieContent() {
    final offSol = exerciseData!["official_solution"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MASTER'S SOLUTION",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 32),
        if (offSol != null && offSol["code"] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.ink,
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: Text(offSol["code"],
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.sky,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.5)),
          )
        else
          const Text("Acest exercițiu nu are o soluție oficială disponibilă.",
              style: TextStyle(fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.sunset,
              letterSpacing: 2.0)),
    );
  }

  Widget _buildCodeSpecBlock(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.sky,
                letterSpacing: 2.0)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.ink, width: 2)),
          child: Text(content,
              style: const TextStyle(fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildInteractionPanel() {
    return RetroBlock(
      bgColor: AppColors.cloud,
      padding: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videogame_asset, size: 36, color: AppColors.ink),
              const SizedBox(width: 16),
              const Text("TERMINAL",
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 2.0)),
              const Spacer(),
              FutureBuilder<bool>(
                future: _isExerciseDone(),
                builder: (context, snapshot) {
                  if (snapshot.data == true || solutionOk) {
                    return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: AppColors.forest,
                        child: const Text("CLEARED",
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)));
                  }
                  return const SizedBox();
                },
              )
            ],
          ),
          if (exerciseData!["tip_exercitiu"] == "grila")
            _buildGrilaSection()
          else if (exerciseData!["tip_exercitiu"] == "text" || exerciseData!["raspuns_corect"] != null)
            _buildTextAnswerSection()
          else
            _uploadSolutionSectionForCode(),
        ],
      ),
    );
  }

  Widget _buildGrilaSection() {
    List<dynamic> variante = exerciseData!["variante"] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 3, color: AppColors.ink),
        const SizedBox(height: 32),
        const Text("SELECT CORRECT OPTION",
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 16)),
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
                    ]),
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
          onPressed: _selectedGrilaOption == null ? () {} : () => _checkAuthAndExecute(_checkSimpleAnswer),
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
                color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
          decoration: const InputDecoration(
            hintText: "Enter value...",
            hintStyle: TextStyle(color: Colors.black38),
            filled: true,
            fillColor: AppColors.cloud,
            contentPadding: EdgeInsets.all(24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink, width: 3)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink, width: 3)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 3)),
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
    final raspunsCorect = exerciseData!["raspuns_corect"]?.toString().trim().toLowerCase();
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
                color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 16)),
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
                fontFamily: 'monospace',
                color: AppColors.sky,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.5),
            decoration: const InputDecoration(
              hintText: "// Write code here...\n#include <iostream>\nusing namespace std;\n\nint main() {\n  return 0;\n}",
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
          tests.add({"input": t["input"]?.toString() ?? "", "output": t["output"]?.toString() ?? ""});
        }
      }

      bool allPassed = true;
      for (int i = 0; i < tests.length; i++) {
        final test = tests[i];
        final inputData = test["input"] ?? "";
        final expectedOutput = test["output"] ?? "";

        final body = jsonEncode({"language_id": 52, "source_code": code, "stdin": inputData});
        final uri = Uri.parse("https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true");
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
          debugLogs.add("  GOT: $normOutput\n");
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
          Icon(solutionOk ? Icons.check_circle : Icons.error, color: Colors.white, size: 36),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              solutionOk ? "QUEST CLEARED! WELL DONE." : "INCORRECT. TRY AGAIN.",
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}