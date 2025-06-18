import 'package:flutter/foundation.dart';
import 'package:quehacemos_cba/src/models/user_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  Set<String> _favoriteIds = {};

  FavoritesProvider() {
    init();
  }

  Future<void> init() async {
    _favoriteIds = await UserPreferences.getFavoriteIds();
    notifyListeners();
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String eventId) => _favoriteIds.contains(eventId);

  Future<void> toggleFavorite(String eventId) async {
    if (_favoriteIds.contains(eventId)) {
      _favoriteIds.remove(eventId);
    } else {
      _favoriteIds.add(eventId);
    }
    await UserPreferences.setFavoriteIds(_favoriteIds);
    notifyListeners();
  }

  Future<void> addFavorite(String eventId) async {
    if (!_favoriteIds.contains(eventId)) {
      _favoriteIds.add(eventId);
      await UserPreferences.setFavoriteIds(_favoriteIds);
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String eventId) async {
    if (_favoriteIds.remove(eventId)) {
      await UserPreferences.setFavoriteIds(_favoriteIds);
      notifyListeners();
    }
  }

  Future<void> clearFavorites() async {
    _favoriteIds.clear();
    await UserPreferences.setFavoriteIds(_favoriteIds);
    notifyListeners();
  }

  List<Map<String, String>> filterFavoriteEvents(List<Map<String, String>> allEvents) {
    return allEvents.where((event) => isFavorite(event['id'] ?? '')).toList();
  }
}