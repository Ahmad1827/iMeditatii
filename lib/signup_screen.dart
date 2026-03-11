import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  final bool googleUser;
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

  String role = 'student';
  String? selectedSubject;
  bool loading = false;
  bool _isHovering = false;

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

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
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trebuie să accepți Termenii și Politica de Confidențialitate!"),
            backgroundColor: Colors.redAccent,
          )
      );
      return;
    }

    setState(() => loading = true);

    try {
      String uid;

      if (widget.googleUser) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("Utilizatorul Google nu este autentificat!");
        }
        uid = user.uid;
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        uid = cred.user!.uid;
      }

      final data = {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'profileCompleted': true,
        'acceptedTerms': true,
        'acceptedPrivacy': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'teacher') {
        data['subject'] = selectedSubject ?? '';
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(data);

      if (role == 'teacher') {
        await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
          'name': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'subject': selectedSubject ?? '',
          'image': '',
          'active': false,
          'hasAccount': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cont creat! Așteaptă aprobarea administratorului.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        if (role == 'teacher') {
          context.go('/profesor/$uid');
        } else {
          context.go('/materii');
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Înregistrare eșuată', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
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

  Widget _buildTextField({required TextEditingController controller, required String labelText, required IconData prefixIcon, bool obscureText = false, bool readOnly = false, String? Function(String?)? validator, TextInputType keyboardType = TextInputType.text}) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 700 ? 700.0 : screenWidth * 0.9;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
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
                        const Text('Creează-ți un cont', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(widget.googleUser ? 'Finalizează înregistrarea pentru contul tău Google.' : 'Introdu detaliile de mai jos.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        const SizedBox(height: 30),

                        _buildTextField(
                          controller: nameCtrl,
                          labelText: 'Nume complet',
                          prefixIcon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? 'Numele este obligatoriu' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: emailCtrl,
                          labelText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          readOnly: widget.googleUser,
                          validator: (v) => v!.contains('@') && v.contains('.') ? null : 'Introduceți un email valid',
                        ),
                        const SizedBox(height: 20),

                        if (!widget.googleUser)
                          _buildTextField(
                            controller: passCtrl,
                            labelText: 'Parolă',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) => v!.length < 6 ? 'Parola trebuie să aibă minim 6 caractere' : null,
                          ),
                        if (!widget.googleUser) const SizedBox(height: 20),

                        _buildTextField(
                          controller: phoneCtrl,
                          labelText: 'Număr de telefon (opțional)',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => null,
                        ),
                        const SizedBox(height: 30),

                        const Text('Selectează rolul tău:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(child: _buildRoleSelector('Elev', 'student')),
                            Expanded(child: _buildRoleSelector('Profesor', 'teacher')),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (role == 'teacher') ...[
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Selectează materia predată',
                              prefixIcon: const Icon(Icons.school_outlined, color: Colors.blueAccent),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
                            ),
                            items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            value: selectedSubject,
                            onChanged: (val) => setState(() => selectedSubject = val),
                            validator: (v) => v == null || v.isEmpty ? 'Te rog selectează o materie' : null,
                          ),
                          const SizedBox(height: 20),
                        ] else const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200)
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    activeColor: Colors.blueAccent,
                                    onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Am citit și sunt de acord cu ',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                        children: [
                                          TextSpan(
                                            text: 'Termenii și Condițiile',
                                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                            recognizer: TapGestureRecognizer()..onTap = () {
                                              context.go('/termeni-si-conditii'); // 🚀 Actualizează URL
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptedPrivacy,
                                    activeColor: Colors.blueAccent,
                                    onChanged: (val) => setState(() => _acceptedPrivacy = val ?? false),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Sunt de acord cu ',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                        children: [
                                          TextSpan(
                                            text: 'Politica de Confidențialitate',
                                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                            recognizer: TapGestureRecognizer()..onTap = () {
                                              context.go('/politica-confidentialitate'); // 🚀 Actualizează URL
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        loading
                            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                            ),
                            child: const Text('Creează Cont', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text("Ai deja cont? Autentifică-te", style: TextStyle(color: Colors.blueAccent, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _isHovering ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: AnimatedScale(
                      scale: _isHovering ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.arrow_back, color: Colors.blueAccent, size: 28),
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

  Widget _buildRoleSelector(String title, String value) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () => setState(() => role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(value == 'teacher' ? Icons.badge : Icons.school, color: isSelected ? Colors.white : Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}