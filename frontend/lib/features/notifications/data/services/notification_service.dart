import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  // Obtener notificaciones del usuario
  Future<List<NotificationModel>> getNotifications({
    bool? isRead,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (isRead != null) queryParams['is_read'] = isRead;
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiService.get(
      ApiConstants.notifications,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final results = response is List ? response : (response['results'] ?? []);
    return results
        .map<NotificationModel>((json) => NotificationModel.fromJson(json))
        .toList();
  }

  // Obtener notificaciones no leídas
  Future<List<NotificationModel>> getUnreadNotifications() async {
    return getNotifications(isRead: false);
  }

  // Obtener conteo de notificaciones no leídas
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(ApiConstants.notificationsUnread);
      return response['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Marcar notificación como leída
  Future<NotificationModel> markAsRead(int notificationId) async {
    final response = await _apiService.post(
      '${ApiConstants.notifications}$notificationId/mark-read/',
    );
    return NotificationModel.fromJson(response);
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    await _apiService.post(ApiConstants.notificationsMarkRead);
  }

  // Eliminar notificación
  Future<void> deleteNotification(int notificationId) async {
    await _apiService.delete('${ApiConstants.notifications}$notificationId/');
  }

  // Obtener notificaciones del sistema (solo admins)
  Future<List<SystemNotificationModel>> getSystemNotifications({
    bool? isRead,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (isRead != null) queryParams['is_read'] = isRead;
    if (page != null) queryParams['page'] = page;

    final response = await _apiService.get(
      '${ApiConstants.notifications}system/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final results = response is List ? response : (response['results'] ?? []);
    return results
        .map<SystemNotificationModel>(
          (json) => SystemNotificationModel.fromJson(json),
        )
        .toList();
  }

  // Marcar notificación del sistema como leída
  Future<void> markSystemNotificationAsRead(int notificationId) async {
    await _apiService.post(
      '${ApiConstants.notifications}system/$notificationId/mark-read/',
    );
  }

  // Suscribirse a notificaciones en tiempo real (simulado con polling)
  Stream<int> unreadCountStream({Duration interval = const Duration(seconds: 30)}) async* {
    while (true) {
      try {
        final count = await getUnreadCount();
        yield count;
      } catch (e) {
        yield 0;
      }
      await Future.delayed(interval);
    }
  }
}
