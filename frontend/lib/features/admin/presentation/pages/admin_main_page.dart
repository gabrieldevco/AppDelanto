import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_notifications_drawer.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.dashboardStats ?? <String, dynamic>{};
    final advances = stats['advances'] is Map<String, dynamic>
        ? stats['advances'] as Map<String, dynamic>
        : <String, dynamic>{};
    final users = stats['users'] is Map<String, dynamic>
        ? stats['users'] as Map<String, dynamic>
        : <String, dynamic>{};
    final earnings = stats['earnings'] is Map<String, dynamic>
        ? stats['earnings'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<AdminProvider>().loadDashboardStats(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminHeader(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panel Administrador',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Monitorea la plataforma de adelantos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatsCard(
                              title: 'Desembolsado',
                              amount: _formatCurrency(
                                advances['total_disbursed'],
                              ),
                              icon: Icons.attach_money,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatsCard(
                              title: 'Recuperado',
                              amount: _formatCurrency(
                                advances['total_recovered'],
                              ),
                              subtitle: _recoveryPercentage(advances),
                              icon: Icons.trending_up,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (adminProvider.isLoading && stats.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (adminProvider.error != null && stats.isEmpty)
                        _buildErrorCard(adminProvider.error!)
                      else
                        _buildEarningsCard(earnings),
                      const SizedBox(height: 16),
                      _buildChartCard(stats),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCountCard(
                              title: 'Empleadores',
                              count: '${_toInt(users['employers'])}',
                              icon: Icons.business,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCountCard(
                              title: 'Empleados',
                              count: '${_toInt(users['employees'])}',
                              icon: Icons.people,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String amount,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(Map<String, dynamic> earnings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Ganancias de la Plataforma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total ganancias',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(earnings['total']),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fee',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(earnings['fees']),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Intereses',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(earnings['interest']),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Map<String, dynamic> stats) {
    final monthly = stats['monthly'] is List
        ? stats['monthly'] as List
        : const [];
    final maxValue = monthly.fold<double>(0, (max, item) {
      if (item is! Map) return max;
      final disbursed = _toDouble(item['disbursed']);
      final recovered = _toDouble(item['recovered']);
      return [max, disbursed, recovered].reduce((a, b) => a > b ? a : b);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desembolsos vs Recuperación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribución últimos meses',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (monthly.isEmpty || maxValue <= 0)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Sin movimientos recientes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  )
                else
                  ...monthly.map((item) {
                    final data = item is Map ? item : const {};
                    final disbursed = _toDouble(data['disbursed']);
                    final recovered = _toDouble(data['recovered']);
                    final safeMax = maxValue <= 0 ? 1 : maxValue;
                    return _buildBarGroup(
                      context,
                      '${data['label'] ?? ''}',
                      (disbursed / safeMax).clamp(0.05, 1).toDouble(),
                      (recovered / safeMax).clamp(0.05, 1).toDouble(),
                      disbursed,
                      recovered,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarGroup(
    BuildContext context,
    String label,
    double height1,
    double height2,
    double desembolsado,
    double recuperado,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Barras con valores encima
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Barra verde con valor encima
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatCompactNumber(desembolsado),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 100 * height1,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // Barra azul con valor encima
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatCompactNumber(recuperado),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 100 * height2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  String _formatCompactNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) => _toDouble(value).round();

  String _formatCurrency(dynamic value) {
    final amount = _toDouble(value).round();
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '\$ $formatted';
  }

  String _recoveryPercentage(Map<String, dynamic> advances) {
    final disbursed = _toDouble(advances['total_disbursed']);
    final recovered = _toDouble(advances['total_recovered']);
    if (disbursed <= 0) return '0%';
    return '${((recovered / disbursed) * 100).toStringAsFixed(1)}%';
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        error,
        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Franjas de desembolso:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• 06:00 - 12:00 → Procesamiento a las 13:00',
            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
          ),
          const Text(
            '• 12:01 - 17:00 → Procesamiento a las 18:00',
            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF059669),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Modelo de ganancias:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Fee por transacción (principal ingreso)',
            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
          ),
          const Text(
            '• Interés 2.5% mensual proporcional',
            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
          ),
          const Text(
            '• 100% de ganancias para la plataforma',
            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }
}
