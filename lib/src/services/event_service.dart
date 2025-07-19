import 'package:intl/intl.dart';
import 'package:quehacemos_cba/src/models/models.dart';
import '../data/repositories/event_repository.dart';
import 'sync_service.dart';

class EventService {
  const EventService();
  EventRepository get _repository => EventRepository();
  SyncService get _syncService => SyncService();

  // ✅ MIGRADO: Obtener eventos para una fecha específica
  Future<List<Map<String, dynamic>>> getEventsForDay(DateTime day) async {
    try {
      //await _syncService.syncOnAppStart();
      final dateString = DateFormat('yyyy-MM-dd').format(day);
      return await _repository.getEventsByDate(dateString);
    } catch (e) {
      print('⚠️ Error obteniendo eventos del día, usando fallback: $e');
      final dateString = DateFormat('yyyy-MM-dd').format(day);
      return events
          .where((event) => event['date']?.startsWith(dateString) ?? false)
          .toList()
          .take(1000)
          .toList();
    }
  }

  // ✅ YA MIGRADO: Obtener todos los eventos
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      //await _syncService.syncOnAppStart();
      return await _repository.getAllEvents();
    } catch (e) {
      print('⚠️ Error obteniendo eventos, usando fallback: $e');
      return events.toList().take(1000).toList();
    }
  }

  // ✅ MIGRADO: Filtrar por categoría
  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    try {
      //await _syncService.syncOnAppStart();
      return await _repository.getEventsByCategory(category);
    } catch (e) {
      print('⚠️ Error obteniendo eventos por categoría, usando fallback: $e');
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
  }

  // ✅ MIGRADO: Buscar por palabra clave
  Future<List<Map<String, dynamic>>> searchEvents(String keyword) async {
    try {
      //await _syncService.syncOnAppStart();
      return await _repository.searchEvents(keyword);
    } catch (e) {
      print('⚠️ Error buscando eventos, usando fallback: $e');
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
  }

  // ✅ YA MIGRADO: Métodos de favoritos
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      //await _syncService.syncOnAppStart();
      return await _repository.getAllFavorites();
    } catch (e) {
      print('⚠️ Error obteniendo favoritos, usando fallback: $e');
      return [];
    }
  }

  Future<bool> isFavorite(int eventId) async {
    try {
      return await _repository.isFavorite(eventId);
    } catch (e) {
      print('⚠️ Error verificando favorito: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(int eventId) async {
    try {
      return await _repository.toggleFavorite(eventId);
    } catch (e) {
      print('⚠️ Error toggle favorito: $e');
      return false;
    }
  }
}