import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'ui_components.dart';

// ----------------------------------------------------
// SYNTAX-HIGHLIGHTED EDITOR CONTROLLER
// Palette follows the style (see CodeHighlighter).
// ----------------------------------------------------
class CppSyntaxController extends TextEditingController {
  CppSyntaxController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    return CodeHighlighter.span(text, style ?? const TextStyle());
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  final String subject;
  final String grade;
  final String id;

  const ExerciseDetailScreen({super.key, required this.subject, required this.grade, required this.id});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  Map<String, dynamic>? exerciseData;
  String selectedTab = "enunt";
  int _consoleTab = 0;
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

  // ===========================================================================
  // DATA HELPERS
  // ===========================================================================
  /// "grila" | "text" | "cod"
  String get _kind {
    final t = exerciseData?["tip_exercitiu"];
    if (t == "grila") return "grila";
    if (t == "text" || exerciseData?["raspuns_corect"] != null) return "text";
    return "cod";
  }

  String get _title => exerciseData?["title"]?.toString() ?? "Problemă fără titlu";

  String? _str(List<String> keys) {
    for (final k in keys) {
      final v = exerciseData?[k];
      if (v == null || v is List) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty && t != '-') return t;
    }
    return null;
  }

  List<String>? _list(List<String> keys) {
    for (final k in keys) {
      final v = exerciseData?[k];
      if (v is List && v.isNotEmpty) return v.map((e) => e.toString()).toList();
    }
    return null;
  }

  List<Map<String, String>> get _examples {
    final out = <Map<String, String>>[];
    void add(dynamic e) {
      if (e is Map) out.add({'input': (e['input'] ?? '').toString(), 'output': (e['output'] ?? '').toString()});
    }

    final raw = exerciseData?['examples'] ?? exerciseData?['exemple'];
    if (raw is Map) {
      add(raw);
    } else if (raw is List) {
      raw.forEach(add);
    }
    return out;
  }

  // ===========================================================================
  // EDITOR LOGIC
  // ===========================================================================
  void _onCodeChanged() {
    if (!_isUndoingOrRedoing) _recordHistorySnapshot(_codeController.value);
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
      _redoStack.add(_undoStack.removeLast());
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

  void _resetCode() => setState(() {
        _codeController.text = defaultCppBoilerplate;
      });

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
        _codeController.value = TextEditingValue(
          text: text.replaceRange(start, end, tabSpaces),
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
          _codeController.value = TextEditingValue(
            text: text.replaceRange(pos, pos, insertion),
            selection: TextSelection.collapsed(offset: pos + insertion.length),
          );
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _insertSnippet(String prefix, String suffix, [int cursorOffset = 0]) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final replacement = "$prefix${text.substring(start, end)}$suffix";
    final newText = text.replaceRange(start, end, replacement);
    final newCursor = start + prefix.length + cursorOffset;
    _codeController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor.clamp(0, newText.length)),
    );
  }

  // ===========================================================================
  // DATA / PROGRESS
  // ===========================================================================
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

  String get _progressKey => "${widget.subject}_${widget.grade}_${widget.id}";

  Future<void> _markExerciseAsDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_progressKey, true);
    if (mounted) setState(() => _alreadyDone = true);
  }

  Future<bool> _isExerciseDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(_progressKey) == true;
  }

  void _checkAuthAndExecute(VoidCallback action) {
    if (FirebaseAuth.instance.currentUser != null) {
      action();
      return;
    }

    if (AppStyle.current.isClean) {
      showPbModal(
        context,
        title: 'Autentificare necesară',
        body: const Text('Intră în cont ca să poți trimite soluții și să îți salvezi progresul.'),
        actions: (ctx) => [
          PbButton(text: 'Renunță', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
          PbButton(
            text: 'Intră în cont',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
          ),
        ],
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2.5)),
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
          RetroButton(text: "CANCEL", bgColor: AppColors.cloud, textColor: AppColors.ink, onPressed: () => dialogContext.pop()),
          const SizedBox(width: 8),
          RetroButton(
            text: "LOGIN",
            bgColor: AppColors.sunset,
            onPressed: () {
              dialogContext.pop();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CHECKERS
  // ===========================================================================
  void _checkSimpleAnswer() async {
    final raspunsCorect = exerciseData!["raspuns_corect"]?.toString().trim().toLowerCase();
    final raspunsElev = exerciseData!["tip_exercitiu"] == "grila"
        ? (_selectedGrilaOption?.trim().toLowerCase() ?? "")
        : _answerController.text.trim().toLowerCase();

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
      _consoleTab = 1;
    });

    try {
      final List<Map<String, dynamic>> tests = [];
      for (final ex in _examples) {
        tests.add({"input": ex['input'], "output": ex['output']});
      }
      if (exerciseData?["tests"] != null) {
        for (var t in exerciseData!["tests"]) {
          tests.add({"input": t["input"]?.toString() ?? "", "output": t["output"]?.toString() ?? ""});
        }
      }

      // No tests => nothing can be verified; never mark as solved.
      if (tests.isEmpty) {
        testResults.add({"index": 1, "passed": false, "expected": "teste definite", "got": "problema nu are teste"});
        if (mounted) setState(() => solutionChecked = true);
        return;
      }

      bool allPassed = true;

      for (int i = 0; i < tests.length; i++) {
        final inputData = tests[i]["input"] ?? "";
        final expectedOutput = tests[i]["output"] ?? "";

        final response = await http.post(
          Uri.parse("https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true"),
          headers: {
            "Content-Type": "application/json",
            "X-RapidAPI-Key": "YOUR_API_KEY",
            "X-RapidAPI-Host": "judge0-ce.p.rapidapi.com",
          },
          body: jsonEncode({"language_id": 52, "source_code": code, "stdin": inputData}),
        );

        final result = jsonDecode(response.body);
        String normalize(String s) => s.replaceAll('\r', '').trim();
        final normOutput = normalize((result["stdout"] ?? "").toString());
        final normExpected = normalize(expectedOutput.toString());
        final ok = normOutput == normExpected;
        if (!ok) allPassed = false;

        testResults.add({"index": i + 1, "passed": ok, "expected": normExpected, "got": normOutput});
        if (mounted) setState(() {});
      }

      if (!mounted) return;
      setState(() {
        solutionChecked = true;
        solutionOk = allPassed;
      });
      if (allPassed) await _markExerciseAsDone();
    } catch (e) {
      testResults.add({"index": testResults.length + 1, "passed": false, "expected": "fără erori", "got": "$e"});
      if (mounted) setState(() => solutionChecked = true);
    } finally {
      if (mounted) setState(() => isRunningCode = false);
    }
  }

  // ===========================================================================
  // SHARED EDITOR (colors per style)
  // ===========================================================================
  Widget _buildEditor({required bool clean, required bool isMobile}) {
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;
    final currentLine = _getCurrentLine();

    final double fontSz = isMobile ? 13.0 : 14.5;
    const double lineH = 1.55;
    final double gutterW = isMobile ? 40 : 50;

    final codeStyle = clean
        ? Pb.mono(fontSz, height: lineH)
        : TextStyle(fontFamily: 'monospace', fontSize: fontSz, height: lineH, fontWeight: FontWeight.w600);
    final strut = StrutStyle.fromTextStyle(codeStyle, forceStrutHeight: true);

    final bg = clean ? Pb.editorBg : const Color(0xFF1B242B);
    final gutterBg = clean ? Pb.editorGutter : const Color(0xFF131A1F);
    final gutterLine = clean ? Pb.border : const Color(0xFF2C3E50);
    final activeLine = clean ? Pb.editorActiveLine : const Color(0xFF2C3E50);
    final numColor = clean ? Pb.muted : const Color(0xFF636E72);
    final activeNum = clean ? Pb.text : const Color(0xFF55EFC4);
    final cursor = clean ? Pb.text : const Color(0xFF55EFC4);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: bg,
        border: clean ? null : Border.all(color: AppColors.border, width: 2.5),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final minH = box.maxHeight.isFinite ? box.maxHeight : 0.0;
          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: gutterW,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gutterBg, border: Border(right: BorderSide(color: gutterLine))),
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
                            final n = i + 1;
                            final isCurrent = n == currentLine;
                            return Container(
                              height: fontSz * lineH,
                              color: isCurrent ? activeLine : Colors.transparent,
                              padding: const EdgeInsets.only(right: 6),
                              alignment: Alignment.centerRight,
                              child: Text(
                                !clean && isCurrent ? "▶$n" : "$n",
                                strutStyle: strut,
                                style: clean
                                    ? Pb.mono(isMobile ? 11 : 12.5, color: isCurrent ? activeNum : numColor)
                                    : TextStyle(
                                        fontFamily: 'monospace',
                                        color: isCurrent ? activeNum : numColor,
                                        fontSize: isMobile ? 10.5 : 12,
                                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
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
                              textSelectionTheme: TextSelectionThemeData(
                                selectionColor: clean ? Pb.primary.withOpacity(0.25) : const Color(0x6674B9FF),
                                cursorColor: cursor,
                                selectionHandleColor: clean ? Pb.primary : const Color(0xFF74B9FF),
                              ),
                            ),
                            child: TextField(
                              controller: _codeController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              cursorColor: cursor,
                              cursorWidth: clean ? 2 : 2.5,
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

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final width = MediaQuery.of(context).size.width;
        return s.isClean ? _buildClean(width < 900) : _buildRetro(width < 920);
      },
    );
  }

  // ===========================================================================
  // CLEAN — pbinfo problem page
  // ===========================================================================
    Widget _buildClean(bool isMobile) {
    Widget shell(Widget body) => Scaffold(
          backgroundColor: Pb.page,
          body: Column(children: [const CustomNavbar(), Expanded(child: body)]),
        );

    if (exerciseData == null) {
      return shell(const Center(child: CircularProgressIndicator(color: Pb.primary)));
    }

    if (exerciseData!.isEmpty) {
      return shell(SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: PbContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PbAlert(type: PbAlertType.danger, text: 'Problema nu a fost găsită.'),
              const SizedBox(height: 12),
              PbLink(text: 'Înapoi la probleme', onTap: () => context.go('/exercitii'), underline: true),
            ],
          ),
        ),
      ));
    }

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cleanBreadcrumbBox(),
        const SizedBox(height: 14),
        _cleanTitle(isMobile, _alreadyDone || solutionOk),
        const SizedBox(height: 12),
        _cleanMetaTable(isMobile),
      ],
    );

    if (isMobile) {
      return shell(SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: PbContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 20),
              _cleanStatementPane(true),
              const SizedBox(height: 20),
              _cleanWorkPane(true),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ));
    }

    return shell(Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _cleanPane(
              header: PbNavTabs(
                labels: const ['Enunț', 'Soluție'],
                selected: selectedTab == 'enunt' ? 0 : 1,
                onSelect: (i) => setState(() => selectedTab = i == 0 ? 'enunt' : 'solutie'),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selectedTab == 'enunt') ...[header, _cleanStatement(false)] else _cleanSolution(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: _kind == 'cod'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _cleanEditorPane()),
                      const SizedBox(height: 12),
                      Expanded(flex: 2, child: _cleanConsolePane()),
                    ],
                  )
                : SingleChildScrollView(child: _cleanWorkPane(false)),
          ),
        ],
      ),
    ));
  }

  Widget _cleanPane({required Widget header, required Widget child}) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Pb.surface, borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 0), child: header),
            Expanded(child: child),
          ],
        ),
      );

  Widget _cleanEditorPane() {
    Widget icon(IconData i, String tip, VoidCallback onTap) => IconButton(
          icon: Icon(i, size: 18),
          color: Pb.muted,
          tooltip: tip,
          splashRadius: 18,
          visualDensity: VisualDensity.compact,
          onPressed: onTap,
        );

    return _cleanPane(
      header: SizedBox(
        height: 42,
        child: Row(
          children: [
            const SizedBox(width: 6),
            Icon(Icons.code, size: 18, color: Pb.primary),
            const SizedBox(width: 8),
            Text('Cod', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(width: 10),
            const PbBadge(text: 'C++', fontSize: 11.5),
            const Spacer(),
            icon(Icons.undo, 'Anulează (Ctrl+Z)', _performUndo),
            icon(Icons.redo, 'Refă (Ctrl+Y)', _performRedo),
            icon(Icons.restart_alt, 'Resetează codul', _resetCode),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: Pb.border),
          Expanded(child: _buildEditor(clean: true, isMobile: false)),
          Container(height: 1, color: Pb.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Linia ${_getCurrentLine()}, coloana ${_getCurrentCol()}',
                    style: TextStyle(color: Pb.muted, fontSize: 13),
                  ),
                ),
                PbButton(
                  text: isRunningCode ? 'Se evaluează...' : 'Trimite soluția',
                  size: PbSize.sm,
                  icon: Icons.play_arrow,
                  loading: isRunningCode,
                  onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanConsolePane() {
    final total = testResults.length;
    final passed = testResults.where((t) => t["passed"] == true).length;
    final examples = _examples;

    Map<String, dynamic>? firstFail;
    for (final t in testResults) {
      if (t["passed"] != true) {
        firstFail = t;
        break;
      }
    }

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(t, style: TextStyle(fontSize: 13, color: Pb.muted)),
        );

    Widget body;
    if (_consoleTab == 0) {
      body = examples.isEmpty
          ? Text('Problema nu are exemple publice.', style: TextStyle(color: Pb.muted, fontSize: 14))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < examples.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  label('Intrare'),
                  PbCodeBox(examples[i]['input']!, fontSize: 13.5),
                  const SizedBox(height: 10),
                  label('Ieșire așteptată'),
                  PbCodeBox(examples[i]['output']!, fontSize: 13.5),
                ],
              ],
            );
    } else if (total == 0 && !isRunningCode) {
      body = Text('Trimite soluția ca să vezi rezultatul pe teste.', style: TextStyle(color: Pb.muted, fontSize: 14));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRunningCode)
            Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)),
                const SizedBox(width: 10),
                Text('Se rulează testele ($total gata)...', style: TextStyle(color: Pb.muted, fontSize: 14)),
              ],
            )
          else ...[
            Text(
              solutionOk ? 'Acceptat' : 'Respins',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: solutionOk ? Pb.success : Pb.danger),
            ),
            const SizedBox(height: 2),
            Text('$passed din $total teste trecute', style: TextStyle(color: Pb.muted, fontSize: 13.5)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in testResults)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: t["passed"] == true ? Pb.successBg : Pb.dangerBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        t["passed"] == true ? Icons.check : Icons.close,
                        size: 14,
                        color: t["passed"] == true ? Pb.successText : Pb.dangerText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Test ${t['index']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t["passed"] == true ? Pb.successText : Pb.dangerText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (firstFail != null && !isRunningCode) ...[
            const SizedBox(height: 18),
            Text('Testul ${firstFail['index']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(height: 8),
            label('Așteptat'),
            PbCodeBox('${firstFail['expected']}', fontSize: 13.5),
            const SizedBox(height: 10),
            label('Obținut'),
            PbCodeBox('${firstFail['got']}'.isEmpty ? '(nimic)' : '${firstFail['got']}', fontSize: 13.5),
          ],
        ],
      );
    }

    return _cleanPane(
      header: PbNavTabs(
        labels: const ['Exemple', 'Rezultat'],
        badges: [null, total == 0 ? null : '$passed/$total'],
        selected: _consoleTab,
        onSelect: (i) => setState(() => _consoleTab = i),
      ),
      child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: body),
    );
  }

    Widget _cleanStatementPane(bool isMobile) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PbNavTabs(
            labels: const ['Enunț', 'Soluție'],
            selected: selectedTab == 'enunt' ? 0 : 1,
            onSelect: (i) => setState(() => selectedTab = i == 0 ? 'enunt' : 'solutie'),
          ),
          PbTabPanel(child: selectedTab == 'enunt' ? _cleanStatement(isMobile) : _cleanSolution()),
        ],
      );

  Widget _cleanWorkPane(bool isMobile) {
    if (_kind == 'grila') return _cleanGrilaCard();
    if (_kind == 'text') return _cleanTextCard();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cleanCodeCard(isMobile),
        if (testResults.isNotEmpty || isRunningCode) ...[
          const SizedBox(height: 20),
          _cleanEvaluation(isMobile),
        ],
      ],
    );
  }

  Widget _cleanMetaTable(bool isMobile) {
    final diffRaw = _str(['dificultate', 'difficulty']);
    final diff = (diffRaw ?? '').toLowerCase();
    Color? diffColor;
    if (diff.startsWith('u') || diff.startsWith('e')) {
      diffColor = const Color(0xFF00A67E);
    } else if (diff.startsWith('m')) {
      diffColor = const Color(0xFFD99A00);
    } else if (diff.startsWith('g') || diff.startsWith('h') || diff.startsWith('d')) {
      diffColor = const Color(0xFFE5484D);
    }

    Widget chip(String label, {Color? fg, IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (fg ?? Pb.muted).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg ?? Pb.muted),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg ?? Pb.text)),
            ],
          ),
        );

    final tags = _list(['tags', 'etichete']) ?? const <String>[];
    final author = _str(['autor', 'author']);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (diffRaw != null) chip(AppStyle.sentence(diffRaw), fg: diffColor),
        chip(
          _kind == 'cod' ? 'C++' : (_kind == 'grila' ? 'Grilă' : 'Răspuns scurt'),
          icon: _kind == 'cod' ? Icons.code : Icons.quiz_outlined,
        ),
        chip('Clasa a ${widget.grade}-a', icon: Icons.school_outlined),
        if (_kind == 'cod') chip('stdin / stdout', icon: Icons.swap_horiz),
        for (final t in tags) chip(t, icon: Icons.sell_outlined),
        if (author != null) chip(author, icon: Icons.person_outline),
      ],
    );
  }

  Widget _cleanTitle(bool isMobile, bool done) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: [
        Text('${widget.id}. $_title', style: TextStyle(fontSize: isMobile ? 24 : 30, color: Pb.text, fontWeight: FontWeight.w700, height: 1.2)),
        if (done) PbBadge(text: 'rezolvată', color: Pb.success, fontSize: 13),
      ],
    );
  }


  Widget _cleanBreadcrumbBox() {
    final listRoute = '/lista-exercitii?materie=${Uri.encodeComponent(widget.subject)}';
    return PbBreadcrumb(items: [
      PbCrumb('Probleme', () => context.go('/exercitii')),
      PbCrumb(widget.subject, () => context.go(listRoute)),
      PbCrumb('Clasa a ${widget.grade}-a'),
    ]);
  }

  Widget _cleanStatement(bool isMobile) {
    final description = exerciseData!["description"]?.toString() ?? "Fără enunț.";
    final input = _str(['input', 'date_intrare']);
    final output = _str(['output', 'date_iesire']);
    final constraintsList = _list(['restrictii', 'constraints', 'restrictions']);
    final constraintsText = _str(['restrictii', 'constraints', 'restrictions']);
    final hint = _str(['hint', 'indicatie']);
    final examples = _examples;

    Widget bullets(List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 10, right: 10), child: CircleAvatar(radius: 2.5, backgroundColor: Pb.text)),
                    Expanded(child: PbRichText(it)),
                  ],
                ),
              ),
          ],
        );

    Widget exampleBox(String label, String content) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
            const SizedBox(height: 6),
            PbCodeBox(content),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PbHeading('Cerința'),
        PbRichText(description),
        if (input != null) ...[const PbHeading('Date de intrare'), PbRichText(input)],
        if (output != null) ...[const PbHeading('Date de ieșire'), PbRichText(output)],
        if (constraintsList != null || constraintsText != null) ...[
          const PbHeading('Restricții și precizări'),
          constraintsList != null ? bullets(constraintsList) : PbRichText(constraintsText!),
        ],
        for (var i = 0; i < examples.length; i++) ...[
          PbHeading(examples.length > 1 ? 'Exemplul ${i + 1}' : 'Exemplu'),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    exampleBox('Intrare', examples[i]['input']!),
                    const SizedBox(height: 12),
                    exampleBox('Ieșire', examples[i]['output']!),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: exampleBox('Intrare', examples[i]['input']!)),
                    const SizedBox(width: 16),
                    Expanded(child: exampleBox('Ieșire', examples[i]['output']!)),
                  ],
                ),
        ],
        if (hint != null) ...[
          const PbHeading('Indicație'),
          PbAlert(type: PbAlertType.info, child: PbRichText(hint, color: Pb.infoText)),
        ],
      ],
    );
  }

  Widget _cleanSolution() {
    final off = exerciseData!["official_solution"];
    final code = off is Map ? off["code"]?.toString() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PbHeading('Soluția oficială'),
        if (code != null)
          PbCodeBox(code, lang: 'cpp')
        else
          const PbAlert(type: PbAlertType.secondary, text: 'Problema nu are încă o soluție oficială.'),
      ],
    );
  }

  Widget _cleanCodeCard(bool isMobile) {
    PbButton tool(String text, VoidCallback onTap, {IconData? icon, PbVariant v = PbVariant.outlineSecondary}) =>
        PbButton(text: text, icon: icon, variant: v, size: PbSize.sm, onPressed: onTap);

    return PbCard(
      header: Row(
        children: [
          Expanded(child: Text('Trimite o soluție', style: TextStyle(fontSize: 19, color: Pb.text))),
          const PbBadge(text: 'C++'),
        ],
      ),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                tool('Anulează', _performUndo, icon: Icons.undo),
                tool('Refă', _performRedo, icon: Icons.redo),
                tool('Tab', () => _insertSnippet("    ", "", 4)),
                tool('{ }', () => _insertSnippet("{\n    ", "\n}", 4)),
                tool('cin >>', () => _insertSnippet("cin >> ", ";", 7)),
                tool('cout <<', () => _insertSnippet("cout << ", " << \"\\n\";", 8)),
                tool('Resetează codul', _resetCode, v: PbVariant.outlineDanger),
              ],
            ),
          ),
          Container(height: 1, color: Pb.border),
          SizedBox(height: isMobile ? 300 : 420, child: _buildEditor(clean: true, isMobile: isMobile)),
          Container(height: 1, color: Pb.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Linia ${_getCurrentLine()}, coloana ${_getCurrentCol()}',
                    style: TextStyle(color: Pb.muted, fontSize: 14),
                  ),
                ),
                PbButton(
                  text: isRunningCode ? 'Se evaluează...' : 'Trimite soluția',
                  loading: isRunningCode,
                  onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanEvaluation(bool isMobile) {
    final total = testResults.length;
    final passed = testResults.where((t) => t["passed"] == true).length;
    final score = total == 0 ? 0 : (passed * 100 / total).round();

    Widget summary;
    if (isRunningCode) {
      summary = PbAlert(type: PbAlertType.info, text: 'Evaluare în curs: $total ${total == 1 ? 'test rulat' : 'teste rulate'}.');
    } else {
      summary = PbAlert(
        type: solutionOk ? PbAlertType.success : PbAlertType.danger,
        child: Text.rich(TextSpan(children: [
          TextSpan(text: 'Punctaj: $score', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(
            text: solutionOk
                ? '. Toate testele au trecut, problema este rezolvată.'
                : '. $passed din $total teste au trecut.',
          ),
        ])),
      );
    }

    return PbCard(
      title: 'Rezultatul evaluării',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          summary,
          if (testResults.isNotEmpty) ...[
            const SizedBox(height: 14),
            PbTable(
              headers: const ['Test', 'Rezultat', 'Răspuns așteptat', 'Răspunsul tău'],
              columnWidths: {
                0: FixedColumnWidth(isMobile ? 54 : 70),
                1: FixedColumnWidth(isMobile ? 80 : 110),
              },
              rowColors: [for (final t in testResults) t["passed"] == true ? Pb.successBg : Pb.dangerBg],
              rows: [
                for (final t in testResults)
                  [
                    Text('#${t['index']}'),
                    Text(
                      t["passed"] == true ? 'corect' : 'greșit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: t["passed"] == true ? Pb.successText : Pb.dangerText,
                      ),
                    ),
                    Text('${t['expected']}', style: Pb.mono(13.5)),
                    Text('${t['got']}'.isEmpty ? '(nimic)' : '${t['got']}', style: Pb.mono(13.5)),
                  ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cleanAnswerAlert() {
    return PbAlert(
      type: solutionOk ? PbAlertType.success : PbAlertType.danger,
      text: solutionOk ? 'Răspuns corect. Problema este marcată ca rezolvată.' : 'Răspuns greșit. Mai încearcă.',
    );
  }

  Widget _cleanGrilaCard() {
    final List<dynamic> variante = exerciseData!["variante"] ?? [];
    return PbCard(
      title: 'Alege răspunsul corect',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final v in variante)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _checkAuthAndExecute(() => setState(() => _selectedGrilaOption = v.toString())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _selectedGrilaOption == v.toString() ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 20,
                        color: _selectedGrilaOption == v.toString() ? Pb.primary : Pb.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(v.toString(), style: TextStyle(fontSize: 16, color: Pb.text, height: 1.4))),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PbButton(
              text: 'Verifică răspunsul',
              onPressed: _selectedGrilaOption == null ? null : () => _checkAuthAndExecute(_checkSimpleAnswer),
            ),
          ),
          if (solutionChecked) ...[const SizedBox(height: 14), _cleanAnswerAlert()],
        ],
      ),
    );
  }

  Widget _cleanTextCard() {
    return PbCard(
      title: 'Răspunsul tău',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _answerController,
            style: TextStyle(fontSize: 16, color: Pb.text),
            cursorColor: Pb.text,
            decoration: Pb.input(hint: 'Scrie răspunsul aici'),
            onSubmitted: (_) => _checkAuthAndExecute(_checkSimpleAnswer),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PbButton(text: 'Verifică răspunsul', onPressed: () => _checkAuthAndExecute(_checkSimpleAnswer)),
          ),
          if (solutionChecked) ...[const SizedBox(height: 14), _cleanAnswerAlert()],
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original two-panel arcade layout
  // ===========================================================================
  Widget _buildRetro(bool isMobile) {
    if (exerciseData == null) {
      return Scaffold(backgroundColor: AppColors.bg, body: Center(child: CircularProgressIndicator(color: AppColors.sunset)));
    }
    if (exerciseData!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.bg, iconTheme: IconThemeData(color: AppColors.ink), elevation: 0),
        body: Center(child: Text("QUEST NOT FOUND.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink))),
      );
    }

    final h = MediaQuery.of(context).size.height;
    final onInk = AppColors.isDark ? const Color(0xFF10161A) : Colors.white;

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
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2.5), child: Container(color: AppColors.border, height: 2.5)),
      ),
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
                          Expanded(flex: 5, child: SingleChildScrollView(child: _retroContentPanel(isMobile))),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: SingleChildScrollView(child: _retroInteractionPanel(isMobile))),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(children: [
                          _retroContentPanel(isMobile),
                          const SizedBox(height: 18),
                          _retroInteractionPanel(isMobile),
                        ]),
                      ),
              ),
            ),
          ),

          // Problem focus
          AnimatedPositioned(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              color: AppColors.sunset,
                              child: const Text("PROBLEM FOCUS MODE",
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                            ),
                            const Spacer(),
                            RetroButton(
                              text: "EXIT FOCUS",
                              icon: Icons.fullscreen_exit,
                              bgColor: AppColors.ink,
                              textColor: onInk,
                              onPressed: () => setState(() => isFullScreenProblem = false),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 16 : 24),
                        Expanded(child: SingleChildScrollView(child: _retroEnunt(isMobile))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Code focus
          AnimatedPositioned(
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
                                      Text("QUEST BRIEF", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.sunset)),
                                      Text("#${widget.id}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(_title.toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                                  const SizedBox(height: 16),
                                  Text(exerciseData!["description"]?.toString() ?? "",
                                      style: TextStyle(fontSize: 16, color: AppColors.ink, height: 1.6, fontWeight: FontWeight.w600)),
                                  if (exerciseData!["input"] != null) ...[
                                    const SizedBox(height: 20),
                                    _retroSpecBlock("INPUT FORMAT", exerciseData!["input"].toString(), isMobile),
                                    const SizedBox(height: 14),
                                    _retroSpecBlock("OUTPUT FORMAT", exerciseData!["output"]?.toString() ?? "-", isMobile),
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
                                _retroIdeHeader(isFullScreen: true, isMobile: isMobile),
                                const SizedBox(height: 10),
                                _retroQuickActions(),
                                const SizedBox(height: 10),
                                Expanded(child: _buildEditor(clean: false, isMobile: isMobile)),
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
                                      textColor: onInk,
                                      onPressed: () => setState(() => isFullScreenCode = false),
                                    ),
                                  ],
                                ),
                                if (testResults.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(height: 130, child: SingleChildScrollView(child: _retroConsole())),
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
                          _retroIdeHeader(isFullScreen: true, isMobile: isMobile),
                          const SizedBox(height: 8),
                          _retroQuickActions(),
                          const SizedBox(height: 8),
                          Expanded(child: _buildEditor(clean: false, isMobile: isMobile)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RetroButton(
                                  text: "RUN",
                                  icon: Icons.play_arrow,
                                  isLoading: isRunningCode,
                                  bgColor: AppColors.forest,
                                  onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
                                ),
                              ),
                              const SizedBox(width: 8),
                              RetroButton(
                                text: "EXIT",
                                icon: Icons.fullscreen_exit,
                                bgColor: AppColors.ink,
                                textColor: onInk,
                                onPressed: () => setState(() => isFullScreenCode = false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retroContentPanel(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _retroTab("enunt", "PROBLEM", isMobile),
            const SizedBox(width: 6),
            _retroTab("solutie", "SOLUTION", isMobile),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => isFullScreenProblem = true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
                decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, size: isMobile ? 14 : 16, color: AppColors.ink),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(isMobile ? "FOCUS" : "FOCUS BRIEF",
                        style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ],
                ),
              ),
            ),
          ],
        ),
        RetroBlock(
          padding: isMobile ? 18 : 28,
          shadowOffset: isMobile ? 3 : 4,
          child: selectedTab == "enunt" ? _retroEnunt(isMobile) : _retroSolutie(isMobile),
        ),
      ],
    );
  }

  Widget _retroTab(String key, String label, bool isMobile) {
    final sel = selectedTab == key;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = key),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.mustard : AppColors.cloud,
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
            color: sel && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
            letterSpacing: 1.0,
            decoration: sel ? TextDecoration.none : TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _retroEnunt(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_title.toUpperCase(),
            style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2)),
        SizedBox(height: isMobile ? 14 : 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: AppColors.sunset,
          child: const Text("DESCRIPTION",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 10),
        Text(
          exerciseData!["description"]?.toString() ?? "Fără descriere disponibilă.",
          style: TextStyle(fontSize: isMobile ? 15 : 18, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.55, letterSpacing: 0.2),
        ),
        if (exerciseData!["hint"] != null) ...[
          SizedBox(height: isMobile ? 16 : 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.sky.withOpacity(0.15), border: Border.all(color: AppColors.sky, width: 2)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: AppColors.ink, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(exerciseData!["hint"].toString(),
                      style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.ink, fontWeight: FontWeight.bold, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
        if (exerciseData!["tip_exercitiu"] == "cod" || exerciseData!["input"] != null) ...[
          SizedBox(height: isMobile ? 18 : 28),
          Container(height: 2, color: AppColors.border),
          SizedBox(height: isMobile ? 14 : 20),
          _retroSpecBlock("INPUT FORMAT", exerciseData!["input"]?.toString() ?? "-", isMobile),
          const SizedBox(height: 12),
          _retroSpecBlock("OUTPUT FORMAT", exerciseData!["output"]?.toString() ?? "-", isMobile),
        ],
      ],
    );
  }

  Widget _retroSolutie(bool isMobile) {
    final off = exerciseData!["official_solution"];
    final code = off is Map ? off["code"]?.toString() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MASTER'S SOLUTION", style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 14),
        if (code != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1B242B), border: Border.all(color: AppColors.border, width: 2.5)),
            child: Text(code,
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: const Color(0xFF55EFC4),
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.bold,
                    height: 1.5)),
          )
        else
          Text("Acest exercițiu nu are o rezolvare oficială încărcată.",
              style: TextStyle(fontSize: isMobile ? 14 : 16, color: AppColors.ink, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _retroSpecBlock(String title, String content, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w900, color: AppColors.sky, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 10 : 14),
          decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 1.5)),
          child: Text(content, style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.4)),
        ),
      ],
    );
  }

  Widget _retroInteractionPanel(bool isMobile) {
    final done = _alreadyDone || solutionOk;
    return RetroBlock(
      bgColor: AppColors.cloud,
      padding: isMobile ? 14 : 20,
      shadowOffset: isMobile ? 3 : 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text("TERMINAL & IDE",
                  style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
              const Spacer(),
              if (done)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.forest,
                  child: const Text("CLEARED",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 10)),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (_kind == "grila")
            _retroGrila(isMobile)
          else if (_kind == "text")
            _retroTextAnswer(isMobile)
          else
            _retroCode(isMobile),
        ],
      ),
    );
  }

  Widget _retroGrila(bool isMobile) {
    final List<dynamic> variante = exerciseData!["variante"] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...variante.map((v) {
          final text = v.toString();
          final sel = _selectedGrilaOption == text;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _checkAuthAndExecute(() => setState(() => _selectedGrilaOption = text)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 12 : 16),
                decoration: BoxDecoration(color: sel ? AppColors.sky : AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                child: Row(
                  children: [
                    Icon(sel ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.ink, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text, style: TextStyle(fontSize: isMobile ? 14 : 16, color: AppColors.ink, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        RetroButton(
          text: "VERIFY ANSWER",
          isFullWidth: true,
          bgColor: AppColors.ink,
          textColor: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
          onPressed: _selectedGrilaOption == null ? () {} : () => _checkAuthAndExecute(_checkSimpleAnswer),
        ),
        _retroResultBox(),
      ],
    );
  }

  Widget _retroTextAnswer(bool isMobile) {
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
        _retroResultBox(),
      ],
    );
  }

  Widget _retroIdeHeader({bool isFullScreen = false, bool isMobile = false}) {
    final onInk = AppColors.isDark ? const Color(0xFF10161A) : Colors.white;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          color: AppColors.ink,
          child: Text("C++20", style: TextStyle(color: onInk, fontSize: 10.5, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 8),
        Text("L${_getCurrentLine()}:C${_getCurrentCol()}", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.ink)),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 14, color: isFullScreen ? Colors.white : onInk),
                const SizedBox(width: 4),
                Text(
                  isFullScreen ? "EXIT" : (isMobile ? "FOCUS" : "FOCUS MODE"),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isFullScreen ? Colors.white : onInk),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _retroQuickActions() {
    Widget btn(String label, VoidCallback onTap, {bool danger = false}) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: danger ? AppColors.sunset : AppColors.border, width: 1.5)),
            child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: danger ? AppColors.sunset : AppColors.ink)),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          btn("UNDO", _performUndo),
          const SizedBox(width: 6),
          btn("REDO", _performRedo),
          const SizedBox(width: 6),
          btn("TAB", () => _insertSnippet("    ", "", 4)),
          const SizedBox(width: 6),
          btn("{ }", () => _insertSnippet("{\n    ", "\n}", 4)),
          const SizedBox(width: 6),
          btn("cin >>", () => _insertSnippet("cin >> ", ";", 7)),
          const SizedBox(width: 6),
          btn("cout <<", () => _insertSnippet("cout << ", " << \"\\n\";", 8)),
          const SizedBox(width: 6),
          btn("RESET", _resetCode, danger: true),
        ],
      ),
    );
  }

  Widget _retroCode(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _retroIdeHeader(isMobile: isMobile),
        const SizedBox(height: 6),
        _retroQuickActions(),
        const SizedBox(height: 8),
        SizedBox(height: isMobile ? 260 : 320, child: _buildEditor(clean: false, isMobile: isMobile)),
        const SizedBox(height: 14),
        RetroButton(
          text: "COMPILE & RUN",
          icon: Icons.play_arrow,
          isFullWidth: true,
          isLoading: isRunningCode,
          bgColor: AppColors.forest,
          onPressed: () => _checkAuthAndExecute(_runJudge0Checker),
        ),
        if (testResults.isNotEmpty) ...[const SizedBox(height: 14), _retroConsole()],
        _retroResultBox(),
      ],
    );
  }

  Widget _retroConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1B242B), border: Border.all(color: AppColors.border, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TEST RESULTS & CONSOLE",
              style: TextStyle(color: AppColors.cloud, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          ...testResults.map((t) {
            final passed = t["passed"] == true;
            final c = passed ? AppColors.forest : AppColors.sunset;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF131A1F), border: Border.all(color: c, width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(passed ? Icons.check_circle : Icons.cancel, size: 14, color: c),
                      const SizedBox(width: 6),
                      Text("TEST ${t['index']}: ${passed ? 'PASSED (OK)' : 'FAILED'}",
                          style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                  if (!passed) ...[
                    const SizedBox(height: 4),
                    Text("EXPECTED: ${t['expected']}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                    Text("OUTPUT:   ${t['got']}", style: TextStyle(color: AppColors.sunset, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _retroResultBox() {
    if (!solutionChecked) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: solutionOk ? AppColors.forest : AppColors.sunset,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: AppStyle.hardShadow(3),
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