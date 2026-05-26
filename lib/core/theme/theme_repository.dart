import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeRepository {
  static const String _themeKey = 'app_theme_mode';

  /// Loads the saved theme from storage
  /// Returns AppThemeMode.light as default if no theme is saved
  Future<AppThemeMode> loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme == 'dark') {
        return AppThemeMode.dark;
      }
      return AppThemeMode.light;
    } catch (e) {
      // If there's any error, default to light mode
      return AppThemeMode.light;
    }
  }

  /// Saves the theme preference to storage
  Future<void> saveTheme(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeValue = mode == AppThemeMode.dark ? 'dark' : 'light';
      await prefs.setString(_themeKey, themeValue);
    } catch (e) {
      // Silently fail if unable to save
      // This prevents the app from crashing if storage is unavailable
    }
  }
}
