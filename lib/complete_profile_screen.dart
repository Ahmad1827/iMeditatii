import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialization_screen.dart';
import 'teachers_dashboard.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String role = 'user';
  String? selectedSubject;

  final subjects = [
    'Matematică',
    'Fizică',
    'Chimie',
    'Informatică',
    'Limba Română',
    'Engleză',
    'Franceză',
    'Istorie',
    'Geografie',
  ];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populează numele dacă este disponibil
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      nameCtrl.text = user.displayName!;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => loading = true);
    try {
      // Date de bază
      final userData = {
        'name': nameCtrl.text.trim(),
        'email': user.email,
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'subject': role == 'teacher' ? selectedSubject : null,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Salvarea în colecția 'users'
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      // 2. Salvarea în colecția 'teachers' (dacă este profesor)
      if (role == 'teacher') {
        await FirebaseFirestore.instance.collection('teachers').doc(user.uid).set({
          'name': nameCtrl.text.trim(),
          'email': user.email,
          'subject': selectedSubject,
          'hasAccount': true,
          'active': true, // Presupunem că un profil completat este activ
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil completat cu succes!')),
        );

        // Navigare în funcție de rol
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
            role == 'teacher' ? const TeachersDashboard() : const SpecializationScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare la salvarea profilului: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Widget reutilizabil pentru câmpurile de text
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(prefixIcon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  // Widget custom pentru selectarea rolului (mai arătos)
  Widget _buildRoleSelector(String title, String value, IconData icon) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          role = value;
          // Resetează materia când rolul se schimbă de la profesor la elev
          if (value == 'user') {
            selectedSubject = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.blueAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 700 ? 700.0 : screenWidth * 0.9;

    return Scaffold(
      body: Container(
        // Fundal cu gradient
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titlu
                    const Text(
                      'Completează Profilul',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te rugăm să introduci detaliile necesare pentru a începe.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nume complet
                    _buildTextField(
                      controller: nameCtrl,
                      labelText: 'Nume complet',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Numele este obligatoriu' : null,
                    ),
                    const SizedBox(height: 20),

                    // Telefon
                    _buildTextField(
                      controller: phoneCtrl,
                      labelText: 'Număr de telefon',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Numărul de telefon este obligatoriu' : null,
                    ),
                    const SizedBox(height: 30),

                    // Alegere rol
                    const Text(
                      'Selectează rolul tău:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleSelector('Elev / Părinte', 'user', Icons.school),
                        ),
                        Expanded(
                          child: _buildRoleSelector('Profesor', 'teacher', Icons.badge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Dacă este profesor, alege materia
                    if (role == 'teacher') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Selectează materia predată',
                          prefixIcon: const Icon(Icons.menu_book, color: Colors.blueAccent),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                          ),
                        ),
                        items: subjects
                            .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        value: selectedSubject,
                        onChanged: (val) {
                          setState(() => selectedSubject = val);
                        },
                        validator: (v) {
                          if (role == 'teacher' && (v == null || v.isEmpty)) {
                            return 'Te rog selectează o materie';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                    ] else const SizedBox(height: 30),

                    // Buton Salvează
                    loading
                        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          'Salvează Profilul',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}