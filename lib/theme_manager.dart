import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppStyleMode { retro, clean }

class ThemeManager {
  // Global notifiers for Theme (Light/Dark) and Style (Retro/Clean)
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<AppStyleMode> styleNotifier = ValueNotifier(AppStyleMode.retro);

  static bool get isDark => themeNotifier.value == ThemeMode.dark;
  static bool get isRetro => styleNotifier.value == AppStyleMode.retro;
  static bool get isClean => styleNotifier.value == AppStyleMode.clean;

  // Load saved preferences on startup
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    final savedStyle = prefs.getString('app_style') ?? 'retro';
    styleNotifier.value = savedStyle == 'clean' ? AppStyleMode.clean : AppStyleMode.retro;
  }

  // Toggle Light / Dark mode
  static Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (themeNotifier.value == ThemeMode.light) {
      themeNotifier.value = ThemeMode.dark;
      await prefs.setBool('is_dark_mode', true);
    } else {
      themeNotifier.value = ThemeMode.light;
      await prefs.setBool('is_dark_mode', false);
    }
  }

  // Toggle Retro / Clean mode
  static Future<void> toggleStyle() async {
    final prefs = await SharedPreferences.getInstance();
    if (styleNotifier.value == AppStyleMode.retro) {
      styleNotifier.value = AppStyleMode.clean;
      await prefs.setString('app_style', 'clean');
    } else {
      styleNotifier.value = AppStyleMode.retro;
      await prefs.setString('app_style', 'retro');
    }
  }
}