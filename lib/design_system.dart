import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'theme_manager.dart';

// =============================================================================
// DESIGN SYSTEM
// The ONLY place where Retro vs Clean is decided. Every token keeps both
// variants side by side, so one tweak here propagates to every screen.
// AppColors is never touched: Clean only derives tints/hairlines from it.
// =============================================================================

class AppStyle {
  final bool isClean;
  final bool isDark;

  const AppStyle._(this.isClean, this.isDark);

  /// Static access (same pattern as AppColors).
  static AppStyle get current => AppStyle._(ThemeManager.isClean, AppColors.isDark);

  /// Same tokens + registers a rebuild dependency on [AppStyleScope].
  static AppStyle of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_AppStyleInherited>();
    return current;
  }

  bool get isRetro => !isClean;

  /// `s.pick(retroValue, cleanValue)` — use for copy, icons, sizes.
  T pick<T>(T retro, T clean) => isClean ? clean : retro;

  /// Retro shouts in caps, Clean keeps text as written.
  String caps(String text) => isClean ? text : text.toUpperCase();

  /// "CALCUL INTEGRAL" -> "Calcul integral" (only touches all-caps strings).
  static String sentence(String t) {
    final trimmed = t.trim();
    if (trimmed.isEmpty || trimmed != trimmed.toUpperCase()) return trimmed;
    final lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  // ---------------------------------------------------------------------------
  // COLORS (derived only — no new palette)
  // ---------------------------------------------------------------------------
  static const Color codeBg = Color(0xFF1B242B);
  static const Color codeGutter = Color(0xFF131A1F);
  static const Color codeGutterLine = Color(0xFF2C3E50);
  static const Color codeText = Color(0xFFECEFF4);
  static const Color codeMuted = Color(0xFF636E72);
  static const Color codeAccent = Color(0xFF55EFC4);

  /// Structural line: hairline (Clean) / ink outline (Retro).
  Color get line => isClean
      ? (isDark ? Colors.white.withOpacity(0.08) : AppColors.ink.withOpacity(0.10))
      : AppColors.border;

  Color get lineStrong => isClean
      ? (isDark ? Colors.white.withOpacity(0.16) : AppColors.ink.withOpacity(0.20))
      : AppColors.border;

  /// Recessed area inside a card (spec labels, progress tracks, tables).
  Color get inset => isClean ? AppColors.bg : AppColors.cloud;

  /// Hero / feature fill.
  Color get heroBg => isClean ? AppColors.cardBg : AppColors.mustard;

  /// Text on [heroBg].
  Color get heroInk => isClean ? AppColors.ink : (isDark ? const Color(0xFF10161A) : AppColors.ink);

  /// Text on a solid AppColors.ink fill (ink flips with light/dark).
  Color get onInk => isDark ? const Color(0xFF10161A) : Colors.white;

  /// Main call-to-action: Retro keeps the per-button accent, Clean uses ink.
  Color primaryFill(Color retro) => isClean ? AppColors.ink : retro;
  Color primaryText(Color retro) => isClean ? onInk : retro;

  Color tint(Color c) => c.withOpacity(isDark ? 0.18 : 0.11);

  Color accentText(Color c) =>
      isDark ? Color.lerp(c, Colors.white, 0.22)! : Color.lerp(c, Colors.black, 0.32)!;

  bool isSurface(Color c) =>
      c == AppColors.cardBg || c == AppColors.cloud || c == AppColors.bg || c == AppColors.inputBg;

  /// Clean drops the loud block fills (mustard / beige) to plain surfaces.
  Color surfaceFor(Color requested) {
    if (isRetro) return requested;
    if (requested == AppColors.mustard ||
        requested == AppColors.cloud ||
        requested == AppColors.headerBg) {
      return AppColors.cardBg;
    }
    return requested;
  }

  Color buttonFill(Color requested) {
    if (isRetro) return requested;
    if (requested == AppColors.mustard || requested == AppColors.cloud) return AppColors.cardBg;
    return requested;
  }

  // ---------------------------------------------------------------------------
  // SHAPE
  // ---------------------------------------------------------------------------
  BorderRadius get rCard => BorderRadius.circular(isClean ? 12 : 0);
  BorderRadius get rButton => BorderRadius.circular(isClean ? 8 : 0);
  BorderRadius get rInset => BorderRadius.circular(isClean ? 8 : 0);
  BorderRadius get rChip => BorderRadius.circular(isClean ? 6 : 0);
  BorderRadius get rTile => BorderRadius.circular(isClean ? 12 : 0);

  // ---------------------------------------------------------------------------
  // ELEVATION
  // ---------------------------------------------------------------------------
  List<BoxShadow> hardShadow(double offset) => [
        BoxShadow(color: AppColors.shadow, offset: Offset(offset, offset), blurRadius: 0),
      ];

  List<BoxShadow> softShadow([int level = 1]) {
    final a = isDark ? 0.32 : 0.045;
    switch (level) {
      case 0:
        return const [];
      case 1:
        return [
          BoxShadow(color: Colors.black.withOpacity(a), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(color: Colors.black.withOpacity(a * 0.9), blurRadius: 14, offset: const Offset(0, 4)),
        ];
      default:
        return [
          BoxShadow(color: Colors.black.withOpacity(a * 1.3), blurRadius: 4, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(a * 1.3), blurRadius: 28, offset: const Offset(0, 12)),
        ];
    }
  }

  List<BoxShadow> shadow({double retroOffset = 4, int cleanLevel = 1}) =>
      isClean ? softShadow(cleanLevel) : hardShadow(retroOffset);

  // ---------------------------------------------------------------------------
  // DECORATIONS
  // ---------------------------------------------------------------------------
  BoxDecoration card({Color? bg, double retroShadow = 6, Color? retroBorder, int cleanLevel = 1}) {
    final color = bg ?? AppColors.cardBg;
    if (isClean) {
      return BoxDecoration(
        color: color,
        borderRadius: rCard,
        border: Border.all(color: line, width: 1),
        boxShadow: softShadow(cleanLevel),
      );
    }
    return BoxDecoration(
      color: color,
      border: Border.all(color: retroBorder ?? AppColors.border, width: 3),
      boxShadow: hardShadow(retroShadow),
    );
  }

  BoxDecoration insetBox({Color? bg, double retroBorder = 2}) => BoxDecoration(
        color: bg ?? inset,
        borderRadius: rInset,
        border: Border.all(color: isClean ? line : AppColors.border, width: isClean ? 1 : retroBorder),
      );

  BoxDecoration button({required Color bg, bool pressed = false, bool hovered = false}) {
    if (isClean) {
      final surface = isSurface(bg);
      final target = surface ? AppColors.ink : (isDark ? Colors.white : Colors.black);
      var fill = bg;
      if (pressed) {
        fill = Color.lerp(bg, target, surface ? 0.09 : 0.16)!;
      } else if (hovered) {
        fill = Color.lerp(bg, target, surface ? 0.05 : 0.09)!;
      }
      return BoxDecoration(
        color: fill,
        borderRadius: rButton,
        border: Border.all(color: surface ? lineStrong : Colors.transparent, width: 1),
        boxShadow: pressed
            ? const []
            : [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 2, offset: const Offset(0, 1))],
      );
    }
    return BoxDecoration(
      color: bg,
      border: Border.all(color: AppColors.border, width: 2.5),
      boxShadow: [
        BoxShadow(color: AppColors.shadow, offset: pressed ? Offset.zero : const Offset(4, 4), blurRadius: 0),
      ],
    );
  }

  Matrix4 buttonTransform({required bool pressed, required bool hovered}) {
    if (isClean) {
      final scale = pressed ? 0.985 : 1.0;
      return Matrix4.diagonal3Values(scale, scale, 1.0);
    }
    final o = pressed ? 3.0 : (hovered ? -1.5 : 0.0);
    return Matrix4.translationValues(o, o, 0);
  }

  /// Dark code surface (editor, solution, console, lecture snippets).
  BoxDecoration codeSurface({double retroBorder = 2.5, bool withShadow = false}) => BoxDecoration(
        color: codeBg,
        borderRadius: rInset,
        border: Border.all(
          color: isClean ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.12)) : AppColors.border,
          width: isClean ? 1 : retroBorder,
        ),
        boxShadow: withShadow ? (isClean ? softShadow(1) : hardShadow(3.5)) : null,
      );

  InputDecoration input({String? hint}) {
    OutlineInputBorder b(Color c, double w) =>
        OutlineInputBorder(borderRadius: rButton, borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.inputBg,
      contentPadding: const EdgeInsets.all(14),
      border: b(isClean ? lineStrong : AppColors.border, isClean ? 1 : 2),
      enabledBorder: b(isClean ? lineStrong : AppColors.border, isClean ? 1 : 2),
      focusedBorder: b(isClean ? AppColors.sky : AppColors.border, isClean ? 1.5 : 2.5),
    );
  }

  // ---------------------------------------------------------------------------
  // TYPOGRAPHY  (font family comes from the ThemeData: VT323 / Inter)
  // ---------------------------------------------------------------------------
  TextStyle display(double size, {Color? color}) => TextStyle(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: isClean ? FontWeight.w700 : FontWeight.w900,
        height: isClean ? 1.12 : 1.1,
        letterSpacing: isClean ? -size * 0.025 : 1.0,
      );

  TextStyle heading(double size, {Color? color}) => TextStyle(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: isClean ? FontWeight.w600 : FontWeight.w900,
        height: 1.25,
        letterSpacing: isClean ? -size * 0.012 : 1.0,
      );

  /// Small label above content. Clean: muted, sentence case, no tracking.
  TextStyle overline(double size, {Color? color}) => TextStyle(
        fontSize: size,
        color: color ?? (isClean ? AppColors.textMuted : AppColors.ink),
        fontWeight: isClean ? FontWeight.w500 : FontWeight.w900,
        letterSpacing: isClean ? 0 : 1.2,
      );

  TextStyle body(double size, {Color? color, double height = 1.55, FontWeight retroWeight = FontWeight.w600}) =>
      TextStyle(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: isClean ? FontWeight.w400 : retroWeight,
        height: height,
        letterSpacing: isClean ? 0 : 0.2,
      );

  TextStyle muted(double size, {double height = 1.5}) => TextStyle(
        fontSize: size,
        color: AppColors.textMuted,
        fontWeight: isClean ? FontWeight.w400 : FontWeight.bold,
        height: height,
      );

  TextStyle buttonText(Color color, double size) => isClean
      ? TextStyle(color: color, fontSize: size - 1, fontWeight: FontWeight.w600, letterSpacing: 0)
      : TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1.0);

  /// Code font: JetBrains Mono in Clean, system monospace in Retro.
  TextStyle mono(double size, {Color? color, FontWeight? weight, double? height}) {
    final base = TextStyle(
      fontSize: size,
      color: color,
      height: height,
      fontWeight: weight ?? (isClean ? FontWeight.w400 : FontWeight.w600),
    );
    return isClean ? GoogleFonts.jetBrainsMono(textStyle: base) : base.copyWith(fontFamily: 'monospace');
  }
}

extension AppStyleContext on BuildContext {
  AppStyle get ds => AppStyle.of(this);
}

// =============================================================================
// SCOPE — mount once in MaterialApp.builder.
// AppColors / ThemeManager are static getters (not context-bound), so a style
// or theme change marks the whole subtree dirty once. State (scroll positions,
// editor text, form input) is preserved; nothing is remounted.
// =============================================================================
class AppStyleScope extends StatefulWidget {
  final Widget child;
  const AppStyleScope({super.key, required this.child});

  @override
  State<AppStyleScope> createState() => _AppStyleScopeState();
}

class _AppStyleScopeState extends State<AppStyleScope> {
  final Listenable _source = Listenable.merge([ThemeManager.themeNotifier, ThemeManager.styleNotifier]);

  @override
  void initState() {
    super.initState();
    _source.addListener(_onChanged);
  }

  @override
  void dispose() {
    _source.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return _AppStyleInherited(
      isClean: ThemeManager.isClean,
      isDark: AppColors.isDark,
      child: widget.child,
    );
  }
}

class _AppStyleInherited extends InheritedWidget {
  final bool isClean;
  final bool isDark;

  const _AppStyleInherited({required this.isClean, required this.isDark, required super.child});

  @override
  bool updateShouldNotify(_AppStyleInherited old) => old.isClean != isClean || old.isDark != isDark;
}