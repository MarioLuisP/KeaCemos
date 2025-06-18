import 'package:intl/intl.dart';
import 'filter_criteria.dart';
import 'category_constants.dart';

/// Maneja toda la lógica de filtrado y búsqueda de eventos
/// Ahora usa FilterCriteria para encapsular parámetros
class EventFilterLogic {
  // 🔥 NUEVO: Fecha actual para filtro de eventos pasados
  final DateTime _currentDate = DateTime(2025, 6, 4); // Usar la misma fecha que HomeViewModel
  
  /// Método principal: aplica todos los filtros según criterios
  List<Map<String, String>> applyFilters(
    List<Map<String, String>> events,
    FilterCriteria criteria,
  ) {
    if (criteria.isEmpty) {
      // 🔥 NUEVO: Aunque no hay filtros específicos, siempre filtrar eventos pasados
      // EXCEPTO cuando hay una fecha específica seleccionada
      if (criteria.selectedDate == null) {
        return _filterPastEvents(events);
      }
      return events;
    }
    
    var filtered = events;
    
    // 🔥 NUEVO: Filtrar eventos pasados PRIMERO (excepto si hay fecha específica)
    if (criteria.selectedDate == null) {
      filtered = _filterPastEvents(filtered);
      print('🕒 Eventos después de filtrar pasados: ${filtered.length}');
    }
    
    // Aplicar filtro de búsqueda
    if (criteria.query.isNotEmpty) {
      filtered = _applySearchFilter(filtered, criteria.query);
      print('🔍 Eventos después de búsqueda: ${filtered.length}');
    }
    
    // Aplicar filtro de categorías
    if (criteria.selectedCategories.isNotEmpty) {
      filtered = _applyCategoryFilter(filtered, criteria.selectedCategories);
      print('🏷️ Eventos después de categorías: ${filtered.length}');
    }
    
    // Aplicar filtro de fecha (si está presente)
    if (criteria.selectedDate != null) {
      filtered = _applyDateFilter(filtered, criteria.selectedDate!);
      print('📅 Eventos después de fecha específica: ${filtered.length}');
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
    print('🔄 Procesando ${events.length} eventos con criterios: ${criteria.toString()}');
    final filtered = applyFilters(events, criteria);
    print('✅ Eventos filtrados: ${filtered.length}');
    return sortEvents(filtered);
  }
  
  // ============ NUEVOS MÉTODOS PARA FILTRO DE EVENTOS PASADOS ============
  
  /// 🔥 NUEVO: Filtra eventos anteriores a hoy
  List<Map<String, String>> _filterPastEvents(List<Map<String, String>> events) {
    final todayStart = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    
    final filteredEvents = events.where((event) {
      try {
        final eventDate = _parseDate(event['date']!);
        final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
        
        // Solo mantener eventos de hoy en adelante
        final isToday = eventDateOnly.isAtSameMomentAs(todayStart);
        final isFuture = eventDateOnly.isAfter(todayStart);
        
        if (!isToday && !isFuture) {
          print('🗑️ Eliminando evento pasado: ${event['title']} (${event['date']})');
        }
        
        return isToday || isFuture;
      } catch (e) {
        print('⚠️ Error parseando fecha para filtro: ${event['date']} - $e');
        return false; // Descartar eventos con fecha inválida
      }
    }).toList();
    
    print('🕒 Filtro de eventos pasados: ${events.length} → ${filteredEvents.length}');
    return filteredEvents;
  }
  
  /// 🔥 NUEVO: Método público para filtrar eventos pasados (útil para testing)
  List<Map<String, String>> filterPastEvents(List<Map<String, String>> events) {
    return _filterPastEvents(events);
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