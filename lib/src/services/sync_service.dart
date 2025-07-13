import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/event_repository.dart';
import '../data/database/database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final EventRepository _eventRepository = EventRepository();
  static const Duration _syncInterval = Duration(hours: 24);
  static const String _lastSyncKey = 'last_sync_timestamp';

  // ========== SYNC PRINCIPAL ==========

  /// Verificar si necesita sincronización
  Future<bool> shouldSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    
    if (lastSyncString == null) return true;
    
    final lastSync = DateTime.parse(lastSyncString);
    final timeSinceLastSync = DateTime.now().difference(lastSync);
    
    return timeSinceLastSync >= _syncInterval;
  }

  /// Sincronización automática completa
  Future<SyncResult> performAutoSync() async {
    try {
      print('🔄 Iniciando sincronización automática...');
      
      // 1. Verificar si es necesario sincronizar
      if (!await shouldSync()) {
        print('⏭️ Sincronización no necesaria aún');
        return SyncResult.notNeeded();
      }

      // 2. Descargar último lote de Firestore
      final events = await _downloadLatestBatch();
      
      if (events.isEmpty) {
        print('📭 No hay eventos nuevos');
        return SyncResult.noNewData();
      }

      // 3. Procesar y guardar eventos
      await _processEvents(events);

      // 4. Limpieza automática
      final cleanupResults = await _performCleanup();

      // 5. Actualizar timestamps
      await _updateSyncTimestamp();

      print('✅ Sincronización completada exitosamente');
      return SyncResult.success(
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );

    } catch (e) {
      print('❌ Error en sincronización: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// Sincronización al abrir la app
  Future<void> syncOnAppStart() async {
    if (await shouldSync()) {
      await performAutoSync();
    }
  }

  // ========== DESCARGA DE FIRESTORE ==========

  /// Descargar último lote de eventos de Firestore
  Future<List<Map<String, dynamic>>> _downloadLatestBatch() async {
    try {
      print('📥 Descargando lote desde Firestore...');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('📭 No hay lotes disponibles en Firestore');
        return [];
      }

      final latestBatch = querySnapshot.docs.first;
      final batchData = latestBatch.data();
      print('🔍 Campos disponibles en batchData: ${batchData.keys.toList()}');
      print('🔍 Total eventos en metadata: ${batchData['metadata']?['total_eventos']}');

      // Verificar si es un lote nuevo
      final currentBatchVersion = await _getCurrentBatchVersion();
      final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
      
      if (currentBatchVersion == newBatchVersion) {
        print('📄 Mismo lote, no hay actualizaciones');
        return [];
      }

      // Extraer eventos del lote
      final events = (batchData['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];      print('📦 Descargados ${events.length} eventos - Versión: $newBatchVersion');
            
      // Actualizar versión del lote
      await _eventRepository.updateSyncInfo(
        batchVersion: newBatchVersion,
        totalEvents: events.length,
      );

      return events;

    } catch (e) {
      print('❌ Error descargando de Firestore: $e');
      rethrow;
    }
  }

  /// Obtener versión actual del lote
  Future<String> _getCurrentBatchVersion() async {
    final syncInfo = await _eventRepository.getSyncInfo();
    return syncInfo?['batch_version'] as String? ?? '0.0.0';
  }

  Future<void> _processEvents(List<Map<String, dynamic>> events) async {
    print('⚙️ Agregando ${events.length} eventos nuevos...'); // CAMBIO
    
    // BATCH INSERT súper rápido - NO borrar nada - NUEVO
    await _eventRepository.insertEvents(events);
    
    print('✅ ${events.length} eventos agregados a SQLite'); // CAMBIO
  }
  
  /// Limpiar eventos actuales (no favoritos)
  Future<void> _clearCurrentEvents() async {
    final db = await DatabaseHelper.database;
    await db.delete('eventos', where: 'favorite = ?', whereArgs: [0]);  
  }

  // ========== LIMPIEZA AUTOMÁTICA ==========
  /// Realizar limpieza automática completa
  Future<CleanupResult> _performCleanup() async {
    print('🧹 Realizando limpieza automática...');
    
    final cleanupStats = await _eventRepository.cleanOldEvents();
    final duplicatesRemoved = await _eventRepository.removeDuplicatesByCodes(); // NUEVO: limpieza duplicados
    
    print('🗑️ Limpieza completada: ${cleanupStats['normalEvents']} eventos normales, ${cleanupStats['favoriteEvents']} favoritos, $duplicatesRemoved duplicados'); // CAMBIO: agregar duplicados
    
    return CleanupResult(
      eventsRemoved: cleanupStats['normalEvents']! + duplicatesRemoved,        // CAMBIO: incluir duplicados
      favoritesRemoved: cleanupStats['favoriteEvents']!,
    );
  } 
  // ========== UTILIDADES ==========

  /// Actualizar timestamp de última sincronización
  Future<void> _updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Obtener información de última sincronización para UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    final syncInfo = await _eventRepository.getSyncInfo();
    final totalEvents = await _eventRepository.getTotalEvents();
    final totalFavorites = await _eventRepository.getTotalFavorites();

    return {
      'lastSync': lastSyncString,
      'batchVersion': syncInfo?['batch_version'],
      'totalEvents': totalEvents,
      'totalFavorites': totalFavorites,
      'needsSync': await shouldSync(),
    };
  }

  /// Forzar limpieza manual (solo para debug/settings)
  Future<CleanupResult> forceCleanup() async {
    return await _performCleanup();
  }

  /// Reset completo (solo para debug)
  Future<void> resetSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await _eventRepository.clearAllData();
  }
}

// ========== MODELOS DE RESULTADO ==========

class SyncResult {
  final bool success;
  final String? error;
  final int eventsAdded;
  final int eventsRemoved;
  final int favoritesRemoved;
  final SyncResultType type;

  SyncResult._({
    required this.success,
    this.error,
    this.eventsAdded = 0,
    this.eventsRemoved = 0,
    this.favoritesRemoved = 0,
    required this.type,
  });

  factory SyncResult.success({
    required int eventsAdded,
    required int eventsRemoved,
    required int favoritesRemoved,
  }) => SyncResult._(
    success: true,
    eventsAdded: eventsAdded,
    eventsRemoved: eventsRemoved,
    favoritesRemoved: favoritesRemoved,
    type: SyncResultType.success,
  );

  factory SyncResult.notNeeded() => SyncResult._(
    success: true,
    type: SyncResultType.notNeeded,
  );

  factory SyncResult.noNewData() => SyncResult._(
    success: true,
    type: SyncResultType.noNewData,
  );

  factory SyncResult.error(String error) => SyncResult._(
    success: false,
    error: error,
    type: SyncResultType.error,
  );
}

enum SyncResultType { success, notNeeded, noNewData, error }

class CleanupResult {
  final int eventsRemoved;
  final int favoritesRemoved;

  CleanupResult({
    required this.eventsRemoved,
    required this.favoritesRemoved,
  });
}