import 'package:flutter/foundation.dart';

class FavoritesProvider with ChangeNotifier {
  Set<String> _favoriteIds = {};
  
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  
  bool isFavorite(String eventId) => _favoriteIds.contains(eventId);
  
  void toggleFavorite(String eventId) {
    if (_favoriteIds.contains(eventId)) {
      _favoriteIds.remove(eventId);
    } else {
      _favoriteIds.add(eventId);
    }
    notifyListeners();
  }
  
  void addFavorite(String eventId) {
    if (!_favoriteIds.contains(eventId)) {
      _favoriteIds.add(eventId);
      notifyListeners();
    }
  }
  
  void removeFavorite(String eventId) {
    if (_favoriteIds.remove(eventId)) {
      notifyListeners();
    }
  }
  
  void clearFavorites() {
    _favoriteIds.clear();
    notifyListeners();
  }
  
  List<Map<String, String>> filterFavoriteEvents(List<Map<String, String>> allEvents) {
    return allEvents.where((event) => isFavorite(event['id'] ?? '')).toList();
  }
}