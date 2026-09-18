import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'custom_navbar.dart';

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({super.key});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedSubject = "PYTHON";
  String _selectedGrade = "9";
  bool _isSaving = false;

  final List<Map<String, TextEditingController>> _sections = [
    {
      "heading": TextEditingController(text: "1. Introducere"),
      "text": TextEditingController(),
      "code": TextEditingController(),
      "callout": TextEditingController(),
    }
  ];

  bool get _isAdmin => FirebaseAuth.instance.currentUser?.email == 'ahmadarnaoute1896@gmail.com';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _moduleCtrl.dispose();
    _descCtrl.dispose();
    for (var s in _sections) {
      s["heading"]?.dispose();
      s["text"]?.dispose();
      s["code"]?.dispose();
      s["callout"]?.dispose();
    }
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sections.add({
        "heading": TextEditingController(text: "${_sections.length + 1}. Secțiune nouă"),
        "text": TextEditingController(),
        "code": TextEditingController(),
        "callout": TextEditingController(),
      });
    });
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    setState(() {
      _sections[index]["heading"]?.dispose();
      _sections[index]["text"]?.dispose();
      _sections[index]["code"]?.dispose();
      _sections[index]["callout"]?.dispose();
      _sections.removeAt(index);
    });
  }

  Future<void> _submitArticle() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final authorName = userDoc.data()?['name'] ?? 'Guild Master';

      final builtSections = _sections.map((s) {
        return {
          "heading": s["heading"]!.text.trim(),
          "text": s["text"]!.text.trim(),
          "code": s["code"]!.text.trim().isEmpty ? null : s["code"]!.text.trim(),
          "callout": s["callout"]!.text.trim().isEmpty ? null : s["callout"]!.text.trim(),
          "lang": _selectedSubject == "PYTHON" ? "python" : "cpp",
        };
      }).toList();

      final articleData = {
        "title": _titleCtrl.text.trim(),
        "subject": _selectedSubject,
        "grade": _selectedGrade,
        "module": _moduleCtrl.text.trim().toUpperCase(),
        "desc": _descCtrl.text.trim(),
        "author": authorName,
        "authorUid": user.uid,
        "date": "${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}",
        "readTime": "${(_descCtrl.text.length / 200).ceil() + 3} MIN",
        "sections": builtSections,
        "approved": _isAdmin, // Auto-approve if owner, otherwise hold for review
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('resources').add(articleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAdmin ? "ARTICOL PUBLICAT ÎN CODEX!" : "ARTICOL TRIMIS SPRE APROBARE DE ADMIN.",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: AppColors.forest,
          ),
        );
        context.go('/panou-profesor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("EROARE: $e"), backgroundColor: AppColors.sunset),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("CONTRIBUTE TO CODEX", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2.5), child: Container(color: AppColors.border, height: 2.5)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(
                      _isAdmin ? "ADMIN PUBLISHING PROTOCOL ACTIVE (INSTANT PUBLISH)" : "TEACHER SUBMISSION (REQUIRES ADMIN REVIEW)",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metadata Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: _inputDecoration("DISCIPLINE"),
                          dropdownColor: AppColors.cardBg,
                          items: ["PYTHON", "C++", "MATEMATICĂ"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          decoration: _inputDecoration("CLASA"),
                          dropdownColor: AppColors.cardBg,
                          items: ["9", "10", "11", "12"].map((g) => DropdownMenuItem(value: g, child: Text("CLASA A $g-A", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (val) => setState(() => _selectedGrade = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _moduleCtrl,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    decoration: _inputDecoration("CAPITOL / MODUL (EX: 2. STRUCTURI DE CONTROL)"),
                    validator: (v) => v!.isEmpty ? "CAMP OBLIGATORIU" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleCtrl,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    decoration: _inputDecoration("TITLU ARTICOL"),
                    validator: (v) => v!.isEmpty ? "CAMP OBLIGATORIU" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    decoration: _inputDecoration("REZUMAT SCURT PENTRU CARD"),
                    validator: (v) => v!.isEmpty ? "CAMP OBLIGATORIU" : null,
                  ),
                  const SizedBox(height: 28),

                  // Dynamic Section Builder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SECȚIUNI LECȚIE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: _addSection,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("ADAUGA SECȚIUNE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(_sections.length, (index) {
                    final sec = _sections[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: sec["heading"],
                                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
                                  decoration: _inputDecoration("TITLU SECȚIUNE"),
                                ),
                              ),
                              if (_sections.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.delete, color: AppColors.sunset),
                                  onPressed: () => _removeSection(index),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sec["text"],
                            maxLines: 4,
                            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                            decoration: _inputDecoration("TEXT EXPLICAȚIE"),
                            validator: (v) => v!.isEmpty ? "TEXTUL NU POATE FI GOL" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sec["code"],
                            maxLines: 4,
                            style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF55EFC4), fontWeight: FontWeight.bold),
                            decoration: _inputDecoration("EXEMPLU DE COD (OPȚIONAL)").copyWith(
                              fillColor: const Color(0xFF1B242B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sec["callout"],
                            maxLines: 2,
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset),
                            decoration: _inputDecoration("CALLOUT / SFAT DE COD (OPȚIONAL)"),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _isSaving ? null : _submitArticle,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isAdmin ? "PUBLICĂ IMEDIAT" : "TRIMITE SPRE APROBARE", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
      filled: true,
      fillColor: AppColors.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 2.5)),
    );
  }
}