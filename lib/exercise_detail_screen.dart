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

// ----------------------------------------------------
// C++ SYNTAX HIGHLIGHTING CONTROLLER
// ----------------------------------------------------
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
      r'(//[^\n]*)' // 1: Comments
      r'|("(\\"|[^"])*")' // 2: Strings
      r'|(#[a-zA-Z]+)' // 4: Preprocessor
      r'|(\b(int|long|float|double|char|bool|void|string|vector|set|map|pair|stack|queue|struct|class)\b)' // 5: Types
      r'|(\b(cin|cout|endl|return|if|else|while|for|break|continue|switch|case|default|using|namespace|std|main)\b)' // 7: Keywords
      r'|(\b\d+\b)' // 9: Numbers
      r'|([{}()\[\]])' // 10: Brackets
      r'|([+\-*/%=<>!&|]+)', // 11: Operators
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

// ----------------------------------------------------
// RETRO BUTTON
// ----------------------------------------------------
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
                    width: 20,
                    height: 20,
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

// ----------------------------------------------------
// EXERCISE DETAIL SCREEN
// ----------------------------------------------------
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

  // Undo / Redo Stacks
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

  // ----------------------------------------------------
  // SMART KEYBOARD HANDLER (TAB, UNINDENT, '}', ENTER, CTRL+Z/Y)
  // ----------------------------------------------------
  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlOrCmd = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      // 1. Undo: Ctrl + Z
      if (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyZ && !isShift) {
        _performUndo();
        return KeyEventResult.handled;
      }

      // 2. Redo: Ctrl + Y sau Ctrl + Shift + Z
      if ((isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyY) ||
          (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyZ && isShift)) {
        _performRedo();
        return KeyEventResult.handled;
      }

      // 3. Tab Key: Inserează 4 spații uniforme în loc să schimbe focusul
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

      // 4. Smart Backspace: Unindent pe nivel de tab (4 spații) la începutul liniei
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        final text = _codeController.text;
        final selection = _codeController.selection;
        if (selection.isCollapsed && selection.baseOffset > 0) {
          final pos = selection.baseOffset;
          final lastNewline = text.lastIndexOf('\n', pos - 1);
          final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
          final beforeCursor = text.substring(lineStart, pos);

          if (beforeCursor.isNotEmpty && RegExp(r'^[ ]+$').hasMatch(beforeCursor)) {
            int spacesToDelete = beforeCursor.length % 4;
            if (spacesToDelete == 0) spacesToDelete = 4;
            spacesToDelete = spacesToDelete.clamp(1, beforeCursor.length);

            final newText = text.replaceRange(pos - spacesToDelete, pos, '');
            _codeController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: pos - spacesToDelete),
            );
            return KeyEventResult.handled;
          }
        }
      }

      // 5. Smart Closing Brace '}': Dedent automat cu 4 spații pentru aliniere
      if (event.character == '}' || event.logicalKey == LogicalKeyboardKey.braceRight) {
        final text = _codeController.text;
        final selection = _codeController.selection;
        if (selection.isCollapsed && selection.baseOffset >= 0) {
          final pos = selection.baseOffset;
          final lastNewline = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
          final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
          final currentLine = text.substring(lineStart, pos);

          if (currentLine.isNotEmpty && RegExp(r'^[ ]+$').hasMatch(currentLine) && currentLine.length >= 4) {
            final newText = text.replaceRange(lineStart, pos, currentLine.substring(4) + "}");
            final newPos = lineStart + currentLine.length - 4 + 1;
            _codeController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newPos),
            );
            return KeyEventResult.handled;
          }
        }
      }

      // 6. Smart Enter: Auto-Indentation identică cu linia anterioară
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
                Icon(Icons.lock, color: AppColors.ink, size: 24),
                const SizedBox(width: 10),
                Text("LOGIN REQUIRED", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 16)),
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
              "${widget.subject.toUpperCase()} • CLASA ${widget.grade} • #${widget.id}",
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 15),
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
              // STANDARD SPLIT VIEW
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 920;

                      return Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: SingleChildScrollView(child: _buildContentPanel())),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 6, child: SingleChildScrollView(child: _buildInteractionPanel())),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildContentPanel(),
                                    const SizedBox(height: 24),
                                    _buildInteractionPanel(),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),

              // ANIMATED FULL SCREEN FOR PROBLEM
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                top: isFullScreenProblem ? 0 : MediaQuery.of(context).size.height,
                bottom: isFullScreenProblem ? 0 : -MediaQuery.of(context).size.height,
                left: 0,
                right: 0,
                child: Container(
                  color: AppColors.bg,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.border, width: 3),
                          boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6))],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  color: AppColors.sunset,
                                  child: const Text("PROBLEM FOCUS MODE",
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                ),
                                const Spacer(),
                                RetroButton(
                                  text: "EXIT FOCUS",
                                  icon: Icons.fullscreen_exit,
                                  bgColor: AppColors.ink,
                                  textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                  onPressed: () => setState(() => isFullScreenProblem = false),
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(child: SingleChildScrollView(child: _buildEnuntContent())),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ANIMATED FULL SCREEN FOR CODE EDITOR
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                top: isFullScreenCode ? 0 : MediaQuery.of(context).size.height,
                bottom: isFullScreenCode ? 0 : -MediaQuery.of(context).size.height,
                left: 0,
                right: 0,
                child: Container(
                  color: AppColors.bg,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Task Sidebar
                      Container(
                        width: 380,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.border, width: 2.5),
                          boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("QUEST BRIEF", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.sunset)),
                                  Text("#${widget.id}", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                exerciseData!["title"]?.toUpperCase() ?? "QUEST",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                exerciseData!["description"] ?? "",
                                style: TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5, fontWeight: FontWeight.w600),
                              ),
                              if (exerciseData!["input"] != null) ...[
                                const SizedBox(height: 16),
                                _buildCodeSpecBlock("INPUT FORMAT", exerciseData!["input"]),
                                const SizedBox(height: 10),
                                _buildCodeSpecBlock("OUTPUT FORMAT", exerciseData!["output"]),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Extended Code Workspace
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cloud,
                            border: Border.all(color: AppColors.border, width: 2.5),
                            boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _buildIdeHeader(isFullScreen: true),
                              const SizedBox(height: 10),
                              _buildCodeQuickActions(),
                              const SizedBox(height: 10),
                              Expanded(child: _buildIdeEditor()),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: RetroButton(
                                      text: "COMPILE & RUN TESTS",
                                      icon: Icons.play_arrow,
                                      isLoading: isRunningCode,
                                      bgColor: AppColors.forest,
                                      onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  RetroButton(
                                    text: "EXIT FULLSCREEN",
                                    icon: Icons.fullscreen_exit,
                                    bgColor: AppColors.ink,
                                    textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                    onPressed: () => setState(() => isFullScreenCode = false),
                                  ),
                                ],
                              ),
                              if (testResults.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                SizedBox(height: 130, child: SingleChildScrollView(child: _buildTestCasesConsole())),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildTab("enunt", "PROBLEM"),
            const SizedBox(width: 6),
            _buildTab("solutie", "SOLUTION"),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => isFullScreenProblem = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fullscreen, size: 14, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text("FOCUS BRIEF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ],
                ),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
          ),
          padding: const EdgeInsets.all(26),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isSelected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
            letterSpacing: 1.0,
            decoration: isSelected ? TextDecoration.none : TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildEnuntContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseData!["title"]?.toUpperCase() ?? "UNTITLED QUEST",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2),
        ),
        const SizedBox(height: 20),
        Text(
          "DESCRIPTION",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.sunset, letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        Text(
          exerciseData!["description"] ?? "Fără descriere disponibilă.",
          style: TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.6),
        ),
        if (exerciseData!["hint"] != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sky.withOpacity(0.15),
              border: Border.all(color: AppColors.sky, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.ink, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exerciseData!["hint"],
                    style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
        if (exerciseData!["tip_exercitiu"] == "cod" || exerciseData!["input"] != null) ...[
          const SizedBox(height: 24),
          Container(height: 2, color: AppColors.border),
          const SizedBox(height: 18),
          _buildCodeSpecBlock("INPUT FORMAT", exerciseData!["input"] ?? "-"),
          const SizedBox(height: 12),
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
        Text("MASTER'S SOLUTION", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 16),
        if (offSol != null && offSol["code"] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B242B),
              border: Border.all(color: AppColors.border, width: 2.5),
            ),
            child: Text(
              offSol["code"],
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF55EFC4),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          )
        else
          Text(
            "Acest exercițiu nu are o rezolvare oficială încărcată.",
            style: TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildCodeSpecBlock(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.sky, letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 1.5)),
          child: Text(content, style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildInteractionPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, size: 22, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                "TERMINAL & IDE",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.2),
              ),
              const Spacer(),
              FutureBuilder<bool>(
                future: _isExerciseDone(),
                builder: (context, snapshot) {
                  if (snapshot.data == true || solutionOk) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: AppColors.forest,
                      child: const Text(
                        "CLEARED",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 11),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          if (exerciseData!["tip_exercitiu"] == "grila")
            _buildGrilaSection()
          else if (exerciseData!["tip_exercitiu"] == "text" || exerciseData!["raspuns_corect"] != null)
            _buildTextAnswerSection()
          else
            _buildCodeSection(),
        ],
      ),
    );
  }

  Widget _buildGrilaSection() {
    List<dynamic> variante = exerciseData!["variante"] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...variante.map((varianta) {
          final isSelected = _selectedGrilaOption == varianta;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                _checkAuthAndExecute(() {
                  setState(() => _selectedGrilaOption = varianta);
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sky : AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.ink, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        varianta,
                        style: TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
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

  Widget _buildTextAnswerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _answerController,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: "Introdu valoarea...",
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
          ),
        ),
        const SizedBox(height: 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppColors.ink,
          child: Text(
            "C++20 (GCC)",
            style: TextStyle(
              color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text("LN $line, COL $col", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.ink)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => isFullScreenCode = !isFullScreenCode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isFullScreen ? AppColors.sunset : AppColors.ink,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 14, color: isFullScreen ? Colors.white : (AppColors.isDark ? const Color(0xFF10161A) : Colors.white)),
                const SizedBox(width: 4),
                Text(
                  isFullScreen ? "EXIT" : "FOCUS MODE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isFullScreen ? Colors.white : (AppColors.isDark ? const Color(0xFF10161A) : Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          _snippetButton("for loop", () => _insertSnippet("for (int i = 0; i < n; i++) {\n    ", "\n}", 28)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: isDanger ? AppColors.sunset : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isDanger ? AppColors.sunset : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildIdeEditor() {
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;
    final currentLine = _getCurrentLine();

    const double fontSz = 14.5;
    const double lineH = 1.5;
    const strut = StrutStyle(
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
          // Gutter Line Numbers
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 14),
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
                  padding: const EdgeInsets.only(right: 6),
                  alignment: Alignment.centerRight,
                  child: Text(
                    isCurrent ? "▶$lineNum" : "$lineNum",
                    strutStyle: strut,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isCurrent ? const Color(0xFF55EFC4) : const Color(0xFF636E72),
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
          ),

          // Code Text Area with Highlight Selection & Smart Keyboard Handlers
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
                  cursorWidth: 3,
                  strutStyle: strut,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: fontSz,
                    height: lineH,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdeHeader(isFullScreen: false),
        const SizedBox(height: 8),
        _buildCodeQuickActions(),
        const SizedBox(height: 8),
        SizedBox(height: 320, child: _buildIdeEditor()),
        const SizedBox(height: 16),
        RetroButton(
          text: "COMPILE & RUN",
          icon: Icons.play_arrow,
          isFullWidth: true,
          isLoading: isRunningCode,
          bgColor: AppColors.forest,
          onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
        ),
        if (testResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTestCasesConsole(),
        ],
        _buildResultBox(),
      ],
    );
  }

  Widget _buildTestCasesConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B242B),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TEST RESULTS & CONSOLE",
            style: TextStyle(color: AppColors.cloud, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          ...testResults.map((t) {
            final passed = t["passed"] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131A1F),
                border: Border.all(color: passed ? AppColors.forest : AppColors.sunset, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(passed ? Icons.check_circle : Icons.cancel, size: 16, color: passed ? AppColors.forest : AppColors.sunset),
                      const SizedBox(width: 6),
                      Text(
                        "TEST ${t['index']}: ${passed ? 'PASSED (OK)' : 'FAILED'}",
                        style: TextStyle(
                          color: passed ? AppColors.forest : AppColors.sunset,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (!passed) ...[
                    const SizedBox(height: 6),
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
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: solutionOk ? AppColors.forest : AppColors.sunset,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(4, 4))],
      ),
      child: Row(
        children: [
          Icon(solutionOk ? Icons.check_circle : Icons.error, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              solutionOk ? "QUEST CLEARED! +50 EXP EARNED." : "TESTS FAILED. INSPECT CONSOLE.",
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}