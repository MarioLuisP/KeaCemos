import 'dart:io'; // 👈 Import necesario para SocketException
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/services/event_service.dart';
import 'package:myapp/src/utils/colors.dart';

enum EventsLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class HomeViewModel with ChangeNotifier {
  final EventService _eventService = EventService();

  // Estado actual
  EventsLoadingState _state = EventsLoadingState.idle;
  List<Map<String, String>> _allEvents = [];
  List<Map<String, String>> _filteredEvents = [];
  DateTime? _selectedDate;
  String _searchQuery = '';
  String? _errorMessage;

  // Configuración de desarrollo
  final DateTime _devNow = DateTime(2025, 6, 4); // Fecha fija en desarrollo

  // Mapeo de categorías centralizado
  static const Map<String, String> _categoryMapping = {
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

  // Getters
  EventsLoadingState get state => _state;
  List<Map<String, String>> get filteredEvents => _filteredEvents;
  DateTime? get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == EventsLoadingState.loading;
  bool get hasError => _state == EventsLoadingState.error;
  DateTime get currentDate => _devNow;

  // Inicialización
  Future<void> initialize({DateTime? selectedDate}) async {
    _selectedDate = selectedDate;
    await loadEvents();
  }

  // Cargar eventos
  Future<void> loadEvents() async {
    _state = EventsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Map<String, String>> events = await retry(
        () async {
          if (_selectedDate != null) {
            return await _eventService.getEventsForDay(_selectedDate!).timeout(
                const Duration(seconds: 10));
          } else {
            return await _eventService.getAllEvents().timeout(
                const Duration(seconds: 10));
          }
        },
        retries: 3,
      );

      _allEvents = events;
      _state = EventsLoadingState.loaded;
      _applyFilters();
    } catch (e) {
      if (e is SocketException) {
        _state = EventsLoadingState.error;
        _errorMessage = 'No hay conexión a internet.';
      } else if (e is TimeoutException) {
        _state = EventsLoadingState.error;
        _errorMessage = 'La carga de eventos tomó demasiado tiempo.';
      } else {
        _state = EventsLoadingState.error;
        _errorMessage = 'Ocurrió un error inesperado: $e';
      }

      _filteredEvents = [];
      notifyListeners();
    }
  }

  // Reintento con delay
  Future<T> retry<T>(Future<T> Function() action, {int retries = 3}) async {
    for (var i = 0; i < retries; i++) {
      try {
        return await action();
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("No se pudo completar la acción");
  }

  // Aplicar filtros (búsqueda + ordenamiento)
  void _applyFilters() {
    _filteredEvents = List.from(_allEvents);

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredEvents = _filteredEvents.where((event) =>
          event['title']!.toLowerCase().contains(lowerQuery) ||
          event['location']!.toLowerCase().contains(lowerQuery)).toList();
    }

    // Ordenar por fecha y luego por tipo
    _filteredEvents.sort((a, b) {
      final dateA = parseDate(a['date']!);
      final dateB = parseDate(b['date']!);

      int dateComparison = dateA.compareTo(dateB);
      if (dateComparison != 0) return dateComparison;

      final typeA = a['type']?.toLowerCase() ?? '';
      final typeB = b['type']?.toLowerCase() ?? '';

      return typeA.compareTo(typeB);
    });

    notifyListeners();
  }

  // Parseo flexible de fecha (con o sin hora)
  DateTime parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-ddTHH:mm').parse(dateString);
    } catch (e) {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    }
  }

  // Aplicar filtros de categorías desde PreferencesProvider
  void applyCategoryFilters(Set<String> activeCategories) {
    if (activeCategories.isEmpty) {
      _filteredEvents = List.from(_allEvents);
    } else {
      final normalizedCategories = activeCategories.map((c) => _categoryMapping[c] ?? c.toLowerCase());
      _filteredEvents = _allEvents.where((event) {
        final eventType = event['type']?.toLowerCase() ?? '';
        return normalizedCategories.contains(eventType);
      }).toList();
    }

    // Aplicar filtro de búsqueda si existe
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredEvents = _filteredEvents.where((event) =>
          event['title']!.toLowerCase().contains(lowerQuery) ||
          event['location']!.toLowerCase().contains(lowerQuery)).toList();
    }

    notifyListeners();
  }

  // Cambiar fecha seleccionada (para Calendar)
  Future<void> setSelectedDate(DateTime? date) async {
    if (_selectedDate != date) {
      _selectedDate = date;
      await loadEvents();
    }
  }

  // Cambiar query de búsqueda (para Explorer)
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  // Limpiar búsqueda
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  // Limpiar fecha seleccionada (volver a mostrar todos)
  Future<void> clearSelectedDate() async {
    _selectedDate = null;
    await loadEvents();
  }

  // Obtener eventos agrupados por fecha (para HomePage)
  Map<String, List<Map<String, String>>> getGroupedEvents() {
    final groupedEvents = <String, List<Map<String, String>>>{};

    for (var event in _filteredEvents) {
      final date = event['date']!;
      if (!groupedEvents.containsKey(date)) {
        groupedEvents[date] = [];
      }
      groupedEvents[date]!.add(event);
    }

    return groupedEvents;
  }

  // Obtener fechas ordenadas (para HomePage)
  List<String> getSortedDates() {
    final groupedEvents = getGroupedEvents();
    final todayString = DateFormat('yyyy-MM-dd').format(_devNow);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(_devNow.add(const Duration(days: 1)));

    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) {
        final dateA = parseDate(a);
        final dateB = parseDate(b);
        if (a == todayString || a.startsWith(todayString)) return -2;
        if (b == todayString || b.startsWith(todayString)) return 2;
        if (a == tomorrowString || a.startsWith(tomorrowString)) return -1;
        if (b == tomorrowString || b.startsWith(tomorrowString)) return 1;
        return dateA.compareTo(dateB);
      });

    return sortedDates;
  }

  // Obtener eventos limitados para HomePage (si no hay fecha seleccionada)
  List<Map<String, String>> getHomePageEvents() {
    if (_selectedDate != null) {
      return _filteredEvents;
    }

    final todayString = DateFormat('yyyy-MM-dd').format(_devNow);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(_devNow.add(const Duration(days: 1)));

    final todayEvents = _filteredEvents
        .where((event) => event['date']!.startsWith(todayString))
        .toList();
    final tomorrowEvents = _filteredEvents
        .where((event) => event['date']!.startsWith(tomorrowString))
        .toList();
    final futureEvents = _filteredEvents.where((event) {
      final eventDate = parseDate(event['date']!);
      return eventDate.isAfter(_devNow.add(const Duration(days: 1)));
    }).toList();

    return [...todayEvents, ...tomorrowEvents, ...futureEvents].take(20).toList();
  }



  String capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

  // Obtener título de sección para una fecha
  String getSectionTitle(String date) {
    final todayString = DateFormat('yyyy-MM-dd').format(_devNow);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(_devNow.add(const Duration(days: 1)));
    final parsedDate = parseDate(date);

    final eventDateString = DateFormat('yyyy-MM-dd').format(parsedDate);

    if (eventDateString == todayString) {
      return 'Hoy';
    } else if (eventDateString == tomorrowString) {
      return 'Mañana';
    } else {
      final weekday = capitalizeWord(DateFormat('EEEE', 'es').format(parsedDate)); // viernes → Viernes
      final day = DateFormat('d', 'es').format(parsedDate);                         // 6
      final month = capitalizeWord(DateFormat('MMMM', 'es').format(parsedDate));   // junio → Junio
      return '$weekday, $day de $month';  // Viernes, 6 de Junio
    }
  }

  // Obtener título principal de la página
  String getPageTitle() {
    if (_selectedDate == null) {
      return 'Próximos Eventos';
    } else {
      final month = capitalizeWord(DateFormat('MMMM', 'es').format(_selectedDate!));
      return 'Eventos de $month';
    }
  }

    // Refresh/reload
    Future<void> refresh() async {
      await loadEvents();
    }

  // Obtener color de card según tipo de evento
  Color getEventCardColor(String eventType, BuildContext context) {
    final category = _categoryMapping.entries
        .firstWhere((entry) => entry.value == eventType.toLowerCase(),
            orElse: () => MapEntry('', 'default'))
        .key;

    final color = AppColors.categoryColors[category] ?? AppColors.defaultColor;
    return AppColors.adjustForTheme(context, color);
  }

  // Formatear fecha para mostrar
  String formatEventDate(String dateString) {
    final eventDate = parseDate(dateString);
    final todayString = DateFormat('yyyy-MM-dd').format(_devNow);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(_devNow.add(const Duration(days: 1)));

    final eventDateString = DateFormat('yyyy-MM-dd').format(eventDate);

    if (eventDateString == todayString) {
      return 'Hoy';
    } else if (eventDateString == tomorrowString) {
      return 'Mañana';
    } else {
      // ✅ Formato correcto aquí también
      return DateFormat('d MMM yyyy', 'es').format(eventDate);
    }
  }
}