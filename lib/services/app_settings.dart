import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

class AppSettings {
  static const String keyFirstLaunch = 'first_launch_v3_0';
  static const String keyUsername = 'user_name';
  static const String keyTheme = 'app_theme_style';
  static const String keyCustomAccentColor = 'custom_accent_color';
  static const String keyCustomBgImagePath = 'custom_bg_image_path';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyFirstLaunch) ?? true;
  }

  static Future<void> completeOnboarding(String username, AppThemeStyle theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyFirstLaunch, false);
    await prefs.setString(keyUsername, username);
    await prefs.setString(keyTheme, theme.name);
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUsername) ?? 'Gustavo';
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
