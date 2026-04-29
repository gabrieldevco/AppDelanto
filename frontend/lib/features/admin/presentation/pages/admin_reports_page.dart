import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_notifications_drawer.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  int? _employerId;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  Future<void> _loadReports() {
    return context.read<AdminProvider>().loadReports(
      startDate: _apiDate(_startDate),
      endDate: _apiDate(_endDate),
      employerId: _employerId,
    );
  }

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _uiDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  int _toInt(dynamic value) => _toDouble(value).round();

  String _currency(dynamic value) {
    final amount = _toDouble(value).round();
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '\$ $formatted';
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
    await _loadReports();
  }

  void _showExportMessage(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte $type generado con los filtros actuales'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final report = adminProvider.reports ?? <String, dynamic>{};
            final summary = report['summary'] as Map<String, dynamic>? ?? {};
            final processed =
                report['processed'] as Map<String, dynamic>? ?? {};
            final totals = report['totals'] as Map<String, dynamic>? ?? {};
            final employers = report['employers'] as List? ?? const [];
            final breakdown = report['breakdown'] as List? ?? const [];

            return RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
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
                            'Reportes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Analitica y estadisticas detalladas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFilters(employers),
                          const SizedBox(height: 20),
                          if (adminProvider.isLoading && report.isEmpty)
                            const Center(child: CircularProgressIndicator())
                          else if (adminProvider.error != null &&
                              report.isEmpty)
                            _buildError(adminProvider.error!)
                          else ...[
                            _buildPeriodSummary(summary),
                            const SizedBox(height: 20),
                            _buildEarnings(summary),
                            const SizedBox(height: 20),
                            _buildProcessed(processed),
                            const SizedBox(height: 20),
                            _buildBreakdown(breakdown),
                            const SizedBox(height: 20),
                            _buildTotals(totals),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFilters(List employers) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros de Consulta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dateField(
                  'Fecha inicio',
                  _startDate,
                  () => _pickDate(start: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(
                  'Fecha fin',
                  _endDate,
                  () => _pickDate(start: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Empleador',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int?>(
            initialValue: _employerId,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los empleadores'),
              ),
              ...employers.map(
                (item) => DropdownMenuItem<int?>(
                  value: item['id'] as int,
                  child: Text('${item['name']}'),
                ),
              ),
            ],
            onChanged: (value) async {
              setState(() => _employerId = value);
              await _loadReports();
            },
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 20),
          _exportButton(
            'Generar Reporte Excel',
            Icons.table_chart,
            const Color(0xFF059669),
            () {
              _showExportMessage('Excel');
            },
          ),
          const SizedBox(height: 12),
          _exportButton(
            'Generar Reporte PDF',
            Icons.picture_as_pdf,
            const Color(0xFFDC2626),
            () {
              _showExportMessage('PDF');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Resumen del Periodo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_apiDate(_startDate)} - ${_apiDate(_endDate)}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Desembolsado',
                  _currency(summary['disbursed']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  'Recuperado',
                  _currency(summary['recovered']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnings(Map<String, dynamic> summary) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'Ganancias de la Plataforma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _earningsRow(
            'Total ganancias',
            _currency(summary['earnings']),
            const Color(0xFF7C3AED),
          ),
          _earningsRow(
            'Fee por transacciones',
            _currency(summary['fees']),
            const Color(0xFF2563EB),
          ),
          _earningsRow(
            'Intereses',
            _currency(summary['interest']),
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessed(Map<String, dynamic> processed) {
    final total = _toInt(processed['total']);
    final approved = _toInt(processed['approved']);
    final rejected = _toInt(processed['rejected']);
    final approvedPercent = total == 0 ? 0 : (approved / total * 100).round();
    final rejectedPercent = total == 0 ? 0 : (rejected / total * 100).round();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitudes Procesadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Center(
            child: _metricBox(
              'Total solicitudes',
              '$total',
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  'Aprobadas',
                  '$approved\n$approvedPercent%',
                  const Color(0xFFECFDF5),
                  const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricBox(
                  'Rechazadas',
                  '$rejected\n$rejectedPercent%',
                  const Color(0xFFFEF2F2),
                  const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(List breakdown) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'Desglose por Empleador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (breakdown.isEmpty)
            const Text(
              'Sin datos para el periodo',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ...breakdown.map((item) => _employerCard(item as Map)),
        ],
      ),
    );
  }

  Widget _buildTotals(Map<String, dynamic> totals) {
    return Row(
      children: [
        Expanded(
          child: _totalCard(
            Icons.business_center,
            '${_toInt(totals['active_employers'])}',
            'Empleadores activos',
            const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _totalCard(
            Icons.people,
            '${_toInt(totals['employees'])}',
            'Empleados registrados',
            const Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _inputDecoration(),
            child: Row(
              children: [
                Expanded(child: Text(_uiDate(value))),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _exportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _employerCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
                      '${item['name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_toInt(item['employees'])} empleados',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Chip(label: Text('${_toInt(item['requests'])} solicitudes')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Desembolsado',
                  _currency(item['disbursed']),
                  const Color(0xFFECFDF5),
                  const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Recuperado',
                  _currency(item['recovered']),
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Ganancias',
                  _currency(item['earnings']),
                  const Color(0xFFF3E8FF),
                  const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return _card(
      child: Text(error, style: const TextStyle(color: Color(0xFF991B1B))),
    );
  }
}
