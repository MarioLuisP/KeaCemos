import 'package:flutter/material.dart';
import 'package:myapp/src/models/user_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  String _theme = 'normal';
  Set<String> _selectedCategories = {};

  PreferencesProvider() {
    // Constructor vacío, inicialización en init()
  }

  Future<void> init() async {
    await _loadPreferences();
  }

  String get theme => _theme;
  Set<String> get selectedCategories => _selectedCategories;

  Future<void> _loadPreferences() async {
    _theme = await UserPreferences.getTheme();
    _selectedCategories = await UserPreferences.getCategories();
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _theme = theme;
    await UserPreferences.setTheme(theme);
    notifyListeners();
  }

  Future<void> toggleCategory(String category) async {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else if (_selectedCategories.length < 4) {
      _selectedCategories.add(category);
    }
    await UserPreferences.setCategories(_selectedCategories);
    notifyListeners();
  }

  Future<void> resetCategories() async {
    _selectedCategories.clear();
    await UserPreferences.setCategories(_selectedCategories);
    notifyListeners();
  }
}