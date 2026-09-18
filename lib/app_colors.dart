import 'package:flutter/material.dart';
import 'theme_manager.dart';

class AppColors {
  static bool get isDark => ThemeManager.themeNotifier.value == ThemeMode.dark;

  // Fundaluri
  static Color get bg => isDark ? const Color(0xFF10161A) : const Color(0xFFF4F1EA);
  static Color get cardBg => isDark ? const Color(0xFF1A232A) : Colors.white;
  static Color get sidebarBg => isDark ? const Color(0xFF161E24) : const Color(0xFFE5E0D4);
  static Color get cloud => isDark ? const Color(0xFF161E24) : const Color(0xFFE5E0D4);
  static Color get inputBg => isDark ? const Color(0xFF12171A) : Colors.white;
  static Color get headerBg => isDark ? const Color(0xFF222F3B) : const Color(0xFFEAB334);

  // Text & Contururi
  static Color get ink => isDark ? const Color(0xFFECEFF4) : const Color(0xFF2C363F);
  static Color get border => isDark ? const Color(0xFF2E3D4D) : const Color(0xFF2C363F);
  static Color get shadow => isDark ? Colors.black87 : const Color(0xFF2C363F);
  static Color get textMuted => isDark ? const Color(0xFF8A9BA8) : const Color(0xFF636E72);

  // Culori de accent
  static Color get sunset => const Color(0xFFE75A41);
  static Color get forest => const Color(0xFF20BF6B);
  static Color get mustard => isDark ? const Color(0xFFF1C40F) : const Color(0xFFEAB334);
  static Color get sky => isDark ? const Color(0xFF45AAF2) : const Color(0xFF5BA8B5);
  static Color get purple => const Color(0xFF8854D0);
  static Color get orange => const Color(0xFFFA8231);
}

class AdminConfig {
  static const String ownerEmail = 'ahmadarnaoute1896@gmail.com';

  static bool isOwner(String? email) => email == ownerEmail;
}