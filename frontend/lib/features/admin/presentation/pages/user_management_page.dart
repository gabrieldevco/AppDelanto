import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_nav_drawer.dart';
import '../widgets/admin_notifications_drawer.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _selectedRole = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final adminProvider = context.read<AdminProvider>();
    await adminProvider.loadUsers(
      role: _selectedRole == 'all' ? null : _selectedRole,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const AdminNotificationsDrawer(),
      drawer: const AdminNavDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: const AdminHeader(),
            ),
            
            // Contenido principal
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 32,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y filtros
                    _buildHeader(),
                    const SizedBox(height: 20),
                    
                    // Filtros
                    _buildFilters(),
                    const SizedBox(height: 20),
                    
                    // Lista de usuarios
                    Expanded(
                      child: _buildUsersList(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.people,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Administra usuarios y documentos',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Búsqueda
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _loadUsers();
                },
              ),
            ),
            onSubmitted: (_) => _loadUsers(),
          ),
        ),
        
        // Filtro por rol
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              items: [
                _buildRoleFilterItem('all', 'Todos los roles'),
                _buildRoleFilterItem('employee', 'Empleados'),
                _buildRoleFilterItem('employer', 'Empleadores'),
                _buildRoleFilterItem('admin', 'Administradores'),
              ],
              onChanged: (v) {
                setState(() => _selectedRole = v!);
                _loadUsers();
              },
            ),
          ),
        ),
        
        // Botón buscar
        ElevatedButton.icon(
          onPressed: _loadUsers,
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Filtrar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildRoleFilterItem(String value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Text(label),
    );
  }

  Widget _buildUsersList() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(adminProvider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUsers,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final users = adminProvider.users;

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text(
                  'No hay usuarios registrados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }

        // Vista responsive: tabla en desktop, cards en móvil
        final isSmallScreen = MediaQuery.of(context).size.width < 800;

        if (isSmallScreen) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) => _buildUserCard(users[index]),
          );
        }

        return _buildUsersTable(users);
      },
    );
  }

  Widget _buildUsersTable(List<dynamic> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Usuario')),
            DataColumn(label: Text('Rol')),
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Empresa/Salario')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Documento PDF')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: users.map((user) => _buildUserDataRow(user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildUserDataRow(dynamic user) {
    final isEmployer = user.role == 'employer';
    final hasCompany = isEmployer && user.company != null;
    final hasDocument = hasCompany && user.company['has_chamber_document'] == true;
    final documentUrl = hasCompany ? user.company['chamber_of_commerce_document_url'] : null;

    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                user.email,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        DataCell(_buildRoleBadge(user.role)),
        DataCell(Text(user.documentNumber ?? 'N/A')),
        DataCell(
          isEmployer
              ? (hasCompany
                  ? Text(user.company['name'] ?? 'N/A')
                  : const Text('Sin empresa'))
              : (user.employeeProfile != null
                  ? Text('\$${user.employeeProfile['salary'] ?? '0'}')
                  : const Text('N/A')),
        ),
        DataCell(
          isEmployer && hasCompany
              ? _buildVerificationBadge(user.company['is_verified'] ?? false)
              : const Text('N/A'),
        ),
        DataCell(
          hasDocument
              ? TextButton.icon(
                  onPressed: () => _openDocument(documentUrl),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  label: const Text('Ver PDF'),
                )
              : const Text('No disponible'),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEmployer && hasCompany && !(user.company['is_verified'] ?? false))
                IconButton(
                  onPressed: () => _verifyCompany(user.company['id']),
                  icon: const Icon(Icons.verified, color: Colors.green),
                  tooltip: 'Verificar empresa',
                ),
              IconButton(
                onPressed: () => _showUserDetails(user),
                icon: const Icon(Icons.visibility, color: Color(0xFF2563EB)),
                tooltip: 'Ver detalles',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final isEmployer = user.role == 'employer';
    final hasCompany = isEmployer && user.company != null;
    final hasDocument = hasCompany && user.company['has_chamber_document'] == true;
    final documentUrl = hasCompany ? user.company['chamber_of_commerce_document_url'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(user.role),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Documento:', user.documentNumber ?? 'N/A'),
            if (isEmployer && hasCompany) ...[
              _buildInfoRow('Empresa:', user.company['name'] ?? 'N/A'),
              _buildInfoRow('Razón Social:', user.company['legal_name'] ?? 'N/A'),
              _buildInfoRow('Estado:', user.company['is_verified'] ? 'Verificada' : 'Pendiente'),
            ] else if (user.employeeProfile != null) ...[
              _buildInfoRow('Salario:', '\$${user.employeeProfile['salary'] ?? '0'}'),
              _buildInfoRow('Límite Adelanto:', '\$${user.employeeProfile['available_advance_limit'] ?? '0'}'),
            ],
            if (hasDocument) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openDocument(documentUrl),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Ver Cámara de Comercio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (isEmployer && hasCompany && !(user.company['is_verified'] ?? false))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyCompany(user.company['id']),
                      icon: const Icon(Icons.verified),
                      label: const Text('Verificar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (isEmployer && hasCompany && !(user.company['is_verified'] ?? false))
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserDetails(user),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Detalles'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final Map<String, dynamic> roleConfig = {
      'employee': {'label': 'Empleado', 'color': const Color(0xFF2563EB)},
      'employer': {'label': 'Empleador', 'color': const Color(0xFF059669)},
      'admin': {'label': 'Admin', 'color': const Color(0xFF7C3AED)},
    };

    final config = roleConfig[role] ?? roleConfig['employee']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          color: config['color'],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.pending,
            size: 14,
            color: isVerified ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verificada' : 'Pendiente',
            style: TextStyle(
              color: isVerified ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(String? url) async {
    if (url == null) return;
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el documento')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _verifyCompany(int companyId) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.verifyCompany(companyId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa verificada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.error ?? 'Error al verificar empresa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetails(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Usuario'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', '${user.firstName} ${user.lastName}'),
              _buildDetailRow('Email:', user.email),
              _buildDetailRow('Rol:', user.roleDisplay ?? user.role),
              _buildDetailRow('Documento:', user.documentNumber ?? 'N/A'),
              _buildDetailRow('Teléfono:', user.phone ?? 'N/A'),
              if (user.role == 'employer' && user.company != null) ...[
                const Divider(),
                const Text(
                  'Información de Empresa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildDetailRow('Nombre:', user.company['name'] ?? 'N/A'),
                _buildDetailRow('Razón Social:', user.company['legal_name'] ?? 'N/A'),
                _buildDetailRow('NIT:', user.company['tax_id'] ?? 'N/A'),
                _buildDetailRow('Dirección:', user.company['address'] ?? 'N/A'),
                _buildDetailRow('Teléfono:', user.company['phone'] ?? 'N/A'),
                _buildDetailRow('Cuenta Bancaria:', user.company['bank_account'] ?? 'N/A'),
                _buildDetailRow('Banco:', user.company['bank_name'] ?? 'N/A'),
                _buildDetailRow('Verificada:', user.company['is_verified'] ? 'Sí' : 'No'),
              ],
              if (user.role == 'employee' && user.employeeProfile != null) ...[
                const Divider(),
                const Text(
                  'Información de Empleado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildDetailRow('Salario:', '\$${user.employeeProfile['salary'] ?? '0'}'),
                _buildDetailRow('Límite Adelanto:', '\$${user.employeeProfile['available_advance_limit'] ?? '0'}'),
                _buildDetailRow('Cuenta Bancaria:', user.employeeProfile['bank_account'] ?? 'N/A'),
                _buildDetailRow('Banco:', user.employeeProfile['bank_name'] ?? 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
