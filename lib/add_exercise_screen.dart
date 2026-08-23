import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

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
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : Text(
                  widget.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: effectiveTextColor,
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
    setState(() {
      _testCases.add({'input': TextEditingController(), 'output': TextEditingController()});
    });
  }

  void _removeTestCase(int index) {
    setState(() {
      _testCases.removeAt(index);
    });
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> exerciseData = {
        'subject': _selectedSubject,
        'grade': _selectedGrade,
        'category': _categoryController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'tip_exercitiu': _selectedType,
        'difficulty': 'medie',
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedType == 'text') {
        exerciseData['raspuns_corect'] = _correctAnswerController.text.trim();
      } else if (_selectedType == 'grila') {
        exerciseData['variante'] = [
          _varAController.text.trim(),
          _varBController.text.trim(),
          _varCController.text.trim(),
          _varDController.text.trim(),
        ];
        exerciseData['raspuns_corect'] = _correctAnswerController.text.trim();
      } else if (_selectedType == 'cod') {
        exerciseData['input'] = _inputFormatController.text.trim();
        exerciseData['output'] = _outputFormatController.text.trim();
        exerciseData['official_solution'] = {
          'language': 'C++',
          'code': _solutionCodeController.text.trim(),
        };

        List<Map<String, String>> testsToSave = [];
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'QUEST SUBMITTED FOR ADMIN APPROVAL.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.border, width: 3),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERROR: $e',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            backgroundColor: AppColors.sunset,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.border, width: 3),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputStyle(String label, {IconData? icon, bool isDark = false, bool isSuccess = false}) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFECEFF4) : AppColors.ink,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: icon != null ? Icon(icon, color: isDark ? const Color(0xFFECEFF4) : AppColors.ink) : null,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1B242B)
          : (isSuccess ? AppColors.mustard : AppColors.inputBg),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: isDark ? const Color(0xFF2C3E50) : AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: isSuccess ? AppColors.sky : AppColors.sunset, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.sunset, width: 3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.sunset, width: 3),
      ),
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
              color: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
              ),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              'INITIALIZE QUEST',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
              onPressed: () => context.pop(),
            ),
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
                                                  value: s,
                                                  child: Text(
                                                    s.toUpperCase(),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.ink,
                                                    ),
                                                  ),
                                                ))
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
                                            .map((g) => DropdownMenuItem(
                                                  value: g,
                                                  child: Text(
                                                    "LVL $g",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.ink,
                                                    ),
                                                  ),
                                                ))
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
                                            value: e.key,
                                            child: Text(
                                              e.value.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ))
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
                            RetroButton(
                              text: 'SUBMIT QUEST',
                              bgColor: AppColors.forest,
                              textColor: Colors.white,
                              isFullWidth: true,
                              onPressed: _saveExercise,
                            ),
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
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
        fontSize: 20,
      ),
      cursorColor: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
      decoration: _inputStyle('Exact Correct Answer', icon: Icons.check_circle, isSuccess: true),
      validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
    );
  }

  Widget _buildGrilaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROVIDE 4 OPTIONS:',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _varAController,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                decoration: _inputStyle('Option A'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _varBController,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                decoration: _inputStyle('Option B'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _varCController,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                decoration: _inputStyle('Option C'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _varDController,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                cursorColor: AppColors.isDark ? const Color(0xFF55EFC4) : AppColors.ink,
                decoration: _inputStyle('Option D'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        TextFormField(
          controller: _correctAnswerController,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
            fontSize: 20,
          ),
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
        Text(
          'OFFICIAL SOLUTION (C++):',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _solutionCodeController,
          maxLines: 8,
          decoration: _inputStyle('Source code...', icon: Icons.code, isDark: true),
          style: const TextStyle(color: Color(0xFF55EFC4), fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
          cursorColor: const Color(0xFF55EFC4),
        ),
        const SizedBox(height: 48),
        Text(
          'EVALUATION TESTS (JUDGE0):',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 24),
        ..._testCases.asMap().entries.map((entry) {
          int index = entry.key;
          var tc = entry.value;
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
                      Text(
                        'TEST BATCH #${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18),
                      ),
                      if (_testCases.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete, color: AppColors.sunset, size: 28),
                          onPressed: () => _removeTestCase(index),
                        ),
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
          child: RetroButton(
            text: '+ ADD TEST BATCH',
            bgColor: AppColors.cloud,
            textColor: AppColors.ink,
            onPressed: _addTestCase,
          ),
        ),
      ],
    );
  }
}