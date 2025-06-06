import 'package:flutter/material.dart';
import 'package:myapp/src/models/user_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  String _theme = 'normal';
  Set<String> _selectedCategories = {'Cine', 'Teatro', 'StandUp', 'Ferias'}; // Por defecto
  Set<String> _activeFilterCategories = {}; // Nuevo: categorías activas para filtrado

  PreferencesProvider() {
    // Constructor vacío, inicialización en init()
  }

  Future<void> init() async {
    await _loadPreferences();
  }

  String get theme => _theme;
  Set<String> get selectedCategories => _selectedCategories;
  Set<String> get activeFilterCategories => _activeFilterCategories;

  Future<void> _loadPreferences() async {
    _theme = await UserPreferences.getTheme();
    _selectedCategories = await UserPreferences.getCategories();
    if (_selectedCategories.isEmpty) {
      _selectedCategories = {'Cine', 'Teatro', 'StandUp', 'Ferias'};
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
    } else if (_selectedCategories.length < 4) {
      _selectedCategories.add(category);
    }
    await UserPreferences.setCategories(_selectedCategories);
    // Resetear filtros activos si la categoría ya no está seleccionada
    if (!_selectedCategories.contains(category)) {
      _activeFilterCategories.remove(category);
      await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    }
    notifyListeners();
  }

  Future<void> resetCategories() async {
    _selectedCategories = {'Cine', 'Teatro', 'StandUp', 'Ferias'};
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