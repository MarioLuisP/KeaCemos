import 'package:flutter/material.dart';
import 'package:myapp/src/models/user_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  String _theme = 'normal';
  Set<String> _selectedCategories = {};
  Set<String> _activeFilterCategories = {};

  PreferencesProvider();

  Future<void> init() async {
    await _loadPreferences();
  }

  String get theme => _theme;
  Set<String> get selectedCategories => _selectedCategories;
  Set<String> get activeFilterCategories => _activeFilterCategories;

  Future<void> _loadPreferences() async {
    _theme = await UserPreferences.getTheme();
    _selectedCategories = await UserPreferences.getCategories();

    // Si no hay nada guardado, activar todas por defecto
    if (_selectedCategories.isEmpty) {
      _selectedCategories = {
        'Música', 'Teatro', 'StandUp', 'Arte', 'Cine', 'Mic', 'Cursos',
        'Ferias', 'Calle', 'Redes', 'Niños', 'Danza'
      };
    }

    _activeFilterCategories = await UserPreferences.getActiveFilterCategories();
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
      _activeFilterCategories.remove(category);
      await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    } else {
      _selectedCategories.add(category);
    }

    await UserPreferences.setCategories(_selectedCategories);
    notifyListeners();
  }

  Future<void> resetCategories() async {
    _selectedCategories = {
      'Música', 'Teatro', 'StandUp', 'Arte', 'Cine', 'Mic', 'Cursos',
      'Ferias', 'Calle', 'Redes', 'Niños', 'Danza'
    };
    _activeFilterCategories.clear();
    await UserPreferences.setCategories(_selectedCategories);
    await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    notifyListeners();
  }

  Future<void> toggleFilterCategory(String category) async {
    if (_activeFilterCategories.contains(category)) {
      _activeFilterCategories.remove(category);
    } else {
      _activeFilterCategories.add(category);
    }
    await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    notifyListeners();
  }
}
