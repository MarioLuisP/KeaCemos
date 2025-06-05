import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _themeKey = 'theme';
  static const String _categoriesKey = 'categories';

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'normal';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  static Future<Set<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categories = prefs.getStringList(_categoriesKey) ?? [];
    return categories.toSet();
  }

  static Future<void> setCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories.toList());
  }
}