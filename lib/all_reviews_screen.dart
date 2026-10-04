import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky;
import 'sticky_footer.dart';
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

class AllReviewsScreen extends StatefulWidget {
  final String teacherId;

  const AllReviewsScreen({super.key, required this.teacherId});

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  late final Stream<QuerySnapshot> _reviews = FirebaseFirestore.instance
      .collection('teachers')
      .doc(widget.teacherId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .snapshots();
  late final Future<DocumentSnapshot> _teacher = FirebaseFirestore.instance.collection('teachers').doc(widget.teacherId).get();

  final ScrollController _scroll = ScrollController();
  int? _stars; // null = all
  String _sort = 'recente'; // recente | bune | slabe
  bool _withText = false;
  int _limit = 10;
  bool _hidden = false;
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _footKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — summary with clickable star bars (tap a bar to filter), sort,
  // "only with comments", most-mentioned tags. Meadow scene.
  // ===========================================================================
  static const Color _amber = Color(0xFFF59E0B);

  int _rOf(Map<String, dynamic> d) => ((d['rating'] as num?) ?? 0).round().clamp(0, 5).toInt();

  Widget _stars0(num v, {double size = 16}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(v >= i + 1 ? Icons.star_rounded : (v >= i + 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded), size: size, color: _amber),
        ),
      );

  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              blockers: [_mainKey, _footKey],
              cardsHidden: _hidden,
              onToggleCards: () => setState(() => _hidden = !_hidden),
              hideLabel: 'Ascunde recenziile',
              showLabel: 'Arată recenziile',
              child: StreamBuilder<QuerySnapshot>(
                stream: _reviews,
                builder: (context, snap) => StickyFooterScroll(
                  controller: _scroll,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 36, isMobile ? 12 : 24, 0),
                        child: KeyedSubtree(key: _mainKey, child: CkReveal(child: _cBody(snap, isMobile))),
                      ),
                    ),
                  ),
                  footer: KeyedSubtree(key: _footKey, child: CkFooter(isMobile: isMobile)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cBody(AsyncSnapshot<QuerySnapshot> snap, bool isMobile) {
    if (!snap.hasData) {
      return const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: Pb.primary)));
    }
    final all = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    final ratings = all.map(_rOf).toList();
    final avg = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
    final counts = List<int>.generate(6, (i) => ratings.where((r) => r == i).length);

    // tag cloud
    final tagCount = <String, int>{};
    for (final d in all) {
      for (final t in (d['tags'] as List? ?? const [])) {
        tagCount['$t'] = (tagCount['$t'] ?? 0) + 1;
      }
    }
    final topTags = tagCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    var list = all.where((d) => (_stars == null || _rOf(d) == _stars) && (!_withText || '${d['comment'] ?? ''}'.trim().isNotEmpty)).toList();
    if (_sort == 'bune') list.sort((a, b) => _rOf(b).compareTo(_rOf(a)));
    if (_sort == 'slabe') list.sort((a, b) => _rOf(a).compareTo(_rOf(b)));
    final shown = list.take(_limit).toList();

    final header = Container(
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: ckDeco(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PbButton(
                text: 'Înapoi la profil',
                icon: Icons.arrow_back,
                variant: PbVariant.outlineSecondary,
                size: PbSize.sm,
                onPressed: () => context.canPop() ? context.pop() : context.go('/profesor/${widget.teacherId}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<DocumentSnapshot>(
            future: _teacher,
            builder: (context, t) {
              final d = (t.data?.data() as Map<String, dynamic>?) ?? {};
              return Row(
                children: [
                  CkAvatar(name: '${d['name'] ?? ''}', image: '${d['image'] ?? ''}', size: 48, color: ckSubjectColor('${d['subject'] ?? ''}')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recenzii', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                        Text('${d['name'] ?? 'Profesor'}',
                            style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Column(
                children: [
                  Text(ratings.isEmpty ? '–' : avg.toStringAsFixed(1), style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: Pb.text, height: 1)),
                  const SizedBox(height: 6),
                  _stars0(avg),
                  const SizedBox(height: 4),
                  Text('${ratings.length} ${ratings.length == 1 ? 'recenzie' : 'recenzii'}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    for (var s = 5; s >= 1; s--)
                      CkHover(
                        onTap: () => setState(() {
                          _stars = _stars == s ? null : s;
                          _limit = 10;
                        }),
                        builder: (h) {
                          final sel = _stars == s;
                          final dim = _stars != null && !sel;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                            decoration: BoxDecoration(color: sel || h ? _amber.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                            child: Opacity(
                              opacity: dim ? 0.45 : 1,
                              child: Row(
                                children: [
                                  SizedBox(width: 14, child: Text('$s', style: TextStyle(fontSize: 12.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: Pb.muted))),
                                  const Icon(Icons.star_rounded, size: 13, color: _amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: ratings.isEmpty ? 0 : counts[s] / ratings.length),
                                        duration: const Duration(milliseconds: 700),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 8, color: _amber, backgroundColor: Pb.gray),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 24, child: Text('${counts[s]}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, color: Pb.muted))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (topTags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Ce spun elevii cel mai des', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pb.text)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in topTags.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Pb.primary.withOpacity(0.09), borderRadius: BorderRadius.circular(999)),
                    child: Text('${t.key} · ${t.value}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Pb.link)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    Widget chip(String label, bool sel, VoidCallback onTap) => CkHover(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? Pb.link.withOpacity(0.1) : (h ? Pb.hoverBg : Pb.surface),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: sel ? Pb.link.withOpacity(0.6) : Pb.border),
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.link : Pb.text)),
          ),
        );

    final controls = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('Recente', _sort == 'recente', () => setState(() => _sort = 'recente')),
        chip('Cele mai bune', _sort == 'bune', () => setState(() => _sort = 'bune')),
        chip('Cele mai slabe', _sort == 'slabe', () => setState(() => _sort = 'slabe')),
        const SizedBox(width: 6),
        chip('Doar cu comentariu', _withText, () => setState(() => _withText = !_withText)),
        if (_stars != null) chip('$_stars stele  ✕', true, () => setState(() => _stars = null)),
      ],
    );

    final items = shown.isEmpty
        ? Container(
            padding: const EdgeInsets.all(26),
            decoration: ckDeco(r: 14),
            child: Column(
              children: [
                Icon(all.isEmpty ? Icons.star_outline_rounded : Icons.filter_alt_off_outlined, size: 32, color: Pb.muted),
                const SizedBox(height: 8),
                Text(all.isEmpty ? 'Încă nu există recenzii.' : 'Nicio recenzie nu se potrivește filtrelor.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
              ],
            ),
          )
        : Column(
            children: [
              for (final d in shown) _ReviewCard(data: d, rating: _rOf(d), stars: _stars0),
              if (list.length > shown.length)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: PbButton(
                    text: 'Arată mai multe (${list.length - shown.length})',
                    variant: PbVariant.outlineSecondary,
                    onPressed: () => setState(() => _limit += 10),
                  ),
                ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 14),
        if (all.isNotEmpty) ...[controls, const SizedBox(height: 12)],
        items,
      ],
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
            title: Text('ALL REVIEWS', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: StreamBuilder<QuerySnapshot>(
                stream: _reviews,
                builder: (context, snap) {
                  if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.sunset));

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: RetroBlock(
                        bgColor: AppColors.cloud,
                        child: Text(
                          'NO REVIEWS FOUND.',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.5),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final rating = data['rating'] ?? 0;
                      final comment = data['comment'] ?? '';
                      final author = data['authorName'] ?? data['userName'] ?? 'ANONYMOUS PLAYER';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: RetroBlock(
                          bgColor: AppColors.cardBg,
                          padding: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.cloud,
                                  border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        author.toString().toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink, letterSpacing: 1.2),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(starIndex < rating ? Icons.star : Icons.star_border, color: AppColors.sunset, size: 28);
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  comment.toString().isEmpty ? 'NO COMMENT PROVIDED.' : '"$comment"',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: comment.toString().isEmpty ? AppColors.textMuted : AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int rating;
  final Widget Function(num v, {double size}) stars;

  const _ReviewCard({required this.data, required this.rating, required this.stars});

  @override
  Widget build(BuildContext context) {
    final author = '${data['authorName'] ?? data['userName'] ?? data['studentName'] ?? 'Elev'}';
    final comment = '${data['comment'] ?? ''}'.trim();
    final tags = (data['tags'] as List? ?? const []).map((e) => '$e').toList();
    final ts = data['createdAt'];
    final dt = ts is Timestamp ? ts.toDate() : null;
    final c = ckColorFor(author);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: ckDeco(r: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CkAvatar(name: author, image: '', size: 36, color: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(author, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Pb.text))),
                    if (dt != null)
                      Text('${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
                          style: TextStyle(fontSize: 12, color: Pb.muted)),
                  ],
                ),
                const SizedBox(height: 3),
                stars(rating, size: 15),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final t in tags)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: Pb.border)),
                          child: Text(t, style: TextStyle(fontSize: 11.5, color: Pb.text)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  comment.isEmpty ? 'Fără comentariu.' : comment,
                  style: TextStyle(fontSize: 14.5, color: comment.isEmpty ? Pb.muted : Pb.text, height: 1.55, fontStyle: comment.isEmpty ? FontStyle.italic : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}