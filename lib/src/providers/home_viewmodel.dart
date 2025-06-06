import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/services/event_service.dart';

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
  final DateTime _devNow = DateTime(2025, 6, 4); // Para mantener fecha fija en desarrollo
  
  // Mapeo de categorías centralizado
  static const Map<String, String> _categoryMapping = {
    'Música': 'música',
    'Teatro': 'teatro',
    'StandUp': 'stand-up',
    'Arte': 'exposición',
    'Cine': 'cine',
    'Mic': 'mic',
    'Cursos': 'talleres',
    'Ferias': 'ferias',
    'Calle': 'calle',
    'Redes': 'comunidad',
  };

  // Getters
  EventsLoadingState get state => _state;
  List<Map<String, String>> get filteredEvents => _filteredEvents;
  DateTime? get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == EventsLoadingState.loading;
  bool get hasError => _state == EventsLoadingState.error;
  DateTime get currentDate => _devNow; // En producción será DateTime.now()

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
      if (_selectedDate != null) {
        _allEvents = await _eventService.getEventsForDay(_selectedDate!);
      } else {
        _allEvents = await _eventService.getAllEvents();
      }
      
      // TODO: Cuando migremos a la nueva estructura de datos:
      // _allEvents = await _eventService.getEventsSummary(); // Solo datos resumen
      // O si hay fecha específica:
      // _allEvents = await _eventService.getEventsSummaryForDay(_selectedDate!);
      
      _state = EventsLoadingState.loaded;
      _applyFilters();
    } catch (error) {
      _state = EventsLoadingState.error;
      _errorMessage = error.toString();
      _filteredEvents = [];
      notifyListeners();
    }
  }

  // Aplicar filtros (categorías + búsqueda)
  void _applyFilters() {
    _filteredEvents = List.from(_allEvents);

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredEvents = _filteredEvents.where((event) =>
          event['title']!.toLowerCase().contains(lowerQuery) ||
          event['location']!.toLowerCase().contains(lowerQuery)).toList();
    }

    notifyListeners();
  }

  // Aplicar filtros de categorías desde PreferencesProvider
  void applyCategoryFilters(Set<String> activeCategories) {
    if (activeCategories.isEmpty) {
      _filteredEvents = List.from(_allEvents);
    } else {
      _filteredEvents = _allEvents.where((event) {
        final eventType = event['type']?.toLowerCase() ?? '';
        final normalizedCategories = activeCategories
            .map((c) => _categoryMapping[c] ?? c.toLowerCase());
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
    final Map<String, List<Map<String, String>>> groupedEvents = {};
    
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
        final dateA = DateFormat('yyyy-MM-dd').parse(a);
        final dateB = DateFormat('yyyy-MM-dd').parse(b);
        if (a == todayString) return -2;
        if (b == todayString) return 2;
        if (a == tomorrowString) return -1;
        if (b == tomorrowString) return 1;
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
        .where((event) => event['date'] == todayString)
        .toList();
    final tomorrowEvents = _filteredEvents
        .where((event) => event['date'] == tomorrowString)
        .toList();
    final futureEvents = _filteredEvents.where((event) {
      final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
      return eventDate.isAfter(_devNow.add(const Duration(days: 1)));
    }).toList();

    return [
      ...todayEvents,
      ...tomorrowEvents,
      ...futureEvents,
    ].take(20).toList();
  }

  // Obtener título de sección para una fecha
  String getSectionTitle(String date) {
    final todayString = DateFormat('yyyy-MM-dd').format(_devNow);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(_devNow.add(const Duration(days: 1)));
    
    if (date == todayString) {
      return 'Hoy';
    } else if (date == tomorrowString) {
      return 'Mañana';
    } else {
      final dateParsed = DateFormat('yyyy-MM-dd').parse(date);
      return 'Próximos (${DateFormat('EEEE, d MMM', 'es').format(dateParsed)})';
    }
  }

  // Obtener título principal de la página
  String getPageTitle() {
    if (_selectedDate == null) {
      return 'Próximos Eventos';
    } else {
      return 'Eventos para ${DateFormat('EEEE, d MMM', 'es').format(_selectedDate!)}';
    }
  }

  // Refresh/reload
  Future<void> refresh() async {
    await loadEvents();
  }

  // Obtener color de card según tipo de evento
  Color getEventCardColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'teatro':
        return const Color(0xFFB2DFDB);
      case 'stand-up':
        return const Color(0xFFFFF9C4);
      case 'música':
        return const Color(0xFFCCE5FF);
      case 'cine':
        return const Color(0xFFE0E0E0);
      case 'infantil':
        return const Color(0xFFE1BEE7);
      case 'exposición':
        return const Color(0xFFFFECB3);
      case 'mic':
        return const Color(0xFFE0E0E0);
      case 'ferias':
        return const Color(0xFFE0E0E0);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  // Formatear fecha para mostrar
  String formatEventDate(String dateString) {
    final eventDate = DateFormat('yyyy-MM-dd').parse(dateString);
    final todayString = DateFormat('yyyy-MM-dd').format(_devNow);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(_devNow.add(const Duration(days: 1)));
    
    if (dateString == todayString) {
      return 'Hoy';
    } else if (dateString == tomorrowString) {
      return 'Mañana';
    } else {
      return DateFormat('d MMM yyyy', 'es').format(eventDate);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}