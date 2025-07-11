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
  Map<String, List<Map<String, dynamic>>> processEventsComplete(
    List<Map<String, dynamic>> allEvents,
    FilterCriteria criteria,
  ) {
    final cleanEvents = _removeDuplicates(allEvents);
    final processedEvents = _filterLogic.processEvents(cleanEvents, criteria);
    return groupEventsByDate(processedEvents);
  }

  /// Procesa eventos para HomePage con límite inteligente (SIN DUPLICADOS)
  List<Map<String, dynamic>> processEventsForHomePage(
    List<Map<String, dynamic>> allEvents,
    FilterCriteria criteria,
  ) {
    final cleanEvents = _removeDuplicates(allEvents);
    final processedEvents = _filterLogic.processEvents(cleanEvents, criteria);
    return getHomePageEvents(processedEvents, criteria.selectedDate != null);
  }

  // ============ MÉTODOS DE AGRUPACIÓN Y ORGANIZACIÓN ============

  /// Agrupa eventos por fecha
  Map<String, List<Map<String, dynamic>>> groupEventsByDate(
    List<Map<String, dynamic>> events,
  ) {
    final groupedEvents = <String, List<Map<String, dynamic>>>{};

    for (var event in events) {
      final date = event['date']!;
      final dateOnly = DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('yyyy-MM-ddTHH:mm').parse(date));
      if (!groupedEvents.containsKey(dateOnly)) {
        groupedEvents[dateOnly] = [];
      }
      groupedEvents[dateOnly]!.add(event);
    }

    return groupedEvents;
  }

  /// Procesa eventos para Calendario SIN LÍMITES (SIN DUPLICADOS)
  List<Map<String, dynamic>> processEventsForCalendar(
    List<Map<String, dynamic>> allEvents,
    FilterCriteria criteria,
  ) {
    final cleanEvents = _removeDuplicates(allEvents);
    return _filterLogic.sortEvents(cleanEvents);
  }

  /// Procesa eventos completos para vistas que necesitan agrupación (SIN DUPLICADOS)
  Map<String, List<Map<String, dynamic>>> processEventsCompleteForCalendar(
    List<Map<String, dynamic>> allEvents,
    FilterCriteria criteria,
  ) {
    final processedEvents = processEventsForCalendar(allEvents, criteria);
    return groupEventsByDate(processedEvents);
  }

  /// Obtiene fechas ordenadas con prioridad para hoy y mañana
  List<String> getSortedDates(
    Map<String, List<Map<String, dynamic>>> groupedEvents,
  ) {
    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat(
      'yyyy-MM-dd',
    ).format(_currentDate.add(const Duration(days: 1)));

    final sortedDates =
        groupedEvents.keys.toList()..sort((a, b) {
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
  List<Map<String, dynamic>> getHomePageEvents(
    List<Map<String, dynamic>> events,
    bool hasSelectedDate,
  ) {
    // Si hay fecha seleccionada, mostrar todos los eventos de ese día
    if (hasSelectedDate) return events;

    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat(
      'yyyy-MM-dd',
    ).format(_currentDate.add(const Duration(days: 1)));

    // USAR SETS para evitar duplicados durante la clasificación temporal
    final processedEventIds = <String>{};
    final result = <Map<String, dynamic>>[];

    // PASO 1: Eventos de hoy (prioridad más alta)
    for (final event in events) {
      if (event['date']!.startsWith(todayString)) {
        final eventId = event['id']?.toString() ?? event['title'] ?? '';
        if (eventId.isNotEmpty && !processedEventIds.contains(eventId)) {
          processedEventIds.add(eventId);
          result.add(event);
        }
      }
    }

    // PASO 2: Eventos de mañana
    for (final event in events) {
      if (event['date']!.startsWith(tomorrowString)) {
        final eventId = event['id']?.toString() ?? event['title'] ?? '';
        if (eventId.isNotEmpty && !processedEventIds.contains(eventId)) {
          processedEventIds.add(eventId);
          result.add(event);
        }
      }
    }

    // PASO 3: Eventos futuros (solo posteriores a mañana)
    final tomorrowDate = _currentDate.add(const Duration(days: 1));
    for (final event in events) {
      final eventDate = _parseDate(event['date']!);
      if (eventDate.isAfter(tomorrowDate)) {
        final eventId = event['id']?.toString() ?? event['title'] ?? '';
        if (eventId.isNotEmpty && !processedEventIds.contains(eventId)) {
          processedEventIds.add(eventId);
          result.add(event);
        }
      }
    }
    // LÍMITE SOLO PARA HOMEPAGE
    return result.take(80).toList();
  }

  // ============ MÉTODOS DE FORMATEO Y PRESENTACIÓN ============

  /// Obtiene título de sección para una fecha
  String getSectionTitle(String date) {
    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat(
      'yyyy-MM-dd',
    ).format(_currentDate.add(const Duration(days: 1)));
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

  /// Formatea fecha para mostrar en diferentes contextos
  String formatEventDate(String dateString, {String format = 'full'}) {
    // Intentar parsear la fecha en diferentes formatos
    DateTime? date;

    try {
      // Primero intentar con formato ISO completo
      date = DateTime.tryParse(dateString);

      // Si falla, intentar solo fecha (yyyy-MM-dd)
      if (date == null && dateString.length >= 10) {
        date = DateTime.tryParse(dateString.substring(0, 10));
      }

      // Si aún falla, devolver string original
      if (date == null) {
        print('⚠️ No se pudo parsear fecha: $dateString');
        return dateString;
      }
    } catch (e) {
      print('❌ Error parseando fecha: $dateString - $e');
      return dateString;
    }

    switch (format) {
      case 'card':
        // Formato para tarjetas: "📅 3 jun - 20:30 hs"
        return "${date.day} ${_getMonthAbbrev(date.month)}${_getTimeString(date)}";

      case 'calendar':
        // Formato para calendario: "3/6"
        return "${date.day}/${date.month}";

      case 'full':
      default:
        // Formato completo para home: "Martes, 3 de Junio"
        return _getFullDateFormat(date);
    }
  }

  /// Obtiene abreviación del mes en español
  String _getMonthAbbrev(int month) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month] ?? 'mes';
  }

  /// Formatea la hora si está disponible
  String _getTimeString(DateTime date) {
    // Si la fecha tiene hora específica (no es medianoche)
    if (date.hour != 0 || date.minute != 0) {
      return " - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hs";
    }
    return ""; // Solo fecha, sin hora
  }

  /// Formato completo de fecha (para HomePage)
  String _getFullDateFormat(DateTime date) {
    final todayString = DateFormat('yyyy-MM-dd').format(_currentDate);
    final tomorrowString = DateFormat(
      'yyyy-MM-dd',
    ).format(_currentDate.add(const Duration(days: 1)));
    final eventDateString = DateFormat('yyyy-MM-dd').format(date);

    if (eventDateString == todayString) {
      return 'Hoy';
    } else if (eventDateString == tomorrowString) {
      return 'Mañana';
    } else {
      final formatter = DateFormat('EEEE, d \'de\' MMMM', 'es_ES');
      String formatted = formatter.format(date);

      // Capitalizar primera letra
      return formatted.substring(0, 1).toUpperCase() + formatted.substring(1);
    }
  }
  // ============ MÉTODOS DE ANÁLISIS Y ESTADÍSTICAS ============

  /// Obtiene estadísticas de los eventos filtrados
  Map<String, dynamic> getEventStatistics(List<Map<String, dynamic>> events) {
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
    final paidEvents =
        events.where((event) {
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
  List<Map<String, dynamic>> _removeDuplicates(
    List<Map<String, dynamic>> events,
  ) {
    final seen = <String>{};
    final deduplicated = <Map<String, dynamic>>[];

    for (final event in events) {
      final eventId = event['id']?.toString() ?? event['title'] ?? '';
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
