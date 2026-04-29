import 'package:flutter/material.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_bottom_nav.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_header.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_notifications_drawer.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _employees = [];
  List<dynamic> _employers = [];
  bool _loadingEmployees = false;
  bool _loadingEmployers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadEmployees(), _loadEmployers()]);
  }

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final response = await apiService.get(
        ApiConstants.adminUserManagement,
        queryParameters: {'role': 'employee'},
      );
      if (mounted) setState(() => _employees = _extractList(response));
    } catch (_) {
      _showSnack('Error al cargar empleados', isError: true);
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _loadEmployers() async {
    setState(() => _loadingEmployers = true);
    try {
      final response = await apiService.get(
        ApiConstants.adminUserManagement,
        queryParameters: {'role': 'employer'},
      );
      if (mounted) setState(() => _employers = _extractList(response));
    } catch (_) {
      _showSnack('Error al cargar empleadores', isError: true);
    } finally {
      if (mounted) setState(() => _loadingEmployers = false);
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['results'] ?? response['data'] ?? response['users'];
      if (data is List) return data;
    }
    return <dynamic>[];
  }

  Future<void> _verifyCompany(int companyId, bool verify) async {
    try {
      await apiService.patch(
        '/api/companies/$companyId/verify/',
        data: {'is_verified': verify},
      );
      _showSnack(verify ? 'Empresa verificada' : 'Verificacion removida');
      await _loadEmployers();
    } catch (_) {
      _showSnack('Error al verificar empresa', isError: true);
    }
  }

  Future<void> _viewPdf(String pdfUrl) async {
    _showSnack('Funcion PDF en desarrollo');
  }

  Future<void> _deleteCompany(int companyId) async {
    try {
      await apiService.delete('/api/companies/$companyId/');
      _showSnack('Empresa eliminada');
      await _loadEmployers();
    } catch (_) {
      _showSnack('Error al eliminar empresa', isError: true);
    }
  }

  Future<void> _deleteUser(int userId, String userType) async {
    try {
      await apiService.delete('/api/users/$userId/');
      _showSnack('$userType eliminado');
      await _loadData();
    } catch (_) {
      _showSnack('Error al eliminar $userType', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
      ),
    );
  }

  void _showDeleteConfirmation(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const AdminHeader(),
            _buildUserManagementHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildEmployeesList(), _buildEmployersList()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
    );
  }

  Widget _buildUserManagementHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.manage_accounts,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion de Usuarios',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Administra empleados y empleadores',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              labelColor: const Color(0xFF111827),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                _buildTab(Icons.people_outline, 'Empleados', _employees.length),
                _buildTab(
                  Icons.business_outlined,
                  'Empleadores',
                  _employers.length,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    if (_loadingEmployees) return _buildLoading();
    if (_employees.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No hay empleados registrados',
        subtitle: 'Cuando se registren empleados apareceran aqui.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: _employees.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return _buildEmployeeCard(
            name:
                '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}',
            email: employee['email'] ?? '',
            document: employee['document_number'] ?? '',
            userId: employee['id'],
          );
        },
      ),
    );
  }

  Widget _buildEmployersList() {
    if (_loadingEmployers) return _buildLoading();
    if (_employers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.business_outlined,
        title: 'No hay empleadores registrados',
        subtitle: 'Las empresas registradas apareceran en esta lista.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: _employers.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final employer = _employers[index];
          final company = employer['company'];
          final isVerified = company?['is_verified'] ?? false;
          final pdfUrl =
              company?['chamber_of_commerce_document_url'] ??
              company?['chamber_of_commerce_document'];

          return _buildEmployerCard(
            name:
                '${employer['first_name'] ?? ''} ${employer['last_name'] ?? ''}',
            email: employer['email'] ?? '',
            document: employer['document_number'] ?? '',
            companyName: company?['name'],
            companyId: company?['id'],
            userId: employer['id'],
            isVerified: isVerified,
            pdfUrl: pdfUrl,
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard({
    required String name,
    required String email,
    required String document,
    required int userId,
  }) {
    final displayName = name.trim().isEmpty ? 'Sin nombre' : name.trim();
    return _userCard(
      accentColor: const Color(0xFF059669),
      icon: Icons.person,
      title: displayName,
      subtitle: email,
      meta: document.isEmpty ? null : 'CC: $document',
      trailing: _deleteButton(
        tooltip: 'Eliminar empleado',
        onPressed: () => _showDeleteConfirmation(
          'Eliminar empleado',
          'Seguro que deseas eliminar a $displayName? Esta accion no se puede deshacer.',
          () => _deleteUser(userId, 'Empleado'),
        ),
      ),
    );
  }

  Widget _buildEmployerCard({
    required String name,
    required String email,
    required String document,
    String? companyName,
    int? companyId,
    required int userId,
    required bool isVerified,
    String? pdfUrl,
  }) {
    final displayName = name.trim().isEmpty ? 'Sin nombre' : name.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: isVerified
            ? const Color(0xFF86EFAC)
            : const Color(0xFFE5E7EB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(const Color(0xFF2563EB), Icons.business),
              const SizedBox(width: 12),
              Expanded(child: _identity(displayName, email, document)),
              _statusBadge(isVerified),
            ],
          ),
          if (companyName != null) ...[
            const SizedBox(height: 14),
            _companyPill(companyName),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pdfUrl != null)
                _softAction(
                  icon: Icons.picture_as_pdf,
                  label: 'Ver PDF',
                  color: const Color(0xFFDC2626),
                  onPressed: () => _viewPdf(pdfUrl),
                ),
              if (companyId != null)
                _softAction(
                  icon: isVerified
                      ? Icons.remove_circle_outline
                      : Icons.verified,
                  label: isVerified ? 'Quitar verificacion' : 'Verificar',
                  color: isVerified
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF059669),
                  onPressed: () => _verifyCompany(companyId, !isVerified),
                ),
              _softAction(
                icon: Icons.person_remove,
                label: 'Eliminar usuario',
                color: const Color(0xFFDC2626),
                onPressed: () => _showDeleteConfirmation(
                  'Eliminar empleador',
                  'Seguro que deseas eliminar a $displayName? Esta accion no se puede deshacer.',
                  () => _deleteUser(userId, 'Empleador'),
                ),
              ),
              if (companyId != null)
                _softAction(
                  icon: Icons.delete_outline,
                  label: 'Eliminar empresa',
                  color: const Color(0xFFDC2626),
                  onPressed: () => _showDeleteConfirmation(
                    'Eliminar empresa',
                    'Seguro que deseas eliminar esta empresa? Esta accion no se puede deshacer.',
                    () => _deleteCompany(companyId),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userCard({
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
    String? meta,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _avatar(accentColor, icon),
          const SizedBox(width: 12),
          Expanded(child: _identity(title, subtitle, meta ?? '')),
          ?trailing,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({Color borderColor = const Color(0xFFE5E7EB)}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  Widget _avatar(Color color, IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }

  Widget _identity(String title, String subtitle, String meta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }

  Widget _deleteButton({
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFFEE2E2),
        foregroundColor: const Color(0xFFDC2626),
      ),
      icon: const Icon(Icons.delete_outline),
    );
  }

  Widget _statusBadge(bool isVerified) {
    final color = isVerified
        ? const Color(0xFF059669)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.pending,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verificado' : 'Pendiente',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyPill(String companyName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              companyName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        backgroundColor: color.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
