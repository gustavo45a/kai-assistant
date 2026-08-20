import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

class AppSettings {
  static const String keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String keyFirstLaunch = 'first_launch_v3_0';
  static const String keyUsername = 'user_name';
  static const String keyUserDialect = 'user_dialect';
  static const String keyUserGender = 'user_gender';
  static const String keyTheme = 'app_theme_style';
  static const String keyCustomAccentColor = 'custom_accent_color';
  static const String keyCustomBgImagePath = 'custom_bg_image_path';

  /// Indica si el usuario ya completó el Setup Inicial de Kai.
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(keyHasCompletedOnboarding)) {
      return prefs.getBool(keyHasCompletedOnboarding) ?? false;
    }
    // Compatibilidad retrospectiva con versiones anteriores
    final firstLaunch = prefs.getBool(keyFirstLaunch);
    if (firstLaunch != null) {
      return !firstLaunch;
    }
    return false;
  }

  /// Guarda el setup inicial completo del usuario y de Kai.
  static Future<void> completeSetup({
    required String username,
    required String dialect,
    required String gender,
    AppThemeStyle theme = AppThemeStyle.vantablackGlass,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasCompletedOnboarding, true);
    await prefs.setBool(keyFirstLaunch, false);
    await prefs.setString(keyUsername, username);
    await prefs.setString(keyUserDialect, dialect);
    await prefs.setString(keyUserGender, gender);
    await prefs.setString(keyTheme, theme.name);
  }

  /// Compatibilidad para flujos rápidos
  static Future<void> completeOnboarding(String username, AppThemeStyle theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasCompletedOnboarding, true);
    await prefs.setBool(keyFirstLaunch, false);
    await prefs.setString(keyUsername, username);
    await prefs.setString(keyTheme, theme.name);
  }

  static Future<bool> isFirstLaunch() async {
    final completed = await hasCompletedOnboarding();
    return !completed;
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUsername) ?? 'Gustavo';
  }

  static Future<String> getDialect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserDialect) ?? 'es-ES (Español)';
  }

  static Future<String> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserGender) ?? 'Neutro / Flexible';
  }

  static Future<AppThemeStyle> getSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(keyTheme);
    if (name != null) {
      return AppThemeStyle.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppThemeStyle.vantablackGlass,
      );
    }
    return AppThemeStyle.vantablackGlass;
  }

  static Future<void> saveTheme(AppThemeStyle theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTheme, theme.name);
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUsername, username);
  }

  static Future<int?> getCustomAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyCustomAccentColor);
  }

  static Future<void> saveCustomAccentColor(int? colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    if (colorValue == null) {
      await prefs.remove(keyCustomAccentColor);
    } else {
      await prefs.setInt(keyCustomAccentColor, colorValue);
    }
  }

  static Future<String?> getCustomBgImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCustomBgImagePath);
  }

  static Future<void> saveCustomBgImagePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(keyCustomBgImagePath);
    } else {
      await prefs.setString(keyCustomBgImagePath, path);
    }
  }
}
