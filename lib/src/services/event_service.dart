import 'package:intl/intl.dart';
import 'package:myapp/src/models/models.dart';

class EventService {
  // Obtener eventos para una fecha específica
  Future<List<Map<String, String>>> getEventsForDay(DateTime day) async {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    return events.where((event) => event['date'] == dateString).toList();
  }

  // Obtener todos los eventos
  Future<List<Map<String, String>>> getAllEvents() async {
    return events.toList();
  }

  // Filtrar por categoría (para Prompt 4 y chips)
  Future<List<Map<String, String>>> getEventsByCategory(String category) async {
    return events
        .where((event) => event['type']!.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Buscar por palabra clave (para 🔍 Explorar)
  Future<List<Map<String, String>>> searchEvents(String keyword) async {
    final lowerKeyword = keyword.toLowerCase();
    return events
        .where((event) =>
            event['title']!.toLowerCase().contains(lowerKeyword) ||
            event['location']!.toLowerCase().contains(lowerKeyword))
        .toList();
  }
}