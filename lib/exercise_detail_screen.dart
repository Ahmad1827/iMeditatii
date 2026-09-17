import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

class CppSyntaxController extends TextEditingController {
  final TextStyle defaultStyle = const TextStyle(
    fontFamily: 'monospace',
    color: Color(0xFFECEFF4),
    fontSize: 14.5,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  CppSyntaxController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final textContent = text;

    final pattern = RegExp(
      r'(//[^\n]*)'
      r'|("(\\"|[^"])*")'
      r'|(#[a-zA-Z]+)'
      r'|(\b(int|long|float|double|char|bool|void|string|vector|set|map|pair|stack|queue|struct|class)\b)'
      r'|(\b(cin|cout|endl|return|if|else|while|for|break|continue|switch|case|default|using|namespace|std|main)\b)'
      r'|(\b\d+\b)'
      r'|([{}()\[\]])'
      r'|([+\-*/%=<>!&|]+)',
    );

    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(textContent)) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(
          text: textContent.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      final matchText = match.group(0)!;
      TextStyle matchStyle = defaultStyle;

      if (match.group(1) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFF7F8C8D), fontStyle: FontStyle.italic);
      } else if (match.group(2) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFFF9CA24));
      } else if (match.group(4) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFFFF7675), fontWeight: FontWeight.bold);
      } else if (match.group(5) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFF55EFC4), fontWeight: FontWeight.bold);
      } else if (match.group(7) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFF74B9FF), fontWeight: FontWeight.bold);
      } else if (match.group(9) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFFFAB1A0));
      } else if (match.group(10) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFFFDCB6E), fontWeight: FontWeight.w900);
      } else if (match.group(11) != null) {
        matchStyle = defaultStyle.copyWith(color: const Color(0xFFFF7675));
      }

      children.add(TextSpan(text: matchText, style: matchStyle));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < textContent.length) {
      children.add(TextSpan(
        text: textContent.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return TextSpan(style: style, children: children);
  }
}

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.bgColor ?? AppColors.sunset;
    final effectiveText = widget.textColor ?? Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => setState(() => isPressed = true),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                setState(() => isPressed = false);
                widget.onPressed();
              },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.isFullWidth ? double.infinity : null,
          transform: Matrix4.translationValues(
            isPressed ? 2.5 : (isHovered ? -1.5 : 0.0),
            isPressed ? 2.5 : (isHovered ? -1.5 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isLoading ? Colors.grey : effectiveBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: effectiveText),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: effectiveText,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
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
  final CppSyntaxController _codeController = CppSyntaxController();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  bool _isUndoingOrRedoing = false;

  List<Map<String, dynamic>> testResults = [];
  bool solutionChecked = false;
  bool solutionOk = false;
  bool isRunningCode = false;

  bool isFullScreenCode = false;
  bool isFullScreenProblem = false;
  String? _selectedGrilaOption;

  final String defaultCppBoilerplate =
      "#include <iostream>\nusing namespace std;\n\nint main() {\n    // Scrie codul aici\n    \n    return 0;\n}";

  @override
  void initState() {
    super.initState();
    _codeController.text = defaultCppBoilerplate;
    _recordHistorySnapshot(_codeController.value);

    _codeController.addListener(_onCodeChanged);
    _loadExerciseDetails();
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _answerController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (!_isUndoingOrRedoing) {
      _recordHistorySnapshot(_codeController.value);
    }
    if (mounted) setState(() {});
  }

  void _recordHistorySnapshot(TextEditingValue value) {
    if (_undoStack.isNotEmpty && _undoStack.last.text == value.text) {
      return;
    }
    _undoStack.add(value);
    if (_undoStack.length > 150) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _performUndo() {
    if (_undoStack.length > 1) {
      _isUndoingOrRedoing = true;
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      final previous = _undoStack.last;
      _codeController.value = previous;
      _isUndoingOrRedoing = false;
      setState(() {});
    }
  }

  void _performRedo() {
    if (_redoStack.isNotEmpty) {
      _isUndoingOrRedoing = true;
      final next = _redoStack.removeLast();
      _undoStack.add(next);
      _codeController.value = next;
      _isUndoingOrRedoing = false;
      setState(() {});
    }
  }

  int _getCurrentLine() {
    final pos = _codeController.selection.baseOffset;
    if (pos < 0 || pos > _codeController.text.length) return 1;
    return '\n'.allMatches(_codeController.text.substring(0, pos)).length + 1;
  }

  int _getCurrentCol() {
    final pos = _codeController.selection.baseOffset;
    if (pos < 0 || pos > _codeController.text.length) return 1;
    final lastNewline = _codeController.text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
    return lastNewline == -1 ? pos + 1 : pos - lastNewline;
  }

  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlOrCmd = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyZ && !isShift) {
        _performUndo();
        return KeyEventResult.handled;
      }

      if ((isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyY) ||
          (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyZ && isShift)) {
        _performRedo();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.tab) {
        final text = _codeController.text;
        final selection = _codeController.selection;
        final start = selection.start < 0 ? text.length : selection.start;
        final end = selection.end < 0 ? text.length : selection.end;
        const tabSpaces = "    ";

        final newText = text.replaceRange(start, end, tabSpaces);
        _codeController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + tabSpaces.length),
        );
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final text = _codeController.text;
        final selection = _codeController.selection;
        if (selection.isCollapsed && selection.baseOffset >= 0) {
          final pos = selection.baseOffset;
          final lastNewline = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
          final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
          final currentLine = text.substring(lineStart, pos);

          final match = RegExp(r'^[ ]*').firstMatch(currentLine);
          String indent = match != null ? match.group(0)! : "";

          if (currentLine.trimRight().endsWith('{')) {
            indent += "    ";
          }

          final insertion = "\n$indent";
          final newText = text.replaceRange(pos, pos, insertion);
          _codeController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: pos + insertion.length),
          );
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
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
      final docSnap = await FirebaseFirestore.instance.collection('exercises').doc(widget.id).get();
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

  void _insertSnippet(String prefix, String suffix, [int cursorOffset = 0]) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    final selectedText = text.substring(start, end);
    final replacement = "$prefix$selectedText$suffix";

    final newText = text.replaceRange(start, end, replacement);
    final newCursor = start + prefix.length + cursorOffset;

    _codeController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor.clamp(0, newText.length)),
    );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.border, width: 2.5),
            ),
            title: Row(
              children: [
                Icon(Icons.lock, color: AppColors.ink, size: 22),
                const SizedBox(width: 8),
                Text("LOGIN REQUIRED", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 15)),
              ],
            ),
            content: Text(
              "Trebuie să fii autentificat pentru a rula teste și a salva progresul.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            actions: [
              RetroButton(
                text: "CANCEL",
                bgColor: AppColors.cloud,
                textColor: AppColors.ink,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
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
    final isMobile = MediaQuery.of(context).size.width < 920;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        if (exerciseData == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
          );
        }

        if (exerciseData!.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(backgroundColor: AppColors.bg, iconTheme: IconThemeData(color: AppColors.ink), elevation: 0),
            body: Center(
              child: Text("QUEST NOT FOUND.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              "${widget.subject.toUpperCase()} • C${widget.grade} • #${widget.id}",
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: isMobile ? 14 : 16),
            ),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2.5),
              child: Container(color: AppColors.border, height: 2.5),
            ),
          ),
          body: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
                        child: !isMobile
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: SingleChildScrollView(child: _buildContentPanel(isMobile))),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 6, child: SingleChildScrollView(child: _buildInteractionPanel(isMobile))),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildContentPanel(isMobile),
                                    const SizedBox(height: 18),
                                    _buildInteractionPanel(isMobile),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentPanel(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildTab("enunt", "PROBLEM", isMobile),
            const SizedBox(width: 6),
            _buildTab("solutie", "SOLUTION", isMobile),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4))],
          ),
          padding: EdgeInsets.all(isMobile ? 18 : 28),
          child: selectedTab == "enunt" ? _buildEnuntContent(isMobile) : _buildSolutieContent(isMobile),
        ),
      ],
    );
  }

  Widget _buildTab(String tabKey, String label, bool isMobile) {
    final isSelected = selectedTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = tabKey),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mustard : AppColors.cloud,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 2.5),
            left: BorderSide(color: AppColors.border, width: 2.5),
            right: BorderSide(color: AppColors.border, width: 2.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w900,
            color: isSelected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
            letterSpacing: 1.0,
            decoration: isSelected ? TextDecoration.none : TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildEnuntContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseData!["title"]?.toUpperCase() ?? "UNTITLED QUEST",
          style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2),
        ),
        SizedBox(height: isMobile ? 14 : 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: AppColors.sunset,
          child: const Text(
            "DESCRIPTION",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          exerciseData!["description"] ?? "Fără descriere disponibilă.",
          style: TextStyle(
            fontSize: isMobile ? 15 : 18,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            height: 1.55,
            letterSpacing: 0.2,
          ),
        ),
        if (exerciseData!["hint"] != null) ...[
          SizedBox(height: isMobile ? 16 : 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sky.withOpacity(0.15),
              border: Border.all(color: AppColors.sky, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: AppColors.ink, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exerciseData!["hint"],
                    style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.ink, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        ],
        if (exerciseData!["tip_exercitiu"] == "cod" || exerciseData!["input"] != null) ...[
          SizedBox(height: isMobile ? 18 : 28),
          Container(height: 2, color: AppColors.border),
          SizedBox(height: isMobile ? 14 : 20),
          _buildCodeSpecBlock("INPUT FORMAT", exerciseData!["input"] ?? "-", isMobile),
          const SizedBox(height: 12),
          _buildCodeSpecBlock("OUTPUT FORMAT", exerciseData!["output"] ?? "-", isMobile),
        ],
      ],
    );
  }

  Widget _buildSolutieContent(bool isMobile) {
    final offSol = exerciseData!["official_solution"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MASTER'S SOLUTION", style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 14),
        if (offSol != null && offSol["code"] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B242B),
              border: Border.all(color: AppColors.border, width: 2.5),
            ),
            child: Text(
              offSol["code"],
              style: TextStyle(
                fontFamily: 'monospace',
                color: const Color(0xFF55EFC4),
                fontSize: isMobile ? 13 : 15,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          )
        else
          Text(
            "Acest exercițiu nu are o rezolvare oficială încărcată.",
            style: TextStyle(fontSize: isMobile ? 14 : 16, color: AppColors.ink, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildCodeSpecBlock(String title, String content, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w900, color: AppColors.sky, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 10 : 14),
          decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 1.5)),
          child: Text(
            content,
            style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionPanel(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4))],
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                "TERMINAL & IDE",
                style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
              ),
              const Spacer(),
              FutureBuilder<bool>(
                future: _isExerciseDone(),
                builder: (context, snapshot) {
                  if (snapshot.data == true || solutionOk) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: AppColors.forest,
                      child: const Text(
                        "CLEARED",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              )
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (exerciseData!["tip_exercitiu"] == "grila")
            _buildGrilaSection(isMobile)
          else if (exerciseData!["tip_exercitiu"] == "text" || exerciseData!["raspuns_corect"] != null)
            _buildTextAnswerSection(isMobile)
          else
            _buildCodeSection(isMobile),
        ],
      ),
    );
  }

  Widget _buildGrilaSection(bool isMobile) {
    List<dynamic> variante = exerciseData!["variante"] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...variante.map((varianta) {
          final isSelected = _selectedGrilaOption == varianta;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                _checkAuthAndExecute(() {
                  setState(() => _selectedGrilaOption = varianta);
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sky : AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.ink, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        varianta,
                        style: TextStyle(fontSize: isMobile ? 14 : 16, color: AppColors.ink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 14),
        RetroButton(
          text: "VERIFY ANSWER",
          isFullWidth: true,
          bgColor: AppColors.ink,
          textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
          onPressed: _selectedGrilaOption == null ? () {} : () => _checkAuthAndExecute(_checkSimpleAnswer),
        ),
        _buildResultBox(),
      ],
    );
  }

  Widget _buildTextAnswerSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _answerController,
          style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.bold, color: AppColors.ink),
          cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
          decoration: InputDecoration(
            hintText: "Introdu valoarea...",
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
          ),
        ),
        const SizedBox(height: 14),
        RetroButton(
          text: "VERIFY ANSWER",
          isFullWidth: true,
          bgColor: AppColors.ink,
          textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
          onPressed: () => _checkAuthAndExecute(_checkSimpleAnswer),
        ),
        _buildResultBox(),
      ],
    );
  }

  Widget _buildIdeHeader({bool isFullScreen = false}) {
    final line = _getCurrentLine();
    final col = _getCurrentCol();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          color: AppColors.ink,
          child: Text(
            "C++20",
            style: TextStyle(
              color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text("L$line:C$col", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.ink)),
      ],
    );
  }

  Widget _buildCodeQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _snippetButton("UNDO", _performUndo),
          const SizedBox(width: 6),
          _snippetButton("REDO", _performRedo),
          const SizedBox(width: 6),
          _snippetButton("TAB", () => _insertSnippet("    ", "", 4)),
          const SizedBox(width: 6),
          _snippetButton("{ }", () => _insertSnippet("{\n    ", "\n}", 4)),
          const SizedBox(width: 6),
          _snippetButton("cin >>", () => _insertSnippet("cin >> ", ";", 7)),
          const SizedBox(width: 6),
          _snippetButton("cout <<", () => _insertSnippet("cout << ", " << \"\\n\";", 8)),
          const SizedBox(width: 6),
          _snippetButton("RESET", () => setState(() => _codeController.text = defaultCppBoilerplate), isDanger: true),
        ],
      ),
    );
  }

  Widget _snippetButton(String label, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: isDanger ? AppColors.sunset : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: isDanger ? AppColors.sunset : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildIdeEditor(bool isMobile) {
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;
    final currentLine = _getCurrentLine();

    final double fontSz = isMobile ? 13.0 : 14.5;
    const double lineH = 1.55;
    final strut = StrutStyle(
      fontFamily: 'monospace',
      fontSize: fontSz,
      height: lineH,
      forceStrutHeight: true,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B242B),
        border: Border.all(color: AppColors.border, width: 2.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 38 : 48,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A1F),
              border: Border(right: BorderSide(color: Color(0xFF2C3E50), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(lineCount, (i) {
                final lineNum = i + 1;
                final isCurrent = lineNum == currentLine;

                return Container(
                  height: fontSz * lineH,
                  color: isCurrent ? const Color(0xFF2C3E50) : Colors.transparent,
                  padding: const EdgeInsets.only(right: 4),
                  alignment: Alignment.centerRight,
                  child: Text(
                    isCurrent ? "▶$lineNum" : "$lineNum",
                    strutStyle: strut,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isCurrent ? const Color(0xFF55EFC4) : const Color(0xFF636E72),
                      fontSize: isMobile ? 10.5 : 12,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Focus(
              focusNode: _editorFocusNode,
              onKeyEvent: _handleEditorKey,
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionColor: Color(0x6674B9FF),
                    cursorColor: Color(0xFF55EFC4),
                    selectionHandleColor: Color(0xFF74B9FF),
                  ),
                ),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  cursorColor: const Color(0xFF55EFC4),
                  cursorWidth: 2.5,
                  strutStyle: strut,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: fontSz,
                    height: lineH,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdeHeader(isFullScreen: false),
        const SizedBox(height: 6),
        _buildCodeQuickActions(),
        const SizedBox(height: 8),
        SizedBox(height: isMobile ? 260 : 320, child: _buildIdeEditor(isMobile)),
        const SizedBox(height: 14),
        RetroButton(
          text: "COMPILE & RUN",
          icon: Icons.play_arrow,
          isFullWidth: true,
          isLoading: isRunningCode,
          bgColor: AppColors.forest,
          onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
        ),
        if (testResults.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildTestCasesConsole(),
        ],
        _buildResultBox(),
      ],
    );
  }

  Widget _buildTestCasesConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B242B),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TEST RESULTS & CONSOLE",
            style: TextStyle(color: AppColors.cloud, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          ...testResults.map((t) {
            final passed = t["passed"] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF131A1F),
                border: Border.all(color: passed ? AppColors.forest : AppColors.sunset, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(passed ? Icons.check_circle : Icons.cancel, size: 14, color: passed ? AppColors.forest : AppColors.sunset),
                      const SizedBox(width: 6),
                      Text(
                        "TEST ${t['index']}: ${passed ? 'PASSED (OK)' : 'FAILED'}",
                        style: TextStyle(
                          color: passed ? AppColors.forest : AppColors.sunset,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (!passed) ...[
                    const SizedBox(height: 4),
                    Text("EXPECTED: ${t['expected']}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                    Text("OUTPUT:   ${t['got']}", style: TextStyle(color: AppColors.sunset, fontSize: 11, fontFamily: 'monospace')),
                  ]
                ],
              ),
            );
          }),
        ],
      ),
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

  Future<void> _runJudge0Checker() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      solutionChecked = false;
      solutionOk = false;
      testResults.clear();
      isRunningCode = true;
    });

    try {
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

      for (int i = 0; i < tests.length; i++) {
        final test = tests[i];
        final inputData = test["input"] ?? "";
        final expectedOutput = test["output"] ?? "";

        final body = jsonEncode({
          "language_id": 52,
          "source_code": code,
          "stdin": inputData,
        });

        final uri = Uri.parse("https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true");
        final response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
            "X-RapidAPI-Key": "YOUR_API_KEY",
            "X-RapidAPI-Host": "judge0-ce.p.rapidapi.com",
          },
          body: body,
        );

        final result = jsonDecode(response.body);
        final output = (result["stdout"] ?? "").toString();

        String normalize(String s) => s.replaceAll('\r', '').trim();
        final normOutput = normalize(output);
        final normExpected = normalize(expectedOutput);

        final isTestOk = (normOutput == normExpected);
        if (!isTestOk) allPassed = false;

        testResults.add({
          "index": i + 1,
          "passed": isTestOk,
          "expected": normExpected,
          "got": normOutput,
        });

        setState(() {});
      }

      setState(() {
        solutionChecked = true;
        solutionOk = allPassed;
      });

      if (allPassed) await _markExerciseAsDone();
    } catch (e) {
      testResults.add({
        "index": 1,
        "passed": false,
        "expected": "No runtime errors",
        "got": "$e",
      });
      setState(() => solutionChecked = true);
    } finally {
      setState(() => isRunningCode = false);
    }
  }

  Widget _buildResultBox() {
    if (!solutionChecked) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: solutionOk ? AppColors.forest : AppColors.sunset,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
      ),
      child: Row(
        children: [
          Icon(solutionOk ? Icons.check_circle : Icons.error, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              solutionOk ? "QUEST CLEARED! +50 EXP EARNED." : "TESTS FAILED. INSPECT CONSOLE.",
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}