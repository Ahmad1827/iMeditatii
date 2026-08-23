import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class CategoryTile extends StatefulWidget {
  final String title;
  final Color bgColor;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.title,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.bgColor,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  final String subject;
  final int grade;

  const CategoryScreen({super.key, required this.subject, required this.grade});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<String> categories = [];
  bool isLoading = true;

  List<Color> get _tileColors => [
    AppColors.sky,
    AppColors.mustard,
    AppColors.sunset,
    AppColors.forest,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    Set<String> uniqueCategories = {};

    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final data = json.decode(response);
      final subjectData = data[widget.subject];

      if (subjectData != null) {
        final gradeData = subjectData[widget.grade.toString()];
        if (gradeData != null) {
          uniqueCategories.addAll((gradeData as Map<String, dynamic>).keys);
        }
      }
    } catch (e) {
      debugPrint("Eroare JSON: $e");
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('subject', isEqualTo: widget.subject)
          .where('grade', isEqualTo: widget.grade.toString())
          .where('approved', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          uniqueCategories.add(data['category'] as String);
        }
      }
    } catch (e) {
      debugPrint("Eroare Firestore: $e");
    }

    if (mounted) {
      setState(() {
        categories = uniqueCategories.toList();
        categories.sort();
        isLoading = false;
      });
    }
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
              "${widget.subject} // LEVEL ${widget.grade}".toUpperCase(),
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/exercitii/${widget.subject}');
                }
              },
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.sunset))
                  : categories.isEmpty
                      ? Center(
                          child: RetroBlock(
                            bgColor: AppColors.cloud,
                            child: Text(
                              "NO QUEST CATEGORIES FOUND.",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final color = _tileColors[index % _tileColors.length];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: CategoryTile(
                                title: category,
                                bgColor: color,
                                onTap: () {
                                  context.go(
                                    '/exercitii/${widget.subject}/${widget.grade}',
                                    extra: category,
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }
}