import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class CustomNavbar extends StatelessWidget {
  const CustomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 🚀 AICI E MAGIA: Verificăm pe ce pagină suntem uitându-ne în URL
    final String currentPath = GoRouterState.of(context).uri.path;

    final bool isProfesoriActive = currentPath.startsWith('/materii') || currentPath.startsWith('/profesor');
    final bool isExercitiiActive = currentPath.startsWith('/exercitii') || currentPath.startsWith('/lista-exercitii') || currentPath.startsWith('/exercitiu');

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Nume
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    const Text('iMeditatii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                  ],
                ],
              ),
            ),
          ),

          // Linkuri & Auth
          Row(
            children: [
              if (!isMobile) ...[
                // Buton Profesori (Dinamic)
                TextButton(
                    onPressed: () => context.go('/materii'),
                    child: Text("Profesori", style: TextStyle(
                        color: isProfesoriActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                        fontWeight: isProfesoriActive ? FontWeight.bold : FontWeight.w600,
                        fontSize: 15
                    ))
                ),
                const SizedBox(width: 8),
                // Buton Exerciții (Dinamic)
                TextButton(
                    onPressed: () => context.go('/exercitii'),
                    child: Text("Exerciții", style: TextStyle(
                        color: isExercitiiActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                        fontWeight: isExercitiiActive ? FontWeight.bold : FontWeight.w600,
                        fontSize: 15
                    ))
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                const SizedBox(width: 16),
              ] else ...[
                // Iconiță Profesori (Dinamic)
                IconButton(
                  onPressed: () => context.go('/materii'),
                  icon: Icon(Icons.people, color: isProfesoriActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
                  tooltip: "Profesori",
                ),
                // Iconiță Exerciții (Dinamic)
                IconButton(
                  onPressed: () => context.go('/exercitii'),
                  icon: Icon(Icons.menu_book, color: isExercitiiActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
                  tooltip: "Exerciții",
                ),
                const SizedBox(width: 4),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                const SizedBox(width: 4),
              ],

              _buildAuthActions(context, isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthActions(BuildContext context, bool isMobile) {
    return StreamBuilder<User?>(
      // 🚀 MAGIA E AICI: Preia userul deja existent din memorie instant, fără delay!
      initialData: FirebaseAuth.instance.currentUser,
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Am scos verificarea de "ConnectionState.waiting".
        // Astfel, butoanele se randează instantaneu pe baza initialData.

        final user = snapshot.data;

        // Când NU este logat
        if (user == null) {
          return isMobile
              ? IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login, color: Color(0xFF0F172A)),
            tooltip: "Intră în cont",
          )
              : ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
            ),
            child: const Text("Intră în cont", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        }

        // Când ESTE logat (Dashboard + Profil + LOGOUT)
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(8),
              constraints: isMobile ? const BoxConstraints() : null,
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && context.mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/panou-profesor');
                    } else {
                      context.go('/panou-elev');
                    }
                  }
                } catch (e) {
                  debugPrint("Eroare dashboard: $e");
                }
              },
              icon: Icon(Icons.dashboard_customize_rounded, color: const Color(0xFF0F172A), size: isMobile ? 24 : 28),
              tooltip: "Panou de control",
            ),
            SizedBox(width: isMobile ? 8 : 4),
            IconButton(
              padding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(8),
              constraints: isMobile ? const BoxConstraints() : null,
              onPressed: () async {
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists && context.mounted) {
                    final role = (userDoc.data() as Map<String, dynamic>)['role'];
                    if (role == 'teacher') {
                      context.go('/profesor/${user.uid}');
                    } else {
                      context.go('/elev/${user.uid}');
                    }
                  }
                } catch (e) {
                  debugPrint("Eroare profil: $e");
                }
              },
              icon: Icon(Icons.account_circle, color: const Color(0xFF3B82F6), size: isMobile ? 26 : 30),
              tooltip: "Contul meu",
            ),
            SizedBox(width: isMobile ? 8 : 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                padding: isMobile ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
                constraints: isMobile ? const BoxConstraints() : null,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                icon: Icon(Icons.logout_rounded, color: Colors.redAccent, size: isMobile ? 20 : 24),
                tooltip: "Deconectare",
              ),
            ),
          ],
        );
      },
    );
  }
}