import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/utils/colors.dart';
import 'package:quehacemos_cba/src/services/event_service.dart';
import 'package:quehacemos_cba/src/services/sync_service.dart';
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
  StreamSubscription<SyncResult>? _syncListener;

  // Estado actual
  EventsLoadingState _state = EventsLoadingState.idle;
  List<Map<String, dynamic>> _allEvents = [];
  FilterCriteria _filterCriteria = FilterCriteria.empty;
  String? _errorMessage;

  // Configuración de desarrollo
  final DateTime _devNow = DateTime.now(); // CAMBIO: Fecha real

  // Eventos procesados (cache)
  List<Map<String, dynamic>> _processedEvents = [];
  Map<String, List<Map<String, dynamic>>> _groupedEvents = {};
  int? _lastCriteriaHash;
  // NUEVO: Cache de datos convertidos a DateTime para optimización
  Map<DateTime, List<Map<String, dynamic>>> _groupedEventsDateTime = {}; 
  List<DateTime> _sortedDatesDateTime = []; // NUEVO: Cache DateTime
  bool _dateTimeCacheValid = false; // NUEVO: Flag para invalidar cache

  // NUEVO: Cache para flatItems (estructura plana optimizada para HomePage)
  List<Map<String, dynamic>> _flatItemsCache = []; // NUEVO: Cache flatItems
  bool _flatItemsCacheValid = false; // NUEVO: Flag para invalidar cache flatItems

  HomeViewModel() : _dataBuilder = EventDataBuilder(DateTime.now());
// Variables para control de refresh
  DateTime? _lastRefreshTime;
  static const Duration _refreshInterval = Duration(minutes: 5);

  // ============ GETTERS PÚBLICOS ============
  
  EventsLoadingState get state => _state;
  FilterCriteria get filterCriteria => _filterCriteria;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == EventsLoadingState.loading;
  bool get hasError => _state == EventsLoadingState.error;
  DateTime get currentDate => _devNow;
  
  // Getters de datos procesados
  List<Map<String, dynamic>> get filteredEvents => _processedEvents;
  Map<String, List<Map<String, dynamic>>> get groupedEvents => _groupedEvents;
  
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
    _listenToSyncUpdates();
    await loadEvents();
  }

  /// Carga eventos desde el servicio y los procesa
  Future<void> loadEvents() async {
    _state = EventsLoadingState.loading;
    _errorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

    try {
      final List<Map<String, dynamic>> events = await _retryOperation(() async {
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
  Future<void> toggleFavorite(dynamic eventId, FavoritesProvider favoritesProvider) async {
    await favoritesProvider.toggleFavorite(eventId.toString());
    print('🤍 Toggle favorito completado: $eventId');
    
    // NUEVO: Opcional - actualizar UI inmediatamente si es necesario
    notifyListeners();
  }
/// Procesa eventos usando la nueva arquitectura
void _processEvents() {
  print('⚙️ Procesando eventos con filtros: ${_filterCriteria.toString()}');
  
  // NUEVO: Hash de criterios para detectar cambios reales
  final criteriaHash = _filterCriteria.hashCode;
  
  // NUEVO: Si criterios no cambiaron, no procesar nada
  if (_lastCriteriaHash == criteriaHash && _processedEvents.isNotEmpty) {
    print('⏭️ Criterios idénticos, usando resultados cacheados');
    return; // NUEVO: Salir sin hacer nada
  }
  
  // NUEVO: Solo procesar si realmente cambió algo
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
  
  // NUEVO: Actualizar hash y cache
  _lastCriteriaHash = criteriaHash; // NUEVO: Guardar hash actual
  _dateTimeCacheValid = false;
  _flatItemsCacheValid = false;
  
  print('🔄 Datos procesados, invalidando cache y notificando'); // NUEVO: Debug
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
Future<void> refreshIfNeeded() async {
  final now = DateTime.now();
  
  if (_lastRefreshTime == null || 
      now.difference(_lastRefreshTime!) > _refreshInterval) {
    print('🔄 Refresh automático por tiempo transcurrido');
    await refresh();
    _lastRefreshTime = now;
  } else {
    print('⏰ Refresh no necesario, último hace ${now.difference(_lastRefreshTime!).inMinutes} min');
  }
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
/// NUEVO: Obtiene eventos agrupados como DateTime (optimizado para HomePage)
Map<DateTime, List<Map<String, dynamic>>> getGroupedEventsDateTime() {
  if (!_dateTimeCacheValid) { // NUEVO: Solo convierte si el cache no es válido
    _updateDateTimeCache();
  }
  return _groupedEventsDateTime;
}

/// NUEVO: Obtiene fechas ordenadas como DateTime (optimizado para HomePage)
List<DateTime> getSortedDatesDateTime() {
  if (!_dateTimeCacheValid) { // NUEVO: Solo convierte si el cache no es válido
    _updateDateTimeCache();
  }
  return _sortedDatesDateTime;
}
/// NUEVO: Obtiene estructura plana optimizada para HomePage (cacheada)
List<Map<String, dynamic>> getFlatItemsForHomePage() {
  if (!_flatItemsCacheValid) { // NUEVO: Solo recalcula si cache inválido
    _updateFlatItemsCache(); // NUEVO: Actualizar cache
  }
  return _flatItemsCache; // NUEVO: Retornar cache
}

/// NUEVO: Actualiza cache de flatItems (se ejecuta UNA sola vez)
void _updateFlatItemsCache() {
  print('🔄 Actualizando cache flatItems...'); // NUEVO: Debug
  
  _flatItemsCache = []; // NUEVO: Limpiar cache
  
  // NUEVO: Obtener datos ya optimizados (desde cache DateTime)
  final groupedEvents = getGroupedEventsDateTime(); // NUEVO: Usar cache existente
  final sortedDates = getSortedDatesDateTime(); // NUEVO: Usar cache existente
  
  // NUEVO: Pre-calcular estructura completa UNA sola vez
  for (final date in sortedDates) { // NUEVO: Loop de construcción
    final eventsOnDate = groupedEvents[date]!; // NUEVO: Eventos de la fecha
    final dateString = DateFormat('yyyy-MM-dd').format(date); // NUEVO: Format UNA vez
    final sectionTitle = getSectionTitle(dateString); // NUEVO: Título UNA vez
    
    // NUEVO: Agregar header con título pre-calculado
    _flatItemsCache.add({
      'type': 'header',
      'title': sectionTitle,
    });
    
    // NUEVO: Agregar eventos como metadata
    for (final event in eventsOnDate) { // NUEVO: Loop eventos
      _flatItemsCache.add({
        'type': 'event',
        'data': event,
      });
    }
  }
  
  _flatItemsCacheValid = true; // NUEVO: Marcar cache como válido
  print('✅ Cache flatItems actualizado: ${_flatItemsCache.length} items'); // NUEVO: Debug
}
/// NUEVO: Actualiza cache de DateTime (conversión una sola vez)
void _updateDateTimeCache() {
  print('🔄 Actualizando cache DateTime...');
  
  // NUEVO: Convertir Map<String, List> → Map<DateTime, List>
  _groupedEventsDateTime = {};
  for (final entry in _groupedEvents.entries) {
    final dateString = entry.key;
    DateTime? dateTime;
    
    try {
      // NUEVO: Misma lógica de parsing que HomePage pero UNA sola vez
      dateTime = DateTime.tryParse(dateString) ?? 
                DateFormat('yyyy-MM-dd').tryParse(dateString) ??
                DateFormat('dd/MM/yyyy').tryParse(dateString);
    } catch (e) {
      print('⚠️ Error parseando fecha en cache: $dateString - $e');
    }
    
    if (dateTime != null) {
      _groupedEventsDateTime[dateTime] = entry.value;
    } else {
      print('⚠️ Usando fecha actual para cache: $dateString');
      _groupedEventsDateTime[DateTime.now()] = entry.value;
    }
  }
  
  // NUEVO: Convertir List<String> → List<DateTime>
  _sortedDatesDateTime = [];
  final rawDates = _dataBuilder.getSortedDates(_groupedEvents);
  
  for (final dateString in rawDates) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.tryParse(dateString) ?? 
                DateFormat('yyyy-MM-dd').tryParse(dateString) ??
                DateFormat('dd/MM/yyyy').tryParse(dateString);
    } catch (e) {
      print('⚠️ Error parseando fecha en sorted cache: $dateString - $e');
    }
    
    if (dateTime != null) {
      _sortedDatesDateTime.add(dateTime);
    }
  }
  
  _sortedDatesDateTime.sort(); // NUEVO: Ordenar fechas
  _dateTimeCacheValid = true; // NUEVO: Marcar cache como válido
  
  print('✅ Cache DateTime actualizado: ${_groupedEventsDateTime.keys.length} fechas');
}
  
  // ============ MÉTODOS ESPECÍFICOS PARA CALENDARIO ============

/// Obtiene TODOS los eventos para calendario (sin límites)
List<Map<String, dynamic>> getCalendarEvents() {
  return _dataBuilder.processEventsForCalendar(_allEvents, _filterCriteria);
}
/// Obtiene TODOS los eventos sin filtros para favoritos
List<Map<String, dynamic>> get allEvents => _allEvents;

/// Obtiene eventos agrupados para calendario (sin límites)
Map<String, List<Map<String, dynamic>>> getCalendarGroupedEvents() {
  return _dataBuilder.processEventsCompleteForCalendar(_allEvents, _filterCriteria);
}

/// Obtiene eventos de un mes específico para calendario
  Future<List<Map<String, dynamic>>> getEventsForMonth(DateTime month) async {
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
  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    final dayString = DateFormat('yyyy-MM-dd').format(day);
    
    // Usar los eventos ya cacheados si es el mes actual
    return _allEvents.where((event) {
      final eventDate = event['date'] ?? '';
      return eventDate.startsWith(dayString);
    }).toList();
  }

// ============ COMPATIBILIDAD - MÉTODOS EXISTENTES PARA HOMEPAGE ============

/// Obtiene eventos limitados para HomePage (mantiene límite de 30)
List<Map<String, dynamic>> getHomePageEvents() {
  return _processedEvents; // Ya tiene límite aplicado
}

/// Obtiene eventos agrupados por fecha (mantiene límite)
Map<String, List<Map<String, dynamic>>> getGroupedEvents() {
  return _groupedEvents; // Ya tiene límite aplicado
}

  // ============ MÉTODOS DE PRESENTACIÓN (DELEGADOS) ============

  /// Obtiene título de sección para una fecha
  String getSectionTitle(String date) {
    return _dataBuilder.getSectionTitle(date);
  }
/// Obtiene nombre de categoría con emoji delegando a EventDataBuilder
  String getCategoryWithEmoji(String type) {
    return CategoryDisplayNames.getCategoryWithEmoji(type);
  }
  /// Obtiene título principal de la página
  String getPageTitle() {
    return _dataBuilder.getPageTitleFromCriteria(_filterCriteria);
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
  void _listenToSyncUpdates() {
  _syncListener = SyncService.onSyncComplete.listen((syncResult) {
    if (syncResult.success && syncResult.eventsAdded > 0) {
      print('🔄 HomeViewModel: Nuevos eventos detectados (${syncResult.eventsAdded}), recargando...');
      loadEvents(); // Recargar eventos desde SQLite actualizada
    }
  });
}
}