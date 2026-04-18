import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../pages/employee_help_page.dart';
import '../pages/employee_profile_page.dart';
import '../providers/notification_provider.dart';

class EmployeeHeader extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const EmployeeHeader({
    super.key,
    this.onNotificationTap,
  });

  @override
  State<EmployeeHeader> createState() => _EmployeeHeaderState();
}

class _EmployeeHeaderState extends State<EmployeeHeader> {
  @override
  void initState() {
    super.initState();
    notificationProvider.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    notificationProvider.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _unreadCount => notificationProvider.unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(
              Icons.attach_money,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AppDelanta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Juan Pérez',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationIcon(context),
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            color: const Color(0xFF6B7280),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeHelpPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
            color: const Color(0xFF6B7280),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            color: const Color(0xFFDC2626),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 20),
          color: const Color(0xFF6B7280),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: widget.onNotificationTap ?? () {
            Scaffold.of(context).openEndDrawer();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Estás seguro?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Cerrar sesión en backend
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Sí, salir',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
