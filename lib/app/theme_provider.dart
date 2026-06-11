import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeController extends StateNotifier<AppThemeMode> {
  ThemeController() : super(AppThemeMode.system) {
    _load();
  }

  static const _key = 'app_theme_mode';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      if (v == 'light') state = AppThemeMode.light;
      if (v == 'dark') state = AppThemeMode.dark;
      if (v == 'system') state = AppThemeMode.system;
    } catch (_) {}
  }

  Future<void> set(AppThemeMode m) async {
    state = m;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, m.name);
    } catch (_) {}
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, AppThemeMode>(
        (ref) => ThemeController());

ThemeMode resolveThemeMode(AppThemeMode m) {
  switch (m) {
    case AppThemeMode.system:
      return ThemeMode.system;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
  }
}
