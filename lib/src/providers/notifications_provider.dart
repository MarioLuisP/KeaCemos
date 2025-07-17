import 'package:flutter/material.dart';

class NotificationsProvider extends ChangeNotifier {
  // NUEVO: Singleton pattern
  static NotificationsProvider? _instance;
  static NotificationsProvider get instance {
    _instance ??= NotificationsProvider._internal();
    return _instance!;
  }
  
  // NUEVO: Estado de notificaciones
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // NUEVO: Getters públicos
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnreadNotifications => _unreadCount > 0;

  NotificationsProvider._internal() {  // CAMBIO: constructor privado
    // NUEVO: Inicializar con datos mock para desarrollo
    _initializeMockNotifications();
  }
  
  // NUEVO: Constructor factory que usa singleton
  factory NotificationsProvider() => instance;

  /// NUEVO: Inicializar con notificaciones mock para desarrollo
  void _initializeMockNotifications() {
    _notifications = [
      {
        'id': '1',
        'title': 'Nuevos eventos agregados',
        'message': 'Se agregaron 5 eventos nuevos en tu zona',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
        'type': 'new_events',
        'icon': '🎉',
      },
      {
        'id': '2',
        'title': 'Evento favorito mañana',
        'message': 'Tu evento favorito "Concierto en el Parque" es mañana',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': true,
        'type': 'favorite_reminder',
        'icon': '❤️',
      },
      {
        'id': '3',
        'title': 'Evento cancelado',
        'message': 'El evento "Teatro Municipal" ha sido cancelado',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': false,
        'type': 'event_cancelled',
        'icon': '⚠️',
      },
    ];

    // NUEVO: Calcular notificaciones no leídas
    _updateUnreadCount();
  }

  /// NUEVO: Actualizar contador de no leídas
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n['isRead']).length;
    notifyListeners();
  }

  /// NUEVO: Marcar notificación como leída
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
      _updateUnreadCount();
    }
  }

  /// NUEVO: Marcar todas como leídas
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
    _updateUnreadCount();
  }

  /// NUEVO: Eliminar notificación
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n['id'] == notificationId);
    _updateUnreadCount();
  }

  /// NUEVO: Limpiar todas las notificaciones
  void clearAllNotifications() {
    _notifications.clear();
    _updateUnreadCount();
  }

  /// NUEVO: Agregar nueva notificación (para cuando llegue desde Firebase)
  void addNotification({
    required String title,
    required String message,
    required String type,
    String? icon,
  }) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'timestamp': DateTime.now(),
      'isRead': false,
      'type': type,
      'icon': icon ?? '🔔',
    };

    _notifications.insert(0, notification); // NUEVO: Insertar al principio
    _updateUnreadCount();
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

  /// NUEVO: Cargar notificaciones desde Firebase (placeholder)
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // NUEVO: Aquí irá la lógica para cargar desde Firebase
      // Por ahora, simular delay de red
      await Future.delayed(const Duration(milliseconds: 500));
      
      // NUEVO: En producción, reemplazar con llamada a Firebase
      // final notifications = await FirebaseService.getNotifications();
      // _notifications = notifications;
      
      print('✅ Notificaciones cargadas: ${_notifications.length}');
    } catch (e) {
      print('❌ Error cargando notificaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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