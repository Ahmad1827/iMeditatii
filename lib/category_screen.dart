import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize;

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
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border, width: 2)),
                child: Icon(Icons.arrow_forward_ios, size: 20, color: AppColors.ink),
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

  // ---- clean extras
  final Map<String, int> _counts = {};
  final TextEditingController _search = TextEditingController();
  String _q = '';
  final GlobalKey _cardKey = GlobalKey();

  List<Color> get _tileColors => [AppColors.sky, AppColors.mustard, AppColors.sunset, AppColors.forest];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final Set<String> uniqueCategories = {};

    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final data = json.decode(response);
      final subjectData = data[widget.subject];

      if (subjectData != null) {
        final gradeData = subjectData[widget.grade.toString()];
        if (gradeData is Map<String, dynamic>) {
          uniqueCategories.addAll(gradeData.keys);
          gradeData.forEach((k, v) {
            final n = v is List ? v.length : (v is Map ? v.length : 0);
            _counts[k] = (_counts[k] ?? 0) + n;
          });
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
        final c = data['category'];
        if (c is String && c.isNotEmpty) {
          uniqueCategories.add(c);
          _counts[c] = (_counts[c] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint("Eroare Firestore: $e");
    }

    if (mounted) {
      setState(() {
        categories = uniqueCategories.toList()..sort();
        isLoading = false;
      });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/exercitii');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — searchable chapter list grouped A–Z with problem counts and a
  // size bar for each chapter. Dragon scene.
  // ===========================================================================
  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final c = ckSubjectColor(widget.subject);
    final q = _q.trim().toLowerCase();
    final list = categories.where((x) => q.isEmpty || x.toLowerCase().contains(q)).toList();
    final total = _counts.values.fold(0, (a, b) => a + b);
    final biggest = _counts.values.isEmpty ? 1 : _counts.values.reduce((a, b) => a > b ? a : b);

    Widget body;
    if (isLoading) {
      body = const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary)));
    } else if (categories.isEmpty) {
      body = Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 32, color: Pb.muted),
            const SizedBox(height: 8),
            Text('Încă nu există capitole pentru clasa asta.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(height: 4),
            Text('Revino curând sau alege altă clasă.', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
          ],
        ),
      );
    } else if (list.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Niciun capitol nu se potrivește cu „$_q”.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted)),
      );
    } else {
      final rows = <Widget>[];
      String? letter;
      for (final cat in list) {
        final l = cat.isEmpty ? '#' : cat[0].toUpperCase();
        if (l != letter) {
          letter = l;
          rows.add(Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
            child: Text(l, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c, letterSpacing: 1)),
          ));
        }
        final n = _counts[cat] ?? 0;
        rows.add(CkHover(
          onTap: () => context.go('/lista-exercitii?materie=${Uri.encodeComponent(widget.subject)}&clasa=${widget.grade}'),
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: h ? c.withOpacity(0.06) : Pb.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: h ? c.withOpacity(0.5) : Pb.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: h ? c : Pb.text)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(value: n / biggest, minHeight: 4, color: c.withOpacity(0.7), backgroundColor: Pb.gray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text(n == 1 ? '1 problemă' : '$n probleme', style: TextStyle(fontSize: 13, color: Pb.muted)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: h ? c : Pb.border),
              ],
            ),
          ),
        ));
      }
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    }

    final card = Container(
      key: _cardKey,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: ckDeco(r: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [PbButton(text: 'Înapoi', icon: Icons.arrow_back, variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _back)]),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(ckSubjectIcon(widget.subject), size: 26, color: c),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.subject}, clasa a ${widget.grade}-a', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                    Text('Capitole', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
                  ],
                ),
              ),
              if (!isLoading && categories.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${categories.length}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Pb.text)),
                    Text('$total probleme', style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.length > 4)
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(fontSize: 15, color: Pb.text),
              cursorColor: Pb.primary,
              decoration: Pb.input(hint: 'Caută un capitol').copyWith(
                prefixIcon: Icon(Icons.search, size: 19, color: Pb.muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
          body,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: HomeSky(
        scene: HomeScene.fantasy,
        blockers: [_cardKey],
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 24 : 48),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: CkReveal(child: card)),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              "${widget.subject} // LEVEL ${widget.grade}".toUpperCase(),
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0),
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
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.5),
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
                                onTap: () => context.go('/exercitii/${widget.subject}/${widget.grade}', extra: category),
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