import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../notifications/data/models/notification_model.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class EmployerNotificationsDrawer extends StatefulWidget {
  const EmployerNotificationsDrawer({super.key});

  @override
  State<EmployerNotificationsDrawer> createState() =>
      _EmployerNotificationsDrawerState();
}

class _EmployerNotificationsDrawerState
    extends State<EmployerNotificationsDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notifications = provider.notifications;

        return Container(
          width: MediaQuery.of(context).size.width * 0.88,
          color: const Color(0xFFF8FAFC),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, provider),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : notifications.isEmpty
                      ? _buildMessage(
                          Icons.notifications_off_outlined,
                          'No tienes notificaciones',
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.loadNotifications(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationCard(
                                context,
                                notifications[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider provider) {
    return Container(
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
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: provider.markAllAsRead,
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
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
  ) {
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
      onTap: unread
          ? () =>
                context.read<NotificationProvider>().markAsRead(notification.id)
          : null,
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
                            color: Color(0xFFDC2626),
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
