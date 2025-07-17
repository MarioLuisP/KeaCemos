import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; 
import '../data/repositories/event_repository.dart';
import '../data/database/database_helper.dart';
import '../providers/notifications_provider.dart'; // CAMBIO: ruta corregida


class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  // NUEVO: StreamController para notificar cuando termina sync
  static final StreamController<SyncResult> _syncCompleteController = 
      StreamController<SyncResult>.broadcast();
  
  // NUEVO: Stream público para escuchar completions de sync
  static Stream<SyncResult> get onSyncComplete => _syncCompleteController.stream;
  final EventRepository _eventRepository = EventRepository();
  final NotificationsProvider _notificationsProvider = NotificationsProvider();
  static const Duration _syncInterval = Duration(hours: 24);
  static const String _lastSyncKey = 'last_sync_timestamp';

  // NUEVO: Flag para evitar múltiples sincronizaciones
  bool _isSyncing = false;

  // ========== SYNC PRINCIPAL ==========

/// Verificar si necesita sincronización
Future<bool> shouldSync() async {
  final prefs = await SharedPreferences.getInstance();
  final lastSyncString = prefs.getString(_lastSyncKey);
  
  final now = DateTime.now();
  
  // Si nunca sincronizó, sincronizar
  if (lastSyncString == null) {
    print('🔄 Primera sincronización');
    return true;
  }
  
  final lastSync = DateTime.parse(lastSyncString);
  
  // Verificar si ya sincronizó hoy
  final today = DateTime(now.year, now.month, now.day);
  final lastSyncDay = DateTime(lastSync.year, lastSync.month, lastSync.day);
  
  if (today.isAfter(lastSyncDay)) {
    // No sincronizó hoy, verificar condiciones
    if (now.hour >= 1) {
      print('🔄 Sincronización por horario (después de 01:00)');
      return true;
    } else {
      print('⏰ Esperando hasta la 1 AM para sincronizar');
      return false;
    }
  }
  
  // Ya sincronizó hoy
  print('✅ Ya sincronizó hoy, omitiendo');
  return false;
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

  /// Sincronización al abrir la app
  Future<void> syncOnAppStart() async {
    if (await shouldSync()) {
      await performAutoSync();
    }
  }
  /// Sincronización automática (respeta shouldSync)
    Future<SyncResult> performAutoSync() async {                    // NUEVO: método principal automático
      if (_isSyncing) {                                            // NUEVO: verificar flag
        print('⏭️ Sincronización ya en progreso, omitiendo...');
        return SyncResult.notNeeded();
      }

      if (!await shouldSync()) {                                   // NUEVO: respetar verificaciones
        print('⏭️ Sincronización no necesaria aún');
        return SyncResult.notNeeded();
      }

      _isSyncing = true;                                           // NUEVO: activar flag
      
      try {
        print('🔄 Iniciando sincronización automática...');
        
        final events = await _downloadLatestBatch();               // NUEVO: usar método existente
        
      if (events.isEmpty) {
        print('📭 No hay eventos nuevos');
        
        // NUEVO: Notificar que sync completó sin eventos nuevos
        _notificationsProvider.addNotification(
          title: '✅ Todo actualizado',
          message: 'No hay eventos nuevos en este momento',
          type: 'sync_no_new_data',
          icon: '📱',
        );
        
        return SyncResult.noNewData();
      }

        await _processEvents(events);                              // NUEVO: procesar eventos
        final cleanupResults = await _performCleanup();           // NUEVO: limpieza
        await _updateSyncTimestamp();                              // NUEVO: actualizar timestamp
              // NUEVO: Enviar notificaciones automáticas
        await _sendSyncNotifications(events.length, cleanupResults);

        print('✅ Sincronización automática completada');
        final result = SyncResult.success(                                     // NUEVO: resultado exitoso
          eventsAdded: events.length,
          eventsRemoved: cleanupResults.eventsRemoved,
          favoritesRemoved: cleanupResults.favoritesRemoved,
        );
        _syncCompleteController.add(result);                               // NUEVO: notificar completion
        return result;    

      } catch (e) {
        print('❌ Error en sincronización automática: $e');
        return SyncResult.error(e.toString());                     // NUEVO: manejo de errores
      } finally {
        _isSyncing = false;                                        // NUEVO: desactivar flag
      }
    }

  /// Reset completo (solo para debug)
  Future<void> resetSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await _eventRepository.clearAllData();
  }
/// MÉTODO TEMPORAL PARA DEV - BORRAR EN PRODUCCIÓN 🔥
  Future<SyncResult> forceSync() async {
    if (_isSyncing) {
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    _isSyncing = true;
    
    try {
      print('🔄 FORZANDO sincronización (dev)...');
      
      // CAMBIO: Saltar verificación de shouldSync() pero forzar descarga
      final events = await _downloadLatestBatch();
      
      if (events.isEmpty) {
        print('📭 No hay eventos nuevos');
        return SyncResult.noNewData();
      }

      await _processEvents(events);
      final cleanupResults = await _performCleanup();
      await _updateSyncTimestamp();

      print('✅ Sincronización FORZADA completada');
      final result = SyncResult.success(        
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );
      _syncCompleteController.add(result);                                 // NUEVO: notificar completion
      return result;        

    } catch (e) {
      print('❌ Error en sincronización forzada: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }
// ========== NOTIFICACIONES AUTOMÁTICAS ========== // NUEVO

  /// NUEVO: Enviar notificaciones automáticas post-sincronización
  Future<void> _sendSyncNotifications(int newEventsCount, CleanupResult cleanupResults) async {
    try {
      // NUEVO: Solo notificar si hay eventos nuevos significativos
      if (newEventsCount > 0) {
        // NUEVO: Crear instancia de NotificationsProvider
          final notificationsProvider = _notificationsProvider;        
        // NUEVO: Notificación principal de eventos nuevos
        notificationsProvider.addNotification(
          title: '🎭 ¡Eventos nuevos en Córdoba!',
          message: 'Se agregaron $newEventsCount eventos culturales',
          type: 'new_events',
          icon: '🎉',
        );
        
        // NUEVO: Notificación adicional si hay muchos eventos
        if (newEventsCount >= 10) {
          notificationsProvider.addNotification(
            title: '🔥 ¡Semana cargada de cultura!',
            message: 'Más de $newEventsCount eventos esperándote',
            type: 'high_activity',
            icon: '🌟',
          );
        }
        
        // NUEVO: Notificación de limpieza si fue significativa
        if (cleanupResults.eventsRemoved > 5) {
          notificationsProvider.addNotification(
            title: '🧹 Base de datos optimizada',
            message: 'Se limpiaron ${cleanupResults.eventsRemoved} eventos pasados',
            type: 'cleanup',
            icon: '✨',
          );
        }
        
        print('📱 Notificaciones de sync enviadas: $newEventsCount eventos');
      }
      
    } catch (e) {
      print('⚠️ Error enviando notificaciones de sync: $e');
      // NUEVO: No fallar la sincronización por errores de notificaciones
    }
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