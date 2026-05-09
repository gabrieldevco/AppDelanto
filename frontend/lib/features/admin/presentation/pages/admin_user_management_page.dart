import 'package:flutter/material.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/widgets/app_popup.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_bottom_nav.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_header.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_notifications_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _verifyCompany(
    int companyId,
    bool verify, {
    Map<String, dynamic>? company,
  }) async {
    try {
      await apiService.patch(
        '/api/companies/$companyId/verify/',
        data: {'is_verified': verify},
      );
      if (!mounted) return;
      await AppPopup.show(
        context,
        title: verify ? 'Empresa verificada' : 'Verificacion removida',
        message: verify
            ? 'Felicidades, tu empresa esta verificada.'
            : 'La empresa quedo pendiente de verificacion.',
        type: verify ? AppPopupType.success : AppPopupType.undo,
      );
      await _loadEmployers();
    } catch (e) {
      if (!mounted) return;
      await AppPopup.show(
        context,
        title: 'Error al verificar empresa',
        message: _friendlyError(e),
        type: AppPopupType.error,
      );
    }
  }

  Future<void> _preapproveCompany(int companyId) async {
    try {
      await apiService.post('/api/companies/$companyId/preapprove/');
      if (!mounted) return;
      await AppPopup.show(
        context,
        title: 'Empresa preaprobada',
        message:
            'El empleador ya puede ingresar para descargar y adjuntar el contrato firmado.',
        type: AppPopupType.success,
      );
      await _loadEmployers();
    } catch (e) {
      if (!mounted) return;
      await AppPopup.show(
        context,
        title: 'No se pudo preaprobar',
        message: _friendlyError(e),
        type: AppPopupType.error,
      );
    }
  }

  Future<void> _openDocument(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = _documentUri(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _showSnack('No se pudo abrir el documento', isError: true);
      }
    } catch (e) {
      _showSnack('Error al abrir documento: $e', isError: true);
    }
  }

  Uri _documentUri(String url) {
    final parsed = Uri.parse(url);
    final base = Uri.parse(ApiConstants.baseUrl);

    if (!parsed.hasScheme) {
      return base.resolve(url);
    }

    if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
      return parsed.replace(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
      );
    }

    return parsed;
  }

  Future<void> _showDocumentation(Map<String, dynamic>? company) async {
    if (company == null) return;
    Map<String, dynamic> companyData = company;
    final companyId = company['id'];

    if (companyId != null) {
      try {
        final response = await apiService.get('/api/companies/$companyId/');
        if (response is Map<String, dynamic>) {
          companyData = response;
        }
      } catch (_) {
        _showSnack('No se pudo actualizar la documentacion', isError: true);
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EmployerDocumentationPage(
          companyName: companyData['name'] ?? 'Empresa',
          documents: [
            _EmployerDocument(
              title: 'RUT',
              url:
                  companyData['rut_document_url'] ??
                  companyData['rut_document'],
            ),
            _EmployerDocument(
              title: 'Camara de Comercio',
              url:
                  companyData['chamber_of_commerce_document_url'] ??
                  companyData['chamber_of_commerce_document'],
            ),
            _EmployerDocument(
              title: 'Copia cedula representante legal',
              url:
                  companyData['legal_representative_id_document_url'] ??
                  companyData['legal_representative_id_document'],
            ),
            _EmployerDocument(
              title: 'Extractos bancarios ultimos 3 meses',
              url:
                  companyData['bank_statements_document_url'] ??
                  companyData['bank_statements_document'],
            ),
            _EmployerDocument(
              title: 'Contrato firmado AppDelanta',
              url:
                  companyData['platform_contract_file_url'] ??
                  companyData['platform_contract_file'],
              highlight:
                  companyData['platform_contract_file_url'] != null ||
                  companyData['platform_contract_file'] != null,
            ),
            _EmployerDocument(
              title: 'Volante de suscripcion',
              url:
                  companyData['subscription_receipt_file_url'] ??
                  companyData['subscription_receipt_file'],
              highlight:
                  companyData['subscription_receipt_file_url'] != null ||
                  companyData['subscription_receipt_file'] != null,
            ),
          ],
          onOpen: _openDocument,
        ),
      ),
    );
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
    AppPopup.show(
      context,
      title: message,
      message: isError
          ? 'Revisa el detalle e intenta nuevamente.'
          : 'La accion se completo correctamente.',
      type: isError ? AppPopupType.error : AppPopupType.success,
    );
  }

  String _friendlyError(Object error) {
    if (error is ApiException) return error.message;

    var message = error.toString();
    for (final prefix in ['ApiException: ', 'Exception: ']) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length);
      }
    }
    if (message.contains(' (Status:')) {
      message = message.split(' (Status:').first;
    }
    return message.trim().isEmpty ? 'Intenta nuevamente.' : message;
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
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const AdminHeader(currentIndex: 1),
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
      decoration: const BoxDecoration(color: Color(0xFFF6F8FB)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.manage_accounts, color: Colors.white),
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
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9D5FF)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              labelColor: Colors.white,
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
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7C3AED),
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
          final isPreapproved = company?['is_preapproved'] ?? false;
          final hasPendingDocs =
              ((company?['platform_contract_file_url'] ??
                          company?['platform_contract_file']) !=
                      null ||
                  (company?['subscription_receipt_file_url'] ??
                          company?['subscription_receipt_file']) !=
                      null) &&
              !isVerified;
          return _buildEmployerCard(
            name:
                '${employer['first_name'] ?? ''} ${employer['last_name'] ?? ''}',
            email: employer['email'] ?? '',
            document: employer['document_number'] ?? '',
            companyName: company?['name'],
            companyId: company?['id'],
            userId: employer['id'],
            isVerified: isVerified,
            isPreapproved: isPreapproved,
            hasNewContract: hasPendingDocs,
            company: company,
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
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
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF7C3AED)),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
      accentColor: const Color(0xFF0D9488),
      icon: Icons.person,
      title: displayName,
      subtitle: email,
      meta: document.isEmpty ? null : 'CC: $document',
      badgeLabel: 'Empleado',
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
    required bool isPreapproved,
    required bool hasNewContract,
    Map<String, dynamic>? company,
  }) {
    final displayName = name.trim().isEmpty ? 'Sin nombre' : name.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        borderColor: isVerified
            ? const Color(0xFF86EFAC)
            : const Color(0xFFE2E8F0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(const Color(0xFF7C3AED), Icons.business),
              const SizedBox(width: 12),
              Expanded(child: _identity(displayName, email, '')),
              _statusBadge(isVerified, isPreapproved),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(
                icon: Icons.work_outline,
                label: 'Empleador',
                color: const Color(0xFF7C3AED),
              ),
              if (document.isNotEmpty)
                _metaChip(
                  icon: Icons.badge_outlined,
                  label: 'CC: $document',
                  color: const Color(0xFF64748B),
                ),
              if (companyName != null) _companyPill(companyName),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (company != null)
                _softAction(
                  icon: Icons.folder_open_outlined,
                  label: 'Ver documentacion',
                  color: const Color(0xFF7C3AED),
                  showDot: hasNewContract,
                  onPressed: () => _showDocumentation(company),
                ),
              if (companyId != null && !isVerified && !isPreapproved)
                _softAction(
                  icon: Icons.verified_user_outlined,
                  label: 'Preaprobar',
                  color: const Color(0xFF0D9488),
                  onPressed: () => _preapproveCompany(companyId),
                ),
              if (companyId != null && (isVerified || isPreapproved))
                _softAction(
                  icon: isVerified
                      ? Icons.remove_circle_outline
                      : Icons.verified,
                  label: isVerified ? 'Quitar verificacion' : 'Verificar',
                  color: isVerified
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF0D9488),
                  onPressed: () =>
                      _verifyCompany(companyId, !isVerified, company: company),
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
    String? badgeLabel,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(accentColor, icon),
              const SizedBox(width: 12),
              Expanded(child: _identity(title, subtitle, '')),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
          if (badgeLabel != null || (meta != null && meta.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (badgeLabel != null)
                  _metaChip(
                    icon: Icons.group_outlined,
                    label: badgeLabel,
                    color: accentColor,
                  ),
                if (meta != null && meta.isNotEmpty)
                  _metaChip(
                    icon: Icons.badge_outlined,
                    label: meta,
                    color: const Color(0xFF64748B),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({Color borderColor = const Color(0xFFE2E8F0)}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 14,
          offset: Offset(0, 7),
        ),
      ],
    );
  }

  Widget _avatar(Color color, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }

  Widget _statusBadge(bool isVerified, bool isPreapproved) {
    final color = isVerified
        ? const Color(0xFF0D9488)
        : isPreapproved
        ? const Color(0xFF2563EB)
        : const Color(0xFFF59E0B);
    final label = isVerified
        ? 'Verificado'
        : isPreapproved
        ? 'Preaprobado'
        : 'Pendiente';
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
            isVerified
                ? Icons.verified
                : isPreapproved
                ? Icons.verified_user_outlined
                : Icons.pending,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
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

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyPill(String companyName) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
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
    bool showDot = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 17),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.35)),
            backgroundColor: color.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmployerDocument {
  final String title;
  final String? url;
  final bool highlight;

  const _EmployerDocument({
    required this.title,
    this.url,
    this.highlight = false,
  });

  bool get hasFile => url != null && url!.isNotEmpty;
}

class _EmployerDocumentationPage extends StatelessWidget {
  final String companyName;
  final List<_EmployerDocument> documents;
  final Future<void> Function(String? url) onOpen;

  const _EmployerDocumentationPage({
    required this.companyName,
    required this.documents,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final availableCount = documents.where((doc) => doc.hasFile).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: const Color(0xFF111827),
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.folder_copy_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Documentacion del empleador',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$availableCount de ${documents.length} documentos disponibles',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: documents.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final document = documents[index];
                  final accent = document.hasFile
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF94A3B8);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: document.highlight
                            ? const Color(0xFFDC2626)
                            : document.hasFile
                            ? const Color(0xFFE9D5FF)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Icon(
                            document.hasFile
                                ? Icons.description_outlined
                                : Icons.insert_drive_file_outlined,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              if (document.highlight) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Nuevo contrato por revisar',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: document.hasFile
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  document.hasFile ? 'Disponible' : 'Pendiente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: document.hasFile
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: document.hasFile
                                ? () => onOpen(document.url)
                                : null,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Ver'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              disabledForegroundColor: const Color(0xFFCBD5E1),
                              backgroundColor: document.hasFile
                                  ? const Color(0xFFF5F3FF)
                                  : const Color(0xFFF8FAFC),
                              side: BorderSide(
                                color: document.hasFile
                                    ? const Color(0xFFD8B4FE)
                                    : const Color(0xFFE2E8F0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
