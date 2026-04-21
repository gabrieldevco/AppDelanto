import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class EmployeeNotificationsDrawer extends StatefulWidget {
  const EmployeeNotificationsDrawer({super.key});

  @override
  State<EmployeeNotificationsDrawer> createState() => _EmployeeNotificationsDrawerState();
}

class _EmployeeNotificationsDrawerState extends State<EmployeeNotificationsDrawer> {
  @override
  void initState() {
    super.initState();
    // Cargar notificaciones al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
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
                  if (notificationProvider.unreadCount > 0)
                    TextButton.icon(
                      onPressed: () => notificationProvider.markAllAsRead(),
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
              child: Builder(
                builder: (context) {
                  final notifications = notificationProvider.notifications;
                  
                  if (notificationProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    Color iconColor;
    IconData iconData;
    
    // Determinar color e icono según el tipo
    final type = notification.type?.toString().toLowerCase() ?? 'info';
    if (type.contains('success') || type == 'aprobado' || type == 'desembolsado') {
      iconColor = const Color(0xFF059669);
      iconData = Icons.check_circle;
    } else if (type.contains('warning') || type == 'rechazado' || type == 'pendiente') {
      iconColor = const Color(0xFFF59E0B);
      iconData = Icons.warning;
    } else {
      iconColor = const Color(0xFF2563EB);
      iconData = Icons.info;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Color(0xFFDC2626)),
      ),
      onDismissed: (_) => _deleteNotification(context, notification.id),
      child: GestureDetector(
        onTap: () => _markAsRead(context, notification.id),
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
                          color: iconColor.withValues(alpha: 0.1),
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
                              _formatTime(notification.createdAt),
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
      ),
    );
  }

  void _deleteNotification(BuildContext context, int id) {
    context.read<NotificationProvider>().deleteNotification(id);
  }

  void _markAsRead(BuildContext context, int id) {
    context.read<NotificationProvider>().markAsRead(id);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays < 30) return 'Hace ${diff.inDays} días';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
