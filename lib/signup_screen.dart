import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialization_screen.dart';
import 'teachers_dashboard.dart';

class SignupScreen extends StatefulWidget {
  final bool googleUser; // true dacă vine din Google Sign-In
  final String? initialEmail;
  final String? initialName;

  const SignupScreen({
    this.googleUser = false,
    this.initialEmail,
    this.initialName,
    Key? key,
  }) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  String role = 'user'; // 'user' sau 'teacher'
  String? selectedSubject;
  bool loading = false;
  bool _isHovering = false; // Pentru efectul de hover pe butonul de înapoi

  final List<String> subjects = [
    "Matematică",
    "Informatică",
    "Fizică",
    "Chimie",
    "Biologie",
    "Istorie",
    "Geografie",
    "Limba Română",
    "Engleză",
    "Franceză",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.googleUser) {
      emailCtrl.text = widget.initialEmail ?? '';
      nameCtrl.text = widget.initialName ?? '';
      // Asigură-te că rolul este setat implicit pe 'user' sau cum dorești la înregistrarea Google
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      String uid;

      if (widget.googleUser) {
        // User deja logat prin Google
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("Utilizatorul Google nu este autentificat!");
        }
        uid = user.uid;
      } else {
        // Creare cont clasic cu email și parolă
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        uid = cred.user!.uid;
      }

      // Datele de salvat în Firestore
      final data = {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'teacher') {
        data['subject'] = selectedSubject ?? '';
      }

      // adaugă în users
      await FirebaseFirestore.instance.collection('users').doc(uid).set(data);

      // dacă e profesor -> adaugă și în teachers
      if (role == 'teacher') {
        await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
          'name': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'subject': selectedSubject ?? '',
          'image': '',
          'active': true,
          'hasAccount': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Navigare după înregistrare
      if (mounted) {
        if (role == 'teacher') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => TeachersDashboard()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => SpecializationScreen()),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Înregistrare eșuată')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  // Widget reutilizabil pentru câmpurile de text
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
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

  @override
  Widget build(BuildContext context) {
    // Definirea lățimii maxime a cardului, similar cu LoginScreen
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
        child: Stack(
          children: [
            // Conținutul principal (Centru)
            Center(
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
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
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
                          'Creează-ți un cont',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.googleUser
                              ? 'Finalizează înregistrarea pentru contul tău Google.'
                              : 'Introdu detaliile de mai jos.',
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

                        // Email
                        _buildTextField(
                          controller: emailCtrl,
                          labelText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          readOnly: widget.googleUser,
                          validator: (v) => v!.contains('@') && v.contains('.') ? null : 'Introduceți un email valid',
                        ),
                        const SizedBox(height: 20),

                        // Parola doar dacă nu e Google
                        if (!widget.googleUser)
                          _buildTextField(
                            controller: passCtrl,
                            labelText: 'Parolă',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) => v!.length < 6 ? 'Parola trebuie să aibă minim 6 caractere' : null,
                          ),
                        if (!widget.googleUser) const SizedBox(height: 20),

                        // Telefon
                        _buildTextField(
                          controller: phoneCtrl,
                          labelText: 'Număr de telefon (opțional)',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => null, // Fără validare strictă, e opțional
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
                              child: _buildRoleSelector('Elev', 'user'),
                            ),
                            Expanded(
                              child: _buildRoleSelector('Profesor', 'teacher'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dacă este profesor, alege materia
                        if (role == 'teacher') ...[
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Selectează materia predată',
                              prefixIcon: const Icon(Icons.school_outlined, color: Colors.blueAccent),
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
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Te rog selectează o materie' : null,
                          ),
                          const SizedBox(height: 30),
                        ] else const SizedBox(height: 30),


                        // Buton Sign Up
                        loading
                            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'Creează Cont',
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Navigare la Login
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Ai deja cont? Autentifică-te",
                              style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Back button animat (Opțional, dar bun pentru consistență)
            Positioned(
              top: 16,
              left: 16,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isHovering
                          ? Colors.blueAccent.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedScale(
                      scale: _isHovering ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget custom pentru selectarea rolului (mai arătos decât RadioListTile)
  Widget _buildRoleSelector(String title, String value) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          role = value;
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
              value == 'teacher' ? Icons.badge : Icons.school,
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
}