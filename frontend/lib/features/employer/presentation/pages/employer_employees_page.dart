import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../../../companies/data/models/company_model.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../widgets/employer_bottom_nav.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_notifications_drawer.dart';

class EmployerEmployeesPage extends StatefulWidget {
  const EmployerEmployeesPage({super.key});

  @override
  State<EmployerEmployeesPage> createState() => _EmployerEmployeesPageState();
}

class _EmployerEmployeesPageState extends State<EmployerEmployeesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
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
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const EmployerNotificationsDrawer(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const EmployerHeader(),
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
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total empleados',
                                value: allEmployees.length.toString(),
                                bgColor: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Nómina total',
                                value: _money(payroll),
                                bgColor: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMonthlyProgress(monthTotal, maxAvailable),
                        const SizedBox(height: 16),
                        _buildSearch(),
                        const SizedBox(height: 16),
                        if (employees.isEmpty)
                          _buildEmpty()
                        else
                          ...employees.map(
                            (employee) => _buildEmployeeCard(
                              employee,
                              _employeeActiveAdvance(employee, advanceProvider),
                              _employeeMonthTotal(employee, advanceProvider),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

  Widget _buildMonthlyProgress(double monthTotal, double maxAvailable) {
    final progress = maxAvailable <= 0
        ? 0.0
        : (monthTotal / maxAvailable).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
              minHeight: 8,
            ),
          ),
        ],
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
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: Color(0xFF2563EB),
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
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  'Banco',
                  '${employee.bankName?.isNotEmpty == true ? employee.bankName : 'Sin banco'}\n$account',
                  const Color(0xFFDBEAFE),
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
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(
                percentage > 0.8
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF2563EB),
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
              color: const Color(0xFFFFF7ED),
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

  Widget _infoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
