import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../notifications/data/models/notification_model.dart';
import '../../../notifications/data/services/notification_service.dart';

class EmployerNotificationProvider {
  static final NotificationService _service = NotificationService(apiService);
  static List<NotificationModel> _notifications = [];
  static int _unreadCount = 0;

  static List<NotificationModel> get notifications => _notifications;
  static int get unreadCount => _unreadCount;

  static Future<void> loadNotifications() async {
    _notifications = await _service.getNotifications();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  static Future<void> loadUnreadCount() async {
    _unreadCount = await _service.getUnreadCount();
  }

  static Future<void> markAsRead(int id) async {
    final updated = await _service.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = updated;
    }
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  static Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    _unreadCount = 0;
  }

  static void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
  }
}

class EmployerNotificationsDrawer extends StatefulWidget {
  const EmployerNotificationsDrawer({super.key});

  @override
  State<EmployerNotificationsDrawer> createState() =>
      _EmployerNotificationsDrawerState();
}

class _EmployerNotificationsDrawerState
    extends State<EmployerNotificationsDrawer> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await EmployerNotificationProvider.loadNotifications();
    } catch (e) {
      _error = 'No se pudieron cargar las notificaciones';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    await EmployerNotificationProvider.markAsRead(id);
    if (mounted) setState(() {});
  }

  Future<void> _markAllAsRead() async {
    await EmployerNotificationProvider.markAllAsRead();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = EmployerNotificationProvider.notifications;
    final unreadCount = EmployerNotificationProvider.unreadCount;

    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Marcar todo'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildMessage(Icons.wifi_off, _error!)
                  : notifications.isEmpty
                  ? _buildMessage(
                      Icons.notifications_off_outlined,
                      'No tienes notificaciones',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(notifications[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final unread = !notification.isRead;
    final iconColor = switch (notification.type) {
      'success' => const Color(0xFF059669),
      'warning' => const Color(0xFFF59E0B),
      'error' => const Color(0xFFDC2626),
      _ => const Color(0xFF2563EB),
    };
    final iconData = switch (notification.type) {
      'success' => Icons.check_circle,
      'warning' => Icons.warning,
      'error' => Icons.error,
      _ => Icons.info,
    };

    return InkWell(
      onTap: unread ? () => _markAsRead(notification.id) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFEEF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unread ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
