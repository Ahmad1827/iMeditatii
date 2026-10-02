import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'theme_manager.dart';

// =============================================================================
// STYLE SWITCH
// Retro keeps AppColors + VT323 exactly as before.
// Clean is a separate design language (pbinfo / Bootstrap): own palette [Pb],
// own font (Ubuntu), own components (Pb* in ui_components.dart) and its own
// screen layouts. AppColors is never touched.
// =============================================================================
class AppStyle {
  final bool isClean;
  final bool isDark;

  const AppStyle._(this.isClean, this.isDark);

  static AppStyle get current => AppStyle._(ThemeManager.isClean, AppColors.isDark);

  /// Same as [current] + rebuild dependency on [AppStyleScope].
  static AppStyle of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_AppStyleInherited>();
    return current;
  }

  bool get isRetro => !isClean;

  T pick<T>(T retro, T clean) => isClean ? clean : retro;

  /// Clean font. Used by main.dart (getTextTheme).
  static TextTheme cleanTextTheme(TextTheme base) => GoogleFonts.ubuntuTextTheme(base);

  /// "CALCUL INTEGRAL" -> "Calcul integral". Leaves mixed-case text alone.
  static String sentence(String t) {
    final s = t.trim();
    if (s.isEmpty || s != s.toUpperCase() || s == s.toLowerCase()) return s;
    final lower = s.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static List<BoxShadow> hardShadow(double offset) => [
        BoxShadow(color: AppColors.shadow, offset: Offset(offset, offset), blurRadius: 0),
      ];
}

// =============================================================================
// Pb — CLEAN PALETTE (pbinfo / Bootstrap 5). Light + dark variants.
// Tweak the Clean look here; every Pb* component and clean layout reads it.
// =============================================================================
class Pb {
  static bool get _d => AppColors.isDark;

  // Layout
  static const double containerMax = 1296;
  static const BorderRadius radius = BorderRadius.all(Radius.circular(6));

  // Surfaces
  static Color get page => _d ? const Color(0xFF212529) : Colors.white;
  static Color get surface => _d ? const Color(0xFF2B3035) : Colors.white;
  static Color get cardHeader => _d ? const Color(0xFF343A40) : const Color(0xFFF7F7F7);
  static Color get gray => _d ? const Color(0xFF343A40) : const Color(0xFFE9ECEF);
  static Color get hoverBg => _d ? const Color(0xFF343A40) : const Color(0xFFF8F9FA);
  static Color get tableStripe => _d ? const Color(0xFF30353B) : const Color(0xFFF2F2F2);
  static Color get border => _d ? const Color(0xFF495057) : const Color(0xFFDEE2E6);
  static Color get inputBorder => _d ? const Color(0xFF495057) : const Color(0xFFCED4DA);

  // Text
  static Color get text => _d ? const Color(0xFFDEE2E6) : const Color(0xFF212529);
  static Color get muted => _d ? const Color(0xFFADB5BD) : const Color(0xFF6C757D);
  static Color get link => _d ? const Color(0xFF6EA8FE) : const Color(0xFF0D6EFD);

  /// Orange statement headings ("Cerința", "Exemplu").
  static Color get heading => _d ? const Color(0xFFF5A04A) : const Color(0xFFF0861E);
  static Color get inlineCode => _d ? const Color(0xFFE685B5) : const Color(0xFFD63384);

  // Chrome
  static Color get navbar => _d ? const Color(0xFF1A1D20) : const Color(0xFF343A40);
  static Color get hero => _d ? const Color(0xFF1F4F7D) : const Color(0xFF3C87C8);
  static Color get infoStrip => _d ? const Color(0xFF087990) : const Color(0xFF0DCAF0);
  static Color get infoStripText => _d ? Colors.white : const Color(0xFF062C33);
  static Color get postMeta => _d ? const Color(0xFF032830) : const Color(0xFFCFF4FC);

  // Code
  static Color get codeBg => _d ? const Color(0xFF1E2226) : const Color(0xFFF8F9FA);
  static Color get editorBg => _d ? const Color(0xFF1E2226) : Colors.white;
  static Color get editorGutter => _d ? const Color(0xFF25292E) : const Color(0xFFF0F0F0);
  static Color get editorActiveLine => _d ? const Color(0xFF343A40) : const Color(0xFFDCDCDC);

  // Semantic (Bootstrap)
  static const Color primary = Color(0xFF0D6EFD);
  static const Color secondary = Color(0xFF6C757D);
  static const Color success = Color(0xFF198754);
  static const Color danger = Color(0xFFDC3545);

  static Color get successBg => _d ? const Color(0xFF051B11) : const Color(0xFFD1E7DD);
  static Color get successText => _d ? const Color(0xFF75B798) : const Color(0xFF0F5132);
  static Color get successBorder => _d ? const Color(0xFF0F5132) : const Color(0xFFBADBCC);
  static Color get dangerBg => _d ? const Color(0xFF2C0B0E) : const Color(0xFFF8D7DA);
  static Color get dangerText => _d ? const Color(0xFFEA868F) : const Color(0xFF842029);
  static Color get dangerBorder => _d ? const Color(0xFF842029) : const Color(0xFFF5C2C7);
  static Color get infoBg => _d ? const Color(0xFF032830) : const Color(0xFFCFF4FC);
  static Color get infoText => _d ? const Color(0xFF6EDFF6) : const Color(0xFF055160);
  static Color get infoBorder => _d ? const Color(0xFF087990) : const Color(0xFFB6EFFB);
  static Color get warningBg => _d ? const Color(0xFF332701) : const Color(0xFFFFF3CD);
  static Color get warningText => _d ? const Color(0xFFFFDA6A) : const Color(0xFF664D03);
  static Color get warningBorder => _d ? const Color(0xFF997404) : const Color(0xFFFFECB5);
  static Color get secondaryBg => _d ? const Color(0xFF343A40) : const Color(0xFFE2E3E5);
  static Color get secondaryText => _d ? const Color(0xFFDEE2E6) : const Color(0xFF41464B);
  static Color get secondaryBorder => _d ? const Color(0xFF495057) : const Color(0xFFD3D6D8);

  // Type helpers (font family comes from the theme: Ubuntu)
  static TextStyle body([double size = 16]) => TextStyle(fontSize: size, color: text, height: 1.6);

  static TextStyle mono(double size, {Color? color, double height = 1.5}) =>
      GoogleFonts.sourceCodePro(fontSize: size, color: color ?? text, height: height);

  static InputDecoration input({String? hint}) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted, fontSize: 16),
      filled: true,
      fillColor: surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: b(inputBorder),
      enabledBorder: b(inputBorder),
      focusedBorder: b(const Color(0xFF86B7FE)),
    );
  }
}

// =============================================================================
// SCOPE — mount once in MaterialApp.builder.
// AppColors / ThemeManager are static getters, so a toggle marks the whole
// subtree dirty once. State (scroll, editor text, inputs) is preserved.
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