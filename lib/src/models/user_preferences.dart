import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme') ?? 'normal';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }

  static Future<Set<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('categories') ?? []).toSet();
  }

  static Future<void> setCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', categories.toList());
  }

    static Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('favorite_ids') ?? []).toSet();
  }

  static Future<void> setFavoriteIds(Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ids', favoriteIds.toList());
  }

  static Future<Set<String>> getActiveFilterCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('activeFilterCategories') ?? []).toSet();
  }

  static Future<void> setActiveFilterCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('activeFilterCategories', categories.toList());
  }
}