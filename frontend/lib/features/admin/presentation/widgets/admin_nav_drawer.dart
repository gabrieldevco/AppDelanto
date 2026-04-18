import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../pages/user_management_page.dart';

class AdminNavDrawer extends StatelessWidget {
  const AdminNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF2563EB),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del drawer
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 32,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Panel Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Administrador',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Menú items
            _buildMenuItem(
              context,
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                // Ya estamos en el dashboard principal
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.people,
              label: 'Gestión de Usuarios',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManagementPage()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.business,
              label: 'Empresas',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a empresas
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.attach_money,
              label: 'Adelantos',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a adelantos
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.bar_chart,
              label: 'Reportes',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a reportes
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings,
              label: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a configuración
              },
            ),

            const Divider(color: Colors.white24, height: 32),

            // Cerrar sesión
            _buildMenuItem(
              context,
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              iconColor: Colors.red.shade300,
              textColor: Colors.red.shade100,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.white70,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
