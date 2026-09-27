import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'custom_navbar.dart';
import 'theme_manager.dart';

/// Shared design tokens. Change things here once instead of in every screen.
class Retro {
  Retro._();

  static const double borderWidth = 2.5;
  static const double maxWidth = 1120;
  static const double breakpoint = 880;
  static const Color darkInk = Color(0xFF10161A);
  static const Color mint = Color(0xFF55EFC4);

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < breakpoint;
  static double shadow(bool mobile) => mobile ? 4 : 6;
  static double gutter(bool mobile) => mobile ? 16 : 24;

  static Border get border => Border.all(color: AppColors.border, width: borderWidth);

  /// Readable text/icon color on top of a fill.
  static Color onAccent(Color fill) {
    if (fill == AppColors.cardBg || fill == AppColors.cloud || fill == AppColors.bg) return AppColors.ink;
    if (fill == AppColors.mustard) return darkInk;
    return Colors.white;
  }

  /// Inverted fill for tags and selected states (works in both themes).
  static Color get strong => AppColors.isDark ? mint : AppColors.ink;
  static Color get onStrong => AppColors.isDark ? darkInk : Colors.white;

  /// Big headlines: the only place we use caps.
  static TextStyle display(double size, {Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: -0.5,
        color: color ?? AppColors.ink,
      );

  static TextStyle title(double size, {Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: color ?? AppColors.ink,
      );

  static TextStyle body(double size, {Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: color ?? AppColors.textMuted,
      );
}

/// Static bordered block with a hard shadow. Same API as before.
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
    return Container(
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.cardBg,
        border: Border.all(color: borderColor ?? AppColors.border, width: Retro.borderWidth),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(shadowOffset, shadowOffset))],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

/// Anything clickable: sinks into its shadow when pressed.
class RetroPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final double shadow;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const RetroPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.shadow = 5,
    this.width,
    this.padding,
  });

  @override
  State<RetroPressable> createState() => _RetroPressableState();
}

class _RetroPressableState extends State<RetroPressable> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.shadow;
    final shift = _down ? s : (_hover ? -1.5 : 0.0);
    final offset = _down ? 0.0 : (_hover ? s + 1.5 : s);

    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _down = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            width: widget.width,
            padding: widget.padding,
            transform: Matrix4.translationValues(shift, shift, 0),
            decoration: BoxDecoration(
              color: widget.color ?? AppColors.cardBg,
              border: Retro.border,
              boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(offset, offset))],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Same API as before, now built on RetroPressable. Sentence case, no forced caps.
class RetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final double fontSize;
  final EdgeInsets padding;
  final IconData? icon;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? AppColors.sunset;
    final fg = textColor ?? Retro.onAccent(bg);

    return RetroPressable(
      onTap: onPressed,
      color: bg,
      shadow: 4,
      width: isFullWidth ? double.infinity : null,
      padding: padding,
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: fontSize + 3),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small bordered label: status, rank, counts.
class RetroTag extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final Color? dot;

  const RetroTag(this.text, {super.key, this.color, this.textColor, this.dot});

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Retro.strong;
    final fg = textColor ?? (color == null ? Retro.onStrong : Retro.onAccent(bg));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, border: Border.all(color: AppColors.border, width: 2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(text, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Centers content and caps its width.
class RetroSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const RetroSection({super.key, required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Retro.maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class RetroSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isMobile;
  final bool center;

  const RetroSectionHeader({
    super.key,
    required this.title,
    required this.isMobile,
    this.subtitle,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), textAlign: align, style: Retro.display(isMobile ? 26 : 38)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(subtitle!, textAlign: align, style: Retro.body(isMobile ? 14 : 16)),
          ),
        ],
      ],
    );
  }
}

/// Even-width responsive grid: cards line up flush with the rest of the page.
class RetroGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const RetroGrid({super.key, required this.children, this.minItemWidth = 300, this.spacing = 24});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        var cols = ((c.maxWidth + spacing) / (minItemWidth + spacing)).floor();
        if (cols < 1) cols = 1;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((e) => SizedBox(width: w, child: e)).toList(),
        );
      },
    );
  }
}

/// One card design for every subject list in the app.
class RetroSubjectCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String tag;
  final String? description;
  final Widget? badge;
  final String cta;
  final bool isMobile;
  final VoidCallback onTap;

  const RetroSubjectCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.tag,
    required this.cta,
    required this.isMobile,
    required this.onTap,
    this.description,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return RetroPressable(
      onTap: onTap,
      shadow: isMobile ? 4 : 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.cloud,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: color, border: Border.all(color: AppColors.border, width: 2)),
                  child: Icon(icon, size: 28, color: Retro.onAccent(color)),
                ),
                if (badge != null) badge!,
              ],
            ),
          ),
          Container(height: Retro.borderWidth, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sunset)),
                const SizedBox(height: 4),
                Text(title.toUpperCase(), style: Retro.display(isMobile ? 20 : 22)),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: Text(description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Retro.body(13.5)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(cta, style: Retro.title(14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      color: Retro.strong,
                      child: Icon(Icons.arrow_forward, size: 15, color: Retro.onStrong),
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
}

class RetroFooter extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isMobile;

  const RetroFooter({super.key, required this.title, required this.subtitle, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 28 : 40),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF161E24) : AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.border, width: Retro.borderWidth)),
      ),
      child: Column(
        children: [
          Text(title, style: Retro.display(isMobile ? 20 : 26, color: Colors.white).copyWith(letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: Retro.body(isMobile ? 13 : 14, color: Colors.white70)),
        ],
      ),
    );
  }
}

/// Navbar + themed scroll page + footer. Every screen uses this.
class RetroPage extends StatefulWidget {
  final List<Widget> Function(BuildContext context, bool isMobile) builder;
  final String footerTitle;
  final String footerSubtitle;

  const RetroPage({
    super.key,
    required this.builder,
    this.footerTitle = 'IMEDITATII',
    required this.footerSubtitle,
  });

  @override
  State<RetroPage> createState() => _RetroPageState();
}

class _RetroPageState extends State<RetroPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        final m = Retro.isMobile(context);
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              const CustomNavbar(),
              Expanded(
                child: Scrollbar(
                  controller: _scroll,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...widget.builder(context, m),
                        SizedBox(height: m ? 32 : 56),
                        RetroFooter(title: widget.footerTitle, subtitle: widget.footerSubtitle, isMobile: m),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}