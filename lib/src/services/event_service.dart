import 'package:intl/intl.dart';
import 'package:quehacemos_cba/src/models/models.dart';

class EventService {
  const EventService(); // Para evitar instancias innecesarias

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
    return events.toList().take(1000).toList();
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
}
