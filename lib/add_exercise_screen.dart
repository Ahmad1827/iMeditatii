import 'package:flutter/material.dart';
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

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
    this.isFullWidth = false,
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
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
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
            color: widget.bgColor,
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
          child: Text(
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
            content: const Text('QUEST SUBMITTED FOR ADMIN APPROVAL.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.ink, width: 3),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: $e', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            backgroundColor: AppColors.sunset,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.ink, width: 3),
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
        color: isDark ? AppColors.cloud : AppColors.ink,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: icon != null ? Icon(icon, color: isDark ? AppColors.cloud : AppColors.ink) : null,
      filled: true,
      fillColor: isDark ? AppColors.ink : (isSuccess ? AppColors.mustard : Colors.white),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: isDark ? AppColors.cloud : AppColors.ink, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: isSuccess ? AppColors.sky : AppColors.sunset, width: 3),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.sunset, width: 3),
      ),
      focusedErrorBorder: const OutlineInputBorder(
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
        bgColor: AppColors.bg,
        padding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
              ),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5),
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
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('INITIALIZE QUEST', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        backgroundColor: AppColors.mustard,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunset))
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
                                    dropdownColor: Colors.white,
                                    iconEnabledColor: AppColors.ink,
                                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                                    onChanged: (val) => setState(() => _selectedSubject = val!),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    decoration: _inputStyle('Level', icon: Icons.school),
                                    value: _selectedGrade,
                                    dropdownColor: Colors.white,
                                    iconEnabledColor: AppColors.ink,
                                    items: grades.map((g) => DropdownMenuItem(value: g, child: Text("LVL $g", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                                    onChanged: (val) => setState(() => _selectedGrade = val!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _categoryController,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 18),
                              decoration: _inputStyle('Quest Title', icon: Icons.title),
                              validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _descController,
                              maxLines: 6,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.5),
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
                              dropdownColor: Colors.white,
                              iconEnabledColor: AppColors.ink,
                              items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (val) => setState(() => _selectedType = val!),
                            ),
                            const SizedBox(height: 32),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
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
  }

  Widget _buildTextSection() {
    return TextFormField(
      controller: _correctAnswerController,
      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 20),
      decoration: _inputStyle('Exact Correct Answer', icon: Icons.check_circle, isSuccess: true),
      validator: (val) => val!.isEmpty ? 'REQUIRED' : null,
    );
  }

  Widget _buildGrilaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROVIDE 4 OPTIONS:', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _varAController, style: const TextStyle(fontWeight: FontWeight.bold), decoration: _inputStyle('Option A'))),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _varBController, style: const TextStyle(fontWeight: FontWeight.bold), decoration: _inputStyle('Option B'))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _varCController, style: const TextStyle(fontWeight: FontWeight.bold), decoration: _inputStyle('Option C'))),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _varDController, style: const TextStyle(fontWeight: FontWeight.bold), decoration: _inputStyle('Option D'))),
          ],
        ),
        const SizedBox(height: 40),
        TextFormField(
          controller: _correctAnswerController,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 20),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: _inputStyle('Input Data Format'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _outputFormatController,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: _inputStyle('Output Data Format'),
        ),
        const SizedBox(height: 32),
        const Text('OFFICIAL SOLUTION (C++):', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _solutionCodeController,
          maxLines: 8,
          decoration: _inputStyle('Source code...', icon: Icons.code, isDark: true),
          style: const TextStyle(color: AppColors.sky, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 48),
        const Text('EVALUATION TESTS (JUDGE0):', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
        const SizedBox(height: 24),
        ..._testCases.asMap().entries.map((entry) {
          int index = entry.key;
          var tc = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: RetroBlock(
              bgColor: Colors.white,
              padding: 24,
              shadowOffset: 4.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TEST BATCH #${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 18)),
                      if (_testCases.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.sunset, size: 28),
                          onPressed: () => _removeTestCase(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tc['input'],
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    decoration: _inputStyle('Expected Input'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tc['output'],
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    decoration: _inputStyle('Expected Output'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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