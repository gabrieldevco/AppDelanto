import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../widgets/employer_bottom_nav.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_notifications_drawer.dart';
import 'employer_requests_page.dart';

class EmployerMainPage extends StatefulWidget {
  const EmployerMainPage({super.key});

  @override
  State<EmployerMainPage> createState() => _EmployerMainPageState();
}

class _EmployerMainPageState extends State<EmployerMainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final companyProvider = context.read<CompanyProvider>();
    final advanceProvider = context.read<AdvanceProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    await companyProvider.loadMyCompany();
    await Future.wait([
      companyProvider.loadEmployees(active: true),
      companyProvider.loadSummary(),
      advanceProvider.loadMyAdvances(),
    ]);
    await notificationProvider.refreshUnreadCount();
    if (mounted) setState(() {});
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
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Consumer2<CompanyProvider, AdvanceProvider>(
                  builder: (context, companyProvider, advanceProvider, _) {
                    final advances = [...advanceProvider.advances]
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final employees = companyProvider.activeEmployees;
                    final isLoading =
                        companyProvider.isLoading || advanceProvider.isLoading;

                    if (isLoading && advances.isEmpty && employees.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final totalAdvanced = advances
                        .where(_countsForTotalAdvanced)
                        .fold<double>(0, (sum, a) => sum + a.amount);
                    final pendingDiscount = advances
                        .where(_countsAsPendingDiscount)
                        .fold<double>(0, (sum, a) => sum + a.amount);

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Panel de Control',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gestiona los adelantos de tus empleados',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildMetricsCards(
                          employeeCount: employees.length,
                          totalAdvanced: totalAdvanced,
                          pendingDiscount: pendingDiscount,
                          requestCount: advances.length,
                        ),
                        const SizedBox(height: 22),
                        _buildRecentRequests(advances.take(3).toList()),
                        const SizedBox(height: 22),
                        _buildImportantInfo(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const EmployerBottomNav(currentIndex: 0),
    );
  }

  Widget _buildMetricsCards({
    required int employeeCount,
    required double totalAdvanced,
    required double pendingDiscount,
    required int requestCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Empleados',
                value: employeeCount.toString(),
                icon: Icons.people,
                bgColor: const Color(0xFF2563EB),
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Adelantado',
                value: _money(totalAdvanced),
                icon: Icons.attach_money,
                bgColor: const Color(0xFF059669),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Pendiente descuento',
                value: _money(pendingDiscount),
                icon: Icons.trending_up,
                bgColor: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total solicitudes',
                value: requestCount.toString(),
                icon: Icons.receipt_long,
                bgColor: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    Color? textColor,
    Color? iconColor,
  }) {
    final titleColor = textColor ?? const Color(0xFF4B5563);
    final valueColor = textColor ?? const Color(0xFF111827);
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor ?? textColor ?? Colors.white, size: 23),
          Text(title, style: TextStyle(fontSize: 12, color: titleColor)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRequests(List<AdvanceModel> advances) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solicitudes recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployerRequestsPage(),
                    ),
                  );
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (advances.isEmpty)
            _buildEmptyLine('Aún no hay solicitudes registradas')
          else
            ...advances.map(_buildRequestCard),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AdvanceModel advance) {
    final color = _statusColor(advance.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advance.employeeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _shortDate(advance.requestDate),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  advance.statusDisplay.toLowerCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _money(advance.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildImportantInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        'El empleador actúa como intermediario operativo y responsable del descuento en nómina. Fee e interés pertenecen a la plataforma.',
        style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'approved' => const Color(0xFF2563EB),
      'disbursed' || 'recovered' => const Color(0xFF059669),
      'rejected' || 'cancelled' => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };
  }

  bool _countsForTotalAdvanced(AdvanceModel advance) {
    return advance.isApproved || advance.isDisbursed || advance.isRecovered;
  }

  bool _countsAsPendingDiscount(AdvanceModel advance) {
    return advance.isApproved || advance.isDisbursed;
  }

  String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _money(num value) {
    final text = value.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$ $text';
  }
}
