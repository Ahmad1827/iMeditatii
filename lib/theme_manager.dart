import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppStyleMode { retro, clean }

class ThemeManager {
  // Global notifiers for Theme (Light/Dark) and Style (Retro/Clean)
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<AppStyleMode> styleNotifier = ValueNotifier(AppStyleMode.clean);
  // Background animations (clouds, birds, armies). Turned off by the visitor,
  // or by the page itself when this computer can't keep up with them.
  static final ValueNotifier<bool> motionNotifier = ValueNotifier(true);
  // A page showing only its work (the editor's focus mode): the floating
  // buttons step aside.
  static final ValueNotifier<bool> focusNotifier = ValueNotifier(false);
  // The theme / style / motion buttons out on the screen, or tucked away
  // behind the tab on the left edge (the default).
  static final ValueNotifier<bool> deckNotifier = ValueNotifier(false);
  static bool _motionChosen = false;

  static bool get isDark => themeNotifier.value == ThemeMode.dark;
  static bool get isRetro => styleNotifier.value == AppStyleMode.retro;
  static bool get isClean => styleNotifier.value == AppStyleMode.clean;

  // Load saved preferences on startup
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // Clean unless the visitor chose Retro themselves (Retro isn't finished yet).
    final savedStyle = prefs.getString('app_style') ?? 'clean';
    styleNotifier.value = savedStyle == 'retro' ? AppStyleMode.retro : AppStyleMode.clean;

    final motion = prefs.getString('ambient_motion'); // 'on', 'off', 'auto_off' or unset
    motionNotifier.value = motion != 'off' && motion != 'auto_off';
    _motionChosen = motion == 'on' || motion == 'off';

    deckNotifier.value = prefs.getBool('deck_open') ?? false;
  }

  // Show / tuck away the theme, style and motion buttons
  static Future<void> toggleDeck() async {
    deckNotifier.value = !deckNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('deck_open', deckNotifier.value);
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

  // Toggle the background animations on / off
  static Future<void> toggleMotion() async {
    final prefs = await SharedPreferences.getInstance();
    motionNotifier.value = !motionNotifier.value;
    _motionChosen = true;
    await prefs.setString('ambient_motion', motionNotifier.value ? 'on' : 'off');
  }

  // The animations are too slow here: stop them, unless the visitor chose
  // themselves to keep them on.
  static Future<void> motionTooSlow() async {
    if (_motionChosen || !motionNotifier.value) return;
    motionNotifier.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ambient_motion', 'auto_off');
  }
}
