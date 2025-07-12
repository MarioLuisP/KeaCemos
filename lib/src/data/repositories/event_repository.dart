import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class EventRepository {
  static final EventRepository _instance = EventRepository._internal();
  factory EventRepository() => _instance;
  EventRepository._internal();

  // ========== EVENTOS PRINCIPALES ==========

  /// Obtener todos los eventos ordenados por fecha
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      orderBy: 'date ASC',
    );
  }

  /// Obtener eventos por categoría
  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date ASC',
    );
  }

  /// Buscar eventos por título o descripción
  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date ASC',
    );
  }

  /// Obtener eventos de una fecha específica
  Future<List<Map<String, dynamic>>> getEventsByDate(String date) async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      where: 'DATE(date) = ?',
      whereArgs: [date],
      orderBy: 'date ASC',
    );
  }

  /// Obtener evento por ID
  Future<Map<String, dynamic>?> getEventById(int id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'eventos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Insertar múltiples eventos (para sync desde Firestore)
  Future<void> insertEvents(List<Map<String, dynamic>> events) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();

    for (var event in events) {
      batch.insert(
        'eventos',
        event,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Limpiar eventos vencidos según configuración
  Future<int> cleanOldEvents() async {
    final db = await DatabaseHelper.database;
    
    // Obtener días de configuración
    final cleanupDays = await _getCleanupDays('cleanup_events_days');
    final cutoffDate = DateTime.now().subtract(Duration(days: cleanupDays));
    
    return await db.delete(
      'eventos',
      where: 'DATE(date) < ?',
      whereArgs: [cutoffDate.toIso8601String().split('T')[0]],
    );
  }

  // ========== FAVORITOS ==========

  /// Obtener todos los favoritos
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'favoritos',
      orderBy: 'date ASC',
    );
  }

  /// Verificar si un evento es favorito
  Future<bool> isFavorite(int eventoId) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'favoritos',
      where: 'evento_id = ?',
      whereArgs: [eventoId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Agregar evento a favoritos
  Future<void> addToFavorites(Map<String, dynamic> evento) async {
    final db = await DatabaseHelper.database;
    
    // Crear registro de favorito con todos los datos del evento
    final favorito = Map<String, dynamic>.from(evento);
    favorito['evento_id'] = evento['id'];
    favorito['favorited_at'] = DateTime.now().toIso8601String();
    favorito['original_created_at'] = evento['created_at'];
    favorito.remove('id'); // Remove para que SQLite genere nuevo ID

    await db.insert(
      'favoritos',
      favorito,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remover evento de favoritos
  Future<void> removeFromFavorites(int eventoId) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      'favoritos',
      where: 'evento_id = ?',
      whereArgs: [eventoId],
    );
  }

  /// Toggle favorito (agregar/remover)
  Future<bool> toggleFavorite(Map<String, dynamic> evento) async {
    final eventoId = evento['id'] as int;
    final isFav = await isFavorite(eventoId);
    
    if (isFav) {
      await removeFromFavorites(eventoId);
      return false;
    } else {
      await addToFavorites(evento);
      return true;
    }
  }

  /// Limpiar favoritos vencidos según configuración
  Future<int> cleanOldFavorites() async {
    final db = await DatabaseHelper.database;
    
    // Obtener días de configuración
    final cleanupDays = await _getCleanupDays('cleanup_favorites_days');
    final cutoffDate = DateTime.now().subtract(Duration(days: cleanupDays));
    
    return await db.delete(
      'favoritos',
      where: 'DATE(date) < ?',
      whereArgs: [cutoffDate.toIso8601String().split('T')[0]],
    );
  }

  // ========== CONFIGURACIÓN ==========

  /// Obtener valor de configuración
  Future<String?> getSetting(String key) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return results.isNotEmpty ? results.first['setting_value'] as String : null;
  }

  /// Actualizar configuración
  Future<void> updateSetting(String key, String value) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'app_settings',
      {
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  /// Obtener días de limpieza desde configuración
  Future<int> _getCleanupDays(String settingKey) async {
    final value = await getSetting(settingKey);
    return value != null ? int.parse(value) : (settingKey.contains('events') ? 3 : 7);
  }

  // ========== SYNC INFO ==========

  /// Obtener información de última sincronización
  Future<Map<String, dynamic>?> getSyncInfo() async {
    final db = await DatabaseHelper.database;
    final results = await db.query('sync_info', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Actualizar información de sincronización
  Future<void> updateSyncInfo({
    required String batchVersion,
    required int totalEvents,
  }) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'sync_info',
      {
        'last_sync': DateTime.now().toIso8601String(),
        'batch_version': batchVersion,
        'total_events': totalEvents,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ========== UTILIDADES ==========

  /// Contar total de eventos
  Future<int> getTotalEvents() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM eventos');
    return result.first['count'] as int;
  }

  /// Contar total de favoritos
  Future<int> getTotalFavorites() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM favoritos');
    return result.first['count'] as int;
  }

  /// Limpiar toda la base de datos (solo para debug/reset)
  Future<void> clearAllData() async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    
    batch.delete('eventos');
    batch.delete('favoritos');
    batch.update('sync_info', {
      'last_sync': DateTime.now().toIso8601String(),
      'batch_version': '0.0.0',
      'total_events': 0,
    }, where: 'id = ?', whereArgs: [1]);
    
    await batch.commit(noResult: true);
  }
}