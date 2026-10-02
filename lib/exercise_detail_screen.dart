import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'ui_components.dart';

// ----------------------------------------------------
// C++ SYNTAX HIGHLIGHTING CONTROLLER
// Font family/size come from the TextField style, so the
// editor follows the design system (and mobile sizes).
// ----------------------------------------------------
class CppSyntaxController extends TextEditingController {
  CppSyntaxController({super.text});

  static final RegExp _pattern = RegExp(
    r'(//[^\n]*)'
    r'|("(\\"|[^"])*")'
    r'|(#[a-zA-Z]+)'
    r'|(\b(int|long|float|double|char|bool|void|string|vector|set|map|pair|stack|queue|struct|class)\b)'
    r'|(\b(cin|cout|endl|return|if|else|while|for|break|continue|switch|case|default|using|namespace|std|main)\b)'
    r'|(\b\d+\b)'
    r'|([{}()\[\]])'
    r'|([+\-*/%=<>!&|]+)',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(color: AppStyle.codeText);
    final children = <TextSpan>[];
    var last = 0;

    for (final m in _pattern.allMatches(text)) {
      if (m.start > last) {
        children.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      children.add(TextSpan(text: m.group(0), style: _styleFor(m, base)));
      last = m.end;
    }
    if (last < text.length) {
      children.add(TextSpan(text: text.substring(last), style: base));
    }
    return TextSpan(style: base, children: children);
  }

  TextStyle _styleFor(RegExpMatch m, TextStyle base) {
    if (m.group(1) != null) return base.copyWith(color: const Color(0xFF7F8C8D), fontStyle: FontStyle.italic);
    if (m.group(2) != null) return base.copyWith(color: const Color(0xFFF9CA24));
    if (m.group(4) != null) return base.copyWith(color: const Color(0xFFFF7675), fontWeight: FontWeight.bold);
    if (m.group(5) != null) return base.copyWith(color: const Color(0xFF55EFC4), fontWeight: FontWeight.bold);
    if (m.group(7) != null) return base.copyWith(color: const Color(0xFF74B9FF), fontWeight: FontWeight.bold);
    if (m.group(9) != null) return base.copyWith(color: const Color(0xFFFAB1A0));
    if (m.group(10) != null) return base.copyWith(color: const Color(0xFFFDCB6E), fontWeight: FontWeight.w900);
    if (m.group(11) != null) return base.copyWith(color: const Color(0xFFFF7675));
    return base;
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

  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  bool _isUndoingOrRedoing = false;

  List<Map<String, dynamic>> testResults = [];
  bool solutionChecked = false;
  bool solutionOk = false;
  bool isRunningCode = false;
  bool _alreadyDone = false;

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
    _isExerciseDone().then((done) {
      if (mounted && done) setState(() => _alreadyDone = true);
    });
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _answerController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  /// "grila" | "text" | "cod"
  String get _kind {
    final t = exerciseData?["tip_exercitiu"];
    if (t == "grila") return "grila";
    if (t == "text" || exerciseData?["raspuns_corect"] != null) return "text";
    return "cod";
  }

  // ---------------------------------------------------------------- EDITOR LOGIC
  void _onCodeChanged() {
    if (!_isUndoingOrRedoing) {
      _recordHistorySnapshot(_codeController.value);
    }
    if (mounted) setState(() {});
  }

  void _recordHistorySnapshot(TextEditingValue value) {
    if (_undoStack.isNotEmpty && _undoStack.last.text == value.text) return;
    _undoStack.add(value);
    if (_undoStack.length > 150) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _performUndo() {
    if (_undoStack.length > 1) {
      _isUndoingOrRedoing = true;
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      _codeController.value = _undoStack.last;
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
          if (currentLine.trimRight().endsWith('{')) indent += "    ";

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

  // ---------------------------------------------------------------- DATA
  Future<void> _loadExerciseDetails() async {
    try {
      final String response = await rootBundle.loadString('assets/data/exercise_details.json');
      final data = json.decode(response);

      if (data[widget.subject] != null &&
          data[widget.subject][widget.grade] != null &&
          data[widget.subject][widget.grade][widget.id] != null) {
        if (!mounted) return;
        setState(() => exerciseData = data[widget.subject][widget.grade][widget.id]);
        return;
      }
    } catch (e) {
      debugPrint("Eroare JSON: $e");
    }

    try {
      final docSnap = await FirebaseFirestore.instance.collection('exercises').doc(widget.id).get();
      if (docSnap.exists) {
        if (!mounted) return;
        setState(() => exerciseData = docSnap.data());
        return;
      }
    } catch (e) {
      debugPrint("Eroare Firestore: $e");
    }

    if (mounted) setState(() => exerciseData = {});
  }

  Future<void> _markExerciseAsDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${widget.grade}_${widget.id}";
    await prefs.setBool(key, true);
    if (mounted) setState(() => _alreadyDone = true);
  }

  Future<bool> _isExerciseDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${widget.subject}_${widget.grade}_${widget.id}";
    return prefs.get(key) == true;
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
    if (FirebaseAuth.instance.currentUser != null) {
      action();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final s = AppStyle.of(dialogContext);
        return AlertDialog(
          backgroundColor: s.pick(AppColors.bg, AppColors.cardBg),
          shape: RoundedRectangleBorder(
            borderRadius: s.rCard,
            side: BorderSide(color: s.isClean ? s.line : AppColors.border, width: s.isClean ? 1 : 2.5),
          ),
          title: Row(
            children: [
              Icon(s.pick(Icons.lock, Icons.lock_outline), color: AppColors.ink, size: 22),
              const SizedBox(width: 8),
              Text(
                s.pick("LOGIN REQUIRED", "Autentificare necesară"),
                style: s.isClean ? s.heading(17) : TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 15),
              ),
            ],
          ),
          content: Text(
            s.pick(
              "Trebuie să fii autentificat pentru a rula teste și a salva progresul.",
              "Intră în cont ca să poți rula testele și să îți salvezi progresul.",
            ),
            style: s.body(14, retroWeight: FontWeight.bold),
          ),
          actions: [
            RetroButton(
              text: s.pick("CANCEL", "Renunță"),
              bgColor: AppColors.cloud,
              textColor: AppColors.ink,
              onPressed: () => dialogContext.pop(),
            ),
            const SizedBox(width: 8),
            RetroButton(
              text: s.pick("LOGIN", "Intră în cont"),
              bgColor: s.primaryFill(AppColors.sunset),
              textColor: s.primaryText(Colors.white),
              onPressed: () {
                dialogContext.pop();
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- BUILD
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 920;

    return StyleBuilder(
      builder: (context, s) {
        if (exerciseData == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: s.pick(AppColors.sunset, AppColors.sky))),
          );
        }

        if (exerciseData!.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(backgroundColor: AppColors.bg, iconTheme: IconThemeData(color: AppColors.ink), elevation: 0),
            body: Center(
              child: Text(s.pick("QUEST NOT FOUND.", "Problema nu a fost găsită."), style: s.heading(20)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: _buildAppBar(s, isMobile),
          body: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
                    child: !isMobile
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: SingleChildScrollView(child: _buildContentPanel(s, isMobile))),
                              const SizedBox(width: 24),
                              Expanded(flex: 6, child: SingleChildScrollView(child: _buildInteractionPanel(s, isMobile))),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildContentPanel(s, isMobile),
                                const SizedBox(height: 18),
                                _buildInteractionPanel(s, isMobile),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              _buildProblemFocusOverlay(s, isMobile),
              _buildCodeFocusOverlay(s, isMobile),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AppStyle s, bool isMobile) {
    final title = s.pick(
      "${widget.subject.toUpperCase()} • C${widget.grade} • #${widget.id}",
      "${widget.subject}, clasa a ${widget.grade}-a, problema #${widget.id}",
    );
    return AppBar(
      title: Text(
        title,
        style: s.isClean
            ? TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 16)
            : TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: isMobile ? 14 : 16),
      ),
      backgroundColor: s.pick(AppColors.bg, AppColors.cardBg),
      iconTheme: IconThemeData(color: AppColors.ink),
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(s.isClean ? 1 : 2.5),
        child: Container(color: s.line, height: s.isClean ? 1 : 2.5),
      ),
    );
  }

  // ---------------------------------------------------------------- OVERLAYS
  Widget _buildProblemFocusOverlay(AppStyle s, bool isMobile) {
    final h = MediaQuery.of(context).size.height;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      top: isFullScreenProblem ? 0 : h,
      bottom: isFullScreenProblem ? 0 : -h,
      left: 0,
      right: 0,
      child: Container(
        color: AppColors.bg,
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: RetroBlock(
              padding: isMobile ? 18 : 36,
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (s.isRetro) AppBadge(text: "PROBLEM FOCUS MODE", color: AppColors.sunset, fontSize: 12),
                      const Spacer(),
                      RetroButton(
                        text: s.pick("EXIT FOCUS", "Închide"),
                        icon: s.pick(Icons.fullscreen_exit, Icons.close),
                        bgColor: s.pick(AppColors.ink, AppColors.cardBg),
                        textColor: s.pick(s.onInk, AppColors.ink),
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onPressed: () => setState(() => isFullScreenProblem = false),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  Expanded(child: SingleChildScrollView(child: _buildEnuntContent(s, isMobile))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeFocusOverlay(AppStyle s, bool isMobile) {
    final h = MediaQuery.of(context).size.height;

    final runButton = RetroButton(
      text: isMobile ? s.pick("RUN", "Rulează") : s.pick("COMPILE & RUN TESTS", "Rulează testele"),
      icon: Icons.play_arrow,
      isLoading: isRunningCode,
      bgColor: AppColors.forest,
      onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
    );

    final exitButton = RetroButton(
      text: isMobile ? s.pick("EXIT", "Ieși") : s.pick("EXIT FULLSCREEN", "Ieși din ecran complet"),
      icon: s.pick(Icons.fullscreen_exit, Icons.close_fullscreen),
      bgColor: s.pick(AppColors.ink, AppColors.cardBg),
      textColor: s.pick(s.onInk, AppColors.ink),
      onPressed: () => setState(() => isFullScreenCode = false),
    );

    final spec = ProblemSpec.fromData(exerciseData!, isMobile: isMobile);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      top: isFullScreenCode ? 0 : h,
      bottom: isFullScreenCode ? 0 : -h,
      left: 0,
      right: 0,
      child: Container(
        color: AppColors.bg,
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: !isMobile
            ? Row(
                children: [
                  SizedBox(
                    width: 420,
                    child: RetroBlock(
                      padding: 24,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.pick("QUEST BRIEF", "Enunț"),
                                  style: s.isClean
                                      ? s.overline(13)
                                      : TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.sunset),
                                ),
                                Text(
                                  "#${widget.id}",
                                  style: s.isClean ? s.muted(13) : TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(_title(s), style: s.heading(22)),
                            const SizedBox(height: 16),
                            Text(
                              exerciseData!["description"]?.toString() ?? "",
                              style: s.body(s.pick(16.0, 15.0), height: 1.6),
                            ),
                            if (!spec.isEmpty) ...[
                              const SizedBox(height: 20),
                              ProblemSpec.fromData(exerciseData!, isMobile: true),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: RetroBlock(
                      bgColor: AppColors.cloud,
                      padding: 18,
                      child: Column(
                        children: [
                          _buildIdeHeader(s, isFullScreen: true, isMobile: isMobile),
                          const SizedBox(height: 10),
                          _buildCodeQuickActions(s),
                          const SizedBox(height: 10),
                          Expanded(child: _buildIdeEditor(s, isMobile)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: runButton),
                              const SizedBox(width: 14),
                              exitButton,
                            ],
                          ),
                          if (testResults.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SizedBox(height: 130, child: SingleChildScrollView(child: _buildTestCasesConsole(s))),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : RetroBlock(
                bgColor: AppColors.cloud,
                padding: 12,
                child: Column(
                  children: [
                    _buildIdeHeader(s, isFullScreen: true, isMobile: isMobile),
                    const SizedBox(height: 8),
                    _buildCodeQuickActions(s),
                    const SizedBox(height: 8),
                    Expanded(child: _buildIdeEditor(s, isMobile)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: runButton),
                        const SizedBox(width: 8),
                        exitButton,
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _title(AppStyle s) {
    final raw = exerciseData!["title"]?.toString();
    if (raw == null || raw.isEmpty) return s.pick("UNTITLED QUEST", "Problemă fără titlu");
    return s.isClean ? raw : raw.toUpperCase();
  }

  // ---------------------------------------------------------------- LEFT PANEL
  Widget _buildContentPanel(AppStyle s, bool isMobile) {
    final focusChip = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => isFullScreenProblem = true),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : s.pick(8.0, 7.0)),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: s.rButton,
            border: Border.all(color: s.isClean ? s.lineStrong : AppColors.border, width: s.isClean ? 1 : 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.pick(Icons.fullscreen, Icons.open_in_full), size: isMobile ? 14 : 16, color: AppColors.ink),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                s.pick(isMobile ? "FOCUS" : "FOCUS BRIEF", isMobile ? "Extinde" : "Citește pe tot ecranul"),
                style: s.isClean
                    ? TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)
                    : TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );

    final tabs = Row(
      crossAxisAlignment: s.isClean ? CrossAxisAlignment.center : CrossAxisAlignment.end,
      children: [
        AppTab(
          label: s.pick("PROBLEM", "Enunț"),
          selected: selectedTab == "enunt",
          isMobile: isMobile,
          onTap: () => setState(() => selectedTab = "enunt"),
        ),
        SizedBox(width: s.pick(6.0, 2.0)),
        AppTab(
          label: s.pick("SOLUTION", "Soluție"),
          selected: selectedTab == "solutie",
          isMobile: isMobile,
          onTap: () => setState(() => selectedTab = "solutie"),
        ),
        const Spacer(),
        focusChip,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.isClean)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: s.line))),
            child: tabs,
          )
        else
          tabs,
        RetroBlock(
          padding: isMobile ? 18 : 28,
          shadowOffset: isMobile ? 3 : 4,
          child: selectedTab == "enunt" ? _buildEnuntContent(s, isMobile) : _buildSolutieContent(s, isMobile),
        ),
      ],
    );
  }

  Widget _buildEnuntContent(AppStyle s, bool isMobile) {
    final spec = ProblemSpec.fromData(exerciseData!, isMobile: isMobile);
    final hint = exerciseData!["hint"]?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_title(s), style: s.heading(isMobile ? 20 : s.pick(26.0, 24.0))),
        SizedBox(height: isMobile ? 14 : s.pick(24.0, 20.0)),
        if (s.isRetro)
          AppBadge(text: "DESCRIPTION", color: AppColors.sunset, fontSize: 11)
        else
          Text("Cerință", style: s.heading(15)),
        const SizedBox(height: 10),
        Text(
          exerciseData!["description"]?.toString() ?? "Fără descriere disponibilă.",
          style: s.body(isMobile ? 15 : s.pick(18.0, 16.0), height: s.pick(1.55, 1.65)),
        ),
        if (hint != null && hint.isNotEmpty) ...[
          SizedBox(height: isMobile ? 16 : 24),
          if (s.isClean)
            AppCallout(text: hint, color: AppColors.sky, icon: Icons.lightbulb_outline, fontSize: isMobile ? 14 : 15)
          else
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
                      hint,
                      style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.ink, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (!spec.isEmpty) ...[
          SizedBox(height: isMobile ? 18 : s.pick(28.0, 24.0)),
          if (s.isRetro) ...[
            const AppDivider(),
            SizedBox(height: isMobile ? 14 : 20),
          ],
          spec,
        ],
      ],
    );
  }

  Widget _buildSolutieContent(AppStyle s, bool isMobile) {
    final offSol = exerciseData!["official_solution"];
    final code = offSol is Map ? offSol["code"]?.toString() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.pick("MASTER'S SOLUTION", "Soluția oficială"), style: s.heading(isMobile ? 16 : 20)),
        const SizedBox(height: 14),
        if (code != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: s.codeSurface(),
            child: SelectableText(
              code,
              style: s.mono(
                isMobile ? 13 : s.pick(15.0, 14.0),
                color: s.pick(AppStyle.codeAccent, AppStyle.codeText),
                weight: s.pick(FontWeight.bold, FontWeight.w400),
                height: 1.5,
              ),
            ),
          )
        else
          Text(
            s.pick("Acest exercițiu nu are o rezolvare oficială încărcată.", "Problema nu are încă o soluție oficială."),
            style: s.body(isMobile ? 14 : 16, retroWeight: FontWeight.bold),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- RIGHT PANEL
  Widget _buildInteractionPanel(AppStyle s, bool isMobile) {
    final done = _alreadyDone || solutionOk;
    final kind = _kind;

    final cleanTitle = kind == "grila" ? "Alege răspunsul" : (kind == "text" ? "Răspunsul tău" : "Editor de cod");
    final cleanIcon = kind == "grila" ? Icons.checklist : (kind == "text" ? Icons.edit_outlined : Icons.code);

    return RetroBlock(
      bgColor: AppColors.cloud,
      padding: isMobile ? 14 : 20,
      shadowOffset: isMobile ? 3 : 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(s.pick(Icons.terminal, cleanIcon), size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                s.pick("TERMINAL & IDE", cleanTitle),
                style: s.isClean
                    ? s.heading(isMobile ? 15 : 17)
                    : TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
              ),
              const Spacer(),
              if (done)
                AppBadge(
                  text: s.pick("CLEARED", "Rezolvată"),
                  color: AppColors.forest,
                  icon: s.isClean ? Icons.check : null,
                  fontSize: 10,
                ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (kind == "grila")
            _buildGrilaSection(s, isMobile)
          else if (kind == "text")
            _buildTextAnswerSection(s, isMobile)
          else
            _buildCodeSection(s, isMobile),
        ],
      ),
    );
  }

  Widget _buildGrilaSection(AppStyle s, bool isMobile) {
    final List<dynamic> variante = exerciseData!["variante"] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...variante.map((v) {
          final text = v.toString();
          final isSelected = _selectedGrilaOption == text;

          final decoration = s.isClean
              ? BoxDecoration(
                  color: isSelected ? s.tint(AppColors.sky) : AppColors.cardBg,
                  borderRadius: s.rButton,
                  border: Border.all(color: isSelected ? AppColors.sky : s.lineStrong, width: 1),
                )
              : BoxDecoration(
                  color: isSelected ? AppColors.sky : AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2),
                );

          final icon = s.isClean
              ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
              : (isSelected ? Icons.check_box : Icons.check_box_outline_blank);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _checkAuthAndExecute(() => setState(() => _selectedGrilaOption = text)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 12 : s.pick(16.0, 14.0)),
                  decoration: decoration,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: s.isClean && isSelected ? s.accentText(AppColors.sky) : (s.isClean ? AppColors.textMuted : AppColors.ink),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: s.isClean
                              ? TextStyle(fontSize: isMobile ? 14 : 15, color: AppColors.ink, fontWeight: FontWeight.w500)
                              : TextStyle(fontSize: isMobile ? 14 : 16, color: AppColors.ink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        RetroButton(
          text: s.pick("VERIFY ANSWER", "Verifică răspunsul"),
          isFullWidth: true,
          bgColor: AppColors.ink,
          textColor: s.onInk,
          onPressed: _selectedGrilaOption == null ? () {} : () => _checkAuthAndExecute(_checkSimpleAnswer),
        ),
        _buildResultBox(s),
      ],
    );
  }

  Widget _buildTextAnswerSection(AppStyle s, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _answerController,
          style: s.isClean
              ? TextStyle(fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.w500, color: AppColors.ink)
              : TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.bold, color: AppColors.ink),
          cursorColor: AppColors.isDark ? AppStyle.codeAccent : AppColors.ink,
          decoration: s.input(hint: s.pick("Introdu valoarea...", "Scrie răspunsul aici")),
        ),
        const SizedBox(height: 14),
        RetroButton(
          text: s.pick("VERIFY ANSWER", "Verifică răspunsul"),
          isFullWidth: true,
          bgColor: AppColors.ink,
          textColor: s.onInk,
          onPressed: () => _checkAuthAndExecute(_checkSimpleAnswer),
        ),
        _buildResultBox(s),
      ],
    );
  }

  // ---------------------------------------------------------------- IDE
  Widget _buildIdeHeader(AppStyle s, {bool isFullScreen = false, bool isMobile = false}) {
    final line = _getCurrentLine();
    final col = _getCurrentCol();

    final toggleLabel = isFullScreen
        ? s.pick("EXIT", "Ieși")
        : (isMobile ? s.pick("FOCUS", "Extinde") : s.pick("FOCUS MODE", "Ecran complet"));

    final toggleFg = s.isClean ? AppColors.ink : (isFullScreen ? Colors.white : s.onInk);

    return Row(
      children: [
        AppBadge(text: "C++20", color: s.pick(AppColors.ink, AppColors.sky), textColor: s.onInk, fontSize: 10.5),
        const SizedBox(width: 10),
        Text(
          s.pick("L$line:C$col", "Linia $line, coloana $col"),
          style: s.isClean
              ? TextStyle(fontSize: 12.5, color: AppColors.textMuted)
              : TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.ink),
        ),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => isFullScreenCode = !isFullScreenCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: s.isClean
                  ? BoxDecoration(color: AppColors.cardBg, borderRadius: s.rButton, border: Border.all(color: s.lineStrong))
                  : BoxDecoration(
                      color: isFullScreen ? AppColors.sunset : AppColors.ink,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s.isClean
                        ? (isFullScreen ? Icons.close_fullscreen : Icons.open_in_full)
                        : (isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                    size: 14,
                    color: toggleFg,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    toggleLabel,
                    style: TextStyle(
                      fontSize: s.pick(11.0, 12.5),
                      fontWeight: s.pick(FontWeight.w900, FontWeight.w500),
                      color: toggleFg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeQuickActions(AppStyle s) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _snippetButton(s, s.pick("UNDO", "Anulează"), _performUndo),
          const SizedBox(width: 6),
          _snippetButton(s, s.pick("REDO", "Refă"), _performRedo),
          const SizedBox(width: 6),
          _snippetButton(s, s.pick("TAB", "Tab"), () => _insertSnippet("    ", "", 4)),
          const SizedBox(width: 6),
          _snippetButton(s, "{ }", () => _insertSnippet("{\n    ", "\n}", 4), isCode: true),
          const SizedBox(width: 6),
          _snippetButton(s, "cin >>", () => _insertSnippet("cin >> ", ";", 7), isCode: true),
          const SizedBox(width: 6),
          _snippetButton(s, "cout <<", () => _insertSnippet("cout << ", " << \"\\n\";", 8), isCode: true),
          const SizedBox(width: 6),
          _snippetButton(
            s,
            s.pick("RESET", "Resetează codul"),
            () => setState(() {
              _codeController.text = defaultCppBoilerplate;
            }),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _snippetButton(AppStyle s, String label, VoidCallback onTap, {bool isDanger = false, bool isCode = false}) {
    final fg = isDanger ? (s.isClean ? s.accentText(AppColors.sunset) : AppColors.sunset) : AppColors.ink;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: s.pick(9.0, 10.0), vertical: s.pick(4.0, 5.0)),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: s.rChip,
            border: Border.all(
              color: isDanger ? (s.isClean ? AppColors.sunset.withOpacity(0.45) : AppColors.sunset) : s.lineStrong,
              width: s.isClean ? 1 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: s.isClean
                ? (isCode ? s.mono(12, color: fg, weight: FontWeight.w500) : TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: fg))
                : TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: fg),
          ),
        ),
      ),
    );
  }

  Widget _buildIdeEditor(AppStyle s, bool isMobile) {
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;
    final currentLine = _getCurrentLine();

    final double fontSz = isMobile ? 13.0 : 14.5;
    const double lineH = 1.55;
    final double gutterW = isMobile ? 38 : 48;

    final codeStyle = s.mono(fontSz, height: lineH);
    final strut = StrutStyle.fromTextStyle(codeStyle, forceStrutHeight: true);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: s.codeSurface(),
      child: LayoutBuilder(
        builder: (context, box) {
          final minH = box.maxHeight.isFinite ? box.maxHeight : 0.0;
          return Stack(
            children: [
              // Gutter background stays put while the code scrolls.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: gutterW,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppStyle.codeGutter,
                    border: Border(right: BorderSide(color: AppStyle.codeGutterLine, width: 1.5)),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: gutterW,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(lineCount, (i) {
                            final lineNum = i + 1;
                            final isCurrent = lineNum == currentLine;
                            return Container(
                              height: fontSz * lineH,
                              color: isCurrent
                                  ? s.pick(AppStyle.codeGutterLine, Colors.white.withOpacity(0.06))
                                  : Colors.transparent,
                              padding: EdgeInsets.only(right: s.pick(4.0, 8.0)),
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.isRetro && isCurrent ? "▶$lineNum" : "$lineNum",
                                strutStyle: strut,
                                style: s.mono(
                                  isMobile ? 10.5 : 12,
                                  color: isCurrent ? s.pick(AppStyle.codeAccent, AppStyle.codeText) : AppStyle.codeMuted,
                                  weight: isCurrent ? s.pick(FontWeight.w900, FontWeight.w600) : s.pick(FontWeight.w600, FontWeight.w400),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minH),
                        child: Focus(
                          focusNode: _editorFocusNode,
                          onKeyEvent: _handleEditorKey,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                selectionColor: Color(0x6674B9FF),
                                cursorColor: AppStyle.codeAccent,
                                selectionHandleColor: Color(0xFF74B9FF),
                              ),
                            ),
                            child: TextField(
                              controller: _codeController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              cursorColor: AppStyle.codeAccent,
                              cursorWidth: s.pick(2.5, 2.0),
                              strutStyle: strut,
                              style: codeStyle,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCodeSection(AppStyle s, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdeHeader(s, isFullScreen: false, isMobile: isMobile),
        const SizedBox(height: 8),
        _buildCodeQuickActions(s),
        const SizedBox(height: 8),
        SizedBox(height: isMobile ? 260 : 320, child: _buildIdeEditor(s, isMobile)),
        const SizedBox(height: 14),
        RetroButton(
          text: s.pick("COMPILE & RUN", "Rulează testele"),
          icon: Icons.play_arrow,
          isFullWidth: true,
          isLoading: isRunningCode,
          bgColor: AppColors.forest,
          onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
        ),
        if (testResults.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildTestCasesConsole(s),
        ],
        _buildResultBox(s),
      ],
    );
  }

  Widget _buildTestCasesConsole(AppStyle s) {
    final passedCount = testResults.where((t) => t["passed"] == true).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: s.codeSurface(retroBorder: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.pick("TEST RESULTS & CONSOLE", "Rezultate: $passedCount din ${testResults.length} teste trecute"),
            style: s.isClean
                ? const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)
                : TextStyle(color: AppColors.cloud, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          ...testResults.map((t) {
            final passed = t["passed"] == true;
            final accent = passed ? AppColors.forest : AppColors.sunset;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppStyle.codeGutter,
                borderRadius: s.rChip,
                border: Border.all(color: s.isClean ? accent.withOpacity(0.5) : accent, width: s.isClean ? 1 : 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(passed ? Icons.check_circle : Icons.cancel, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        s.pick(
                          "TEST ${t['index']}: ${passed ? 'PASSED (OK)' : 'FAILED'}",
                          "Testul ${t['index']}: ${passed ? 'corect' : 'greșit'}",
                        ),
                        style: TextStyle(
                          color: accent,
                          fontWeight: s.pick(FontWeight.w900, FontWeight.w600),
                          fontSize: s.pick(11.0, 12.5),
                        ),
                      ),
                    ],
                  ),
                  if (!passed) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${s.pick('EXPECTED:', 'Așteptat:')} ${t['expected']}",
                      style: s.mono(11.5, color: Colors.white70),
                    ),
                    Text(
                      "${s.pick('OUTPUT:  ', 'Obținut: ')} ${t['got']}",
                      style: s.mono(11.5, color: AppColors.sunset),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- CHECKERS
  void _checkSimpleAnswer() async {
    final raspunsCorect = exerciseData!["raspuns_corect"]?.toString().trim().toLowerCase();
    String raspunsElev;

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

        if (mounted) setState(() {});
      }

      if (!mounted) return;
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
      if (mounted) setState(() => solutionChecked = true);
    } finally {
      if (mounted) setState(() => isRunningCode = false);
    }
  }

  Widget _buildResultBox(AppStyle s) {
    if (!solutionChecked) return const SizedBox();

    if (s.isClean) {
      final isCode = _kind == "cod";
      final msg = solutionOk
          ? (isCode ? "Toate testele au trecut. Problema e rezolvată." : "Răspuns corect. Problema e rezolvată.")
          : (isCode ? "Unele teste nu au trecut. Compară rezultatul obținut cu cel așteptat." : "Răspuns greșit. Mai încearcă.");
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: AppCallout(
          text: msg,
          color: solutionOk ? AppColors.forest : AppColors.sunset,
          icon: solutionOk ? Icons.check_circle_outline : Icons.error_outline,
          fontSize: 14,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: solutionOk ? AppColors.forest : AppColors.sunset,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: s.hardShadow(3),
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