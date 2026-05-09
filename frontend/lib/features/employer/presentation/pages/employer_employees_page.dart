import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../../../companies/data/models/company_model.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../widgets/employer_bottom_nav.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_notifications_drawer.dart';
import 'employer_create_employee_page.dart';

class EmployerEmployeesPage extends StatefulWidget {
  const EmployerEmployeesPage({super.key});

  @override
  State<EmployerEmployeesPage> createState() => _EmployerEmployeesPageState();
}

class _EmployerEmployeesPageState extends State<EmployerEmployeesPage> {
  static const int _employeesPerPage = 3;

  final _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _currentPage = 0;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final companyProvider = context.read<CompanyProvider>();
    final advanceProvider = context.read<AdvanceProvider>();
    await companyProvider.loadMyCompany();
    await Future.wait([
      companyProvider.loadEmployees(active: true),
      advanceProvider.loadMyAdvances(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const EmployerNotificationsDrawer(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const EmployerHeader(currentIndex: 2),
            Expanded(
              child: Consumer2<CompanyProvider, AdvanceProvider>(
                builder: (context, companyProvider, advanceProvider, _) {
                  final employees = companyProvider.activeEmployees.where((e) {
                    if (_query.isEmpty) return true;
                    return e.name.toLowerCase().contains(_query) ||
                        (e.documentNumber ?? '').toLowerCase().contains(
                          _query,
                        ) ||
                        e.email.toLowerCase().contains(_query);
                  }).toList();
                  final totalPages = (employees.length / _employeesPerPage)
                      .ceil()
                      .clamp(1, 999);
                  if (_currentPage >= totalPages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _currentPage = totalPages - 1);
                      }
                    });
                  }
                  final safePage = _currentPage.clamp(0, totalPages - 1);
                  final pageStart = safePage * _employeesPerPage;
                  final pageEnd = (pageStart + _employeesPerPage).clamp(
                    0,
                    employees.length,
                  );
                  final visibleEmployees = employees.sublist(
                    pageStart,
                    pageEnd,
                  );

                  final allEmployees = companyProvider.activeEmployees;
                  final payroll = allEmployees.fold<double>(
                    0,
                    (sum, e) => sum + e.salary,
                  );
                  final monthTotal = advanceProvider.advances
                      .where(
                        (a) =>
                            a.createdAt.month == DateTime.now().month &&
                            a.createdAt.year == DateTime.now().year &&
                            _countsForMonthlyTotal(a),
                      )
                      .fold<double>(0, (sum, a) => sum + a.amount);
                  final maxAvailable = allEmployees.fold<double>(
                    0,
                    (sum, e) => sum + (e.salary * 0.5),
                  );

                  if (companyProvider.isLoading && allEmployees.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Empleados',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gestiona tu equipo de trabajo',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTeamHero(
                          employeeCount: allEmployees.length,
                          payroll: payroll,
                          monthTotal: monthTotal,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total empleados',
                                value: allEmployees.length.toString(),
                                bgColor: const Color(0xFF047857),
                                icon: Icons.groups_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Nómina total',
                                value: _money(payroll),
                                bgColor: const Color(0xFF0F766E),
                                icon: Icons.account_balance_wallet_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMonthlyProgress(monthTotal, maxAvailable),
                        const SizedBox(height: 16),
                        _buildSearch(),
                        const SizedBox(height: 12),
                        _buildAddEmployeeButton(),
                        const SizedBox(height: 16),
                        if (employees.isEmpty)
                          _buildEmpty()
                        else ...[
                          ...visibleEmployees.map(
                            (employee) => _buildEmployeeCard(
                              employee,
                              _employeeActiveAdvance(employee, advanceProvider),
                              _employeeMonthTotal(employee, advanceProvider),
                            ),
                          ),
                          if (employees.length > _employeesPerPage)
                            _buildPagination(
                              currentPage: safePage,
                              totalPages: totalPages,
                              totalItems: employees.length,
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const EmployerBottomNav(currentIndex: 2),
    );
  }

  double _employeeMonthTotal(EmployeeModel employee, AdvanceProvider provider) {
    return provider.advances
        .where(
          (a) =>
              a.employeeId == employee.id &&
              a.createdAt.month == DateTime.now().month &&
              a.createdAt.year == DateTime.now().year &&
              _countsForMonthlyTotal(a),
        )
        .fold<double>(0, (sum, a) => sum + a.amount);
  }

  double _employeeActiveAdvance(
    EmployeeModel employee,
    AdvanceProvider provider,
  ) {
    return provider.advances
        .where((a) => a.employeeId == employee.id && _countsAsUsed(a))
        .fold<double>(0, (sum, a) => sum + a.amount);
  }

  bool _countsForMonthlyTotal(AdvanceModel advance) {
    return advance.isApproved || advance.isDisbursed || advance.isRecovered;
  }

  bool _countsAsUsed(AdvanceModel advance) {
    return advance.isApproved || advance.isDisbursed;
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, Color.lerp(bgColor, Colors.black, 0.14)!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHero({
    required int employeeCount,
    required double payroll,
    required double monthTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(Icons.badge_outlined, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$employeeCount activos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Equipo y nomina',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Controla cupos, salarios y adelantos mensuales con una vista clara.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _heroPill('Nomina', _money(payroll))),
              const SizedBox(width: 10),
              Expanded(child: _heroPill('Adelantado', _money(monthTotal))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA7F3D0)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgress(double monthTotal, double maxAvailable) {
    final progress = maxAvailable <= 0
        ? 0.0
        : (monthTotal / maxAvailable).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Adelantado este mes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                _money(monthTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEmployeeButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const EmployerCreateEmployeePage(),
            ),
          );
          if (created == true && mounted) {
            await _load();
            if (!mounted) return;
            await AppPopup.show(
              context,
              title: 'Empleado creado',
              message: 'Se enviaron las credenciales de acceso al correo.',
              type: AppPopupType.success,
            );
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Registrar empleado'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF047857),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, correo o cédula...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA7F3D0)),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
    EmployeeModel employee,
    double activeAdvance,
    double monthTotal,
  ) {
    final maxLimit = employee.salary * 0.5;
    final used = activeAdvance.clamp(0.0, maxLimit);
    final available = (maxLimit - used).clamp(0.0, maxLimit);
    final percentage = maxLimit <= 0 ? 0.0 : (used / maxLimit).clamp(0.0, 1.0);
    final document = employee.documentNumber?.isNotEmpty == true
        ? employee.documentNumber!
        : 'Sin cédula';
    final account = employee.bankAccount?.isNotEmpty == true
        ? '****${employee.bankAccount!.substring(employee.bankAccount!.length > 4 ? employee.bankAccount!.length - 4 : 0)}'
        : 'Sin cuenta';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF047857), Color(0xFF14B8A6)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'CC: $document',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Despedir empleado',
                onPressed: () => _confirmDismissEmployee(employee),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoBox(
                  'Salario',
                  _money(employee.salary),
                  const Color(0xFFECFDF5),
                  trailing: IconButton(
                    tooltip: 'Editar salario',
                    onPressed: () => _editSalary(employee),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  'Banco',
                  '${employee.bankName?.isNotEmpty == true ? employee.bankName : 'Sin banco'}\n$account',
                  const Color(0xFFF0FDFA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Adelanto actual',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                _money(used),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                percentage > 0.8
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF10B981),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponible: ${_money(available)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                '${(percentage * 100).round()}% usado',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFFEDD5)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Color(0xFFEA580C),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total mes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Text(
                  _money(monthTotal),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required int totalItems,
  }) {
    final canGoBack = currentPage > 0;
    final canGoNext = currentPage < totalPages - 1;

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _paginationButton(
            icon: Icons.chevron_left,
            enabled: canGoBack,
            onPressed: () => setState(() => _currentPage--),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Pagina ${currentPage + 1} de $totalPages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalItems empleados',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _paginationButton(
            icon: Icons.chevron_right,
            enabled: canGoNext,
            onPressed: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 22),
      color: const Color(0xFF047857),
      disabledColor: const Color(0xFFCBD5E1),
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xFFECFDF5)
            : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(42, 42),
      ),
    );
  }

  Widget _infoBox(
    String label,
    String value,
    Color color, {
    Widget trailing = const SizedBox.shrink(),
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDismissEmployee(EmployeeModel employee) async {
    final confirmed = await AppPopup.confirm(
      context,
      title: 'Confirmar despido',
      message:
          '¿Esta seguro que quiere despedir al empleado ${employee.name} con salario ${_money(employee.salary)}?',
      type: AppPopupType.warning,
      primaryLabel: 'Si, despedir',
      secondaryLabel: 'Cancelar',
    );
    if (!confirmed || !mounted) return;

    final companyProvider = context.read<CompanyProvider>();
    final ok = await companyProvider.removeEmployee(employee.id);
    if (!mounted) return;
    if (ok) {
      await _load();
      if (!mounted) return;
      await AppPopup.show(
        context,
        title: 'Empleado despedido',
        message: '${employee.name} fue retirado del equipo.',
        type: AppPopupType.success,
      );
      return;
    }
    await AppPopup.show(
      context,
      title: 'No se pudo despedir',
      message:
          companyProvider.errorMessage ??
          'No fue posible despedir al empleado.',
      type: AppPopupType.error,
    );
  }

  Future<void> _editSalary(EmployeeModel employee) async {
    final controller = TextEditingController(
      text: employee.salary.round().toString(),
    );
    final newSalary = await _showSalaryEditor(employee, controller);
    if (newSalary == null || newSalary <= 0 || !mounted) return;

    final confirmed = await AppPopup.confirm(
      context,
      title: 'Confirmar cambio',
      message:
          '¿Deseas actualizar el salario de ${employee.name} a ${_money(newSalary)}?',
      type: AppPopupType.info,
      primaryLabel: 'Si, actualizar',
      secondaryLabel: 'Cancelar',
    );
    if (!confirmed || !mounted) return;

    final companyProvider = context.read<CompanyProvider>();
    final ok = await companyProvider.updateEmployee(
      employee.id,
      salary: newSalary,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
      if (!mounted) return;
      await AppPopup.show(
        context,
        title: 'Salario actualizado',
        message: '${employee.name} ahora tiene salario ${_money(newSalary)}.',
        type: AppPopupType.success,
      );
      return;
    }
    await AppPopup.show(
      context,
      title: 'No se pudo actualizar',
      message:
          companyProvider.errorMessage ?? 'No fue posible guardar el salario.',
      type: AppPopupType.error,
    );
  }

  Future<double?> _showSalaryEditor(
    EmployeeModel employee,
    TextEditingController controller,
  ) {
    return showGeneralDialog<double>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.36),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              constraints: const BoxConstraints(maxWidth: 390),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.22),
                    blurRadius: 34,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF064E3B),
                            Color(0xFF059669),
                            Color(0xFF14B8A6),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Modificar salario',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  employee.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payments_outlined,
                                  color: Color(0xFF047857),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Salario actual',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _money(employee.salary),
                                        style: const TextStyle(
                                          color: Color(0xFF111827),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Nuevo salario',
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w900,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final parsed = double.tryParse(
                                      controller.text
                                          .replaceAll('.', '')
                                          .replaceAll(',', ''),
                                    );
                                    Navigator.pop(dialogContext, parsed);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047857),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continuar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.only(top: 96),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No hay empleados para mostrar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _money(num value) {
    final text = value.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$ $text';
  }
}
