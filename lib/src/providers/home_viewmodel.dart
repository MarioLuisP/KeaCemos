import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/services/event_service.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'filter_criteria.dart';
import 'category_constants.dart';
import 'event_filter_logic.dart';
import 'event_data_builder.dart';

enum EventsLoadingState { idle, loading, loaded, error }

/// ViewModel refactorizado que usa la nueva arquitectura modular
/// Delega el procesamiento de eventos a EventDataBuilder y EventFilterLogic
class HomeViewModel with ChangeNotifier {
  final EventService _eventService = EventService();
  final EventDataBuilder _dataBuilder;
  final EventFilterLogic _filterLogic = EventFilterLogic();

  // Estado actual
  EventsLoadingState _state = EventsLoadingState.idle;
  List<Map<String, String>> _allEvents = [];
  FilterCriteria _filterCriteria = FilterCriteria.empty;
  String? _errorMessage;

  // Configuración de desarrollo
  final DateTime _devNow = DateTime(2025, 6, 4);

  // Eventos procesados (cache)
  List<Map<String, String>> _processedEvents = [];
  Map<String, List<Map<String, String>>> _groupedEvents = {};

  HomeViewModel() : _dataBuilder = EventDataBuilder(DateTime(2025, 6, 4));


  // ============ GETTERS PÚBLICOS ============
  
  EventsLoadingState get state => _state;
  FilterCriteria get filterCriteria => _filterCriteria;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == EventsLoadingState.loading;
  bool get hasError => _state == EventsLoadingState.error;
  DateTime get currentDate => _devNow;
  
  // Getters de datos procesados
  List<Map<String, String>> get filteredEvents => _processedEvents;
  Map<String, List<Map<String, String>>> get groupedEvents => _groupedEvents;
  
  // Getters derivados de FilterCriteria
  DateTime? get selectedDate => _filterCriteria.selectedDate;
  String get searchQuery => _filterCriteria.query;
  Set<String> get selectedCategories => _filterCriteria.selectedCategories;

  // ============ INICIALIZACIÓN Y CARGA DE DATOS ============

  /// Inicializa el ViewModel con criterios opcionales
  Future<void> initialize({FilterCriteria? initialCriteria}) async {
    if (initialCriteria != null) {
      _filterCriteria = initialCriteria;
    }
    await loadEvents();
  }

  /// Carga eventos desde el servicio y los procesa
  Future<void> loadEvents() async {
    _state = EventsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Map<String, String>> events = await _retryOperation(() async {
        if (_filterCriteria.selectedDate != null) {
          return await _eventService
              .getEventsForDay(_filterCriteria.selectedDate!)
              .timeout(const Duration(seconds: 10));
        } else {
          return await _eventService.getAllEvents().timeout(
            const Duration(seconds: 10),
          );
        }
      });

      _allEvents = events;
      _state = EventsLoadingState.loaded;
      _processEvents();
    } catch (e) {
      _handleLoadError(e);
    }
  }
// ============ MÉTODOS DE FAVORITOS ============

  /// Toggle favorito de un evento
  void toggleFavorite(String eventId, FavoritesProvider favoritesProvider) {
    favoritesProvider.toggleFavorite(eventId);
    print('🤍 Toggle favorito: $eventId');
  }
  /// Procesa eventos usando la nueva arquitectura
/// Procesa eventos usando la nueva arquitectura
void _processEvents() {
  print('⚙️ Procesando eventos con filtros: ${_filterCriteria.toString()}');
  
  if (_allEvents.isEmpty) {
    print('📭 No hay eventos para procesar');
    _processedEvents = [];
    _groupedEvents = {};
  } else {
    // Usar EventDataBuilder para procesamiento completo
    _groupedEvents = _dataBuilder.processEventsComplete(_allEvents, _filterCriteria);
    
    // Para compatibilidad, generar lista plana para HomePage
    _processedEvents = _dataBuilder.processEventsForHomePage(_allEvents, _filterCriteria);
    
    print('✅ Procesados: ${_processedEvents.length} eventos, ${_groupedEvents.keys.length} fechas');
  }
  
  // ASEGURAR que siempre notifique
  notifyListeners();
}
  // ============ MÉTODOS DE FILTRADO ============

/// Actualiza criterios de filtrado y reprocesa eventos
void updateFilterCriteria(FilterCriteria newCriteria) {
  print('🔄 Actualizando filtros: ${newCriteria.toString()}');
  
  // SIEMPRE actualizar, sin comparación problemática
  _filterCriteria = newCriteria;
  _processEvents();
  print('✅ Filtros actualizados. Eventos filtrados: ${_processedEvents.length}');
}

/// Actualiza solo la búsqueda
void setSearchQuery(String query) {
  print('🔍 Actualizando búsqueda: "$query"');
  final newCriteria = _filterCriteria.copyWith(query: query);
  updateFilterCriteria(newCriteria);
}

/// Actualiza solo las categorías seleccionadas
void setSelectedCategories(Set<String> categories) {
  print('🏷️ Actualizando categorías: $categories');
  final newCriteria = _filterCriteria.copyWith(selectedCategories: categories);
  updateFilterCriteria(newCriteria);
}

/// Método específico para toggle de categoría (más robusto)
void toggleCategory(String category) {
  print('🔄 Toggle categoría: $category');
  
  final currentCategories = Set<String>.from(_filterCriteria.selectedCategories);
  
  if (currentCategories.contains(category)) {
    currentCategories.remove(category);
    print('➖ Removiendo categoría: $category');
  } else {
    currentCategories.add(category);
    print('➕ Agregando categoría: $category');
  }
  
  setSelectedCategories(currentCategories);
}

/// Método específico para seleccionar solo una categoría
void selectSingleCategory(String category) {
  print('🎯 Seleccionando solo categoría: $category');
  setSelectedCategories({category});
}

/// Limpia todos los filtros
void clearAllFilters() {
  print('🧹 Limpiando todos los filtros');
  updateFilterCriteria(FilterCriteria.empty);
}

/// Limpia solo la búsqueda
void clearSearch() {
  print('🧹 Limpiando búsqueda');
  setSearchQuery('');
}

/// Actualiza solo la fecha seleccionada
Future<void> setSelectedDate(DateTime? date) async {
  print('📅 Actualizando fecha: $date');
  
  final newCriteria = _filterCriteria.copyWith(
    selectedDate: date,
    clearDate: date == null,
  );
  
  // SIEMPRE actualizar y recargar para fechas
  _filterCriteria = newCriteria;
  await loadEvents(); // Recargar eventos si cambia la fecha
}

/// Limpia solo la fecha seleccionada
Future<void> clearSelectedDate() async {
  print('🧹 Limpiando fecha seleccionada');
  await setSelectedDate(null);
}

  // ============ COMPATIBILIDAD CON CÓDIGO EXISTENTE ============

  /// Aplica filtros de categorías (para PreferencesProvider)
  void applyCategoryFilters(Set<String> activeCategories) {
    setSelectedCategories(activeCategories);
  }

 

  /// Obtiene fechas ordenadas con prioridad para hoy/mañana
  List<String> getSortedDates() {
    return _dataBuilder.getSortedDates(_groupedEvents);
  }

  
  // ============ MÉTODOS ESPECÍFICOS PARA CALENDARIO ============

/// Obtiene TODOS los eventos para calendario (sin límites)
List<Map<String, String>> getCalendarEvents() {
  return _dataBuilder.processEventsForCalendar(_allEvents, _filterCriteria);
}

/// Obtiene eventos agrupados para calendario (sin límites)
Map<String, List<Map<String, String>>> getCalendarGroupedEvents() {
  return _dataBuilder.processEventsCompleteForCalendar(_allEvents, _filterCriteria);
}

/// Obtiene eventos de un mes específico para calendario
  Future<List<Map<String, String>>> getEventsForMonth(DateTime month) async {
    try {
      print('📅 Cargando eventos para: ${month.month}/${month.year}');
      
      // 1. Obtener eventos del servicio
      final allEvents = await _eventService.getAllEvents()
          .timeout(const Duration(seconds: 10));
      
      print('📊 Eventos totales: ${allEvents.length}');
      
      
      // 3. Usar EventDataBuilder para filtrar eficientemente
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      // Crear criterio específico para el mes
      final monthCriteria = _filterCriteria.copyWith(
        selectedDate: null, // No filtrar por día específico
      );
      
      // 4. Procesar Y filtrar en una sola pasada
      final filteredEvents = allEvents.where((event) {
        try {
          // Parsear fecha del evento
          final eventDateStr = event['date'] ?? '';
          final eventDate = DateFormat('yyyy-MM-dd').tryParse(eventDateStr) ??
              DateFormat('yyyy-MM-ddTHH:mm').tryParse(eventDateStr);
          
          if (eventDate == null) return false;
          
          // Verificar si está en el mes correcto
          return eventDate.year == month.year && eventDate.month == month.month;
        } catch (e) {
          print('⚠️ Error parseando fecha: ${event['date']} - $e');
          return false;
        }
      }).toList();
      
      // 5. Aplicar filtros adicionales (búsqueda, categorías) usando la arquitectura existente
      final finalEvents = _dataBuilder.processEventsForCalendar(filteredEvents, monthCriteria);
      
      print('✅ Eventos del mes procesados: ${finalEvents.length}');
      return finalEvents;
      
    } catch (e) {
      print('❌ Error cargando eventos del mes: $e');
      return [];
    }
  }

/// Obtiene eventos de un día específico para calendario
  List<Map<String, String>> getEventsForDay(DateTime day) {
    final dayString = DateFormat('yyyy-MM-dd').format(day);
    
    // Usar los eventos ya cacheados si es el mes actual
    return _allEvents.where((event) {
      final eventDate = event['date'] ?? '';
      return eventDate.startsWith(dayString);
    }).toList();
  }

// ============ COMPATIBILIDAD - MÉTODOS EXISTENTES PARA HOMEPAGE ============

/// Obtiene eventos limitados para HomePage (mantiene límite de 30)
List<Map<String, String>> getHomePageEvents() {
  return _processedEvents; // Ya tiene límite aplicado
}

/// Obtiene eventos agrupados por fecha (mantiene límite)
Map<String, List<Map<String, String>>> getGroupedEvents() {
  return _groupedEvents; // Ya tiene límite aplicado
}

  // ============ MÉTODOS DE PRESENTACIÓN (DELEGADOS) ============

  /// Obtiene título de sección para una fecha
  String getSectionTitle(String date) {
    return _dataBuilder.getSectionTitle(date);
  }
/// Obtiene nombre de categoría con emoji delegando a EventDataBuilder
  String getCategoryWithEmoji(String type) {
    return _dataBuilder.getCategoryWithEmoji(type);
  }
  /// Obtiene título principal de la página
  String getPageTitle() {
    return _dataBuilder.getPageTitleFromCriteria(_filterCriteria);
  }

  /// Obtiene color de card según tipo de evento
  Color getEventCardColor(String eventType, BuildContext context) {
    return _dataBuilder.getEventCardColor(eventType, context);
  }

  /// Formatea fecha para mostrar en eventos
  String formatEventDate(String dateString, {String format = 'full'}) {
    return _dataBuilder.formatEventDate(dateString, format: format);
}
  // ============ ANÁLISIS Y ESTADÍSTICAS ============

  /// Obtiene estadísticas de los eventos actuales
  Map<String, dynamic> getEventStatistics() {
    return _dataBuilder.getEventStatistics(_processedEvents);
  }

  /// Verifica si hay filtros activos
  bool get hasActiveFilters => _filterCriteria.hasActiveFilters;

  /// Verifica si solo hay búsqueda activa
  bool get hasOnlySearch => _filterCriteria.hasOnlySearch;

  /// Obtiene resumen de filtros activos para UI
  String getActiveFiltersDescription() {
    if (_filterCriteria.isEmpty) return 'Sin filtros';
    
    final parts = <String>[];
    
    if (_filterCriteria.query.isNotEmpty) {
      parts.add('Búsqueda: "${_filterCriteria.query}"');
    }
    
    if (_filterCriteria.selectedCategories.isNotEmpty) {
      parts.add('${_filterCriteria.selectedCategories.length} categorías');
    }
    
    if (_filterCriteria.selectedDate != null) {
      parts.add('Fecha específica');
    }
    
    return parts.join(', ');
  }

  // ============ OPERACIONES DE REFRESH ============

  /// Refresh/reload completo
  Future<void> refresh() async {
    await loadEvents();
  }

  /// Recarga manteniendo filtros actuales
  Future<void> reloadWithCurrentFilters() async {
    final currentCriteria = _filterCriteria;
    await loadEvents();
    // Los filtros se mantienen automáticamente
  }

  // ============ MÉTODOS PRIVADOS ============

  /// Manejo de errores de carga
  void _handleLoadError(Object error) {
    if (error is SocketException) {
      _state = EventsLoadingState.error;
      _errorMessage = 'No hay conexión a internet.';
    } else if (error is TimeoutException) {
      _state = EventsLoadingState.error;
      _errorMessage = 'La carga de eventos tomó demasiado tiempo.';
    } else {
      _state = EventsLoadingState.error;
      _errorMessage = 'Ocurrió un error inesperado: $error';
    }

    _processedEvents = [];
    _groupedEvents = {};
    notifyListeners();
  }

  /// Reintento con delay exponencial
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    var delay = const Duration(seconds: 1);
    
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2); // Backoff exponencial
      }
    }
    
    throw Exception("No se pudo completar la operación");
  }

  // ============ MÉTODOS DE DEPURACIÓN ============

  /// Debug: información del estado actual
  Map<String, dynamic> getDebugInfo() {
    return {
      'state': _state.toString(),
      'totalEvents': _allEvents.length,
      'filteredEvents': _processedEvents.length,
      'groupedDates': _groupedEvents.keys.length,
      'filterCriteria': _filterCriteria.toString(),
      'hasError': hasError,
      'errorMessage': _errorMessage,
    };
  }

  @override
  void dispose() {
    // Cleanup si es necesario
    super.dispose();
  }
}