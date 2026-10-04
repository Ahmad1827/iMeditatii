import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, PbAlert, PbAlertType;

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final double padding;
  final double shadowOffset;
  final Color? borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = bgColor ?? AppColors.cardBg;
    final effectiveBorder = borderColor ?? AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(color: effectiveBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final bool isLoading;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
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
    final effectiveBg = widget.bgColor ?? AppColors.sunset;
    final effectiveTextColor = widget.textColor ?? Colors.white;

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
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.isLoading ? Colors.grey : effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: widget.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(
                  widget.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: effectiveTextColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
        ),
      ),
    );
  }
}

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedSubject = 'Matematică';
  String _selectedGrade = '9';
  String _selectedType = 'text';

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _correctAnswerController = TextEditingController();
  final TextEditingController _varAController = TextEditingController();
  final TextEditingController _varBController = TextEditingController();
  final TextEditingController _varCController = TextEditingController();
  final TextEditingController _varDController = TextEditingController();
  final TextEditingController _inputFormatController = TextEditingController();
  final TextEditingController _outputFormatController = TextEditingController();
  final TextEditingController _solutionCodeController = TextEditingController();

  final List<Map<String, TextEditingController>> _testCases = [
    {'input': TextEditingController(), 'output': TextEditingController()}
  ];

  bool _isSaving = false;

  final List<String> subjects = ['Matematică', 'Informatică', 'Istorie', 'Fizică', 'Română', 'Biologie'];
  final List<String> grades = ['5', '6', '7', '8', '9', '10', '11', '12'];
  final Map<String, String> types = {
    'text': 'Răspuns Scurt',
    'grila': 'Grilă (4 variante)',
    'cod': 'Problemă de Programare',
  };

  // ---- clean state
  String _difficulty = 'medie';
  int? _correctIdx;
  String? _error;
  final GlobalKey _mainKey = GlobalKey();

  List<TextEditingController> get _opts => [_varAController, _varBController, _varCController, _varDController];

  @override
  void initState() {
    super.initState();
    // live preview
    for (final c in [_categoryController, _titleController, _descController, _correctAnswerController, ..._opts, _inputFormatController, _outputFormatController]) {
      c.addListener(_refresh);
    }
    for (final tc in _testCases) {
      tc['input']!.addListener(_refresh);
      tc['output']!.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted && AppStyle.current.isClean) setState(() {});
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _correctAnswerController.dispose();
    _varAController.dispose();
    _varBController.dispose();
    _varCController.dispose();
    _varDController.dispose();
    _inputFormatController.dispose();
    _outputFormatController.dispose();
    _solutionCodeController.dispose();
    for (var tc in _testCases) {
      tc['input']?.dispose();
      tc['output']?.dispose();
    }
    super.dispose();
  }

  void _addTestCase() {
    final tc = {'input': TextEditingController(), 'output': TextEditingController()};
    tc['input']!.addListener(_refresh);
    tc['output']!.addListener(_refresh);
    setState(() => _testCases.add(tc));
  }

  void _removeTestCase(int index) {
    final tc = _testCases[index];
    setState(() => _testCases.removeAt(index));
    tc['input']?.dispose();
    tc['output']?.dispose();
  }

  Future<void> _saveExercise() async {
    final clean = AppStyle.current.isClean;
    if (!_formKey.currentState!.validate()) {
      if (clean) setState(() => _error = 'Completează câmpurile marcate cu roșu.');
      return;
    }
    if (clean && _selectedType == 'grila') {
      if (_opts.any((c) => c.text.trim().isEmpty)) {
        setState(() => _error = 'Completează toate cele 4 variante.');
        return;
      }
      if (_correctIdx == null) {
        setState(() => _error = 'Bifează varianta corectă.');
        return;
      }
      _correctAnswerController.text = _opts[_correctIdx!].text.trim();
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> exerciseData = {
        'subject': _selectedSubject,
        'grade': _selectedGrade,
        'category': _categoryController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'tip_exercitiu': _selectedType,
        'difficulty': _difficulty,
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedType == 'text') {
        exerciseData['raspuns_corect'] = _correctAnswerController.text.trim();
      } else if (_selectedType == 'grila') {
        exerciseData['variante'] = _opts.map((c) => c.text.trim()).toList();
        exerciseData['raspuns_corect'] = _correctAnswerController.text.trim();
      } else if (_selectedType == 'cod') {
        exerciseData['input'] = _inputFormatController.text.trim();
        exerciseData['output'] = _outputFormatController.text.trim();
        exerciseData['official_solution'] = {'language': 'C++', 'code': _solutionCodeController.text.trim()};

        final List<Map<String, String>> testsToSave = [];
        for (var tc in _testCases) {
          final inText = tc['input']!.text.trim();
          final outText = tc['output']!.text.trim();
          if (inText.isNotEmpty || outText.isNotEmpty) {
            testsToSave.add({'input': inText, 'output': outText});
          }
        }
        exerciseData['tests'] = testsToSave;
      }

      await FirebaseFirestore.instance.collection('exercises').add(exerciseData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        clean
            ? const SnackBar(
                content: Text('Problema a fost trimisă. Apare pe site după aprobare.', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFF212529),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: Pb.radius),
              )
            : SnackBar(
                content: const Text('QUEST SUBMITTED FOR ADMIN APPROVAL.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                backgroundColor: AppColors.forest,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
              ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/panou-profesor');
      }
    } catch (e) {
      if (!mounted) return;
      if (clean) {
        setState(() => _error = 'Nu am putut trimite problema. Încearcă din nou.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: $e', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            backgroundColor: AppColors.sunset,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — form in 3 cards + a LIVE PREVIEW of exactly what the student will
  // see. Multiple choice: click the circle to mark the correct option.
  // Dragon scene (same as the problem pages).
  // ===========================================================================
  static const _diffs = {'usoara': ('Ușoară', Color(0xFF10B981)), 'medie': ('Medie', Color(0xFFF59E0B)), 'grea': ('Grea', Color(0xFFE5484D))};

  InputDecoration _dec(String hint, {IconData? icon, bool mono = false}) => Pb.input(hint: hint).copyWith(
        prefixIcon: icon == null ? null : Icon(icon, size: 18, color: Pb.muted),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        errorStyle: const TextStyle(fontSize: 12),
      );

  Widget _label(String t, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(t, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
            if (hint != null) ...[const SizedBox(width: 6), Text(hint, style: TextStyle(fontSize: 12.5, color: Pb.muted))],
          ],
        ),
      );

  Widget _section(int n, String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: ckDeco(r: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Pb.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: Text('$n', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.primary)),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Pb.text)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  Widget _chips<T>(List<T> values, T current, String Function(T) label, void Function(T) onPick, {Color Function(T)? color}) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in values)
            CkHover(
              onTap: () => setState(() => onPick(v)),
              builder: (h) {
                final sel = v == current;
                final c = color?.call(v) ?? Pb.link;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? c.withOpacity(0.12) : (h ? Pb.hoverBg : Colors.transparent),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: sel ? c : Pb.border),
                  ),
                  child: Text(label(v), style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? c : Pb.text)),
                );
              },
            ),
        ],
      );

  Widget _buildClean(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 1000;

    final typeCards = Row(
      children: [
        for (final e in const [
          ('text', 'Răspuns scurt', Icons.short_text, 'Un număr sau un cuvânt'),
          ('grila', 'Grilă', Icons.checklist, '4 variante, una corectă'),
          ('cod', 'Programare', Icons.code, 'Cod C++ cu teste'),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: CkHover(
                onTap: () => setState(() => _selectedType = e.$1),
                builder: (h) {
                  final sel = _selectedType == e.$1;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? Pb.primary.withOpacity(0.08) : (h ? Pb.hoverBg : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? Pb.primary : Pb.border, width: sel ? 1.6 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(e.$3, size: 20, color: sel ? Pb.primary : Pb.muted),
                        const SizedBox(height: 8),
                        Text(e.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pb.text)),
                        const SizedBox(height: 2),
                        Text(e.$4, style: TextStyle(fontSize: 12, color: Pb.muted, height: 1.3)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(1, 'Unde apare', [
            _label('Materia'),
            _chips<String>(subjects, _selectedSubject, (s) => s, (s) => _selectedSubject = s, color: ckSubjectColor),
            const SizedBox(height: 14),
            _label('Clasa'),
            _chips<String>(grades, _selectedGrade, (g) => 'a $g-a', (g) => _selectedGrade = g),
            const SizedBox(height: 14),
            _label('Capitol'),
            TextFormField(
              controller: _categoryController,
              style: TextStyle(fontSize: 15, color: Pb.text),
              decoration: _dec('Ex.: Ecuații de gradul II', icon: Icons.folder_outlined),
              validator: (v) => v!.trim().isEmpty ? 'Scrie capitolul.' : null,
            ),
            const SizedBox(height: 14),
            _label('Dificultate'),
            _chips<String>(_diffs.keys.toList(), _difficulty, (d) => _diffs[d]!.$1, (d) => _difficulty = d, color: (d) => _diffs[d]!.$2),
          ]),
          _section(2, 'Enunțul', [
            _label('Titlu'),
            TextFormField(
              controller: _titleController,
              style: TextStyle(fontSize: 15, color: Pb.text),
              decoration: _dec('Ex.: Suma rădăcinilor'),
              validator: (v) => v!.trim().isEmpty ? 'Scrie un titlu.' : null,
            ),
            const SizedBox(height: 14),
            _label('Cerința', hint: 'ce trebuie să rezolve elevul'),
            TextFormField(
              controller: _descController,
              maxLines: 6,
              style: TextStyle(fontSize: 15, color: Pb.text, height: 1.5),
              decoration: _dec('Scrie enunțul complet, cu toate datele necesare.').copyWith(contentPadding: const EdgeInsets.all(14)),
              validator: (v) => v!.trim().isEmpty ? 'Scrie enunțul.' : null,
            ),
          ]),
          _section(3, 'Răspunsul', [
            typeCards,
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _selectedType == 'text' ? _cText() : (_selectedType == 'grila' ? _cGrila() : _cCode()),
            ),
          ]),
          if (_error != null) ...[
            PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14))),
            const SizedBox(height: 12),
          ],
          PbButton(
            text: 'Trimite spre aprobare',
            icon: Icons.send_outlined,
            fullWidth: true,
            loading: _isSaving,
            onPressed: _isSaving ? null : _saveExercise,
          ),
          const SizedBox(height: 8),
          Text('Un administrator verifică problema înainte să apară pe site.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
        ],
      ),
    );

    final preview = _cPreview();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PbButton(
              text: 'Înapoi',
              icon: Icons.arrow_back,
              variant: PbVariant.outlineSecondary,
              size: PbSize.sm,
              onPressed: () => context.canPop() ? context.pop() : context.go('/panou-profesor'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Problemă nouă', style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Completează pașii de mai jos. În dreapta vezi exact cum o va vedea elevul.', style: TextStyle(fontSize: 14.5, color: Pb.muted)),
        const SizedBox(height: 18),
        if (isMobile) ...[form, const SizedBox(height: 14), preview] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: form), const SizedBox(width: 18), SizedBox(width: 380, child: preview)],
          ),
        const SizedBox(height: 40),
      ],
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              scene: HomeScene.fantasy,
              blockers: [_mainKey],
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 32, isMobile ? 12 : 24, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: KeyedSubtree(key: _mainKey, child: CkReveal(child: content)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cText() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Răspunsul corect', hint: 'comparat exact cu ce scrie elevul'),
          TextFormField(
            controller: _correctAnswerController,
            style: TextStyle(fontSize: 15, color: Pb.text, fontWeight: FontWeight.w600),
            decoration: _dec('Ex.: 12', icon: Icons.check_circle_outline),
            validator: (v) => _selectedType == 'text' && v!.trim().isEmpty ? 'Scrie răspunsul corect.' : null,
          ),
        ],
      );

  Widget _cGrila() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Variantele', hint: 'bifează cercul celei corecte'),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  InkResponse(
                    radius: 20,
                    onTap: () => setState(() => _correctIdx = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _correctIdx == i ? Pb.primary : Colors.transparent,
                        border: Border.all(color: _correctIdx == i ? Pb.primary : Pb.border, width: 1.6),
                      ),
                      child: _correctIdx == i
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(String.fromCharCode(65 + i), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.muted)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _opts[i],
                      style: TextStyle(fontSize: 15, color: Pb.text),
                      decoration: _dec('Varianta ${String.fromCharCode(65 + i)}').copyWith(
                        fillColor: _correctIdx == i ? Pb.primary.withOpacity(0.06) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _cCode() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Date de intrare'),
          TextFormField(controller: _inputFormatController, maxLines: 2, style: TextStyle(fontSize: 14.5, color: Pb.text), decoration: _dec('Ex.: Pe prima linie se află n.')),
          const SizedBox(height: 12),
          _label('Date de ieșire'),
          TextFormField(controller: _outputFormatController, maxLines: 2, style: TextStyle(fontSize: 14.5, color: Pb.text), decoration: _dec('Ex.: Se afișează suma.')),
          const SizedBox(height: 14),
          _label('Soluția oficială', hint: 'C++'),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
            child: TextFormField(
              controller: _solutionCodeController,
              maxLines: 9,
              style: const TextStyle(color: Color(0xFFD4D4D4), fontFamily: 'monospace', fontSize: 14, height: 1.5),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: '#include <iostream>\nusing namespace std;\n\nint main() {\n  \n}',
                hintStyle: TextStyle(color: Color(0xFF6A6A6A), fontFamily: 'monospace'),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _label('Teste de evaluare', hint: '${_testCases.length}')),
              PbButton(text: 'Test nou', icon: Icons.add, size: PbSize.sm, variant: PbVariant.outlinePrimary, onPressed: _addTestCase),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _testCases.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Pb.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Testul ${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text)),
                      const Spacer(),
                      if (_testCases.length > 1)
                        IconButton(
                          tooltip: 'Șterge testul',
                          splashRadius: 16,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE5484D)),
                          onPressed: () => _removeTestCase(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _testCases[i]['input'],
                          maxLines: 3,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 13.5, color: Pb.text),
                          decoration: _dec('Intrare'),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.fromLTRB(8, 14, 8, 0), child: Icon(Icons.arrow_forward, size: 16)),
                      Expanded(
                        child: TextFormField(
                          controller: _testCases[i]['output'],
                          maxLines: 3,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 13.5, color: Pb.text),
                          decoration: _dec('Ieșire așteptată'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );

  /// What the student will see.
  Widget _cPreview() {
    final c = ckSubjectColor(_selectedSubject);
    final d = _diffs[_difficulty]!;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    Widget pill(String t, Color col) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: col)),
        );

    Widget answer;
    if (_selectedType == 'grila') {
      answer = Column(
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _correctIdx == i ? Pb.primary : Pb.border),
                color: _correctIdx == i ? Pb.primary.withOpacity(0.06) : null,
              ),
              child: Row(
                children: [
                  Text('${String.fromCharCode(65 + i)}.', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Pb.muted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_opts[i].text.trim().isEmpty ? '…' : _opts[i].text.trim(), style: TextStyle(fontSize: 14, color: Pb.text)),
                  ),
                  if (_correctIdx == i) const Icon(Icons.check_circle, size: 16, color: Pb.primary),
                ],
              ),
            ),
        ],
      );
    } else if (_selectedType == 'cod') {
      final first = _testCases.isEmpty ? null : _testCases.first;
      Widget mono(String label, String v) => Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Pb.muted)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Pb.border)),
                  child: Text(v.isEmpty ? '…' : v, style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Pb.text)),
                ),
              ],
            ),
          );
      answer = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_inputFormatController.text.trim().isNotEmpty) ...[
            Text('Date de intrare', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text)),
            Text(_inputFormatController.text.trim(), style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.45)),
            const SizedBox(height: 8),
          ],
          if (_outputFormatController.text.trim().isNotEmpty) ...[
            Text('Date de ieșire', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Pb.text)),
            Text(_outputFormatController.text.trim(), style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.45)),
            const SizedBox(height: 8),
          ],
          if (first != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [mono('Exemplu intrare', first['input']!.text.trim()), const SizedBox(width: 8), mono('Exemplu ieșire', first['output']!.text.trim())],
            ),
        ],
      );
    } else {
      answer = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Pb.border)),
        child: Row(
          children: [
            Expanded(child: Text('Răspunsul tău…', style: TextStyle(fontSize: 14, color: Pb.muted))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Pb.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('Verifică', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ckDeco(r: 16).copyWith(border: Border.all(color: c.withOpacity(0.35))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: Pb.muted),
              const SizedBox(width: 6),
              Text('Previzualizare elev', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              const Spacer(),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('live', style: TextStyle(fontSize: 12, color: Pb.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              pill(_selectedSubject, c),
              pill('Clasa a $_selectedGrade-a', const Color(0xFF3B82F6)),
              pill(d.$1, d.$2),
              if (_categoryController.text.trim().isNotEmpty) pill(_categoryController.text.trim(), Pb.muted),
            ],
          ),
          const SizedBox(height: 12),
          Text(title.isEmpty ? 'Titlul problemei' : title,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: title.isEmpty ? Pb.muted : Pb.text)),
          const SizedBox(height: 8),
          Text(desc.isEmpty ? 'Enunțul apare aici pe măsură ce scrii.' : desc,
              style: TextStyle(fontSize: 14, color: desc.isEmpty ? Pb.muted : Pb.text, height: 1.55, fontStyle: desc.isEmpty ? FontStyle.italic : null)),
          const SizedBox(height: 14),
          Container(height: 1, color: Pb.border),
          const SizedBox(height: 14),
          answer,
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  InputDecoration _inputStyle(String label, {IconData? icon, bool isDark = false, bool isSuccess = false}) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: TextStyle(color: isDark ? const Color(0xFFECEFF4) : AppColors.ink, fontWeight: FontWeight.bold),
      prefixIcon: icon != null ? Icon(icon, color: isDark ? const Color(0xFFECEFF4) : AppColors.ink) : null,
      filled: true,
      fillColor: isDark ? const Color(0xFF1B242B) : (isSuccess ? AppColors.mustard : AppColors.inputBg),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? const Color(0xFF2C3E50) : AppColors.border, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isSuccess ? AppColors.sky : AppColors.sunset, width: 3)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sunset, width: 3)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sunset, width: 3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }

  Widget _buildRetroCard({required String title, required Color accentColor, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: RetroBlock(
        bgColor: AppColors.cardBg,
        padding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: accentColor, border: Border(bottom: BorderSide(color: AppColors.border, width: 3))),
              child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetro(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text('INITIALIZE QUEST', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(color: AppColors.border, height: 3)),
            leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.ink, size: 32), onPressed: () => context.pop()),
          ),
          body: _isSaving
              ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRetroCard(
                              title: 'Quest Parameters',
                              accentColor: AppColors.sky,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<String>(
                                        decoration: _inputStyle('Discipline', icon: Icons.book),
                                        value: _selectedSubject,
                                        dropdownColor: AppColors.cardBg,
                                        iconEnabledColor: AppColors.ink,
                                        items: subjects
                                            .map((s) => DropdownMenuItem(
                                                value: s, child: Text(s.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink))))
                                            .toList(),
                                        onChanged: (val) => setState(() => _selectedSubject = val!),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        decoration: _inputStyle('Level', icon: Icons.school),
                                        value: _selectedGrade,
                                        dropdownColor: AppColors.cardBg,
                                        iconEnabledColor: AppColors.ink,
                                        items: grades
                                            .map((g) => DropdownMenuItem(value: g, child: Text("LVL $g", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink))))
                                            .toList(),
                                        onChanged: (val) => setState(() => _selectedGrade = val!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _categoryController,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                                  cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                                  decoration: _inputStyle('Category (e.g., Algebra)', icon: Icons.folder),
                                  validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
                                ),
                              ],
                            ),
                            _buildRetroCard(
                              title: 'Quest Content',
                              accentColor: AppColors.mustard,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 18),
                                  cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                                  decoration: _inputStyle('Quest Title', icon: Icons.title),
                                  validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _descController,
                                  maxLines: 6,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.5),
                                  cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                                  decoration: _inputStyle('Write the problem description here...'),
                                  validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
                                ),
                              ],
                            ),
                            _buildRetroCard(
                              title: 'Response Format',
                              accentColor: AppColors.sunset,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: _inputStyle('Exercise Type'),
                                  value: _selectedType,
                                  dropdownColor: AppColors.cardBg,
                                  iconEnabledColor: AppColors.ink,
                                  items: types.entries
                                      .map((e) => DropdownMenuItem(
                                          value: e.key, child: Text(e.value.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink))))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedType = val!),
                                ),
                                const SizedBox(height: 32),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: _selectedType == 'text'
                                        ? _buildTextSection()
                                        : _selectedType == 'grila'
                                            ? _buildGrilaSection()
                                            : _buildCodeSection(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RetroButton(text: 'SUBMIT QUEST', bgColor: AppColors.forest, textColor: Colors.white, isFullWidth: true, onPressed: _saveExercise),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTextSection() {
    return TextFormField(
      controller: _correctAnswerController,
      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, fontSize: 20),
      cursorColor: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
      decoration: _inputStyle('Exact Correct Answer', icon: Icons.check_circle, isSuccess: true),
      validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
    );
  }

  Widget _buildGrilaSection() {
    Widget opt(TextEditingController c, String l) => Expanded(
          child: TextFormField(
            controller: c,
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
            cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
            decoration: _inputStyle(l),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROVIDE 4 OPTIONS:', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18)),
        const SizedBox(height: 16),
        Row(children: [opt(_varAController, 'Option A'), const SizedBox(width: 16), opt(_varBController, 'Option B')]),
        const SizedBox(height: 16),
        Row(children: [opt(_varCController, 'Option C'), const SizedBox(width: 16), opt(_varDController, 'Option D')]),
        const SizedBox(height: 40),
        TextFormField(
          controller: _correctAnswerController,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink, fontSize: 20),
          cursorColor: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
          decoration: _inputStyle('RE-TYPE CORRECT OPTION', icon: Icons.star, isSuccess: true),
          validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
        ),
      ],
    );
  }

  Widget _buildCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _inputFormatController,
          maxLines: 2,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
          cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
          decoration: _inputStyle('Input Data Format'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _outputFormatController,
          maxLines: 2,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
          cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
          decoration: _inputStyle('Output Data Format'),
        ),
        const SizedBox(height: 32),
        Text('OFFICIAL SOLUTION (C++):', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _solutionCodeController,
          maxLines: 8,
          decoration: _inputStyle('Source code...', icon: Icons.code, isDark: true),
          style: const TextStyle(color: Color(0xFF55EFC4), fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
          cursorColor: const Color(0xFF55EFC4),
        ),
        const SizedBox(height: 48),
        Text('EVALUATION TESTS (JUDGE0):', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
        const SizedBox(height: 24),
        ..._testCases.asMap().entries.map((entry) {
          final index = entry.key;
          final tc = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: RetroBlock(
              bgColor: AppColors.cardBg,
              padding: 24,
              shadowOffset: 4.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TEST BATCH #${index + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18)),
                      if (_testCases.length > 1)
                        IconButton(icon: Icon(Icons.delete, color: AppColors.sunset, size: 28), onPressed: () => _removeTestCase(index)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tc['input'],
                    style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.ink),
                    cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                    decoration: _inputStyle('Expected Input'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tc['output'],
                    style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.ink),
                    cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                    decoration: _inputStyle('Expected Output'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: RetroButton(text: '+ ADD TEST BATCH', bgColor: AppColors.cloud, textColor: AppColors.ink, onPressed: _addTestCase),
        ),
      ],
    );
  }
}