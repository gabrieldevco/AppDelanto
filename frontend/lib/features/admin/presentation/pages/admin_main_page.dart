import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/responsive_utils.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdminHome());
  }

  Future<void> _loadAdminHome() async {
    final provider = context.read<AdminProvider>();
    await Future.wait([provider.loadDashboardStats(), provider.loadSettings()]);
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
    final settings = adminProvider.settings ?? <String, dynamic>{};

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAdminHome,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminHeader(currentIndex: 0),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getHorizontalPadding(
                          context,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroAdminCard(advances, users, settings),
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
                                  color: const Color(0xFFDC2626),
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
                                  color: const Color(0xFF10B981),
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
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCountCard(
                                  title: 'Empleados',
                                  count: '${_toInt(users['employees'])}',
                                  icon: Icons.people,
                                  color: const Color(0xFF0D9488),
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

  Widget _buildHeroAdminCard(
    Map<String, dynamic> advances,
    Map<String, dynamic> users,
    Map<String, dynamic> settings,
  ) {
    final totalUsers = _toInt(users['employees']) + _toInt(users['employers']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalUsers usuarios',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Panel Administrador',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vista ejecutiva de operaciones, usuarios y rentabilidad.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFFEDE9FE),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _buildCapitalHeroMetric(settings),
        ],
      ),
    );
  }

  Widget _buildCapitalHeroMetric(Map<String, dynamic> settings) {
    final capital = _formatCurrency(settings['initial_capital'] ?? 20000000);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capital',
                          style: TextStyle(
                            color: Color(0xFFEDE9FE),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configurable desde Operacion',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFD8B4FE),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  capital,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _capitalChip(Icons.verified_outlined, 'Fondo operativo'),
                  const SizedBox(width: 8),
                  _capitalChip(Icons.auto_graph_outlined, 'En tiempo real'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _capitalChip(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFEDE9FE), size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFEDE9FE),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.16)!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.07),
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
              const Icon(Icons.show_chart, color: Color(0xFF0EA5E9), size: 20),
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
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(earnings['total']),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0EA5E9),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                    ),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suscripciones',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(earnings['subscriptions']),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${earnings['verified_companies_count'] ?? 0} empresas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                          color: Color(0xFF64748B),
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
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 100 * height1,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
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
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 100 * height2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Franjas de desembolso:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4338CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• 06:00 - 12:00 → Procesamiento a las 13:00',
            style: TextStyle(fontSize: 13, color: Color(0xFF4338CA)),
          ),
          const Text(
            '• 12:01 - 17:00 → Procesamiento a las 18:00',
            style: TextStyle(fontSize: 13, color: Color(0xFF4338CA)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Modelo de ganancias:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4338CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Fee por transacción (principal ingreso)',
            style: TextStyle(fontSize: 13, color: Color(0xFF4338CA)),
          ),
          const Text(
            '• Interés 2.5% mensual proporcional',
            style: TextStyle(fontSize: 13, color: Color(0xFF4338CA)),
          ),
          const Text(
            '• 100% de ganancias para la plataforma',
            style: TextStyle(fontSize: 13, color: Color(0xFF4338CA)),
          ),
        ],
      ),
    );
  }
}
