import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/utils/colors.dart';
import 'filter_criteria.dart';
import 'category_constants.dart';
import 'event_filter_logic.dart';

/// Maneja la organización y estructuración de datos de eventos
/// Ahora integrado con FilterCriteria y CategoryConstants
class EventDataBuilder {
  final DateTime _currentDate;
  final EventFilterLogic _filterLogic;
  
  EventDataBuilder(this._currentDate) : _filterLogic = EventFilterLogic();

  // ============ MÉTODOS PRINCIPALES (NUEVA API) ============
  
  /// Procesa eventos completos: filtra, ordena y agrupa (SIN DUPLICADOS)
  Map<String, List<Map<String, String>>> processEventsComplete(
    List<Map<String, String>> allEvents,
    FilterCriteria criteria,
  ) {
    final cleanEvents = _removeDuplicates(allEvents);
    final processedEvents = _filterLogic.processEvents(cleanEvents, criteria);
    return groupEventsByDate(processedEvents);
  }
  
  /// Procesa eventos para HomePage con límite inteligente (SIN DUPLICADOS)
  List<Map<String, String>> processEventsForHomePage(
    List<Map<String, String>> allEvents,
    FilterCriteria criteria,
  ) {
    final cleanEvents = _removeDuplicates(allEvents);
    final processedEvents = _filterLogic.processEvents(cleanEvents, criteria);
    return getHomePageEvents(processedEvents, criteria.selectedDate != null);
  }
  
  // ============ MÉTODOS DE AGRUPACIÓN Y ORGANIZACIÓN ============

  /// Agrupa eventos por fecha
  Map<String, List<Map<String, String>>> groupEventsByDate(
    List<Map<String, String>> events,
  ) {
    final groupedEvents = <String, List<Map<String, String>>>{};

    for (var event in events) {
      final date = event['date']!;
      final dateOnly = DateFormat('yyyy-MM-dd').format(DateFormat('yyyy-MM-ddTHH:mm').parse(date));
      if (!groupedEvents.containsKey(dateOnly)) {
        groupedEvents[dateOnly] = [];
      }
      groupedEvents[dateOnly]!.add(event);
    }

    return groupedEvents;
  }
  
  /// Procesa eventos para Calendario SIN LÍMITES (SIN DUPLICADOS)
  List<Map<String, String>> processEventsForCalendar(
    List<Map<String, String>> allEvents,
    FilterCriteria criteria,
  ) {
    final cleanEvents = _removeDuplicates(allEvents);
    return _filterLogic.processEvents(cleanEvents, criteria);
  }

  /// Procesa eventos completos para vistas que necesitan agrupación (SIN DUPLICADOS)
  Map<String, List<Map<String, String>>> processEventsCompleteForCalendar(
    List<Map<String, String>> allEvents,
    FilterCriteria criteria,
  ) {
    final processedEvents = processEventsForCalendar(allEvents, criteria);
    return groupEventsByDate(processedEvents);
  }
  
  /// Obtiene fechas ordenadas con prioridad para hoy y mañana
  List<String> getSortedDates(Map<String, List<Map<String, String>>> groupedEvents) {
    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(
      _currentDate.add(const Duration(days: 1)),
    );

    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDate(a);
        final dateB = _parseDate(b);
        
        // Priorizar hoy
        if (a == todayString || a.startsWith(todayString)) return -2;
        if (b == todayString || b.startsWith(todayString)) return 2;
        
        // Priorizar mañana
        if (a == tomorrowString || a.startsWith(tomorrowString)) return -1;
        if (b == tomorrowString || b.startsWith(tomorrowString)) return 1;
        
        return dateA.compareTo(dateB);
      });

    return sortedDates;
  }

  /// Obtiene eventos limitados para HomePage (SIN DUPLICADOS)
  List<Map<String, String>> getHomePageEvents(
    List<Map<String, String>> events,
    bool hasSelectedDate,
  ) {
    // Si hay fecha seleccionada, mostrar todos los eventos de ese día
    if (hasSelectedDate) return events;

    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(
      _currentDate.add(const Duration(days: 1)),
    );

    // USAR SETS para evitar duplicados durante la clasificación temporal
    final processedEventIds = <String>{};
    final result = <Map<String, String>>[];

    // PASO 1: Eventos de hoy (prioridad más alta)
    for (final event in events) {
      if (event['date']!.startsWith(todayString)) {
        final eventId = event['id'] ?? event['title'] ?? '';
        if (eventId.isNotEmpty && !processedEventIds.contains(eventId)) {
          processedEventIds.add(eventId);
          result.add(event);
        }
      }
    }

    // PASO 2: Eventos de mañana
    for (final event in events) {
      if (event['date']!.startsWith(tomorrowString)) {
        final eventId = event['id'] ?? event['title'] ?? '';
        if (eventId.isNotEmpty && !processedEventIds.contains(eventId)) {
          processedEventIds.add(eventId);
          result.add(event);
        }
      }
    }

    // PASO 3: Eventos futuros
    for (final event in events) {
      final eventDate = _parseDate(event['date']!);
      if (eventDate.isAfter(_currentDate.add(const Duration(days: 1)))) {
        final eventId = event['id'] ?? event['title'] ?? '';
        if (eventId.isNotEmpty && !processedEventIds.contains(eventId)) {
          processedEventIds.add(eventId);
          result.add(event);
        }
      }
    }

    // LÍMITE SOLO PARA HOMEPAGE
    return result.take(30).toList();
  }

  // ============ MÉTODOS DE FORMATEO Y PRESENTACIÓN ============

  /// Obtiene título de sección para una fecha
  String getSectionTitle(String date) {
    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(
      _currentDate.add(const Duration(days: 1)),
    );
    final parsedDate = _parseDate(date);
    final eventDateString = DateFormat('yyyy-MM-dd').format(parsedDate);

    if (eventDateString == todayString) {
      return 'Hoy';
    } else if (eventDateString == tomorrowString) {
      return 'Mañana';
    } else {
      final weekday = _capitalizeWord(
        DateFormat('EEEE', 'es').format(parsedDate),
      );
      final day = DateFormat('d', 'es').format(parsedDate);
      final month = _capitalizeWord(
        DateFormat('MMMM', 'es').format(parsedDate),
      );
      return '$weekday, $day de $month';
    }
  }

  /// Obtiene título principal de la página
  String getPageTitle(DateTime? selectedDate) {
    if (selectedDate == null) {
      return 'Próximos Eventos';
    } else {
      final month = _capitalizeWord(
        DateFormat('MMMM', 'es').format(selectedDate),
      );
      return 'Eventos de $month';
    }
  }
  
  /// Obtiene título principal usando FilterCriteria
  String getPageTitleFromCriteria(FilterCriteria criteria) {
    return getPageTitle(criteria.selectedDate);
  }

  /// Obtiene color de card según tipo de evento
  Color getEventCardColor(String eventType, BuildContext context) {
    final uiCategory = CategoryConstants.getUiName(eventType.toLowerCase());
    final color = CategoryConstants.getColor(uiCategory);
    return AppColors.adjustForTheme(context, color);
  }

  /// Formatea fecha para mostrar en eventos
  String formatEventDate(String dateString) {
    final eventDate = _parseDate(dateString);
    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(
      _currentDate.add(const Duration(days: 1)),
    );
    final eventDateString = DateFormat('yyyy-MM-dd').format(eventDate);

    if (eventDateString == todayString) {
      return 'Hoy';
    } else if (eventDateString == tomorrowString) {
      return 'Mañana';
    } else {
      return DateFormat('d MMM yyyy', 'es').format(eventDate);
    }
  }
  
  // ============ MÉTODOS DE ANÁLISIS Y ESTADÍSTICAS ============
  
  /// Obtiene estadísticas de los eventos filtrados
  Map<String, dynamic> getEventStatistics(
    List<Map<String, String>> events,
  ) {
    final stats = <String, dynamic>{};
    
    // Conteo por categorías
    final categoryCount = <String, int>{};
    for (var event in events) {
      final category = CategoryConstants.getUiName(event['type'] ?? '');
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    // Conteo por fechas
    final dateCount = <String, int>{};
    for (var event in events) {
      final date = formatEventDate(event['date']!);
      dateCount[date] = (dateCount[date] ?? 0) + 1;
    }
    
    // Conteo por level (eventos pagos)
    final paidEvents = events.where((event) {
      final level = int.tryParse(event['level'] ?? '0') ?? 0;
      return level > 0;
    }).length;
    
    stats['total'] = events.length;
    stats['byCategory'] = categoryCount;
    stats['byDate'] = dateCount;
    stats['paidEvents'] = paidEvents;
    stats['freeEvents'] = events.length - paidEvents;
    
    return stats;
  }

  // ============ MÉTODOS PRIVADOS ============

  /// Remueve eventos duplicados basándose en su ID
  List<Map<String, String>> _removeDuplicates(List<Map<String, String>> events) {
    final seen = <String>{};
    final deduplicated = <Map<String, String>>[];
    
    for (final event in events) {
      final eventId = event['id'] ?? event['title'] ?? '';
      if (eventId.isNotEmpty && !seen.contains(eventId)) {
        seen.add(eventId);
        deduplicated.add(event);
      }
    }
    
    return deduplicated;
  }

  /// Parseo flexible de fecha (con o sin hora)
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-ddTHH:mm').parse(dateString);
    } catch (e) {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    }
  }

  /// Capitaliza la primera letra de una palabra
  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }
}