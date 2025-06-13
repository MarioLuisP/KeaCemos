import 'package:intl/intl.dart';
import 'filter_criteria.dart';
import 'category_constants.dart';

/// Maneja toda la lógica de filtrado y búsqueda de eventos
/// Ahora usa FilterCriteria para encapsular parámetros
class EventFilterLogic {
  
  /// Método principal: aplica todos los filtros según criterios
  List<Map<String, String>> applyFilters(
    List<Map<String, String>> events,
    FilterCriteria criteria,
  ) {
    if (criteria.isEmpty) return events;
    
    var filtered = events;
    
    // Aplicar filtro de búsqueda
    if (criteria.query.isNotEmpty) {
      filtered = _applySearchFilter(filtered, criteria.query);
    }
    
    // Aplicar filtro de categorías
    if (criteria.selectedCategories.isNotEmpty) {
      filtered = _applyCategoryFilter(filtered, criteria.selectedCategories);
    }
    
    // Aplicar filtro de fecha (si está presente)
    if (criteria.selectedDate != null) {
      filtered = _applyDateFilter(filtered, criteria.selectedDate!);
    }
    
    return filtered;
  }
  
  /// Ordena eventos por fecha, luego por level (pago por pauta), luego por tipo
  List<Map<String, String>> sortEvents(List<Map<String, String>> events) {
    final sortedEvents = List<Map<String, String>>.from(events);
    
    sortedEvents.sort((a, b) {
      // 1. Primero por fecha
      final dateA = _parseDate(a['date']!);
      final dateB = _parseDate(b['date']!);
      int dateComparison = dateA.compareTo(dateB);
      if (dateComparison != 0) return dateComparison;

      // 2. Dentro de la misma fecha, por level (descendente: 40, 20, 5, 0)
      final levelA = int.tryParse(a['level'] ?? '0') ?? 0;
      final levelB = int.tryParse(b['level'] ?? '0') ?? 0;
      int levelComparison = levelB.compareTo(levelA); // DESC
      if (levelComparison != 0) return levelComparison;

      // 3. Finalmente por tipo (ascendente)
      final typeA = a['type']?.toLowerCase() ?? '';
      final typeB = b['type']?.toLowerCase() ?? '';
      return typeA.compareTo(typeB);
    });

    return sortedEvents;
  }
  
  /// Aplica filtros y ordenamiento en un solo paso
  List<Map<String, String>> processEvents(
    List<Map<String, String>> events,
    FilterCriteria criteria,
  ) {
    final filtered = applyFilters(events, criteria);
    return sortEvents(filtered);
  }
  
  // ============ MÉTODOS LEGACY (RETROCOMPATIBILIDAD) ============
  
  /// Método legacy - usar applyFilters() con FilterCriteria.search()
  @Deprecated('Usar applyFilters() con FilterCriteria en su lugar')
  List<Map<String, String>> applySearchFilter(
    List<Map<String, String>> events,
    String searchQuery,
  ) {
    return _applySearchFilter(events, searchQuery);
  }

  /// Método legacy - usar applyFilters() con FilterCriteria.categories()
  @Deprecated('Usar applyFilters() con FilterCriteria en su lugar')
  List<Map<String, String>> applyCategoryFilter(
    List<Map<String, String>> events,
    Set<String> activeCategories,
  ) {
    return _applyCategoryFilter(events, activeCategories);
  }

  /// Método legacy - usar applyFilters() directamente
  @Deprecated('Usar applyFilters() con FilterCriteria en su lugar')
  List<Map<String, String>> applyAllFilters(
    List<Map<String, String>> events,
    Set<String> activeCategories,
    String searchQuery,
  ) {
    final criteria = FilterCriteria(
      query: searchQuery,
      selectedCategories: activeCategories,
    );
    return applyFilters(events, criteria);
  }

  /// Getter legacy - usar CategoryConstants.uiToBackend
  @Deprecated('Usar CategoryConstants.uiToBackend en su lugar')
  static Map<String, String> get categoryMapping => CategoryConstants.uiToBackend;
  
  // ============ MÉTODOS PRIVADOS ============
  
  /// Filtro interno de búsqueda por texto
  List<Map<String, String>> _applySearchFilter(
    List<Map<String, String>> events,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return events;

    final lowerQuery = searchQuery.toLowerCase();
    return events
        .where((event) =>
            event['title']!.toLowerCase().contains(lowerQuery) ||
            event['location']!.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Filtro interno de categorías
  List<Map<String, String>> _applyCategoryFilter(
    List<Map<String, String>> events,
    Set<String> activeCategories,
  ) {
    if (activeCategories.isEmpty) return events;

    final normalizedCategories = activeCategories
        .map((category) => CategoryConstants.getBackendId(category))
        .toSet();

    return events.where((event) {
      final eventType = event['type']?.toLowerCase() ?? '';
      return normalizedCategories.contains(eventType);
    }).toList();
  }
  
  /// Filtro interno de fecha específica
  List<Map<String, String>> _applyDateFilter(
    List<Map<String, String>> events,
    DateTime selectedDate,
  ) {
    final targetDateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    return events.where((event) {
      final eventDate = _parseDate(event['date']!);
      final eventDateString = DateFormat('yyyy-MM-dd').format(eventDate);
      return eventDateString == targetDateString;
    }).toList();
  }

  /// Parseo flexible de fecha (con o sin hora)
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-ddTHH:mm').parse(dateString);
    } catch (e) {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    }
  }
}