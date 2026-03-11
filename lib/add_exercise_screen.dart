import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; // Importul necesar pentru navigare

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({Key? key}) : super(key: key);

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variabile pentru Dropdowns
  String _selectedSubject = 'Matematică';
  String _selectedGrade = '9';
  String _selectedType = 'text';

  // Controllere Generale
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Controllere pentru "Text" și "Grilă"
  final TextEditingController _correctAnswerController = TextEditingController();

  // Controllere pentru "Grilă"
  final TextEditingController _varAController = TextEditingController();
  final TextEditingController _varBController = TextEditingController();
  final TextEditingController _varCController = TextEditingController();
  final TextEditingController _varDController = TextEditingController();

  // Controllere pentru "Cod"
  final TextEditingController _inputFormatController = TextEditingController();
  final TextEditingController _outputFormatController = TextEditingController();
  final TextEditingController _solutionCodeController = TextEditingController();

  // 🔥 NOU: Lista dinamică pentru testele de cod (Judge0)
  // Începem cu un test gol (1 Input și 1 Output)
  final List<Map<String, TextEditingController>> _testCases = [
    {'input': TextEditingController(), 'output': TextEditingController()}
  ];

  bool _isSaving = false;

  final List<String> subjects = ['Matematică', 'Informatică', 'Istorie', 'Fizică', 'Română', 'Biologie'];
  final List<String> grades = ['5', '6', '7', '8', '9', '10', '11', '12'];
  final Map<String, String> types = {
    'text': 'Răspuns Scurt (Ex: Mate, Fizică)',
    'grila': 'Grilă cu 4 variante (Ex: Istorie)',
    'cod': 'Problemă de Programare (Info)',
  };

  // Funcție pentru a adăuga un test nou pe ecran
  void _addTestCase() {
    setState(() {
      _testCases.add({'input': TextEditingController(), 'output': TextEditingController()});
    });
  }

  // Funcție pentru a șterge un test de pe ecran
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
      };

      if (_selectedType == 'text') {
        exerciseData['raspuns_corect'] = _correctAnswerController.text.trim();
      }
      else if (_selectedType == 'grila') {
        exerciseData['variante'] = [
          _varAController.text.trim(),
          _varBController.text.trim(),
          _varCController.text.trim(),
          _varDController.text.trim(),
        ];
        exerciseData['raspuns_corect'] = _correctAnswerController.text.trim();
      }
      else if (_selectedType == 'cod') {
        exerciseData['input'] = _inputFormatController.text.trim();
        exerciseData['output'] = _outputFormatController.text.trim();
        exerciseData['official_solution'] = {
          'language': 'C++',
          'code': _solutionCodeController.text.trim(),
        };

        // Extragem textele din controllerele dinamice și le punem în lista "tests"
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
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Exercițiul a fost salvat cu succes!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Schimbat din Navigator.pop(context) în context.pop()
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- STILURI GENERICE REUTILIZABILE ---
  InputDecoration _inputStyle(String label, {IconData? icon, bool isDark = false, bool isSuccess = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      prefixIcon: icon != null ? Icon(icon, color: isDark ? Colors.grey[400] : Colors.blueAccent) : null,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : (isSuccess ? Colors.green.withOpacity(0.05) : Colors.grey[100]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isSuccess ? Colors.green : Colors.blueAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Adaugă Exercițiu', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // CARD 1: Detalii Principale
              _buildCard(
                title: 'Detalii Principale',
                icon: Icons.dashboard_customize_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _inputStyle('Materia', icon: Icons.book_outlined),
                          value: _selectedSubject,
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _inputStyle('Clasa', icon: Icons.school_outlined),
                          value: _selectedGrade,
                          items: grades.map((g) => DropdownMenuItem(value: g, child: Text("Clasa $g"))).toList(),
                          onChanged: (val) => setState(() => _selectedGrade = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: _inputStyle('Categoria (ex: Algebră)', icon: Icons.folder_open_outlined),
                    validator: (val) => val!.isEmpty ? 'Obligatoriu' : null,
                  ),
                ],
              ),

              // CARD 2: Enunțul Problemei
              _buildCard(
                title: 'Conținut Exercițiu',
                icon: Icons.edit_note_outlined,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputStyle('Titlul exercițiului', icon: Icons.title),
                    validator: (val) => val!.isEmpty ? 'Obligatoriu' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: _inputStyle('Scrie cerința problemei aici...'),
                    validator: (val) => val!.isEmpty ? 'Obligatoriu' : null,
                  ),
                ],
              ),

              // CARD 3: Tip și Răspuns
              _buildCard(
                title: 'Format Răspuns',
                icon: Icons.rule_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: _inputStyle('Tipul Exercițiului'),
                    value: _selectedType,
                    items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                  const SizedBox(height: 20),

                  // Secțiuni dinamice
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        if (_selectedType == 'text') _buildTextSection(),
                        if (_selectedType == 'grila') _buildGrilaSection(),
                        if (_selectedType == 'cod') _buildCodeSection(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // BUTON SALVARE MARE
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _saveExercise,
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('Salvează Exercițiul', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return TextFormField(
      controller: _correctAnswerController,
      decoration: _inputStyle('Răspunsul Corect Exact (ex: 11)', icon: Icons.check_circle_outline, isSuccess: true),
      validator: (val) => val!.isEmpty ? 'Acest câmp este obligatoriu' : null,
    );
  }

  Widget _buildGrilaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Completează cele 4 variante:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _varAController, decoration: _inputStyle('Varianta A'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _varBController, decoration: _inputStyle('Varianta B'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _varCController, decoration: _inputStyle('Varianta C'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _varDController, decoration: _inputStyle('Varianta D'))),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        TextFormField(
          controller: _correctAnswerController,
          decoration: _inputStyle('Scrie din nou varianta CORECTĂ', icon: Icons.star_border, isSuccess: true),
          validator: (val) => val!.isEmpty ? 'Trebuie să specifici răspunsul corect' : null,
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
          decoration: _inputStyle('Explică datele de intrare (Input)'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _outputFormatController,
          maxLines: 2,
          decoration: _inputStyle('Explică datele de ieșire (Output)'),
        ),
        const SizedBox(height: 20),
        const Text('Soluția oficială (C++):', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _solutionCodeController,
          maxLines: 8,
          decoration: _inputStyle('Codul sursă aici...', icon: Icons.code, isDark: true),
          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        const Text('Teste de evaluare (Judge0):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.blueAccent)),
        const SizedBox(height: 8),
        const Text('Aceste teste vor rula în fundal (fără ca elevul să le vadă complet) pentru a valida codul.', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 16),

        // Lista dinamică generată
        ..._testCases.asMap().entries.map((entry) {
          int index = entry.key;
          var tc = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Testul #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (_testCases.length > 1) // Arată butonul de ștergere doar dacă e mai mult de un test
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _removeTestCase(index),
                        tooltip: 'Șterge acest test',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: tc['input'],
                  decoration: _inputStyle('Input (ce se citește)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tc['output'],
                  decoration: _inputStyle('Output așteptat (ce se afișează)'),
                  maxLines: 2,
                ),
              ],
            ),
          );
        }).toList(),

        // Butonul de a adăuga mai multe teste
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addTestCase,
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            label: const Text('Adaugă încă un test', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}