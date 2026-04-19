import 'package:flutter/material.dart';

enum NotificationType { success, warning, info }

class NotificationData {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;

  NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });

  NotificationData copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Provider global simple para notificaciones
class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _instance = NotificationProvider._internal();
  factory NotificationProvider() => _instance;
  NotificationProvider._internal();

  // Iniciar con lista vacía - las notificaciones se cargan desde el backend
  List<NotificationData> _notifications = [];

  List<NotificationData> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Limpiar notificaciones (llamar al iniciar sesión con nuevo usuario)
  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }

  // Cargar notificaciones desde el backend (implementar cuando el endpoint esté listo)
  Future<void> loadNotificationsFromBackend() async {
    // TODO: Implementar llamada al backend cuando el endpoint esté disponible
    // Por ahora, las notificaciones se mantienen vacías para usuarios nuevos
    _notifications = [];
    notifyListeners();
  }

  // Agregar notificación (para usar cuando llegue del backend)
  void addNotification(NotificationData notification) {
    _notifications.insert(0, notification); // Agregar al inicio
    notifyListeners();
  }
}

// Instancia global
final notificationProvider = NotificationProvider();
