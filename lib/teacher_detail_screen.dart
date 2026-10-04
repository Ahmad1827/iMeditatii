import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'custom_navbar.dart' show CustomNavbar;
import 'home_ambient.dart' show HomeSky;
import 'sticky_footer.dart';
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbVariant, PbSize, PbLink, PbContainer, showPbModal;

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

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.bgColor ?? AppColors.sunset;
    final effectiveText = widget.textColor ?? Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
            color: effectiveBg,
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveText, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: effectiveText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherDetailScreen extends StatefulWidget {
  final String teacherId;

  const TeacherDetailScreen({required this.teacherId, super.key});

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  late Future<DocumentSnapshot> _future = FirebaseFirestore.instance.collection('teachers').doc(widget.teacherId).get();
  final ScrollController _scroll = ScrollController();

  String get teacherId => widget.teacherId;

  @override
  void didUpdateWidget(covariant TeacherDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.teacherId != widget.teacherId) {
      _future = FirebaseFirestore.instance.collection('teachers').doc(widget.teacherId).get();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) => s.isClean
          ? _buildClean(context, MediaQuery.of(context).size.width < 750)
          : _buildRetro(context, MediaQuery.of(context).size.width < 750),
    );
  }

  // ===========================================================================
  // CLEAN — profile card with a coloured cover banner and an overlapping avatar
  // ===========================================================================
  static const Color _cBlue = Color(0xFF3B82F6);
  static const Color _cAmber = Color(0xFFF59E0B);

  Color _subjectColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('matemat')) return const Color(0xFFE5484D);
    if (l.contains('info')) return Pb.primary;
    if (l.contains('fizic')) return const Color(0xFF8B5CF6);
    if (l.contains('chim')) return const Color(0xFF14B8A6);
    if (l.contains('bio')) return const Color(0xFF22A06B);
    if (l.contains('român')) return _cBlue;
    if (l.contains('englez')) return _cAmber;
    if (l.contains('francez')) return const Color(0xFF6366F1);
    if (l.contains('istorie')) return const Color(0xFFD97706);
    if (l.contains('geograf')) return const Color(0xFF0EA5E9);
    return Pb.primary;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF212529),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Pb.radius),
      ),
    );
  }

  Widget _buildClean(BuildContext context, bool isMobile) {
    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              child: FutureBuilder<DocumentSnapshot>(
                future: _future,
                builder: (context, snapshot) {
                  Widget body;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    body = const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CircularProgressIndicator(color: Pb.primary)),
                    );
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    body = _cNotFound(context);
                  } else {
                    body = _cProfile(context, snapshot.data!.data() as Map<String, dynamic>, isMobile);
                  }
                  return StickyFooterScroll(
                    controller: _scroll,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 40, isMobile ? 12 : 24, 0),
                          child: _TdReveal(child: body),
                        ),
                      ),
                    ),
                    footer: _cFooter(context, isMobile),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cNotFound(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Pb.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pb.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.person_off_outlined, size: 36, color: Pb.muted),
          const SizedBox(height: 10),
          Text('Profilul nu a fost găsit.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Pb.text)),
          const SizedBox(height: 4),
          Text('Poate a fost șters sau nu e încă aprobat.', style: TextStyle(fontSize: 14, color: Pb.muted)),
          const SizedBox(height: 16),
          PbButton(text: 'Înapoi la profesori', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: () => context.go('/materii')),
        ],
      ),
    );
  }

  Widget _cProfile(BuildContext context, Map<String, dynamic> data, bool isMobile) {
    final name = '${data['name'] ?? 'Profesor'}';
    final image = '${data['image'] ?? ''}';
    final subject = '${data['specialization'] ?? data['subject'] ?? 'General'}';
    final exp = int.tryParse('${data['experience'] ?? 0}') ?? 0;
    final education = '${data['education'] ?? ''}'.trim();
    final email = '${data['email'] ?? ''}'.trim();
    final contact = '${data['contact'] ?? ''}'.trim();
    final c = _subjectColor(subject);
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final initials = parts.isEmpty ? '?' : parts.map((w) => w[0].toUpperCase()).join();
    final avatar = isMobile ? 96.0 : 112.0;

    Widget tile(IconData i, String label, String value, Color col, {Widget? trailing}) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Pb.border.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(i, size: 19, color: col),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                    const SizedBox(height: 2),
                    Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Pb.text)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        );

    final copyEmail = email.isEmpty
        ? null
        : IconButton(
            tooltip: 'Copiază emailul',
            splashRadius: 18,
            icon: Icon(Icons.copy_rounded, size: 18, color: Pb.muted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              _toast(context, 'Emailul a fost copiat.');
            },
          );

    final tiles = [
      tile(Icons.military_tech_outlined, 'Experiență', exp == 0 ? 'Profesor nou' : '$exp ${exp == 1 ? 'an' : 'ani'}', _cAmber),
      tile(Icons.school_outlined, 'Studii', education.isEmpty ? 'Nespecificat' : education, _cBlue),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: PbButton(
            text: 'Înapoi',
            icon: Icons.arrow_back,
            variant: PbVariant.outlineSecondary,
            size: PbSize.sm,
            onPressed: () => _back(context),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Pb.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Pb.border.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(AppColors.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // cover banner
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: isMobile ? 96 : 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.withOpacity(0.85), Color.lerp(c, _cBlue, 0.45)!.withOpacity(0.7)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 5),
                              Text('Profesor verificat',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: isMobile ? 18 : 28,
                    bottom: -avatar / 2,
                    child: Container(
                      width: avatar,
                      height: avatar,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Pb.surface, shape: BoxShape.circle),
                      child: CircleAvatar(
                        backgroundColor: c.withOpacity(0.15),
                        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                        onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
                        child: image.isEmpty
                            ? Text(initials, style: TextStyle(fontSize: avatar * 0.3, fontWeight: FontWeight.w700, color: c))
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: avatar / 2 + 10),
              Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 18 : 28, 0, isMobile ? 18 : 28, isMobile ? 20 : 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: isMobile ? 24 : 30, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                          child: Text(subject, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
                        ),
                        Text('Meditații 1 la 1, online', style: TextStyle(fontSize: 13.5, color: Pb.muted)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isMobile) ...[
                      tiles[0],
                      const SizedBox(height: 10),
                      tiles[1],
                    ] else
                      Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 12), Expanded(child: tiles[1])]),
                    const SizedBox(height: 10),
                    tile(Icons.mail_outline, 'Email', email.isEmpty ? 'Nespecificat' : email, Pb.primary, trailing: copyEmail),
                    const SizedBox(height: 22),
                    if (isMobile) ...[
                      _cContactButton(context, name, email, contact),
                      const SizedBox(height: 10),
                      PbButton(
                        text: 'Vezi recenziile',
                        icon: Icons.rate_review_outlined,
                        variant: PbVariant.outlineSecondary,
                        fullWidth: true,
                        onPressed: () => context.push('/profesor/$teacherId/recenzii'),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(flex: 3, child: _cContactButton(context, name, email, contact)),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: PbButton(
                              text: 'Vezi recenziile',
                              icon: Icons.rate_review_outlined,
                              variant: PbVariant.outlineSecondary,
                              fullWidth: true,
                              onPressed: () => context.push('/profesor/$teacherId/recenzii'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cContactButton(BuildContext context, String name, String email, String contact) {
    return PbButton(
      text: 'Contactează',
      icon: Icons.forum_outlined,
      fullWidth: true,
      onPressed: () => showPbModal(
        context,
        title: 'Contactează-l pe $name',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in [
              (Icons.phone_outlined, 'Telefon', contact.isEmpty ? 'Nespecificat' : contact, contact),
              (Icons.mail_outline, 'Email', email.isEmpty ? 'Nespecificat' : email, email),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(row.$1, size: 19, color: Pb.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.$2, style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                          Text(row.$3, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Pb.text)),
                        ],
                      ),
                    ),
                    if (row.$4.isNotEmpty)
                      IconButton(
                        tooltip: 'Copiază',
                        splashRadius: 18,
                        icon: Icon(Icons.copy_rounded, size: 18, color: Pb.muted),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: row.$4));
                          _toast(context, 'Copiat.');
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
        actions: (ctx) => [
          PbButton(text: 'Închide', variant: PbVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  Widget _cFooter(BuildContext context, bool isMobile) {
    final links = [
      PbLink(text: 'Termeni și condiții', fontSize: 14, onTap: () => context.go('/termeni-si-conditii')),
      PbLink(text: 'Politica de confidențialitate', fontSize: 14, onTap: () => context.go('/politica-confidentialitate')),
    ];
    final copy = Text('© 2026 iMeditații', style: TextStyle(color: Pb.muted, fontSize: 14));
    return Container(
      decoration: BoxDecoration(color: Pb.surface, border: Border(top: BorderSide(color: Pb.border))),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: PbContainer(
        child: isMobile
            ? Column(children: [
                copy,
                const SizedBox(height: 10),
                Wrap(spacing: 18, runSpacing: 8, alignment: WrapAlignment.center, children: links),
              ])
            : Row(children: [copy, const Spacer(), ...links.expand((l) => [const SizedBox(width: 22), l])]),
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(BuildContext context, bool isMobile) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'GUILD MASTER PROFILE',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
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
          icon: Icon(Icons.arrow_back, color: AppColors.ink, size: isMobile ? 26 : 32),
          onPressed: () => _back(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.sunset));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: RetroBlock(
                bgColor: AppColors.cloud,
                child: Text(
                  'MASTER DATA CORRUPTED OR NOT FOUND.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final imageUrl = data['image'] ?? '';
          final specialization = data['specialization'] ?? data['subject'] ?? 'UNKNOWN DISCIPLINE';

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    RetroBlock(
                      bgColor: AppColors.mustard,
                      padding: isMobile ? 24 : 40,
                      shadowOffset: isMobile ? 4 : 6,
                      child: Column(
                        children: [
                          Container(
                            width: isMobile ? 110 : 140,
                            height: isMobile ? 110 : 140,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              border: Border.all(color: AppColors.border, width: 4),
                              boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(6, 6))],
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl.isEmpty ? Icon(Icons.person, size: isMobile ? 64 : 80, color: AppColors.ink) : null,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            color: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            child: Text(
                              "VERIFIED MASTER",
                              style: TextStyle(
                                color: AppColors.isDark ? const Color(0xFF10161A) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            (data['name'] ?? 'UNKNOWN').toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            specialization.toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 32),
                    if (isMobile) ...[
                      _infoTile('EXPERIENCE', '${data['experience'] ?? 0} YEARS', AppColors.sky, Icons.star, isMobile),
                      const SizedBox(height: 14),
                      _infoTile('EDUCATION', data['education'] ?? 'NOT SPECIFIED', AppColors.cloud, Icons.school, isMobile),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _infoTile('EXPERIENCE', '${data['experience'] ?? 0} YEARS', AppColors.sky, Icons.star, isMobile),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _infoTile('EDUCATION', data['education'] ?? 'NOT SPECIFIED', AppColors.cloud, Icons.school, isMobile),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: isMobile ? 14 : 24),
                    _infoTile('COMMUNICATION LINK', data['email'] ?? 'UNKNOWN', AppColors.cardBg, Icons.email, isMobile, isFullWidth: true),
                    SizedBox(height: isMobile ? 14 : 24),
                    _infoTile('SYSTEM UID', teacherId, AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink, Icons.fingerprint, isMobile,
                        isFullWidth: true, textColor: Colors.white),
                    SizedBox(height: isMobile ? 28 : 48),
                    RetroButton(
                      text: 'INITIATE CONTACT',
                      icon: Icons.forum,
                      bgColor: AppColors.forest,
                      textColor: Colors.white,
                      isFullWidth: true,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'CONTACT CHANNEL OPENED. PHONE: ${data['contact'] ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            backgroundColor: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: AppColors.border, width: 3),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    RetroButton(
                      text: 'VIEW PLAYER REVIEWS',
                      icon: Icons.rate_review,
                      bgColor: AppColors.sky,
                      textColor: Colors.white,
                      isFullWidth: true,
                      onPressed: () {
                        context.push('/profesor/$teacherId/recenzii');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String? value, Color bgColor, IconData icon, bool isMobile, {bool isFullWidth = false, Color? textColor}) {
    final effectiveTextColor = textColor ?? AppColors.ink;

    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(isMobile ? 3 : 4, isMobile ? 3 : 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: effectiveTextColor, size: isMobile ? 20 : 24),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: effectiveTextColor,
                  fontSize: isMobile ? 12 : 14,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (value ?? '-').toUpperCase(),
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: effectiveTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TdReveal extends StatefulWidget {
  final Widget child;
  const _TdReveal({required this.child});

  @override
  State<_TdReveal> createState() => _TdRevealState();
}

class _TdRevealState extends State<_TdReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(_a), child: widget.child),
    );
  }
}