import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Centraliza todas las constantes relacionadas con categorías
/// Evita duplicación entre EventFilterLogic y EventDataBuilder
class CategoryConstants {
  // Mapeo de categorías UI → Backend
  static const Map<String, String> uiToBackend = {
    'Música': 'musica',
    'Teatro': 'teatro', 
    'StandUp': 'standup',
    'Arte': 'arte',
    'Cine': 'cine',
    'Mic': 'mic',
    'Cursos': 'cursos',
    'Ferias': 'ferias',
    'Calle': 'calle',
    'Redes': 'redes',
    'Niños': 'ninos',
    'Danza': 'danza',
  };
  
  // Mapeo inverso Backend → UI
  static final Map<String, String> backendToUi = {
    for (var entry in uiToBackend.entries) entry.value: entry.key
  };
  
  /// Obtiene el identificador backend de una categoría UI
  static String getBackendId(String uiCategory) {
    return uiToBackend[uiCategory] ?? uiCategory.toLowerCase();
  }
  
  /// Obtiene el nombre UI de una categoría backend
  static String getUiName(String backendId) {
    return backendToUi[backendId] ?? _capitalizeFirst(backendId);
  }
  
  /// Obtiene el color de una categoría desde AppColors
  static Color getColor(String category) {
    return AppColors.categoryColors[category] ?? AppColors.defaultColor;
  }
  
  /// Verifica si una categoría existe
  static bool isValidUiCategory(String category) {
    return uiToBackend.containsKey(category);
  }
  
  /// Verifica si un ID backend existe
  static bool isValidBackendId(String backendId) {
    return backendToUi.containsKey(backendId);
  }
  
  /// Obtiene todas las categorías UI disponibles
  static List<String> get allUiCategories => uiToBackend.keys.toList();
  
  /// Obtiene todos los IDs backend disponibles
  static List<String> get allBackendIds => uiToBackend.values.toList();
  
  /// Capitaliza la primera letra
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Conjunto de categorías especiales para lógica específica
  static const Set<String> musicCategories = {'Música', 'Mic', 'Danza'};
  static const Set<String> performanceCategories = {'Teatro', 'StandUp', 'Danza'};
  static const Set<String> visualCategories = {'Arte', 'Cine'};
  static const Set<String> learningCategories = {'Cursos'};
  static const Set<String> familyCategories = {'Niños'};
  static const Set<String> outdoorCategories = {'Calle', 'Ferias'};
  static const Set<String> digitalCategories = {'Redes'};
}