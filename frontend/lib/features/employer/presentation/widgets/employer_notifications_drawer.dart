import 'package:flutter/material.dart';

// Simple notification model for employer
class EmployerNotificationData {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final NotificationType type;

  EmployerNotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
  });
}

enum NotificationType { success, warning, info }

// Simple provider for employer notifications
class EmployerNotificationProvider {
  static final List<EmployerNotificationData> _notifications = [];  // Iniciar vacío - cargar desde backend

  static List<EmployerNotificationData> get notifications => _notifications;
  
  static int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = EmployerNotificationData(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        time: _notifications[index].time,
        isRead: true,
        type: _notifications[index].type,
      );
    }
  }

  static void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = EmployerNotificationData(
        id: _notifications[i].id,
        title: _notifications[i].title,
        message: _notifications[i].message,
        time: _notifications[i].time,
        isRead: true,
        type: _notifications[i].type,
      );
    }
  }

  static void clearNotifications() {
    _notifications.clear();
  }
}

class EmployerNotificationsDrawer extends StatefulWidget {
  const EmployerNotificationsDrawer({super.key});

  @override
  State<EmployerNotificationsDrawer> createState() => _EmployerNotificationsDrawerState();
}

class _EmployerNotificationsDrawerState extends State<EmployerNotificationsDrawer> {
  List<EmployerNotificationData> get _notifications => EmployerNotificationProvider.notifications;
  int get _unreadCount => EmployerNotificationProvider.unreadCount;

  void _markAsRead(String id) {
    setState(() {
      EmployerNotificationProvider.markAsRead(id);
    });
  }

  void _markAllAsRead() {
    setState(() {
      EmployerNotificationProvider.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            // Header del drawer
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (_unreadCount > 0)
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
            // Contenido
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(_notifications[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(EmployerNotificationData notification) {
    Color iconColor;
    IconData iconData;
    
    switch (notification.type) {
      case NotificationType.success:
        iconColor = const Color(0xFF059669);
        iconData = Icons.check_circle;
        break;
      case NotificationType.warning:
        iconColor = const Color(0xFFF59E0B);
        iconData = Icons.warning;
        break;
      case NotificationType.info:
        iconColor = const Color(0xFF2563EB);
        iconData = Icons.info;
        break;
    }

    return GestureDetector(
      onTap: () => _markAsRead(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF93C5FD),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Indicador de no leído
            if (!notification.isRead)
              Container(
                width: 4,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconData,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Contenido
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
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
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
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.time,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
