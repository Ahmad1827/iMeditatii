import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'signup_screen.dart';
import 'specialization_screen.dart';
import 'teachers_dashboard.dart';
import 'complete_profile_screen.dart'; // noul ecran de completare profil

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleSigningIn = false;
  bool _isHovering = false;
  bool _showPassword = false;

  /// Verifică dacă profilul este completat
  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists || !doc.data()!.containsKey('role')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    } else {
      // Dacă e profesor, mergem la dashboard
      final role = doc.data()!['role'];
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
  }

  /*──────── LOGIN EMAIL/PAROLĂ ────────*/
  Future<void> _login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să completați ambele câmpuri.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _checkUserProfile();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Autentificare eșuată: $e')));
    }

    if (mounted) setState(() => isLoading = false);
  }

  /*──────── LOGIN GOOGLE ────────*/
  Future<void> _signInWithGoogle() async {
    setState(() => isGoogleSigningIn = true);

    try {
      // Pas 1: Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isGoogleSigningIn = false);
        return;
      }

      // Pas 2: Credentiale Firebase
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Pas 3: Autentificare
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = userCred.user!.uid;
      final email = userCred.user!.email ?? '';
      final name = userCred.user!.displayName ?? '';

      // 🔑 Verificăm dacă userul e NOU
      if (userCred.additionalUserInfo?.isNewUser ?? false) {
        // Dacă este utilizator nou, îl trimitem la ecranul de înregistrare
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => SignupScreen(
              googleUser: true,
              initialEmail: email,
              initialName: name,
            ),
          ),
              (route) => false,
        );
        return;
      }

      // Dacă userul NU e nou, verificăm Firestore
      final usersRef = FirebaseFirestore.instance.collection('users');
      final userDoc = await usersRef.doc(uid).get();

      // Dacă profilul nu este completat (sau lipsește)
      if (!userDoc.exists || userDoc.data()?['profileCompleted'] != true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(), // Trimitem direct la completare profil
          ),
              (route) => false,
        );
        return;
      }

      // Dacă are profil complet
      final data = userDoc.data();
      if (data?['role'] == 'teacher') {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentificare Google eșuată: $e')),
      );
    }

    if (mounted) setState(() => isGoogleSigningIn = false);
  }

  // Widget pentru câmpul de intrare (pentru reutilizare)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blueAccent) : null,
        suffixIcon: suffixIcon,
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


  /*──────── UI ────────*/
  @override
  Widget build(BuildContext context) {
    // Definirea lățimii maxime a cardului, adaptată la dimensiunea ecranului
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.9;

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
            // Container principal (Centru)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                child: Container(
                  width: cardWidth, // Lățime adaptivă/fixă
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titlu
                      Text(
                        'Bun venit înapoi!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Autentifică-te pentru a continua învățarea',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Email
                      _buildTextField(
                        controller: emailController,
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Parola
                      _buildTextField(
                        controller: passwordController,
                        labelText: 'Parolă',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_showPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Buton login email/parolă
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.blueAccent)
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: const Text(
                            'Autentificare',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Separator
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('SAU', style: TextStyle(color: Colors.grey.shade500)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 30),


                      // Google Sign In (CORECTAT: Lățime maximă egală cu butonul de login)
                      isGoogleSigningIn
                          ? const CircularProgressIndicator(color: Colors.blueAccent)
                          : SizedBox(
                        width: double.infinity, // Setăm la fel ca butonul de login
                        child: ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          label: const Text(
                            'Continuă cu Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Creare cont
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        ),
                        child: Text(
                          "Nu ai cont? Creează un cont nou",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Back button animat
            Positioned(
              top: 16,
              left: 16,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: GestureDetector(
                  onTap: () {
                    // Logica de navigare se păstrează
                    Navigator.pushReplacementNamed(context, '/');
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
}