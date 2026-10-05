import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'brand_mark.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant;

// =============================================================================
// Legal pages: Termeni și condiții + Politica de confidențialitate
//
// Retro  - unchanged ("USER AGREEMENT" / "DATA DIRECTIVE" documents).
// Clean  - a reader layout:
//            * reading-progress bar under the navbar
//            * table of contents that follows the scroll and jumps on click
//              (side panel on desktop, chip strip on phones)
//            * "Pe scurt" card with the three things that matter most
//            * numbered section cards, each with its own colour
//            * switch between the two documents without leaving the page
//
// The legal text itself is the same in both styles and lives in one place
// (_termsDoc / _privacyDoc at the bottom of this file).
// =============================================================================

// Retro palette of this page (light only, as before). main.dart hides it.
class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

// =============================================================================
// DATA
// =============================================================================
class _LegalSection {
  final String retroTitle;
  final String title;
  final IconData icon;
  final String body;

  const _LegalSection(this.retroTitle, this.title, this.icon, this.body);
}

class _LegalDoc {
  final String route;
  final String otherRoute;
  final String otherTitle;
  final String title;
  final String badge;
  final IconData badgeIcon;
  final Color accent;
  final String intro;
  final List<(IconData, String)> summary;
  final List<_LegalSection> sections;

  // Retro labels.
  final String retroBar;
  final String retroBadge;
  final Color retroBadgeBg;
  final Color retroBadgeFg;
  final String retroTitle;

  const _LegalDoc({
    required this.route,
    required this.otherRoute,
    required this.otherTitle,
    required this.title,
    required this.badge,
    required this.badgeIcon,
    required this.accent,
    required this.intro,
    required this.summary,
    required this.sections,
    required this.retroBar,
    required this.retroBadge,
    required this.retroBadgeBg,
    required this.retroBadgeFg,
    required this.retroTitle,
  });
}

const String _updatedRetro = 'LAST LOG: NOVEMBER 1, 2024';
const String _updatedClean = '1 noiembrie 2024';

const Color _lGreen = Color(0xFF10B981);
const Color _lBlue = Color(0xFF3B82F6);
const Color _lViolet = Color(0xFF8B5CF6);
const Color _lAmber = Color(0xFFF59E0B);
const Color _lRose = Color(0xFFE5484D);
const Color _lTeal = Color(0xFF14B8A6);
const List<Color> _lCycle = [_lGreen, _lBlue, _lViolet, _lAmber, _lRose, _lTeal];

// =============================================================================
// SCREENS
// =============================================================================
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(key: ValueKey('legal-terms'), doc: _termsDoc);
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(key: ValueKey('legal-privacy'), doc: _privacyDoc);
}

class _LegalPage extends StatefulWidget {
  final _LegalDoc doc;

  const _LegalPage({super.key, required this.doc});

  @override
  State<_LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<_LegalPage> {
  final ScrollController _scroll = ScrollController();
  final ScrollController _chipScroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  late final List<GlobalKey> _keys = [for (final _ in widget.doc.sections) GlobalKey()];
  late final List<GlobalKey> _chipKeys = [for (final _ in widget.doc.sections) GlobalKey()];

  double _progress = 0;
  int _active = 0;
  bool _copied = false;

  _LegalDoc get doc => widget.doc;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  // Which section is being read: the last one whose top has passed a line
  // a little below the top of the reading area.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final progress = pos.maxScrollExtent <= 0 ? 1.0 : (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);

    var active = 0;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is RenderBox && viewport.hasSize) {
      final line = viewport.localToGlobal(Offset.zero).dy + 150;
      for (var i = 0; i < _keys.length; i++) {
        final box = _keys[i].currentContext?.findRenderObject();
        if (box is RenderBox && box.hasSize && box.localToGlobal(Offset.zero).dy <= line) active = i;
      }
    }
    if (pos.pixels >= pos.maxScrollExtent - 4) active = _keys.length - 1;

    if (active != _active || (progress - _progress).abs() > 0.004) {
      final changed = active != _active;
      setState(() {
        _active = active;
        _progress = progress;
      });
      if (changed) _revealChip(active);
    }
  }

  void _revealChip(int i) {
    final ctx = _chipKeys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _jumpTo(int i) {
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, alignment: 0.04, duration: const Duration(milliseconds: 420), curve: Curves.easeInOutCubic);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(FirebaseAuth.instance.currentUser == null ? '/inregistrare' : '/');
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: '${Uri.base.origin}${doc.route}'));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  int get _readMinutes {
    final words = doc.sections.fold<int>(0, (n, s) => n + s.body.split(RegExp(r'\s+')).length);
    return (words / 180).ceil().clamp(1, 60);
  }

  String _fix(String s) => s.replaceAll('iMeditatii', 'iMeditații');

  bool get _dark => Pb.page.computeLuminance() < 0.5;

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) => s.isClean ? _buildClean(MediaQuery.of(context).size.width < 900) : _buildRetro(),
    );
  }

  // ===========================================================================
  // CLEAN
  // ===========================================================================
  Widget _buildClean(bool isMobile) {
    final content = SingleChildScrollView(
      key: _viewportKey,
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 8, isMobile ? 18 : 30, isMobile ? 14 : 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cHeader(isMobile),
          const SizedBox(height: 18),
          _cSummary(isMobile),
          const SizedBox(height: 22),
          for (var i = 0; i < doc.sections.length; i++)
            Padding(
              key: _keys[i],
              padding: const EdgeInsets.only(bottom: 14),
              child: _cSection(i, isMobile),
            ),
          const SizedBox(height: 8),
          _cEnd(isMobile),
          const SizedBox(height: 26),
          Center(child: Text('© 2026 iMeditații', style: TextStyle(fontSize: 13, color: Pb.muted))),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          _cProgressBar(),
          if (isMobile) _cChipStrip(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: isMobile
                    ? content
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 290, child: _cSidePanel()),
                          Expanded(child: Scrollbar(controller: _scroll, child: content)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cCard({Color? tint, bool hover = false, double r = 16}) => BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: tint != null && hover ? tint.withOpacity(0.5) : Pb.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: tint != null && hover
                ? tint.withOpacity(_dark ? 0.2 : 0.15)
                : Colors.black.withOpacity(_dark ? 0.3 : 0.06),
            blurRadius: hover ? 30 : 22,
            offset: Offset(0, hover ? 10 : 7),
          ),
        ],
      );

  Widget _cProgressBar() => Container(
        height: 3,
        color: Pb.border.withOpacity(0.5),
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 120),
          alignment: Alignment.centerLeft,
          widthFactor: _progress.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [doc.accent, _lTeal]),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
            ),
          ),
        ),
      );

  // ------------------------------------------------------------------ header
  Widget _cDocSwitch() {
    Widget tab(String label, IconData icon, bool sel, Color c, VoidCallback onTap) => _LHover(
          onTap: sel ? null : onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? Pb.surface : (h ? Pb.surface.withOpacity(0.6) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? c.withOpacity(0.4) : Colors.transparent),
              boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: sel || h ? c : Pb.muted),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel || h ? Pb.text : Pb.muted)),
              ],
            ),
          ),
        );

    final terms = doc.route == _termsDoc.route;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab('Termeni', Icons.description_outlined, terms, _termsDoc.accent, () => context.go(_termsDoc.route)),
          tab('Confidențialitate', Icons.shield_outlined, !terms, _privacyDoc.accent, () => context.go(_privacyDoc.route)),
        ],
      ),
    );
  }

  Widget _cMeta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Pb.muted),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
        ],
      );

  Widget _cHeader(bool isMobile) {
    final c = doc.accent;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cCard(r: 20).copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.alphaBlend(c.withOpacity(0.12), Pb.surface), Pb.surface],
          stops: const [0, 0.65],
        ),
      ),
      child: Stack(
        children: [
          // Big faded icon in the corner.
          Positioned(
            right: -18,
            top: -22,
            child: IgnorePointer(child: Icon(doc.badgeIcon, size: 170, color: c.withOpacity(_dark ? 0.08 : 0.07))),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _cDocSwitch(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(doc.badgeIcon, size: 14, color: c),
                          const SizedBox(width: 5),
                          Text(doc.badge, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  doc.title,
                  style: TextStyle(
                      fontSize: isMobile ? 27 : 36, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.8, height: 1.12),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(doc.intro, style: TextStyle(fontSize: 15.5, color: Pb.muted, height: 1.55)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _cMeta(Icons.event_outlined, 'Actualizat la $_updatedClean'),
                    _cMeta(Icons.schedule, 'Aproximativ $_readMinutes min de citit'),
                    _cMeta(Icons.format_list_numbered, '${doc.sections.length} secțiuni'),
                    _LHover(
                      onTap: _copyLink,
                      builder: (h) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_copied ? Icons.check : Icons.link, size: 15, color: _copied ? _lGreen : (h ? c : Pb.muted)),
                          const SizedBox(width: 5),
                          Text(
                            _copied ? 'Link copiat' : 'Copiază linkul',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: _copied ? _lGreen : (h ? c : Pb.muted),
                              decoration: h && !_copied ? TextDecoration.underline : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ summary
  Widget _cSummary(bool isMobile) {
    Widget point(int i) {
      final (icon, text) = doc.summary[i];
      final c = _lCycle[i % _lCycle.length];
      return _LHover(
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: h ? c.withOpacity(0.10) : Pb.hoverBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: h ? c.withOpacity(0.45) : Colors.transparent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: h ? c : c.withOpacity(0.16), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 17, color: h ? Colors.white : c),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Pb.text, height: 1.45)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 18, color: _lAmber),
              const SizedBox(width: 6),
              Text('Pe scurt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Rezumat orientativ; textul complet de mai jos este cel care contează.',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < doc.summary.length; i++) ...[if (i > 0) const SizedBox(height: 8), point(i)],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < doc.summary.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: point(i)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ sections
  // Body text: plain paragraphs, plus "• Label: text" lines shown as a list.
  List<Widget> _cBody(String body, Color c) {
    final out = <Widget>[];
    final style = TextStyle(fontSize: 15.5, color: Pb.text, height: 1.68);
    for (final raw in _fix(body).split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        out.add(const SizedBox(height: 10));
      } else if (line.startsWith('•')) {
        final text = line.substring(1).trim();
        final cut = text.indexOf(':');
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 10),
                child: Icon(Icons.check_circle, size: 16, color: c),
              ),
              Expanded(
                child: SelectableText.rich(
                  TextSpan(
                    style: style,
                    children: cut < 0
                        ? [TextSpan(text: text)]
                        : [
                            TextSpan(text: text.substring(0, cut + 1), style: const TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(text: text.substring(cut + 1)),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ));
      } else {
        out.add(SelectableText(line, style: style));
      }
    }
    return out;
  }

  Widget _cSection(int i, bool isMobile) {
    final s = doc.sections[i];
    final c = _lCycle[i % _lCycle.length];
    final active = i == _active;

    return _LHover(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: _cCard(tint: c, hover: h || active),
        child: Stack(
            children: [
              // Colour strip down the left edge.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  color: h || active ? c : c.withOpacity(0.25),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isMobile ? 18 : 24, 18, isMobile ? 16 : 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: h ? c : c.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(s.icon, size: 20, color: h ? Colors.white : c),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Secțiunea ${i + 1}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.3)),
                                const SizedBox(height: 1),
                                Text(s.title,
                                    style: TextStyle(
                                        fontSize: isMobile ? 18 : 20,
                                        fontWeight: FontWeight.w700,
                                        color: Pb.text,
                                        letterSpacing: -0.3,
                                        height: 1.2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ..._cBody(s.body, c),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  // ------------------------------------------------------------------ end card
  Widget _cEnd(bool isMobile) {
    final buttons = [
      PbButton(text: 'Am înțeles', icon: Icons.check, onPressed: _goBack),
      PbButton(
        text: doc.otherTitle,
        icon: Icons.arrow_forward,
        variant: PbVariant.outlineSecondary,
        onPressed: () => context.go(doc.otherRoute),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: _cCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(size: 38, glow: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ai ajuns la final', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Pb.text)),
                    const SizedBox(height: 3),
                    Text(
                      'Dacă ceva nu e clar, scrie-ne la adresa de suport afișată pe platformă.',
                      style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: buttons),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ contents (desktop)
  Widget _cTocRow(int i) {
    final c = _lCycle[i % _lCycle.length];
    final active = i == _active;
    final done = i < _active;
    return _LHover(
      onTap: () => _jumpTo(i),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.12) : (h ? Pb.hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c : (done ? c.withOpacity(0.16) : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(color: active || done ? Colors.transparent : (h ? c : Pb.border), width: 1.5),
              ),
              child: done
                  ? Icon(Icons.check, size: 14, color: c)
                  : Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : (h ? c : Pb.muted))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                doc.sections[i].title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? c : (h ? Pb.text : Pb.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cSidePanel() {
    final pct = (_progress * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LHover(
            onTap: _goBack,
            builder: (h) => Row(
              children: [
                AnimatedSlide(
                  offset: Offset(h ? -0.2 : 0, 0),
                  duration: const Duration(milliseconds: 170),
                  child: Icon(Icons.arrow_back, size: 17, color: h ? Pb.link : Pb.muted),
                ),
                const SizedBox(width: 7),
                Text('Înapoi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: h ? Pb.link : Pb.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            decoration: _cCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Text('CUPRINS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Pb.muted, letterSpacing: 0.6)),
                ),
                for (var i = 0; i < doc.sections.length; i++) _cTocRow(i),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Pb.gray,
                          color: doc.accent,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        pct >= 100 ? 'Ai citit tot documentul' : 'Ai parcurs $pct%',
                        style: TextStyle(fontSize: 12.5, color: pct >= 100 ? doc.accent : Pb.muted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ contents (phone)
  Widget _cChipStrip() => Container(
        decoration: BoxDecoration(color: Pb.surface, border: Border(bottom: BorderSide(color: Pb.border))),
        child: SingleChildScrollView(
          controller: _chipScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < doc.sections.length; i++)
                Padding(
                  key: _chipKeys[i],
                  padding: const EdgeInsets.only(right: 6),
                  child: Builder(builder: (context) {
                    final c = _lCycle[i % _lCycle.length];
                    final active = i == _active;
                    return _LHover(
                      onTap: () => _jumpTo(i),
                      builder: (h) => AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? c.withOpacity(0.14) : (h ? Pb.hoverBg : Colors.transparent),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? c.withOpacity(0.6) : Pb.border),
                        ),
                        child: Text(
                          '${i + 1}. ${doc.sections[i].title}',
                          style: TextStyle(
                              fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? c : Pb.text),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      );

  // ===========================================================================
  // RETRO (unchanged look)
  // ===========================================================================
  Widget _retroSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink, width: 3),
              boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetro() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
          onPressed: () => context.go('/inregistrare'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
        title: Text(
          doc.retroBar,
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _LRetroBlock(
              bgColor: AppColors.cloud,
              padding: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: doc.retroBadgeBg, border: Border.all(color: AppColors.ink, width: 2)),
                    child: Text(
                      doc.retroBadge,
                      style: TextStyle(color: doc.retroBadgeFg, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    doc.retroTitle,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    _updatedRetro,
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  for (final s in doc.sections) _retroSection(s.retroTitle, s.body),
                  const SizedBox(height: 32),
                  Container(height: 3, color: AppColors.ink),
                  const SizedBox(height: 32),
                  _LRetroButton(
                    text: 'ACKNOWLEDGE & RETURN',
                    isFullWidth: true,
                    bgColor: AppColors.sky,
                    textColor: AppColors.ink,
                    onPressed: () => context.go('/inregistrare'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SMALL PIECES
// =============================================================================
class _LHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  const _LHover({required this.builder, this.onTap});

  @override
  State<_LHover> createState() => _LHoverState();
}

class _LHoverState extends State<_LHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(_hover);
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.onTap == null
          ? child
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: child),
    );
  }
}

class _LRetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;

  const _LRetroBlock({
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
          BoxShadow(color: AppColors.ink, offset: Offset(shadowOffset, shadowOffset), blurRadius: 0),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class _LRetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;
  final bool isFullWidth;

  const _LRetroButton({
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
    this.isFullWidth = false,
  });

  @override
  State<_LRetroButton> createState() => _LRetroButtonState();
}

class _LRetroButtonState extends State<_LRetroButton> {
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
          widget.onPressed();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// THE TEXT
// =============================================================================
const _LegalDoc _termsDoc = _LegalDoc(
  route: '/termeni-si-conditii',
  otherRoute: '/politica-confidentialitate',
  otherTitle: 'Politica de confidențialitate',
  title: 'Termeni și condiții',
  badge: 'Acord de utilizare',
  badgeIcon: Icons.description_outlined,
  accent: _lGreen,
  intro: 'Regulile după care funcționează iMeditații, pentru elevi și pentru profesori. '
      'Creând un cont, confirmi că le-ai citit și că ești de acord cu ele.',
  summary: [
    (Icons.storefront_outlined, 'iMeditații este un intermediar. Profesorii sunt independenți, nu angajații platformei.'),
    (Icons.payments_outlined, 'Plățile se fac doar prin platformă, prin Stripe. Ocolirea lor duce la suspendarea contului.'),
    (Icons.receipt_long_outlined, 'Profesorii își declară singuri veniturile și își plătesc taxele.'),
  ],
  retroBar: 'TERMS OF SERVICE',
  retroBadge: 'OFFICIAL SYSTEM DOCUMENT',
  retroBadgeBg: AppColors.mustard,
  retroBadgeFg: AppColors.ink,
  retroTitle: 'USER AGREEMENT',
  sections: [
    _LegalSection(
      '1. SYSTEM ACCESS',
      'Acceptarea termenilor',
      Icons.handshake_outlined,
      "Acest document reprezintă un acord legal între dumneavoastră (în calitate de utilizator, profesor sau elev) și platforma iMeditatii. Prin crearea unui cont și utilizarea serviciilor noastre, confirmați că ați citit, ați înțeles și acceptați integral acești Termeni și Condiții. Dacă nu sunteți de acord, vă rugăm să nu utilizați platforma.",
    ),
    _LegalSection(
      '2. PLATFORM STATUS',
      'Rolul platformei',
      Icons.storefront_outlined,
      "iMeditatii funcționează exclusiv ca un furnizor de tehnologie și intermediar (marketplace). Noi punem la dispoziție o infrastructură digitală pentru ca elevii și profesorii să poată comunica, partaja resurse și desfășura apeluri video. iMeditatii nu este angajatorul profesorilor înregistrați pe platformă. Fiecare profesor activează ca un profesionist independent.",
    ),
    _LegalSection(
      '3. USER VERIFICATION',
      'Conturi și verificare',
      Icons.verified_user_outlined,
      "Utilizatorii se obligă să furnizeze informații reale, precise și complete. Conturile de profesor sunt supuse unui proces de verificare internă înainte de a deveni active pe platformă. Ne rezervăm dreptul de a respinge sau suspenda orice cont care prezintă informații false sau care încalcă standardele noastre de calitate.",
    ),
    _LegalSection(
      '4. TRANSACTIONS',
      'Plăți și comisioane',
      Icons.payments_outlined,
      "Toate tranzacțiile financiare sunt procesate în mod securizat prin partenerul nostru, Stripe. Elevii achită contravaloarea ședințelor direct prin platformă. iMeditatii va reține un comision de administrare și procesare din suma achitată, restul fiind transferat direct în contul bancar al profesorului.\n\nProfesorii sunt unici responsabili pentru declararea veniturilor obținute și plata taxelor și impozitelor aferente conform legislației fiscale din România.",
    ),
    _LegalSection(
      '5. SYSTEM RULES',
      'Reguli de conduită',
      Icons.gavel,
      "Ne dorim o comunitate sigură și respectuoasă. Este strict interzisă utilizarea unui limbaj licențios, hărțuirea, discriminarea sau partajarea de conținut inadecvat. De asemenea, încercarea de a ocoli sistemul de plăți al platformei (ex. solicitarea plății în numerar sau prin alte aplicații) va duce la suspendarea permanentă a conturilor implicate.",
    ),
    _LegalSection(
      '6. LIMITATIONS',
      'Limitarea răspunderii',
      Icons.info_outline,
      "Deși depunem eforturi constante pentru a asigura calitatea profesorilor, iMeditatii nu garantează obținerea unor anumite note sau rezultate academice. Responsabilitatea actului educațional revine profesorului, iar responsabilitatea asimilării informației revine elevului. Nu răspundem pentru eventualele întreruperi de funcționare cauzate de furnizorii de internet sau forță majoră.",
    ),
  ],
);

const _LegalDoc _privacyDoc = _LegalDoc(
  route: '/politica-confidentialitate',
  otherRoute: '/termeni-si-conditii',
  otherTitle: 'Termeni și condiții',
  title: 'Politica de confidențialitate',
  badge: 'Conform GDPR',
  badgeIcon: Icons.shield_outlined,
  accent: _lBlue,
  intro: 'Ce date colectăm, de ce le folosim, cu cine le împărțim și ce drepturi ai asupra lor.',
  summary: [
    (Icons.block, 'Nu vindem, nu închiriem și nu comercializăm datele tale personale.'),
    (Icons.credit_card_off_outlined, 'Detaliile bancare sunt colectate de Stripe și nu sunt stocate pe serverele noastre.'),
    (Icons.delete_outline, 'Poți cere oricând ștergerea permanentă a contului și a datelor asociate.'),
  ],
  retroBar: 'PRIVACY POLICY',
  retroBadge: 'GDPR COMPLIANT',
  retroBadgeBg: AppColors.forest,
  retroBadgeFg: Colors.white,
  retroTitle: 'DATA DIRECTIVE',
  sections: [
    _LegalSection(
      '1. DATA COLLECTION',
      'Ce date colectăm',
      Icons.badge_outlined,
      "Când vă creați un cont pe iMeditatii, colectăm informații cu caracter personal precum: numele complet, adresa de email, numărul de telefon și, opțional, fotografia de profil. Pentru procesarea plăților, detaliile bancare sunt colectate direct de procesatorul nostru securizat (Stripe) și nu sunt stocate pe serverele noastre.",
    ),
    _LegalSection(
      '2. DATA USAGE',
      'Cum folosim datele',
      Icons.settings_suggest_outlined,
      "Datele dumneavoastră sunt utilizate exclusiv pentru a asigura buna funcționare a platformei. Aceasta include: crearea și administrarea contului, facilitarea comunicării (chat și apeluri video) între elevi și profesori, procesarea plăților, afișarea profilului public (pentru profesori) și trimiterea de notificări legate de activitatea contului.",
    ),
    _LegalSection(
      '3. SYSTEM SECURITY',
      'Securitatea datelor',
      Icons.lock_outline,
      "Siguranța datelor dumneavoastră este o prioritate. Folosim infrastructura securizată Firebase (operată de Google) pentru stocarea bazei de date. Toate comunicațiile și datele transferate între dispozitivul dumneavoastră și serverele noastre sunt criptate (SSL/TLS).",
    ),
    _LegalSection(
      '4. THIRD-PARTY SHARING',
      'Partajarea cu terți',
      Icons.share_outlined,
      "Nu vindem, nu închiriem și nu comercializăm datele dumneavoastră personale. Informațiile sunt partajate doar cu parteneri de încredere esențiali funcționării serviciului, precum Stripe (pentru procesarea plăților) și Google Firebase (pentru găzduire cloud), ambii fiind conformi cu reglementările GDPR.",
    ),
    _LegalSection(
      '5. USER RIGHTS',
      'Drepturile tale',
      Icons.how_to_reg_outlined,
      "Conform Regulamentului General privind Protecția Datelor (GDPR), aveți următoarele drepturi:\n• Dreptul de acces: Puteți solicita un raport cu datele pe care le deținem despre dumneavoastră.\n• Dreptul la rectificare: Puteți corecta datele inexacte din secțiunea 'Editează profil'.\n• Dreptul la ștergere ('Dreptul de a fi uitat'): Puteți solicita oricând ștergerea permanentă a contului și a datelor asociate.\n\nPentru exercitarea acestor drepturi, ne puteți contacta la adresa de email de suport afișată pe platformă.",
    ),
  ],
);