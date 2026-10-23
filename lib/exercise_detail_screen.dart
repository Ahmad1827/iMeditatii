import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'theme_manager.dart';
import 'classes_models.dart' show Classes, HwProblem, Solution;
import 'browser_run.dart';
import 'judge0.dart';
import 'math_sheet.dart';
import 'problem_quiz.dart';
import 'statement.dart';
import 'statement_text.dart';
import 'workspace_screen.dart' show wsAgo;
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
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

  /// Whether a typed short answer counts as the expected one.
  static bool answersMatch(String given, String expected) => _ExerciseDetailScreenState.answersMatch(given, expected);

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
  Solution? _sent; // maths: the solution sent to be checked, as it stands
  StreamSubscription? _sentSub;
  int _attemptsN = 0; // how many times it was sent, for the tab's count
  StreamSubscription? _attemptsSub;

  List<QuizQuestion> _quiz = const []; // the questions asked on opening the problem
  bool isFullScreenCode = false;
  bool isFullScreenProblem = false;
  String? _selectedGrilaOption;

  final String defaultCppBoilerplate =
      "#include <iostream>\nusing namespace std;\n\nint main() {\n    // Scrie codul aici\n    \n    return 0;\n}";

  /// A problem with files, like at the olympiad: its name, so the program
  /// reads `name.in` and writes `name.out` (the keyboard and screen don't count).
  String? get _file {
    final f = _str(['fisier', 'file'])?.trim();
    return f == null || f.isEmpty ? null : f;
  }

  String get _boilerplate => _file == null
      ? defaultCppBoilerplate
      : '#include <fstream>\nusing namespace std;\n\nifstream fin("$_file.in");\nofstream fout("$_file.out");\n\nint main() {\n    // Citește cu fin >> ..., scrie cu fout << ...\n    \n    return 0;\n}';

  /// Why a test of a problem with files has nothing to compare, if it's that.
  String _fileNote(RunResult r) {
    final f = _file;
    if (f == null || r.status == 'Compilation Error') return '';
    final screen = r.console.trim();
    if (r.noFile) {
      return screen.isEmpty
          ? 'Programul nu a creat $f.out. Rezultatul se scrie în fișierul $f.out, nu pe ecran.'
          : 'Ai afișat pe ecran ($screen), dar la această problemă rezultatul se scrie în $f.out.';
    }
    if (r.stdout.trim().isEmpty && screen.isNotEmpty) return 'Ai afișat pe ecran ($screen); în $f.out nu ai scris nimic.';
    return '';
  }

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _sentSub = Classes.solutions.doc(Classes.solutionId(uid, _progressKey)).snapshots().listen((d) {
        final s = d.data() == null ? null : Solution.fromJson(d.data()!);
        if (mounted) setState(() => _sent = s != null && s.isSheet ? s : null);
      }, onError: (_) {});
      _attemptsSub = Classes.attempts(uid, _progressKey).listen((l) {
        if (mounted) setState(() => _attemptsN = l.length);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _sentSub?.cancel();
    _attemptsSub?.cancel();
    if (_cFocus) Future.microtask(() => ThemeManager.focusNotifier.value = false); // not while the tree is locked
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

  /// Maths is solved on a sheet and checked by a person (see math_sheet.dart).
  bool get _isSheet => isMathSubject(widget.subject) && _kind != 'cod';

  HwProblem get _problem => HwProblem(id: widget.id, title: _title, subject: widget.subject, grade: widget.grade);

  Widget _sheet({bool fill = false}) => MathSheetPanel(
        problem: _problem,
        fill: fill,
        onAccepted: () {
          if (!_alreadyDone) _markExerciseAsDone();
        },
      );

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
    BrowserRun.warm('cpp'); // the student is writing code: load the compiler meanwhile
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
        _codeController.text = _boilerplate;
      });

  /// A problem with files starts from a program that opens them, unless something's written already.
  void _fileTemplate() {
    if (_file != null && _codeController.text.trim() == defaultCppBoilerplate.trim()) _codeController.text = _boilerplate;
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
  /// The problem's questions, asked as soon as it opens (they can be skipped).
  Future<void> _offerQuiz() async {
    final qs = await ProblemQuiz.load(widget.subject, widget.grade, widget.id, problem: exerciseData);
    if (!mounted || qs.isEmpty) return;
    setState(() => _quiz = qs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showProblemQuiz(context, qs);
    });
  }

  Future<void> _loadExerciseDetails() async {
    try {
      final String response = await rootBundle.loadString('assets/data/exercise_details.json');
      final data = json.decode(response);
      if (data[widget.subject] != null &&
          data[widget.subject][widget.grade] != null &&
          data[widget.subject][widget.grade][widget.id] != null) {
        if (!mounted) return;
        setState(() => exerciseData = data[widget.subject][widget.grade][widget.id]);
        _fileTemplate();
        _offerQuiz();
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
        _fileTemplate();
        _offerQuiz();
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

    // Clasament: fiecare problemă se numără o singură dată pe cont.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final solved = List<String>.from((snap.data()?['solvedIds'] as List?) ?? const []);
        if (solved.contains(_progressKey)) return;
        tx.set(
          ref,
          {
            'solvedIds': FieldValue.arrayUnion([_progressKey]),
            'solvedCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      debugPrint('Leaderboard sync: $e');
    }
  }

  /// Keeps what was sent, so a teacher can read it on the student's desk.
  void _saveSolution(String text, String? lang, bool passed) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;
    Classes.saveSolution(uid: uid, key: _progressKey, text: text, lang: lang, passed: passed).catchError((e) => debugPrint('Solution save: $e'));
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
  /// "− 12", "-12" and "-12,0" are the same answer; so are "1/2" and "0.5".
  static String _normAnswer(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[−–—]'), '-').replaceAll(',', '.').replaceAll(RegExp(r'\s+'), '');

  static double? _answerValue(String s) {
    final direct = double.tryParse(s);
    if (direct != null) return direct;
    final parts = s.split('/');
    if (parts.length != 2) return null;
    final a = double.tryParse(parts[0]), b = double.tryParse(parts[1]);
    return a == null || b == null || b == 0 ? null : a / b;
  }

  /// Program output against the expected output, the way judges compare it:
  /// spaces at the end of a line and blank lines at the end don't count.
  static String normOutput(String s) => s.replaceAll('\r', '').split('\n').map((l) => l.trimRight()).join('\n').trim();

  static bool answersMatch(String given, String expected) {
    final g = _normAnswer(given), e = _normAnswer(expected);
    if (g.isEmpty) return false;
    if (g == e) return true;
    final gv = _answerValue(g), ev = _answerValue(e);
    return gv != null && ev != null && (gv - ev).abs() < 1e-9;
  }

  void _checkSimpleAnswer() async {
    final isGrila = exerciseData!["tip_exercitiu"] == "grila";
    final raspunsCorect = exerciseData!["raspuns_corect"]?.toString() ?? '';
    final raspunsElev = isGrila ? (_selectedGrilaOption ?? '') : _answerController.text;
    // A multiple-choice option must be the very one marked correct, not just equal in value.
    final ok = isGrila
        ? raspunsElev.trim().toLowerCase() == raspunsCorect.trim().toLowerCase()
        : answersMatch(raspunsElev, raspunsCorect);

    setState(() {
      solutionChecked = true;
      solutionOk = ok;
    });
    _saveSolution(raspunsElev, null, ok);
    if (solutionOk) {
      setState(() => _cCheer++);
      await _markExerciseAsDone();
    }
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

        final result = await Judge0.run(code: code, stdin: inputData.toString(), file: _file);
        final got = normOutput(result.stdout);
        final normExpected = normOutput(expectedOutput.toString());
        final ok = got == normExpected;
        if (!ok) allPassed = false;
        final note = ok ? '' : _fileNote(result);

        testResults.add({"index": i + 1, "passed": ok, "expected": normExpected, "got": note.isEmpty ? got : '$got  [$note]'});
        if (mounted) setState(() {});
      }

      if (!mounted) return;
      setState(() {
        solutionChecked = true;
        solutionOk = allPassed;
      });
      _saveSolution(code, 'cpp', allPassed);
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
  // CLEAN — problem workspace (header bar + split panes + console)
  // ===========================================================================
  int _cTab = 0; // 0 enunț, 1 soluție, 2 trimiteri
  int _cBottom = 0; // 0 exemplu, 1 rezultat
  int _cSelTest = 0;
  bool _cLastWasRun = false;
  bool _cHintOpen = false;
  bool _whyOpen = false; // why the problem is at its level: it gives the idea away, so it waits for a tap
  bool _cShowSol = false;
  final List<Map<String, dynamic>> _cSubmissions = [];
  int _cCheer = 0; // bump -> the army cheers, dragons breathe fire
  bool _cHidden = false; // panes slid out to show the scene
  bool _cFocus = false; // focus mode: the editor alone, the statement and the terminal at hand
  bool _fStatement = false; // focus: the statement open beside the code
  bool _fTerminal = false; // focus: the terminal open under the code
  double _fStatementW = 420;
  double _fTerminalH = 240;
  final GlobalKey _cHeadKey = GlobalKey();
  final GlobalKey _cLeftKey = GlobalKey();
  final GlobalKey _cRightKey = GlobalKey();

  Widget _cSceneToggle() => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 6),
        child: Tooltip(
          message: _cHidden ? 'Arată problema' : 'Ascunde panourile și privește scena',
          child: PbButton(
            text: _cHidden ? 'Arată problema' : 'Scena',
            icon: _cHidden ? Icons.visibility_outlined : Icons.landscape_outlined,
            variant: PbVariant.outlineSecondary,
            size: PbSize.sm,
            onPressed: () => setState(() => _cHidden = !_cHidden),
          ),
        ),
      );

  Widget _buildClean(bool isMobile) {
    Widget shell(Widget body, {bool sky = true}) => Scaffold(
          backgroundColor: Pb.page,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: sky
                    ? HomeSky(
                        scene: HomeScene.fantasy,
                        cheerSignal: _cCheer,
                        blockers: [_cHeadKey, _cLeftKey, _cRightKey],
                        cardsHidden: _cHidden,
                        onToggleCards: _cHidden ? () => setState(() => _cHidden = false) : null,
                        showLabel: 'Arată problema',
                        child: body,
                      )
                    : body,
              ),
            ],
          ),
        );

    if (exerciseData == null) {
      return shell(const Center(child: CircularProgressIndicator(color: Pb.primary)), sky: false);
    }
    if (exerciseData!.isEmpty) {
      return shell(Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Pb.border.withOpacity(0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Problema nu a fost găsită.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Pb.text)),
              const SizedBox(height: 12),
              PbButton(text: 'Înapoi la probleme', onPressed: () => context.go('/exercitii')),
            ],
          ),
        ),
      ));
    }

    final tabContent = _cTab == 0 ? _cStatement() : (_cTab == 1 ? _cSolution() : _cSubmissionsList());
    final isCode = _kind == 'cod';
    if (_cFocus && isCode) return _cFocusView(isMobile);

    Widget slide(double dx, Widget child) => AnimatedSlide(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          offset: _cHidden ? Offset(dx, 0) : Offset.zero,
          child: IgnorePointer(ignoring: _cHidden, child: child),
        );

    final header = KeyedSubtree(key: _cHeadKey, child: _cHeader(isMobile));

    if (isMobile) {
      return shell(SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 14),
              slide(
                -1.4,
                KeyedSubtree(
                  key: _cLeftKey,
                  child: _cCard(child: Padding(padding: const EdgeInsets.all(16), child: tabContent)),
                ),
              ),
              const SizedBox(height: 14),
              slide(
                1.4,
                KeyedSubtree(
                  key: _cRightKey,
                  child: isCode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_cEditor(height: 340), const SizedBox(height: 14), _cConsole(fill: false)],
                        )
                      : (_isSheet ? _sheet() : _cAnswerPanel()),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ));
    }

    return shell(Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: slide(
                    -1.4,
                    KeyedSubtree(
                      key: _cLeftKey,
                      child: _cCard(
                        fill: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                          child: tabContent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: slide(
                    1.4,
                    KeyedSubtree(
                      key: _cRightKey,
                      child: isCode
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 3, child: _cEditor()),
                                const SizedBox(height: 14),
                                Expanded(flex: 2, child: _cConsole(fill: true)),
                              ],
                            )
                          : (_isSheet ? _sheet(fill: true) : SingleChildScrollView(child: _cAnswerPanel())),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // ---------------------------------------------------------------- building blocks
  Widget _cCard({Widget? header, required Widget child, bool fill = false}) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Pb.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Pb.border.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.07), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[header, Container(height: 1, color: Pb.border)],
            fill ? Expanded(child: child) : child,
          ],
        ),
      );

  Widget _cTabs(List<String> labels, int sel, ValueChanged<int> onSel, {List<String?>? counts}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onSel(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: i == sel ? Pb.primary : Colors.transparent, width: 2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: i == sel ? FontWeight.w600 : FontWeight.w400,
                        color: i == sel ? Pb.text : Pb.muted,
                      ),
                    ),
                    if (counts != null && i < counts.length && counts[i] != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(counts[i]!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Pb.muted)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- header
  Widget _cHeader(bool isMobile) {
    final listRoute = '/lista-exercitii?materie=${Uri.encodeComponent(widget.subject)}';
    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('/', style: TextStyle(fontSize: 13, color: Pb.muted)),
    );
    final title = Text(
      '${widget.id}. $_title',
      style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.w700, color: Pb.text, height: 1.2),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 20, 14, isMobile ? 14 : 20, 0),
      decoration: BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.07), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PbLink(text: 'Probleme', fontSize: 13, onTap: () => context.go('/exercitii')),
              sep,
              PbLink(text: widget.subject, fontSize: 13, onTap: () => context.go(listRoute)),
              sep,
              Text('Clasa a ${widget.grade}-a', style: TextStyle(fontSize: 13, color: Pb.muted)),
            ],
          ),
          const SizedBox(height: 8),
          if (isMobile) ...[
            title,
            const SizedBox(height: 10),
            _cChips(),
            const SizedBox(height: 12),
            _cStatus(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 10), _cChips()],
                  ),
                ),
                const SizedBox(width: 16),
                _cStatus(),
              ],
            ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _cTabs(
                    const ['Enunț', 'Soluție', 'Trimiterile mele'],
                    _cTab,
                    (i) => setState(() => _cTab = i),
                    counts: [null, null, _isSheet ? (_sent == null ? null : '${_attemptsN > 0 ? _attemptsN : 1}') : (_cSubmissions.isEmpty ? null : '${_cSubmissions.length}')],
                  ),
                ),
              ),
              _cSceneToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cStatus() {
    final sent = _isSheet ? _sent : null;
    if (sent != null && !sent.approved) {
      // maths sent to be checked: waiting (amber) or turned down (red)
      final bad = sent.rejected;
      final fg = bad ? Pb.dangerText : Pb.warningText;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bad ? Pb.dangerBg : Pb.warningBg,
          borderRadius: Pb.radius,
          border: Border.all(color: bad ? Pb.dangerBorder : Pb.warningBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bad ? Icons.cancel : Icons.hourglass_top_rounded, size: 20, color: fg),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bad ? 'Respinsă' : 'La verificare', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                Text(
                  bad ? 'Corectează și trimite din nou' : 'Trimisă ${wsAgo(sent.lastAt)}',
                  style: TextStyle(fontSize: 12.5, color: Pb.muted),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final done = _alreadyDone || (sent?.approved ?? false);
    final best = _cSubmissions
        .where((s) => s['submit'] == true)
        .fold<int>(0, (m, s) => (s['score'] as int) > m ? s['score'] as int : m);
    final sub = best > 0 ? 'Cel mai bun punctaj: $best/100' : (done ? 'Rezolvată anterior' : 'Încă nicio trimitere');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: done ? Pb.successBg : Pb.hoverBg,
        borderRadius: Pb.radius,
        border: Border.all(color: done ? Pb.successBorder : Pb.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: done ? Pb.successText : Pb.muted),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(done ? 'Rezolvată' : 'Nerezolvată',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: done ? Pb.successText : Pb.text)),
              Text(sub, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cChips() {
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
    final time = _str(['limita_timp', 'time_limit']);
    final mem = _str(['limita_memorie', 'memory_limit']);
    final tags = _list(['tags', 'etichete']) ?? const <String>[];
    final kind = _kind == 'cod' ? 'C++' : (_isSheet ? 'Pe foaie' : (_kind == 'grila' ? 'Grilă' : 'Răspuns scurt'));

    Widget chip(String label, {Color? fg, IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: (fg ?? Pb.muted).withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: fg ?? Pb.muted), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: fg ?? Pb.text)),
            ],
          ),
        );

    final why = _str(['dificultate_motiv']);
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (diffRaw != null) chip(AppStyle.sentence(diffRaw), fg: diffColor),
        chip(kind, icon: _kind == 'cod' ? Icons.code : (_isSheet ? Icons.draw_outlined : Icons.quiz_outlined)),
        if (_file != null) chip('$_file.in / $_file.out', icon: Icons.description_outlined),
        chip('Clasa a ${widget.grade}-a', icon: Icons.school_outlined),
        if (time != null) chip(time, icon: Icons.timer_outlined),
        if (mem != null) chip(mem, icon: Icons.memory),
        for (final t in tags) chip(t, icon: Icons.sell_outlined),
      ],
    );
    if (why == null) return chips; // the source is shown above the statement
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 15, color: Pb.muted)),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: Pb.muted))),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips,
        _whyOpen
            ? line(Icons.insights_outlined, 'De ce e ${diff.isEmpty ? 'la acest nivel' : diff}: $why')
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: PbLink(
                  text: 'De ce e ${diff.isEmpty ? 'la acest nivel' : diff}? (dă un indiciu)',
                  fontSize: 13,
                  onTap: () => setState(() => _whyOpen = true),
                ),
              ),
      ],
    );
  }

  // ---------------------------------------------------------------- left pane
  Widget _cStatement() {
    final input = _str(['input', 'date_intrare']);
    final output = _str(['output', 'date_iesire']);
    final cList = _list(['restrictii', 'constraints', 'restrictions']);
    final cText = _str(['restrictii', 'constraints', 'restrictions']);
    final hint = _str(['hint', 'indicatie']);
    final expl = _str(['explicatie', 'explanation']);
    final examples = _examples;
    final parts = StatementParts.of(exerciseData!, file: _file);
    final options = _isSheet && _kind == 'grila' ? (_list(['variante']) ?? const <String>[]) : const <String>[];
    // what explains the first example: its own field, then the statement's "Exemplu: ..." paragraphs
    final explained = [if (expl != null) expl, ...parts.examples];
    final source = parts.source.isNotEmpty ? parts.source : _str(['sursa']);
    final pictures = _list(['imagine_originala']) ?? [if (_str(['imagine_originala']) != null) _str(['imagine_originala'])!];

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (source != null || pictures.isNotEmpty) ...[_cOrigin(source, pictures), const SizedBox(height: 16)],
          if (_str(['nota_examen']) != null) ...[_cExamNote(_str(['nota_examen'])!), const SizedBox(height: 16)],
          if (_file != null) ...[
            PbAlert(
              type: PbAlertType.info,
              icon: Icons.description_outlined,
              text: 'Problemă cu fișiere: citești din $_file.in și scrii în $_file.out. Ce citești de la tastatură e gol, iar ce afișezi pe ecran nu se ia în calcul.',
            ),
            const SizedBox(height: 16),
          ],
          if (parts.context.isNotEmpty) ...[_cContext(parts.context), const SizedBox(height: 14)],
          _cTask(parts.body),
          if (options.isNotEmpty) _cSection('Variante de răspuns', Icons.checklist_rtl, _cOptions(options)),
          if (input != null || output != null) _cSection('Date', Icons.swap_horiz, _cInOut(input, output)),
          if (cList != null || cText != null) _cSection('Restricții', Icons.rule, _cConstraints(cList ?? [cText!])),
          for (var i = 0; i < examples.length; i++)
            _cSection(examples.length == 1 ? 'Exemplu' : 'Exemplul ${i + 1}', Icons.science_outlined, _cExample(examples[i], i == 0 ? explained : const [])),
          if (examples.isEmpty && explained.isNotEmpty) _cSection('Exemplu', Icons.science_outlined, _cExplanation(explained)),
          if (hint != null) _cHint(hint),
          if (_quiz.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: PbButton(
                text: 'Întrebări ajutătoare (${_quiz.length})',
                icon: Icons.quiz_outlined,
                variant: PbVariant.outlineSecondary,
                size: PbSize.sm,
                onPressed: () => showProblemQuiz(context, _quiz),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cSection(String title, IconData icon, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: Pb.primary),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  /// Where the problem comes from, and the page of the paper it was set on.
  Widget _cOrigin(String? source, List<String> pictures) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
        child: Row(
          children: [
            Icon(source != null && source.startsWith('BAC') ? Icons.history_edu_outlined : Icons.emoji_events_outlined, size: 18, color: Pb.muted),
            const SizedBox(width: 10),
            Expanded(child: Text(source ?? 'Subiectul original', style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.4, fontWeight: FontWeight.w500))),
            if (pictures.isNotEmpty) ...[
              const SizedBox(width: 8),
              PbButton(
                text: 'Subiectul original',
                icon: Icons.image_outlined,
                variant: PbVariant.outlineSecondary,
                size: PbSize.sm,
                onPressed: () => _showOriginal(pictures, source),
              ),
            ],
          ],
        ),
      );

  void _showOriginal(List<String> pictures, String? source) => showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (d) => Dialog(
          backgroundColor: Pb.surface,
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 6, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(source ?? 'Subiectul original', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
                      ),
                      IconButton(tooltip: 'Închide', icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(d).pop()),
                    ],
                  ),
                ),
                Container(height: 1, color: Pb.border),
                Flexible(
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: SingleChildScrollView(
                      child: Container(
                        color: Colors.white, // the paper is white in the dark theme too
                        padding: const EdgeInsets.all(8),
                        child: Column(children: [for (final p in pictures) Image.asset(p, fit: BoxFit.fitWidth, width: double.infinity)]),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: Text('Din varianta oficială a Ministerului Educației. Mărește cu două degete sau cu rotița.',
                      style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                ),
              ],
            ),
          ),
        ),
      );

  /// What was different at the exam (a file instead of the keyboard, the
  /// algorithm described in words), so the task above it can say only what to do here.
  Widget _cExamNote(String note) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 16, color: Pb.muted)),
          const SizedBox(width: 8),
          Expanded(child: StatementText(note, fontSize: 13.5, height: 1.5, color: Pb.muted)),
        ],
      );

  /// The story and the definitions: what the words of the task mean.
  Widget _cContext(List<String> paragraphs) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: Icon(Icons.menu_book_outlined, size: 18, color: Pb.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, p) in paragraphs.indexed)
                    Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 10), child: StatementText(p, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );

  /// What the student has to do, on a card of its own.
  Widget _cTask(List<String> paragraphs) => ClipRRect(
        borderRadius: BorderRadius.circular(12), // a one-sided border can't be rounded itself
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Pb.primary.withOpacity(AppColors.isDark ? 0.10 : 0.05),
            border: const Border(left: BorderSide(color: Pb.primary, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CERINȚA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Pb.primary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              if (paragraphs.isEmpty) Text('Fără enunț.', style: TextStyle(fontSize: 15.5, color: Pb.muted)),
              for (final (i, p) in paragraphs.indexed)
                Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 12), child: StatementText(p, fontSize: 16)),
            ],
          ),
        ),
      );

  /// A maths multiple-choice problem's options, A to D, as on the paper.
  Widget _cOptions(List<String> options) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth >= 440 ? (c.maxWidth - 10) / 2 : c.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, o) in options.indexed)
                Container(
                  width: w,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Pb.primary.withOpacity(0.12), shape: BoxShape.circle),
                        child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Pb.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: StatementText(o, fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
            ],
          );
        },
      );

  /// What is read and what is written, side by side.
  Widget _cInOut(String? input, String? output) {
    Widget card(IconData icon, Color tint, String label, String text) => Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Pb.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: tint.withOpacity(0.13), borderRadius: BorderRadius.circular(7)),
                    child: Icon(icon, size: 15, color: tint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text))),
                ],
              ),
              const SizedBox(height: 8),
              StatementText(text, fontSize: 14.5, height: 1.6),
            ],
          ),
        );
    final cards = [
      if (input != null) card(Icons.login, const Color(0xFF2563EB), _file == null ? 'Date de intrare' : 'Date de intrare · $_file.in', input),
      if (output != null) card(Icons.logout, Pb.primary, _file == null ? 'Date de ieșire' : 'Date de ieșire · $_file.out', output),
    ];
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 480 && cards.length == 2
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: cards[0]), const SizedBox(width: 10), Expanded(child: cards[1])],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final (i, c) in cards.indexed) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 10), child: c)],
            ),
    );
  }

  /// The limits, one chip each.
  Widget _cConstraints(List<String> items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final it in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Pb.codeBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Pb.border)),
              child: StatementText.line(it, TextStyle(fontSize: 14, height: 1.45, color: Pb.text)),
            ),
        ],
      );

  /// One example: what goes in and what comes out side by side (named after
  /// the files when the problem has them), with what explains it underneath.
  Widget _cExample(Map<String, String> ex, List<String> explanation) {
    Widget box(IconData icon, String label, String v) => Container(
          decoration: BoxDecoration(color: Pb.codeBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: Pb.muted),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.muted)),
                  ],
                ),
              ),
              Container(height: 1, color: Pb.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(v.isEmpty ? ' ' : v, style: Pb.mono(14, color: Pb.text)),
                ),
              ),
            ],
          ),
        );
    final input = box(Icons.login, _file == null ? 'Intrare' : '$_file.in', ex['input']!);
    final output = box(Icons.logout, _file == null ? 'Ieșire' : '$_file.out', ex['output']!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 440
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: input),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 18, color: Pb.muted)),
                      Expanded(child: output),
                    ],
                  ),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [input, const SizedBox(height: 10), output]),
        ),
        if (explanation.isNotEmpty) ...[const SizedBox(height: 10), _cExplanation(explanation)],
      ],
    );
  }

  Widget _cExplanation(List<String> paragraphs) => ClipRRect(
        borderRadius: BorderRadius.circular(10), // a one-sided border can't be rounded itself
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.06),
            border: const Border(left: BorderSide(color: Color(0xFF2563EB), width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "Exemplu (cerința 3): ..." is a case of its own, not this example explained
              Text(paragraphs.every((p) => p.startsWith('Exemplu (')) ? 'Alt exemplu' : 'De ce',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
              const SizedBox(height: 6),
              for (final (i, p) in paragraphs.indexed)
                Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 8), child: StatementText(p, fontSize: 14.5, height: 1.6)),
            ],
          ),
        ),
      );

  Widget _cHint(String hint) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _cHintOpen = !_cHintOpen),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Pb.muted),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Indiciu', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text))),
                        Icon(_cHintOpen ? Icons.expand_less : Icons.expand_more, color: Pb.muted),
                      ],
                    ),
                  ),
                ),
              ),
              if (_cHintOpen) ...[
                Container(height: 1, color: Pb.border),
                Padding(padding: const EdgeInsets.all(14), child: StatementText(hint, fontSize: 15, height: 1.6)),
              ],
            ],
          ),
        ),
      );

  Widget _cSolution() {
    final off = exerciseData!['official_solution'];
    final code = off is Map ? off['code']?.toString() : null;
    final worked = _str(['solutie', 'rezolvare']); // maths: a worked solution in words

    if (code == null && worked == null) {
      return Text('Problema nu are încă o soluție oficială.', style: TextStyle(fontSize: 15, color: Pb.muted));
    }
    if (!_alreadyDone && !_cShowSol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 28, color: Pb.muted),
          const SizedBox(height: 10),
          Text('Soluția oficială e ascunsă până rezolvi problema.',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Pb.text)),
          const SizedBox(height: 6),
          Text('Încearcă mai întâi singur. O poți deschide oricând.', style: TextStyle(fontSize: 14, color: Pb.muted)),
          const SizedBox(height: 14),
          PbButton(
            text: 'Arată soluția',
            variant: PbVariant.outlineSecondary,
            size: PbSize.sm,
            onPressed: () => setState(() => _cShowSol = true),
          ),
        ],
      );
    }
    if (code == null) {
      final answer = exerciseData!['raspuns_corect']?.toString();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionArea(child: StatementText(worked!, fontSize: 15.5, height: 1.7)),
          if (answer != null && answer.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Pb.successBg, borderRadius: Pb.radius, border: Border.all(color: Pb.successBorder)),
              child: StatementText('**Răspuns:** $answer', fontSize: 15, height: 1.5, color: Pb.successText),
            ),
          ],
        ],
      );
    }
    return PbCodeBox(code, lang: 'cpp', fontSize: 14);
  }

  Widget _cSubmissionsList() {
    if (_isSheet) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || _sent == null) return Text('Nu ai trimis încă o rezolvare.', style: TextStyle(fontSize: 14.5, color: Pb.muted));
      return SheetHistory(uid: uid, problemKey: _progressKey, current: _sent);
    }
    if (_cSubmissions.isEmpty) {
      return Text('Nu ai trimis încă nicio soluție în această sesiune.', style: TextStyle(fontSize: 14.5, color: Pb.muted));
    }
    return PbTable(
      headers: const ['Ora', 'Tip', 'Verdict', 'Teste', 'Punctaj'],
      rows: [
        for (final s in _cSubmissions)
          [
            Text('${s['time']}'),
            Text(s['submit'] == true ? 'Trimitere' : 'Rulare'),
            Text(
              s['ok'] == true
                  ? (s['submit'] == true ? 'Acceptat' : 'Exemple corecte')
                  : (s['submit'] == true ? 'Respins' : 'Exemple greșite'),
              style: TextStyle(fontWeight: FontWeight.w600, color: s['ok'] == true ? Pb.success : Pb.danger),
            ),
            Text('${s['passed']}/${s['total']}'),
            Text(s['submit'] == true ? '${s['score']}' : '–'),
          ],
      ],
    );
  }

  // ---------------------------------------------------------------- editor
  Widget _cEditor({double? height}) {
    final fill = height == null;

    Widget iconBtn(IconData i, String tip, VoidCallback f) => IconButton(
          icon: Icon(i, size: 18),
          color: Pb.muted,
          tooltip: tip,
          splashRadius: 18,
          visualDensity: VisualDensity.compact,
          onPressed: f,
        );

    final header = SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Pb.hoverBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Pb.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 15, color: Pb.primary),
                  const SizedBox(width: 6),
                  Text('C++ 20', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
                ],
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: 'Inserează',
              color: Pb.surface,
              icon: Icon(Icons.add_box_outlined, size: 18, color: Pb.muted),
              onSelected: (v) {
                switch (v) {
                  case 'cin':
                    _insertSnippet("cin >> ", ";");
                    break;
                  case 'cout':
                    _insertSnippet("cout << ", " << \"\\n\";");
                    break;
                  case 'for':
                    _insertSnippet("for (int i = 0; i < n; i++) {\n    ", "\n}");
                    break;
                  case 'tab':
                    _insertSnippet("    ", "");
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'cin', child: Text('cin >> x;', style: Pb.mono(13))),
                PopupMenuItem(value: 'cout', child: Text('cout << x;', style: Pb.mono(13))),
                PopupMenuItem(value: 'for', child: Text('for (...) { }', style: Pb.mono(13))),
                PopupMenuItem(value: 'tab', child: Text('Tab (4 spații)', style: TextStyle(fontSize: 13, color: Pb.text))),
              ],
            ),
            iconBtn(Icons.fullscreen, 'Mod focus', _cEnterFocus),
            iconBtn(Icons.undo, 'Anulează (Ctrl+Z)', _performUndo),
            iconBtn(Icons.redo, 'Refă (Ctrl+Y)', _performRedo),
            iconBtn(Icons.restart_alt, 'Resetează codul', _resetCode),
          ],
        ),
      ),
    );

    final footer = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text('Ln ${_getCurrentLine()}, Col ${_getCurrentCol()}', style: TextStyle(color: Pb.muted, fontSize: 12.5)),
          ),
          PbButton(
            text: 'Rulează',
            icon: Icons.play_arrow,
            variant: PbVariant.outlineSecondary,
            size: PbSize.sm,
            onPressed: isRunningCode ? null : () => _checkAuthAndExecute(() => _cRun(submit: false)),
          ),
          const SizedBox(width: 8),
          PbButton(
            text: isRunningCode ? 'Se evaluează...' : 'Trimite',
            icon: Icons.cloud_upload_outlined,
            variant: PbVariant.success,
            size: PbSize.sm,
            loading: isRunningCode,
            onPressed: isRunningCode ? null : () => _checkAuthAndExecute(() => _cRun(submit: true)),
          ),
        ],
      ),
    );

    final editor = _buildEditor(clean: true, isMobile: !fill);

    return _cCard(
      header: header,
      fill: fill,
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fill ? Expanded(child: editor) : SizedBox(height: height, child: editor),
          Container(height: 1, color: Pb.border),
          footer,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- console
  Widget _cConsole({required bool fill}) {
    final passed = testResults.where((t) => t['passed'] == true).length;
    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _cTabs(
        const ['Exemplu', 'Rezultat'],
        _cBottom,
        (i) => setState(() => _cBottom = i),
        counts: [null, testResults.isEmpty ? null : '$passed/${testResults.length}'],
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.all(14),
      child: _cBottom == 0 ? _cSampleView() : _cResultView(),
    );
    return _cCard(header: header, fill: fill, child: fill ? SingleChildScrollView(child: body) : body);
  }

  // ---------------------------------------------------------------- focus mode
  //   The editor takes the screen. The statement waits in a bar on the left
  //   (open it to reread, close it again), and the console is a terminal at the
  //   bottom that opens by itself on Rulează or Trimite.
  void _cEnterFocus() {
    setState(() {
      _cFocus = true;
      _fTerminal = testResults.isNotEmpty || isRunningCode;
    });
    ThemeManager.focusNotifier.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _editorFocusNode.requestFocus());
  }

  void _cExitFocus() {
    setState(() => _cFocus = false);
    ThemeManager.focusNotifier.value = false;
  }

  void _fRun({required bool submit}) {
    if (isRunningCode) return;
    setState(() => _fTerminal = true);
    _checkAuthAndExecute(() => _cRun(submit: submit));
  }

  Widget _cFocusView(bool isMobile) {
    final size = MediaQuery.of(context).size;
    final passed = testResults.where((t) => t['passed'] == true).length;

    Widget iconBtn(IconData i, String tip, VoidCallback f, {bool on = false}) => IconButton(
          icon: Icon(i, size: 19),
          color: on ? Pb.primary : Pb.muted,
          tooltip: tip,
          splashRadius: 18,
          visualDensity: VisualDensity.compact,
          onPressed: f,
        );

    final bar = Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12),
      decoration: BoxDecoration(color: Pb.surface, border: Border(bottom: BorderSide(color: Pb.border))),
      child: Row(
        children: [
          iconBtn(Icons.fullscreen_exit, 'Ieși din modul focus (Esc)', _cExitFocus),
          iconBtn(Icons.article_outlined, _fStatement ? 'Ascunde enunțul' : 'Arată enunțul', () => setState(() => _fStatement = !_fStatement), on: _fStatement),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${widget.id}. $_title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text),
            ),
          ),
          if (!isMobile) ...[
            if (_file != null) ...[
              Icon(Icons.insert_drive_file_outlined, size: 15, color: Pb.muted),
              const SizedBox(width: 4),
              Text('$_file.in → $_file.out', style: Pb.mono(12.5, color: Pb.muted)),
              const SizedBox(width: 14),
            ],
            Text('Ln ${_getCurrentLine()}, Col ${_getCurrentCol()}', style: TextStyle(color: Pb.muted, fontSize: 12.5)),
            const SizedBox(width: 6),
            iconBtn(Icons.undo, 'Anulează (Ctrl+Z)', _performUndo),
            iconBtn(Icons.redo, 'Refă (Ctrl+Y)', _performRedo),
            const SizedBox(width: 6),
          ],
          isMobile
              ? iconBtn(Icons.play_arrow, 'Rulează (Ctrl+Enter)', () => _fRun(submit: false))
              : PbButton(
                  text: 'Rulează',
                  icon: Icons.play_arrow,
                  variant: PbVariant.outlineSecondary,
                  size: PbSize.sm,
                  onPressed: isRunningCode ? null : () => _fRun(submit: false),
                ),
          const SizedBox(width: 8),
          PbButton(
            text: isMobile ? 'Trimite' : (isRunningCode ? 'Se evaluează...' : 'Trimite'),
            icon: Icons.cloud_upload_outlined,
            variant: PbVariant.success,
            size: PbSize.sm,
            loading: isRunningCode,
            onPressed: isRunningCode ? null : () => _fRun(submit: true),
          ),
        ],
      ),
    );

    // The statement: a slim bar when closed, a panel to reread it when open.
    final statementBar = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _fStatement = true),
        child: Container(
          width: 38,
          decoration: BoxDecoration(color: Pb.surface, border: Border(right: BorderSide(color: Pb.border))),
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              Icon(Icons.chevron_right, size: 18, color: Pb.muted),
              const SizedBox(height: 10),
              RotatedBox(
                quarterTurns: 1,
                child: Text('ENUNȚ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: Pb.muted)),
              ),
            ],
          ),
        ),
      ),
    );
    final statementPanel = Container(
      color: Pb.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Pb.border))),
            child: Row(
              children: [
                Icon(Icons.article_outlined, size: 16, color: Pb.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Enunț', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Pb.text))),
                iconBtn(isMobile ? Icons.close : Icons.chevron_left, 'Ascunde enunțul', () => setState(() => _fStatement = false)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: _cStatement(),
            ),
          ),
        ],
      ),
    );

    // The terminal: a strip when closed (with the last result), the console when open.
    final termHeader = Container(
      height: 38,
      padding: const EdgeInsets.only(left: 6, right: 4),
      decoration: BoxDecoration(
        color: Pb.editorGutter,
        border: Border(top: BorderSide(color: Pb.border), bottom: _fTerminal ? BorderSide(color: Pb.border) : BorderSide.none),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.terminal, size: 16, color: Pb.muted),
          ),
          if (_fTerminal)
            _cTabs(
              const ['Exemplu', 'Rezultat'],
              _cBottom,
              (i) => setState(() => _cBottom = i),
              counts: [null, testResults.isEmpty ? null : '$passed/${testResults.length}'],
            )
          else
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _fTerminal = true),
                  child: Row(
                    children: [
                      Text('Terminal', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
                      const SizedBox(width: 12),
                      if (isRunningCode)
                        Text('se rulează...', style: TextStyle(fontSize: 13, color: Pb.muted))
                      else if (testResults.isNotEmpty) ...[
                        Icon(solutionOk ? Icons.check_circle : Icons.cancel, size: 15, color: solutionOk ? Pb.success : Pb.danger),
                        const SizedBox(width: 5),
                        Text('$passed/${testResults.length} teste', style: TextStyle(fontSize: 13, color: Pb.muted)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (_fTerminal) const Spacer(),
          iconBtn(
            _fTerminal ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            _fTerminal ? 'Închide terminalul' : 'Deschide terminalul',
            () => setState(() => _fTerminal = !_fTerminal),
          ),
        ],
      ),
    );
    final maxTerm = size.height * 0.7;
    final termH = _fTerminalH.clamp(120.0, maxTerm < 120 ? 120.0 : maxTerm);
    final terminal = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fTerminal)
          MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) => setState(() => _fTerminalH = (termH - d.delta.dy).clamp(120.0, maxTerm)),
              child: const SizedBox(height: 6),
            ),
          ),
        termHeader,
        if (_fTerminal)
          Container(
            height: termH,
            color: Pb.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: _cBottom == 0 ? _cSampleView() : _cResultView(),
            ),
          ),
      ],
    );

    final code = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Expanded(child: _buildEditor(clean: true, isMobile: isMobile)), terminal],
    );

    final maxW = size.width * 0.6;
    final statementW = _fStatementW.clamp(260.0, maxW < 260 ? 260.0 : maxW);
    final Widget body = isMobile
        ? Stack(
            children: [
              Positioned.fill(child: code),
              if (_fStatement) Positioned.fill(child: statementPanel),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_fStatement) ...[
                SizedBox(width: statementW, child: statementPanel),
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) => setState(() => _fStatementW = (statementW + d.delta.dx).clamp(260.0, maxW)),
                    child: Container(width: 6, color: Pb.border),
                  ),
                ),
              ] else
                statementBar,
              Expanded(child: code),
            ],
          );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _cExitFocus,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _fRun(submit: false),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () => _fRun(submit: false),
      },
      child: Scaffold(
        backgroundColor: Pb.editorBg,
        body: SafeArea(child: Column(children: [bar, Expanded(child: body)])),
      ),
    );
  }

  Widget _cSampleView() {
    final ex = _examples;
    if (ex.isEmpty) {
      return Text('Problema nu are un exemplu public.', style: TextStyle(fontSize: 14, color: Pb.muted));
    }
    Widget box(String label, String v) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Pb.muted)),
            const SizedBox(height: 4),
            PbCodeBox(v, fontSize: 13.5),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: box('Intrare', ex.first['input']!)),
            const SizedBox(width: 12),
            Expanded(child: box('Ieșire așteptată', ex.first['output']!)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '„Rulează” verifică doar exemplele. „Trimite” rulează toate testele și îți salvează progresul.',
          style: TextStyle(fontSize: 12.5, color: Pb.muted, height: 1.4),
        ),
      ],
    );
  }

  Widget _cResultView() {
    final total = testResults.length;
    if (total == 0 && !isRunningCode) {
      return Text('Rulează sau trimite soluția ca să vezi rezultatele aici.', style: TextStyle(fontSize: 14, color: Pb.muted));
    }
    final passed = testResults.where((t) => t['passed'] == true).length;

    final Widget banner = isRunningCode
        ? Row(
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)),
              const SizedBox(width: 10),
              Text('Se rulează testele... ($total gata)', style: TextStyle(fontSize: 14, color: Pb.muted)),
            ],
          )
        : Row(
            children: [
              Icon(solutionOk ? Icons.check_circle : Icons.cancel, size: 26, color: solutionOk ? Pb.success : Pb.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cLastWasRun
                          ? (solutionOk ? 'Exemplele trec' : 'Exemplele nu trec')
                          : (solutionOk ? 'Acceptat. Felicitări!' : 'Respins'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: solutionOk ? Pb.success : Pb.danger),
                    ),
                    Text(
                      '$passed din $total teste corecte${_cLastWasRun || total == 0 ? '' : ', punctaj ${(passed * 100 / total).round()}'}',
                      style: TextStyle(fontSize: 13, color: Pb.muted),
                    ),
                  ],
                ),
              ),
            ],
          );

    if (total == 0) return banner;

    final sel = _cSelTest >= total ? 0 : _cSelTest;
    final t = testResults[sel];
    final visible = t['sample'] == true;

    Widget detailBox(String label, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Pb.muted)),
              const SizedBox(height: 4),
              PbCodeBox(v.isEmpty ? '(nimic)' : v, fontSize: 13.5),
            ],
          ),
        );

    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible) ...[
          detailBox('Intrare', '${t['input'] ?? ''}'),
          detailBox('Ieșire așteptată', '${t['expected']}'),
          detailBox('Ieșirea ta', '${t['got']}'),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: Pb.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Test ascuns: datele nu sunt afișate.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                ),
              ],
            ),
          ),
        if ('${t['note'] ?? ''}'.isNotEmpty) detailBox('De ce nu e corect', '${t['note']}'),
        if ('${t['error'] ?? ''}'.isNotEmpty) detailBox('Erori de compilare / execuție', '${t['error']}'),
      ],
    );

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (var i = 0; i < total; i++) _cTestTile(i, testResults[i], i == sel)],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth < 420
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [list, const SizedBox(height: 10), detail])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 150, child: list),
                    const SizedBox(width: 14),
                    Expanded(child: detail),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _cTestTile(int i, Map<String, dynamic> t, bool sel) {
    final ok = t['passed'] == true;
    final sample = t['sample'] == true;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _cSelTest = i),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? Pb.hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: sel ? Pb.border : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.cancel, size: 16, color: ok ? Pb.success : Pb.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(sample ? 'Exemplu ${i + 1}' : 'Test ${i + 1}', style: TextStyle(fontSize: 13.5, color: Pb.text)),
              ),
              if (!sample) Icon(Icons.lock_outline, size: 13, color: Pb.muted),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- run / submit
  Future<void> _cRun({required bool submit}) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final sampleCount = _examples.length;
    final tests = <Map<String, String>>[
      for (final ex in _examples) {'input': ex['input']!, 'output': ex['output']!},
      if (submit && exerciseData?['tests'] is List)
        for (final t in exerciseData!['tests'] as List)
          if (t is Map) {'input': '${t['input'] ?? ''}', 'output': '${t['output'] ?? ''}'},
    ];

    setState(() {
      isRunningCode = true;
      solutionChecked = false;
      solutionOk = false;
      testResults.clear();
      _cBottom = 1;
      _cSelTest = 0;
      _cLastWasRun = !submit;
    });

    if (tests.isEmpty) {
      setState(() {
        isRunningCode = false;
        solutionChecked = true;
        testResults.add({'index': 1, 'passed': false, 'sample': true, 'input': '', 'expected': 'teste definite', 'got': 'problema nu are teste', 'error': ''});
      });
      return;
    }

    var all = true;
    try {
      for (var i = 0; i < tests.length; i++) {
        final r = await Judge0.run(code: code, stdin: tests[i]['input'] ?? '', file: _file);
        final got = normOutput(r.stdout);
        final err = r.error.replaceAll('\r', '').trim();
        final exp = normOutput(tests[i]['output']!);
        final ok = got == exp;
        final note = ok ? '' : _fileNote(r);
        if (!ok) all = false;

        testResults.add({
          'index': i + 1,
          'passed': ok,
          'sample': i < sampleCount,
          'input': tests[i]['input'],
          'expected': exp,
          'got': got,
          'error': err,
          'note': note,
        });
        if (mounted) setState(() {});
      }
    } catch (e) {
      all = false;
      testResults.add({'index': testResults.length + 1, 'passed': false, 'sample': true, 'input': '', 'expected': 'fără erori', 'got': '', 'error': '$e'});
    }

    if (!mounted) return;
    final passed = testResults.where((t) => t['passed'] == true).length;
    final score = (passed * 100 / testResults.length).round();

    setState(() {
      isRunningCode = false;
      solutionChecked = true;
      solutionOk = all;
      _cSubmissions.insert(0, {
        'time': TimeOfDay.now().format(context),
        'submit': submit,
        'ok': all,
        'score': score,
        'passed': passed,
        'total': testResults.length,
      });
    });

    if (submit) _saveSolution(code, 'cpp', all);
    if (submit && all) {
      setState(() => _cCheer++);
      await _markExerciseAsDone();
    }
  }

  // ---------------------------------------------------------------- grilă / răspuns scurt
  Widget _cAnswerPanel() {
    final isGrila = _kind == 'grila';
    final List<dynamic> variante = exerciseData!['variante'] ?? [];

    return _cCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isGrila ? 'Alege un răspuns' : 'Răspunsul tău',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
            const SizedBox(height: 4),
            Text(isGrila ? 'Un singur răspuns este corect.' : 'Scrie doar valoarea cerută.',
                style: TextStyle(fontSize: 13.5, color: Pb.muted)),
            const SizedBox(height: 14),
            if (isGrila)
              ...[for (var i = 0; i < variante.length; i++) _cOption(i, variante[i].toString())]
            else
              TextField(
                controller: _answerController,
                style: TextStyle(fontSize: 16, color: Pb.text),
                cursorColor: Pb.text,
                decoration: Pb.input(hint: 'Scrie răspunsul aici'),
                onSubmitted: (_) => _checkAuthAndExecute(_checkSimpleAnswer),
              ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: PbButton(
                text: 'Verifică',
                variant: PbVariant.success,
                onPressed: isGrila && _selectedGrilaOption == null ? null : () => _checkAuthAndExecute(_checkSimpleAnswer),
              ),
            ),
            if (solutionChecked) ...[
              const SizedBox(height: 14),
              PbAlert(
                type: solutionOk ? PbAlertType.success : PbAlertType.danger,
                text: solutionOk ? 'Răspuns corect. Problema e marcată ca rezolvată.' : 'Răspuns greșit. Mai încearcă.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cOption(int i, String text) {
    final sel = _selectedGrilaOption == text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _checkAuthAndExecute(() => setState(() => _selectedGrilaOption = text)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? Pb.primary.withOpacity(0.08) : Pb.surface,
              borderRadius: Pb.radius,
              border: Border.all(color: sel ? Pb.primary : Pb.border, width: sel ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? Pb.primary : Pb.hoverBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    String.fromCharCode(65 + i),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : Pb.text),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: Pb.text, height: 1.4))),
              ],
            ),
          ),
        ),
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
                                  StatementText(exerciseData!["description"]?.toString() ?? "",
                                      fontSize: 16, color: AppColors.ink, height: 1.6, weight: FontWeight.w600),
                                  if (exerciseData!["input"] != null) ...[
                                    const SizedBox(height: 20),
                                    _retroSpecBlock(_file == null ? "INPUT FORMAT" : "INPUT FILE: $_file.in", exerciseData!["input"].toString(), isMobile),
                                    const SizedBox(height: 14),
                                    _retroSpecBlock(_file == null ? "OUTPUT FORMAT" : "OUTPUT FILE: $_file.out", exerciseData!["output"]?.toString() ?? "-", isMobile),
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
        if (_str(['sursa']) != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
            child: Text(_str(['sursa'])!.toUpperCase(),
                style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.6)),
          ),
        ],
        if (_str(['dificultate_motiv']) != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _whyOpen = !_whyOpen),
            child: Text(
                _whyOpen
                    ? '${(_str(['dificultate', 'difficulty']) ?? 'Nivel').toUpperCase()}: ${_str(['dificultate_motiv'])}'
                    : 'DE CE E ${(_str(['dificultate', 'difficulty']) ?? 'LA ACEST NIVEL').toUpperCase()}? APASĂ PENTRU INDICIU',
                style: TextStyle(
                    fontSize: isMobile ? 12.5 : 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    decoration: _whyOpen ? null : TextDecoration.underline)),
          ),
        ],
        SizedBox(height: isMobile ? 14 : 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: AppColors.sunset,
          child: const Text("DESCRIPTION",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 10),
        StatementText(
          exerciseData!["description"]?.toString() ?? "Fără descriere disponibilă.",
          fontSize: isMobile ? 15 : 18,
          color: AppColors.ink,
          weight: FontWeight.w600,
          height: 1.55,
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
                  child: StatementText(exerciseData!["hint"].toString(),
                      fontSize: isMobile ? 13 : 16, color: AppColors.ink, weight: FontWeight.bold, height: 1.4),
                ),
              ],
            ),
          ),
        ],
        if (exerciseData!["tip_exercitiu"] == "cod" || exerciseData!["input"] != null) ...[
          SizedBox(height: isMobile ? 18 : 28),
          Container(height: 2, color: AppColors.border),
          SizedBox(height: isMobile ? 14 : 20),
          _retroSpecBlock(_file == null ? "INPUT FORMAT" : "INPUT FILE: $_file.in", exerciseData!["input"]?.toString() ?? "-", isMobile),
          const SizedBox(height: 12),
          _retroSpecBlock(_file == null ? "OUTPUT FORMAT" : "OUTPUT FILE: $_file.out", exerciseData!["output"]?.toString() ?? "-", isMobile),
        ],
        if (_quiz.isNotEmpty) ...[
          SizedBox(height: isMobile ? 16 : 22),
          RetroButton(
            text: "ÎNTREBĂRI AJUTĂTOARE (${_quiz.length})",
            icon: Icons.quiz_outlined,
            bgColor: AppColors.mustard,
            textColor: AppColors.ink,
            fontSize: 13,
            onPressed: () => showProblemQuiz(context, _quiz),
          ),
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
          child: StatementText(content, fontSize: isMobile ? 13 : 16, color: AppColors.ink, weight: FontWeight.w700, height: 1.4),
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
          if (_isSheet)
            _sheet()
          else if (_kind == "grila")
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