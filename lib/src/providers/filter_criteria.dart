import 'package:flutter/foundation.dart';

/// Encapsula todos los criterios de filtrado de eventos
/// Inmutable para evitar mutaciones accidentales
class FilterCriteria {
  final String query;
  final Set<String> selectedCategories;
  final DateTime? selectedDate;
  
  const FilterCriteria({
    this.query = '',
    this.selectedCategories = const {},
    this.selectedDate,
  });
  
  /// Crea una nueva instancia con algunos valores modificados
  FilterCriteria copyWith({
    String? query,
    Set<String>? selectedCategories,
    DateTime? selectedDate,
    bool clearDate = false,
  }) {
    return FilterCriteria(
      query: query ?? this.query,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
    );
  }
  
  /// Verifica si no hay filtros activos
  bool get isEmpty => 
      query.isEmpty && 
      selectedCategories.isEmpty && 
      selectedDate == null;
  
  /// Verifica si hay filtros activos
  bool get hasActiveFilters => !isEmpty;
  
  /// Verifica si solo hay búsqueda activa
  bool get hasOnlySearch => 
      query.isNotEmpty && 
      selectedCategories.isEmpty && 
      selectedDate == null;
  
  /// Verifica si solo hay categorías activas
  bool get hasOnlyCategories => 
      query.isEmpty && 
      selectedCategories.isNotEmpty && 
      selectedDate == null;
  
  /// Verifica si solo hay fecha activa
  bool get hasOnlyDate => 
      query.isEmpty && 
      selectedCategories.isEmpty && 
      selectedDate != null;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterCriteria &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          setEquals(selectedCategories, other.selectedCategories) &&
          selectedDate == other.selectedDate;

  @override
  int get hashCode => 
      query.hashCode ^ 
      selectedCategories.hashCode ^ 
      selectedDate.hashCode;
      
  @override
  String toString() {
    return 'FilterCriteria(query: "$query", categories: $selectedCategories, date: $selectedDate)';
  }
  
  /// Crea criterios vacíos
  static const FilterCriteria empty = FilterCriteria();
  
  /// Crea criterios solo con búsqueda
  static FilterCriteria search(String query) => FilterCriteria(query: query);
  
  /// Crea criterios solo con categorías
  static FilterCriteria categories(Set<String> categories) => 
      FilterCriteria(selectedCategories: categories);
  
  /// Crea criterios solo con fecha
  static FilterCriteria date(DateTime date) => 
      FilterCriteria(selectedDate: date);
}