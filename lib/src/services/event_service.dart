import 'package:intl/intl.dart';
import 'package:quehacemos_cba/src/models/models.dart';
import '../data/repositories/event_repository.dart';    // NUEVO: import repository
import 'sync_service.dart';                            // NUEVO: import sync service

class EventService {
  const EventService(); // Para evitar instancias innecesarias
  EventRepository get _repository => EventRepository();   // NUEVO
  SyncService get _syncService => SyncService();         // NUEVO


  // Obtener eventos para una fecha específica
  Future<List<Map<String, dynamic>>> getEventsForDay(DateTime day) async {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    return events
        .where((event) => event['date']?.startsWith(dateString) ?? false)
        .toList()
        .take(1000)
        .toList();
  }

  // Obtener todos los eventos
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      await _syncService.syncOnAppStart();           // 👈 AGREGAR ESTA LÍNEA
      return await _repository.getAllEvents();       // 👈 CAMBIAR ESTA LÍNEA
    } catch (e) {
      print('⚠️ Error obteniendo eventos, usando fallback: $e');
      return events.toList().take(1000).toList();    // 👈 FALLBACK
    }
  }

  // Filtrar por categoría (para Prompt 4 y chips)
  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    final lowerCategory = category.toLowerCase();
    return events
        .where((event) {
          final type = event['type']?.toLowerCase() ?? '';
          return type == lowerCategory;
        })
        .toList()
        .take(1000)
        .toList();
  }

  // Buscar por palabra clave (para 🔍 Explorar)
  Future<List<Map<String, dynamic>>> searchEvents(String keyword) async {
    final lowerKeyword = keyword.toLowerCase();
    return events
        .where((event) {
          final title = event['title']?.toLowerCase() ?? '';
          final location = event['location']?.toLowerCase() ?? '';
          return title.contains(lowerKeyword) ||
              location.contains(lowerKeyword);
        })
        .toList()
        .take(1000)
        .toList();
  }
  // ========== MÉTODOS DE FAVORITOS (NUEVO) ==========

  /// Obtener todos los favoritos                                  // NUEVO: método completo
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      await _syncService.syncOnAppStart();
      return await _repository.getAllFavorites();
    } catch (e) {
      print('⚠️ Error obteniendo favoritos, usando fallback: $e');
      return []; // Sin favoritos en fallback
    }
  }

  /// Verificar si es favorito                                     // NUEVO: método completo
  Future<bool> isFavorite(int eventId) async {
    try {
      return await _repository.isFavorite(eventId);
    } catch (e) {
      print('⚠️ Error verificando favorito: $e');
      return false;
    }
  }

  /// Toggle favorito                                              // NUEVO: método completo
  Future<bool> toggleFavorite(int eventId) async {
    try {
      return await _repository.toggleFavorite(eventId);
    } catch (e) {
      print('⚠️ Error toggle favorito: $e');
      return false;
    }
}

}
