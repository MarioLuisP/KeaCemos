import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// NUEVO: Gestor de cache persistente para imágenes de eventos
/// Mantiene las imágenes descargadas entre sesiones de la app
class CustomCacheManager {
  static const String key = 'quehacemos_images';
  
  // NUEVO: Cache manager personalizado con configuración persistente
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),           // NUEVO: Cache por 30 días
      maxNrOfCacheObjects: 200,                        // NUEVO: Máximo 200 imágenes
      repo: JsonCacheInfoRepository(databaseName: key), // NUEVO: Base de datos persistente
      fileSystem: IOFileSystem(key),                   // NUEVO: Sistema de archivos local
    ),
  );
  
  /// NUEVO: Método para limpiar cache manualmente si es necesario
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }
  
  /// NUEVO: Método para obtener información del cache
  static Future<void> getCacheInfo() async {
    final cacheSize = await instance.store.getCacheSize();
    final fileCount = await instance.store.retrieveCacheData().then((list) => list?.length ?? 0);  // CAMBIO: Verificación null
    print('📸 Cache info: $fileCount imágenes, ${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB');
  }
  
  /// NUEVO: Precargar imagen en cache (opcional para eventos próximos)
  static Future<void> precacheImage(String imageUrl) async {
    try {
      await instance.downloadFile(imageUrl);
      print('✅ Imagen precargada: $imageUrl');
    } catch (e) {
      print('❌ Error precargando imagen: $e');
    }
  }
}