import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'custom_navbar.dart';

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

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({super.key});

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  final List<Map<String, dynamic>> specializations = [
    {'name': 'Matematică', 'icon': Icons.functions, 'color': AppColors.sunset, 'desc': 'Algebră, Geometrie, Analiză și Bacalaureat.'},
    {'name': 'Fizică', 'icon': Icons.bolt, 'color': AppColors.mustard, 'desc': 'Mecanică, Termodinamică, Electricitate și Optică.'},
    {'name': 'Chimie', 'icon': Icons.science, 'color': AppColors.sky, 'desc': 'Chimie Organică, Anorganică și admitere Medicină.'},
    {'name': 'Informatică', 'icon': Icons.data_object, 'color': AppColors.forest, 'desc': 'Algoritmi, C++, Python și pregătire olimpiade.'},
    {'name': 'Limba Română', 'icon': Icons.menu_book, 'color': AppColors.sunset, 'desc': 'Eseuri, Gramatică, pregătire Evaluare și BAC.'},
    {'name': 'Engleză', 'icon': Icons.language, 'color': AppColors.mustard, 'desc': 'Gramatică, Vocabular, Conversație și Cambridge.'},
    {'name': 'Franceză', 'icon': Icons.tour, 'color': AppColors.sky, 'desc': 'Nivel A1-C1, atestate DELF și conversație.'},
    {'name': 'Istorie', 'icon': Icons.account_balance, 'color': AppColors.forest, 'desc': 'Istoria Românilor, Istorie Universală și BAC.'},
    {'name': 'Geografie', 'icon': Icons.public, 'color': AppColors.sunset, 'desc': 'Geografia Europei, României și cartografie.'},
  ];

  String searchQuery = '';
  bool _loadingTeachers = true;
  Map<String, int> teacherCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('teachers')
          .where('active', isEqualTo: true)
          .get();

      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final subject = doc.data()['subject'] ?? '';
        counts[subject] = (counts[subject] ?? 0) + 1;
      }

      setState(() {
        teacherCounts = counts;
        _loadingTeachers = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
      if (mounted) setState(() => _loadingTeachers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = specializations.where((s) =>
        s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: _buildHeaderAndSearch(),
                      ),
                    ),
                  ),
                ),
                if (_loadingTeachers)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.sunset)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: _buildBentoGrid(filtered),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppColors.sky,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text(
            "GUILD ROSTER",
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "SELECT DISCIPLINE",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "OVER 100 MASTERS AWAIT TO BEGIN YOUR TRAINING.",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 48),
        Container(
          width: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.ink, offset: Offset(6, 6)),
            ],
          ),
          child: TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: "SEARCH DISCIPLINE...",
              hintStyle: TextStyle(
                color: Colors.black38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.ink, size: 28),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return RetroBlock(
        bgColor: AppColors.cloud,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text(
              "NO DISCIPLINES FOUND.",
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 1.2,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final spec = data[index];
        final count = teacherCounts[spec['name']] ?? 0;
        return RetroCategoryCard(
          data: spec,
          count: count,
          onTap: () {
            context.go(
              '/materii/${Uri.encodeComponent(spec['name'])}',
              extra: spec,
            );
          },
        );
      },
    );
  }
}

class RetroCategoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int count;
  final VoidCallback onTap;

  const RetroCategoryCard({
    super.key,
    required this.data,
    required this.count,
    required this.onTap,
  });

  @override
  State<RetroCategoryCard> createState() => _RetroCategoryCardState();
}

class _RetroCategoryCardState extends State<RetroCategoryCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.data['color'];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(24),
          transform: Matrix4.translationValues(
            _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
            _isPressed ? 4.0 : (_isHovering ? -4.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: _isPressed ? const Offset(0, 0) : const Offset(8, 8),
                blurRadius: 0,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      border: Border.all(color: AppColors.ink, width: 3),
                    ),
                    child: Icon(widget.data['icon'], color: AppColors.ink, size: 36),
                  ),
                  if (widget.count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                      child: Text(
                        "${widget.count} MASTERS",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.data['name'].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.data['desc'].toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}