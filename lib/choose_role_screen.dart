import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'theme_manager.dart';
import 'app_colors.dart';
import 'clean_kit.dart';
import 'home_ambient.dart' show HomeSky, HomeScene;
import 'ui_components.dart' show StyleBuilder, Pb, PbButton, PbAlert, PbAlertType;

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

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
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
    final effectiveTextColor = widget.textColor ?? Colors.white;

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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class ChooseRoleScreen extends StatefulWidget {
  final String uid;
  final String email;

  const ChooseRoleScreen({required this.uid, required this.email, super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _picked = 'student';
  String? _saving;
  String? _error;
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _setRole(BuildContext context, String role) async {
    if (_saving != null) return;
    setState(() {
      _saving = role;
      _error = null;
    });
    try {
      // merge: never wipe the name / photo that may already be on the profile
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'email': widget.email,
        'role': role,
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      context.go(role == 'teacher' ? '/panou-profesor' : '/materii');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = null;
        _error = 'Nu am putut salva alegerea. Verifică internetul și încearcă din nou.';
      });
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — two role cards with what each role gets, and a "where you'll land"
  // preview strip that follows the selection. Dragon scene.
  // ===========================================================================
  Widget _buildClean(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    const blue = Color(0xFF3B82F6);

    final student = _RoleCard(
      selected: _picked == 'student',
      color: Pb.primary,
      icon: Icons.backpack_outlined,
      title: 'Sunt elev',
      subtitle: 'Vreau să învăț și să exersez.',
      perks: const ['Probleme cu verificare automată', 'Lecții pentru clasele IX–XII', 'Meditații 1 la 1 cu profesori verificați'],
      onTap: () => setState(() => _picked = 'student'),
    );
    final teacher = _RoleCard(
      selected: _picked == 'teacher',
      color: blue,
      icon: Icons.school_outlined,
      title: 'Sunt profesor',
      subtitle: 'Vreau să predau și să găsesc elevi.',
      perks: const ['Profil public cu recenzii', 'Chat și lecții video cu tablă', 'Plăți direct în cont prin Stripe'],
      onTap: () => setState(() => _picked = 'teacher'),
    );

    final c = _picked == 'teacher' ? blue : Pb.primary;
    final landing = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_picked),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(_picked == 'teacher' ? Icons.dashboard_outlined : Icons.travel_explore, size: 19, color: c),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _picked == 'teacher'
                    ? 'Mergi direct în Panoul profesorului, unde îți vezi elevii și mesajele.'
                    : 'Mergi la lista de materii, ca să-ți alegi primul profesor.',
                style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );

    final card = Container(
      key: _cardKey,
      padding: EdgeInsets.all(isMobile ? 18 : 30),
      decoration: ckDeco(r: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(tooltip: 'Înapoi', icon: Icon(Icons.arrow_back, color: Pb.muted), onPressed: () => _back(context)),
              const Spacer(),
              if (widget.email.isNotEmpty)
                Flexible(
                  child: Text(widget.email, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Pb.muted)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Cum vrei să folosești iMeditații?',
              textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 23 : 28, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('Poți schimba asta mai târziu din profil.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Pb.muted)),
          const SizedBox(height: 24),
          if (isMobile) ...[student, const SizedBox(height: 12), teacher] else
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: student), const SizedBox(width: 14), Expanded(child: teacher)]),
            ),
          const SizedBox(height: 16),
          landing,
          if (_error != null) ...[
            const SizedBox(height: 12),
            PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14))),
          ],
          const SizedBox(height: 18),
          PbButton(
            text: _picked == 'teacher' ? 'Continuă ca profesor' : 'Continuă ca elev',
            icon: Icons.arrow_forward,
            fullWidth: true,
            loading: _saving != null,
            onPressed: _saving != null ? null : () => _setRole(context, _picked),
          ),
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
            title: Text('INITIALIZE PROFILE', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
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
              onPressed: () => _back(context),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: RetroBlock(
                  bgColor: AppColors.cloud,
                  padding: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_esports, size: 80, color: AppColors.ink),
                      const SizedBox(height: 24),
                      Text(
                        'SELECT YOUR CLASS',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Are you here to master the system or to guide other players?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 48),
                      RetroButton(
                        text: 'I AM A GUILD MASTER (TEACHER)',
                        bgColor: AppColors.sunset,
                        textColor: Colors.white,
                        isFullWidth: true,
                        onPressed: () => _setRole(context, 'teacher'),
                      ),
                      const SizedBox(height: 24),
                      RetroButton(
                        text: 'I AM A PLAYER (STUDENT)',
                        bgColor: AppColors.sky,
                        textColor: Colors.white,
                        isFullWidth: true,
                        onPressed: () => _setRole(context, 'student'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoleCard extends StatefulWidget {
  final bool selected;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> perks;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.perks,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final sel = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover && !sel ? -2 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: sel ? c.withOpacity(0.07) : Pb.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? c : (_hover ? c.withOpacity(0.45) : Pb.border), width: sel ? 1.8 : 1),
            boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 8))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.icon, size: 22, color: c),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                    child: Icon(
                      sel ? Icons.check_circle : Icons.circle_outlined,
                      key: ValueKey(sel),
                      size: 22,
                      color: sel ? c : Pb.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Pb.text)),
              const SizedBox(height: 3),
              Text(widget.subtitle, style: TextStyle(fontSize: 13.5, color: Pb.muted)),
              const SizedBox(height: 14),
              for (final p in widget.perks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check, size: 15, color: c)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p, style: TextStyle(fontSize: 13.5, color: Pb.text, height: 1.4))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}