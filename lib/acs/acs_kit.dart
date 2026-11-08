// =============================================================================
// ACS KIT: the section's own look, shared by every ACS page
//   Two looks (a terminal, a notebook page), each light and dark, all set in
//   Iosevka. A page is [AcsPage]; inside it, everything takes its colours from
//   [AcsInk.of] so the workspaces (shell, emulator, circuit...) follow the look.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';

import '../app_link.dart';
import '../statement.dart';
import '../theme_manager.dart';

const String acsFont = 'Iosevka';
const List<String> acsFallback = ['monospace'];

/// The colours of one look in one theme.
class AcsInk {
  final Color bg, fg, strong, accent, muted, dim, line, hover, panel, good, bad, warn;
  final bool terminal, dark;
  const AcsInk({
    required this.bg,
    required this.fg,
    required this.strong,
    required this.accent,
    required this.muted,
    required this.dim,
    required this.line,
    required this.hover,
    required this.panel,
    required this.good,
    required this.bad,
    required this.warn,
    required this.terminal,
    required this.dark,
  });

  static AcsInk get current => of(ThemeManager.acsStyleNotifier.value, ThemeManager.isDark);

  static AcsInk of(AcsStyle style, bool dark) {
    if (style == AcsStyle.terminal) {
      return dark
          ? const AcsInk(
              bg: Color(0xFF121513), fg: Color(0xFFCFD6C9), strong: Color(0xFFE9EFE2), accent: Color(0xFF9FCF8F),
              muted: Color(0xFF7D887A), dim: Color(0xFF4B544A), line: Color(0xFF2A302A), hover: Color(0xFF1A1F1B),
              panel: Color(0xFF0C0E0D), good: Color(0xFF9FCF8F), bad: Color(0xFFE07A6E), warn: Color(0xFFD9B45A),
              terminal: true, dark: true)
          : const AcsInk(
              bg: Color(0xFFF2F4EF), fg: Color(0xFF243025), strong: Color(0xFF111A12), accent: Color(0xFF2F7A3A),
              muted: Color(0xFF5D6B5C), dim: Color(0xFFA3AD9F), line: Color(0xFFD3D9CF), hover: Color(0xFFE6EAE2),
              panel: Color(0xFFE9ECE5), good: Color(0xFF2F7A3A), bad: Color(0xFFB2372B), warn: Color(0xFF8A6512),
              terminal: true, dark: false);
    }
    return dark
        ? const AcsInk(
            bg: Color(0xFF1B1C1E), fg: Color(0xFFDADAD6), strong: Color(0xFFF0F0EC), accent: Color(0xFF8AB4F0),
            muted: Color(0xFF9A9A96), dim: Color(0xFF6A6B6E), line: Color(0xFF4A4B4E), hover: Color(0xFF252629),
            panel: Color(0xFF232427), good: Color(0xFF7FC48A), bad: Color(0xFFE88A80), warn: Color(0xFFE0B860),
            terminal: false, dark: true)
        : const AcsInk(
            bg: Color(0xFFFBFBF9), fg: Color(0xFF2B2B2B), strong: Color(0xFF222222), accent: Color(0xFF1F5FA8),
            muted: Color(0xFF666666), dim: Color(0xFF8A8A8A), line: Color(0xFFB9B9B9), hover: Color(0xFFF0F0EC),
            panel: Color(0xFFF3F3EF), good: Color(0xFF2E7D3A), bad: Color(0xFFB3261E), warn: Color(0xFF8A6512),
            terminal: false, dark: false);
  }

  TextStyle mono(double size, {Color? color, FontWeight? weight, double height = 1.45}) =>
      TextStyle(fontFamily: acsFont, fontFamilyFallback: acsFallback, fontSize: size, color: color ?? fg, fontWeight: weight, height: height);
}

/// A whole ACS page: the look and theme switches top right, the colours given
/// to [builder]. Rebuilds when the look or the theme changes.
class AcsPage extends StatelessWidget {
  final double maxWidth;
  final bool scroll;
  final Widget Function(BuildContext context, AcsInk ink, bool narrow) builder;
  const AcsPage({super.key, required this.builder, this.maxWidth = 900, this.scroll = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.themeNotifier, ThemeManager.acsStyleNotifier]),
      builder: (context, _) {
        final ink = AcsInk.current;
        final width = MediaQuery.of(context).size.width;
        final narrow = width < 600;
        final body = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(narrow ? 16 : 32, 18, narrow ? 16 : 32, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerRight, child: AcsSwitches(ink: ink)),
                  const SizedBox(height: 14),
                  builder(context, ink, narrow),
                ],
              ),
            ),
          ),
        );
        return Scaffold(
          backgroundColor: ink.bg,
          body: DefaultTextStyle(
            style: ink.mono(15),
            child: SafeArea(child: scroll ? SingleChildScrollView(child: body) : body),
          ),
        );
      },
    );
  }
}

/// Terminal / notebook, and light / dark.
class AcsSwitches extends StatelessWidget {
  final AcsInk ink;
  const AcsSwitches({super.key, required this.ink});

  @override
  Widget build(BuildContext context) {
    final style = ThemeManager.acsStyleNotifier.value;
    final dark = ThemeManager.isDark;
    Widget seg(String label, AcsStyle s) {
      final on = style == s;
      return AcsTap(
        label: 'Aspect $label',
        onTap: () => ThemeManager.setAcsStyle(s),
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: on ? ink.accent : (h ? ink.hover : Colors.transparent),
          child: Text(label, style: ink.mono(13, weight: FontWeight.w700, color: on ? ink.bg : ink.muted)),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: ink.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [seg('terminal', AcsStyle.terminal), seg('notebook', AcsStyle.notebook)]),
        ),
        const SizedBox(width: 8),
        AcsTap(
          label: dark ? 'Temă luminoasă' : 'Temă întunecată',
          onTap: ThemeManager.toggleTheme,
          builder: (h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: ink.line), color: h ? ink.hover : Colors.transparent),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: ink.fg),
                const SizedBox(width: 6),
                Text(dark ? 'light' : 'dark', style: ink.mono(13, weight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A clickable bit of text: hand cursor, hover state, read out as a button.
class AcsTap extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget Function(bool hover) builder;
  const AcsTap({super.key, required this.label, required this.onTap, required this.builder});

  @override
  State<AcsTap> createState() => _AcsTapState();
}

class _AcsTapState extends State<AcsTap> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: widget.label,
      child: MouseRegion(
        cursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: widget.builder(_h && on)),
      ),
    );
  }
}

/// A command button: `[ rulează ]` in the terminal, an outlined label in the notebook.
class AcsButton extends StatelessWidget {
  final AcsInk ink;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  const AcsButton(this.ink, this.label, this.onTap, {super.key, this.primary = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return AcsTap(
      label: label,
      onTap: onTap,
      builder: (h) {
        final fill = primary && on;
        final fg = !on ? ink.dim : (fill ? ink.bg : (h ? ink.strong : ink.accent));
        return Container(
          padding: EdgeInsets.symmetric(horizontal: ink.terminal ? 8 : 12, vertical: 5),
          decoration: BoxDecoration(
            color: fill ? (h ? ink.strong : ink.accent) : (h ? ink.hover : Colors.transparent),
            border: Border.all(color: on ? (fill ? Colors.transparent : ink.accent) : ink.line),
            borderRadius: ink.terminal ? null : BorderRadius.circular(4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
            Text(ink.terminal ? '[ $label ]' : label, style: ink.mono(13.5, weight: FontWeight.w700, color: fg)),
          ]),
        );
      },
    );
  }
}

/// A bordered panel; a title line on top if given.
class AcsBox extends StatelessWidget {
  final AcsInk ink;
  final String? title;
  final Widget child;
  final EdgeInsets padding;
  final Widget? trailing;
  final Color? color;
  const AcsBox(this.ink, {super.key, this.title, required this.child, this.padding = const EdgeInsets.all(12), this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? ink.panel,
        border: Border.all(color: ink.line),
        borderRadius: ink.terminal ? null : BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
              child: Row(children: [
                Expanded(child: Text(ink.terminal ? '── $title' : title!, style: ink.mono(13, weight: FontWeight.w700, color: ink.muted))),
                if (trailing != null) trailing!,
              ]),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// The links of the section, split by pipes: "materii | uso | ← iMeditatii".
class AcsNav extends StatelessWidget {
  final AcsInk ink;
  final List<(String, String)> trail; // after "materii": (label, route)
  final double size;
  const AcsNav({super.key, required this.ink, this.trail = const [], this.size = 15});

  @override
  Widget build(BuildContext context) {
    final links = [('materii', '/acs'), ...trail, ('← iMeditatii', '/exercitii')];
    final on = links.length - 2; // the page we're on
    Widget link(int i) {
      final (t, to) = links[i];
      final here = i == on;
      return AppLink(
        to: to,
        child: AcsTap(
          label: t,
          onTap: () => context.go(to),
          builder: (h) => Text(t,
              style: ink.mono(size,
                      weight: FontWeight.w700, color: here ? ink.accent : ink.strong)
                  .copyWith(decoration: h ? TextDecoration.underline : null, decorationColor: here ? ink.accent : ink.strong)),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('|', style: ink.mono(size, color: ink.dim))),
          link(i),
        ],
      ],
    );
  }
}

/// `student@acs:~/uso$ cmd`, the terminal's prompt line.
class AcsPrompt extends StatelessWidget {
  final AcsInk ink;
  final String cmd;
  final String dir;
  final double size;
  const AcsPrompt(this.ink, this.cmd, {super.key, this.dir = '~', this.size = 15});

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
          TextSpan(text: ':$dir', style: TextStyle(color: ink.muted)),
          TextSpan(text: '\$ ', style: TextStyle(color: ink.accent)),
          TextSpan(text: cmd, style: TextStyle(color: ink.fg)),
        ]),
        style: ink.mono(size),
      );
}

/// The blinking block at a prompt; still when the system asks for less motion.
class AcsCursor extends StatefulWidget {
  final Color color;
  final double height;
  const AcsCursor({super.key, required this.color, this.height = 18});

  @override
  State<AcsCursor> createState() => _AcsCursorState();
}

class _AcsCursorState extends State<AcsCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Opacity(
          opacity: _c.value < 0.5 ? 1 : 0,
          child: Container(width: widget.height / 2, height: widget.height, color: widget.color),
        ),
      );
}

/// A statement in the section's look: the markup of statement.dart (code,
/// **bold**, $formulas$, bullets, lettered parts, ``` boxes ```).
class AcsText extends StatelessWidget {
  final String text;
  final AcsInk ink;
  final double size;
  final Color? color;
  const AcsText(this.text, this.ink, {super.key, this.size = 15, this.color});

  @override
  Widget build(BuildContext context) {
    final blocks = Markup.blocks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in blocks.indexed) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 9), child: _block(b)),
      ],
    );
  }

  TextStyle get _style => ink.mono(size, color: color ?? ink.fg, height: 1.6);

  Widget _block(StatementBlock b) {
    switch (b.kind) {
      case BlockKind.prose:
        return line(b.text);
      case BlockKind.math:
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _tex(b.text, display: true),
          ),
        );
      case BlockKind.code:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: ink.panel,
            border: ink.terminal ? Border(left: BorderSide(color: ink.accent, width: 2)) : Border.all(color: ink.line),
            borderRadius: ink.terminal ? null : BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(b.text, style: ink.mono(size - 1, color: ink.strong)),
          ),
        );
      case BlockKind.bullets:
      case BlockKind.parts:
        final parts = b.kind == BlockKind.parts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in b.items.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: parts ? 30 : 20,
                      child: Text(parts ? b.labels[i] : (ink.terminal ? '-' : '•'),
                          style: _style.copyWith(fontWeight: FontWeight.w700, color: ink.accent)),
                    ),
                    Expanded(child: line(item)),
                  ],
                ),
              ),
          ],
        );
    }
  }

  Widget line(String text) {
    return Text.rich(
      TextSpan(
        style: _style,
        children: [
          for (final s in Markup.spans(text))
            switch (s.kind) {
              SpanKind.text => TextSpan(text: s.text),
              SpanKind.bold => TextSpan(text: s.text, style: TextStyle(fontWeight: FontWeight.w700, color: ink.strong)),
              SpanKind.code => TextSpan(text: s.text, style: TextStyle(color: ink.accent, backgroundColor: ink.panel)),
              SpanKind.tex => WidgetSpan(alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic, child: _tex(s.text)),
            },
        ],
      ),
    );
  }

  Widget _tex(String tex, {bool display = false}) => Math.tex(
        tex,
        mathStyle: display ? MathStyle.display : MathStyle.text,
        textStyle: TextStyle(fontSize: size * 1.1, color: color ?? ink.strong, height: 1),
        onErrorFallback: (_) => Text(tex, style: ink.mono(size * 0.95, color: color ?? ink.fg)),
      );
}
