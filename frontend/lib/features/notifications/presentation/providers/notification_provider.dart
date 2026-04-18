import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import '../../../../core/services/api_service.dart';

enum NotificationStatus { initial, loading, loaded, submitting, error }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  
  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _errorMessage;

  NotificationProvider() : _notificationService = NotificationService(apiService);

  // Getters
  NotificationStatus get status => _status;
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => 
    _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotificationStatus.loading;
  bool get hasUnread => _unreadCount > 0;

  // Cargar notificaciones
  Future<void> loadNotifications({bool? isRead}) async {
    _status = NotificationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(isRead: isRead);
      _status = NotificationStatus.loaded;
      
      // Actualizar conteo de no leídas
      _unreadCount = unreadNotifications.length;
    } catch (e) {
      _status = NotificationStatus.error;
      _errorMessage = 'Error al cargar notificaciones: ${e.toString()}';
    }
    notifyListeners();
  }

  // Cargar solo no leídas
  Future<void> loadUnreadNotifications() async {
    await loadNotifications(isRead: false);
  }

  // Actualizar conteo de no leídas
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      // Error silencioso
    }
  }

  // Marcar como leída
  Future<bool> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al marcar como leída: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Marcar todas como leídas
  Future<bool> markAllAsRead() async {
    _status = NotificationStatus.submitting;
    notifyListeners();

    try {
      await _notificationService.markAllAsRead();
      
      _notifications = _notifications.map((n) => 
        n.copyWith(isRead: true, readAt: DateTime.now())
      ).toList();
      _unreadCount = 0;
      _status = NotificationStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = NotificationStatus.error;
      _errorMessage = 'Error al marcar todas: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Eliminar notificación
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      final wasUnread = _notifications
          .firstWhere((n) => n.id == notificationId, orElse: () => 
            NotificationModel(id: 0, userId: 0, type: '', title: '', message: '', isRead: true, createdAt: DateTime.now()))
          .isRead == false;
      
      _notifications.removeWhere((n) => n.id == notificationId);
      if (wasUnread && _unreadCount > 0) _unreadCount--;
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Agregar notificación local (para notificaciones en tiempo real)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) _unreadCount++;
    notifyListeners();
  }

  // Polling de notificaciones no leídas
  Future<void> startUnreadPolling({Duration interval = const Duration(seconds: 30)}) async {
    // Este método se puede llamar periódicamente desde la UI
    await refreshUnreadCount();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Limpiar datos
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _status = NotificationStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
