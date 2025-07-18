import 'package:flutter/material.dart';
import '../data/repositories/event_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  // NUEVO: Singleton pattern
  static NotificationsProvider? _instance;
  static NotificationsProvider get instance {
    _instance ??= NotificationsProvider._internal();
    return _instance!;
  }
  
  // CAMBIO: Repositorio para acceso a SQLite
  final EventRepository _eventRepository = EventRepository();
  
  // CAMBIO: Cache en memoria para performance de UI
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _cacheLoaded = false;                      // NUEVO: flag para lazy loading

  // NUEVO: Getters públicos
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnreadNotifications => _unreadCount > 0;
  
  NotificationsProvider._internal() {  // CAMBIO: constructor privado
      // NUEVO: Cargar notificaciones automáticamente al inicializar
      _initializeNotifications();
    }
    
    /// NUEVO: Inicialización automática de notificaciones
    void _initializeNotifications() {                 // CAMBIO: void en vez de Future
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await loadNotifications();                  // NUEVO: carga desde SQLite
          print('✅ NotificationsProvider inicializado con ${_notifications.length} notificaciones');
        } catch (e) {
          print('❌ Error inicializando NotificationsProvider: $e');
          // NUEVO: Fallback silencioso - continúa sin notificaciones
        }
      });
    }
  // NUEVO: Constructor factory que usa singleton
  factory NotificationsProvider() => instance;

  /// NUEVO: Inicializar con notificaciones mock para desarrollo


/// CAMBIO: Actualizar contador con fuente de verdad en SQLite
  Future<void> _updateUnreadCount() async {
    try {
      // NUEVO: Obtener count desde SQLite como fuente de verdad
      _unreadCount = await _eventRepository.getUnreadNotificationsCount();
      
      // NUEVO: También sincronizar cache en memoria por consistencia
      final cacheUnread = _notifications.where((n) => !n['isRead']).length;
      if (cacheUnread != _unreadCount && _cacheLoaded) { // NUEVO: detectar inconsistencias
        print('⚠️ Inconsistencia cache/SQLite: cache=$cacheUnread, db=$_unreadCount');
      }
      
      notifyListeners();
    } catch (e) {
      // NUEVO: Fallback a cache en memoria si SQLite falla
      _unreadCount = _notifications.where((n) => !n['isRead']).length;
      notifyListeners();
      print('❌ Error obteniendo unread count, usando cache: $e');
    }
  }

/// CAMBIO: Marcar notificación como leída con persistencia
  Future<void> markAsRead(dynamic notificationId) async { // CAMBIO: dynamic para int/String
    try {
      final id = notificationId is String ? int.parse(notificationId) : notificationId as int; // NUEVO: conversión
      
      // NUEVO: Actualizar en SQLite
      await _eventRepository.markNotificationAsRead(id);
      
      // CAMBIO: Actualizar cache en memoria
      final index = _notifications.indexWhere((n) => n['id'] == id); // CAMBIO: comparar como int
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        _updateUnreadCount();
      }
    } catch (e) {
      print('❌ Error marcando como leída: $e');    // NUEVO: error handling
    }
  }
/// CAMBIO: Marcar todas como leídas con persistencia
  Future<void> markAllAsRead() async {
    try {
      // NUEVO: Actualizar todas en SQLite
      await _eventRepository.markAllNotificationsAsRead();
      
      // CAMBIO: Actualizar cache en memoria
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _updateUnreadCount();
    } catch (e) {
      print('❌ Error marcando todas como leídas: $e'); // NUEVO: error handling
    }
  }

/// CAMBIO: Eliminar notificación con persistencia
  Future<void> removeNotification(dynamic notificationId) async { // CAMBIO: dynamic para int/String
    try {
      final id = notificationId is String ? int.parse(notificationId) : notificationId as int; // NUEVO: conversión
      
      // NUEVO: Eliminar de SQLite
      await _eventRepository.deleteNotification(id);
      
      // CAMBIO: Eliminar de cache en memoria
      _notifications.removeWhere((n) => n['id'] == id); // CAMBIO: comparar como int
      _updateUnreadCount();
    } catch (e) {
      print('❌ Error eliminando notificación: $e');   // NUEVO: error handling
    }
  }
/// CAMBIO: Limpiar todas las notificaciones con persistencia
  Future<void> clearAllNotifications() async {
    try {
      // NUEVO: Limpiar SQLite
      await _eventRepository.clearAllNotifications();
      
      // CAMBIO: Limpiar cache en memoria
      _notifications.clear();
      await _updateUnreadCount();                  // CAMBIO: await necesario
    } catch (e) {
      print('❌ Error limpiando notificaciones: $e'); // NUEVO: error handling
    }
  }
/// CAMBIO: Agregar nueva notificación con persistencia SQLite
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? icon,
    String? eventCode,                              // NUEVO: para recordatorios de eventos
  }) async {
    try {
      // NUEVO: Insertar en SQLite
      final notificationId = await _eventRepository.insertNotification(
        title: title,
        message: message,
        type: type,
        eventCode: eventCode,                       // NUEVO: campo event_code
      );
      
      // CAMBIO: Crear objeto para cache con ID de SQLite
      final notification = {
        'id': notificationId,                       // CAMBIO: usar ID de SQLite
        'title': title,
        'message': message,
        'timestamp': DateTime.now(),
        'isRead': false,
        'type': type,
        'icon': icon ?? '🔔',
        'event_code': eventCode,                    // NUEVO: incluir event_code
      };

      _notifications.insert(0, notification);      // MANTENER: cache en memoria
      _updateUnreadCount();
    } catch (e) {
      print('❌ Error agregando notificación: $e'); // NUEVO: error handling
    }
  }

  /// NUEVO: Simular llegada de nueva notificación (para desarrollo)
  void simulateNewNotification() {
    final mockNotifications = [
      {
        'title': 'Evento añadido',
        'message': 'Nuevo evento de música en tu zona',
        'type': 'new_events',
        'icon': '🎵',
      },
      {
        'title': 'Recordatorio',
        'message': 'Tu evento favorito es en 2 horas',
        'type': 'reminder',
        'icon': '⏰',
      },
      {
        'title': 'Actualización',
        'message': 'Cambio de horario en evento guardado',
        'type': 'event_update',
        'icon': '📅',
      },
    ];

    final random = mockNotifications[DateTime.now().millisecond % mockNotifications.length];
    
    addNotification(
      title: random['title']!,
      message: random['message']!,
      type: random['type']!,
      icon: random['icon'],
    );
  }

  /// NUEVO: Obtener notificaciones de un tipo específico
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return _notifications.where((n) => n['type'] == type).toList();
  }

  /// NUEVO: Obtener notificaciones recientes (últimas 24 horas)
  List<Map<String, dynamic>> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((n) => 
      (n['timestamp'] as DateTime).isAfter(yesterday)
    ).toList();
  }

  /// NUEVO: Formatear tiempo de notificación
  String getNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

/// CAMBIO: Cargar notificaciones desde SQLite
  Future<void> loadNotifications() async {
    if (_cacheLoaded) return;                       // NUEVO: evitar cargas múltiples
    
    _isLoading = true;
    notifyListeners();

    try {
      // CAMBIO: Cargar desde SQLite en vez de Firebase
      final dbNotifications = await _eventRepository.getAllNotifications();
      
      // CAMBIO: Convertir formato SQLite a formato cache
      _notifications = dbNotifications.map((dbNotif) => {
        'id': dbNotif['id'],
        'title': dbNotif['title'],
        'message': dbNotif['message'],
        'timestamp': DateTime.parse(dbNotif['created_at']), // CAMBIO: parsear timestamp
        'isRead': (dbNotif['is_read'] as int) == 1,          // CAMBIO: convertir int a bool
        'type': dbNotif['type'],
        'icon': _getIconForType(dbNotif['type']),            // NUEVO: derivar icon del tipo
        'event_code': dbNotif['event_code'],                 // NUEVO: incluir event_code
      }).toList();
      
      _cacheLoaded = true;                          // NUEVO: marcar cache como cargado
      _updateUnreadCount();
      
      print('✅ Notificaciones cargadas desde SQLite: ${_notifications.length}');
    } catch (e) {
      print('❌ Error cargando notificaciones desde SQLite: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
/// NUEVO: Derivar icon del tipo de notificación
  String _getIconForType(String type) {
    switch (type) {                                 // NUEVO: mapeo tipo → icon
      case 'sync':
      case 'new_events':
        return '🎭';
      case 'sync_up_to_date':
      case 'sync_no_new_data':
        return '✅';
      case 'favorite_added':
        return '❤️';
      case 'favorite_removed':
        return '💔';
      case 'event_reminder':
        return '⏰';
      case 'sync_error':
        return '⚠️';
      case 'maintenance':
        return '🧹';
      default:
        return '🔔';                               // NUEVO: fallback
    }
  }
  /// NUEVO: Enviar notificación push (placeholder)
  Future<void> sendPushNotification(String title, String body) async {
    // NUEVO: Aquí irá la lógica para enviar push notifications
    // Por ahora, solo agregar localmente
    addNotification(
      title: title,
      message: body,
      type: 'push',
      icon: '📱',
    );
  }
}