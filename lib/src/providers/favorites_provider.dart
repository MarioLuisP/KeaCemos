import 'package:flutter/foundation.dart';
import '../data/repositories/event_repository.dart'; // NUEVO: import repository
import '../providers/notifications_provider.dart';

class FavoritesProvider with ChangeNotifier {
  final EventRepository _repository = EventRepository(); // NUEVO: instancia repository
  Set<String> _favoriteIds = {};                        // CAMBIO: cache local
  bool _isInitialized = false;

  FavoritesProvider() {
    _initializeAsync();
  }

  bool get isInitialized => _isInitialized;

  void _initializeAsync() {                             // CAMBIO: sin migración
    init();
  }

  Future<void> init() async {                           // CAMBIO: cargar desde SQLite
    await _loadFavoritesFromSQLite();                   // NUEVO: método SQLite
    _isInitialized = true;
    notifyListeners();
  }

  /// NUEVO: Cargar favoritos desde SQLite
  Future<void> _loadFavoritesFromSQLite() async {
    try {
      final favorites = await _repository.getAllFavorites();
      _favoriteIds = favorites.map((e) => e['id'].toString()).toSet();
      print('📋 Cargados ${_favoriteIds.length} favoritos desde SQLite');
    } catch (e) {
      print('❌ Error cargando favoritos: $e');
      _favoriteIds = {};
    }
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String eventId) => _favoriteIds.contains(eventId);

  Future<void> toggleFavorite(String eventId) async {  // CAMBIO: usar SQLite
    try {
      final numericId = int.parse(eventId);
      final wasAdded = await _repository.toggleFavorite(numericId);
      
      if (wasAdded) {
        _favoriteIds.add(eventId);
        print('❤️ Favorito agregado: $eventId');
        
        // NUEVO: Notificación de favorito agregado
        await _sendFavoriteNotification(eventId, true);
        
      } else {
        _favoriteIds.remove(eventId);
        print('💔 Favorito removido: $eventId');
      }
      
      notifyListeners();



    } catch (e) {
      print('❌ Error toggle favorito $eventId: $e');
    }
  }

  Future<void> addFavorite(String eventId) async {     // CAMBIO: usar toggleFavorite
    if (!_favoriteIds.contains(eventId)) {
      await toggleFavorite(eventId);
    }
  }

  Future<void> removeFavorite(String eventId) async {  // CAMBIO: usar toggleFavorite
    if (_favoriteIds.contains(eventId)) {
      await toggleFavorite(eventId);
    }
  }

  Future<void> clearFavorites() async {                // CAMBIO: limpiar SQLite
    try {
      // NUEVO: limpiar todos los favoritos en SQLite
      for (final eventId in _favoriteIds.toList()) {
        await _repository.removeFromFavorites(int.parse(eventId));
      }
      
      _favoriteIds.clear();
      notifyListeners();
      print('🧹 Todos los favoritos eliminados');
    } catch (e) {
      print('❌ Error limpiando favoritos: $e');
    }
  }
  // ========== NOTIFICACIONES DE FAVORITOS ========== // NUEVO

  /// NUEVO: Enviar notificaciones relacionadas con favoritos
  Future<void> _sendFavoriteNotification(String eventId, bool isAdded) async {
    try {
      final notificationsProvider = NotificationsProvider();
      
      if (isAdded) {
        // NUEVO: Obtener detalles del evento para notificación personalizada
        final eventDetails = await _getEventDetails(eventId);
        
        if (eventDetails != null) {
          notificationsProvider.addNotification(
            title: '❤️ Evento guardado en favoritos',
            message: '${eventDetails['title']} - ${eventDetails['date']}',
            type: 'favorite_added',
            icon: '⭐',
          );
        }
      }
      
    } catch (e) {
      print('⚠️ Error enviando notificación de favorito: $e');
    }
  }

  /// NUEVO: Obtener detalles de un evento específico
  Future<Map<String, dynamic>?> _getEventDetails(String eventId) async {
    try {
      final numericId = int.parse(eventId);
      return await _repository.getEventById(numericId);
    } catch (e) {
      print('⚠️ Error obteniendo detalles del evento $eventId: $e');
      return null;
    }
  }
  List<Map<String, dynamic>> filterFavoriteEvents(List<Map<String, dynamic>> allEvents) { // MANTENER: sin cambios
    return allEvents.where((event) => isFavorite(event['id']?.toString() ?? '')).toList();
  }
}