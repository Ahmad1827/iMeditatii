import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
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
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                child: const Icon(
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
  Map<String, dynamic> classData = {};

  final List<Color> _tileColors = [
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
    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final data = json.decode(response);

      final subjectData = data[widget.subject];
      if (subjectData != null) {
        final gradeData = subjectData[widget.grade.toString()];
        if (gradeData != null) {
          setState(() {
            categories = gradeData.keys.toList();
            classData = gradeData;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        categories = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        categories = [];
        isLoading = false;
      });
      debugPrint("Eroare la încărcarea categoriilor: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          "${widget.subject} // LEVEL ${widget.grade}".toUpperCase(),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.sunset))
              : categories.isEmpty
              ? Center(
            child: RetroBlock(
              bgColor: AppColors.cloud,
              child: const Text(
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
  }
}