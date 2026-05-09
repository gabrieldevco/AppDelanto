import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_popup.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_notifications_drawer.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_FeeControllers> _fees = [];
  final List<_WindowControllers> _windows = [];
  final _interestController = TextEditingController();
  final _salaryPercentController = TextEditingController();
  final _initialCapitalController = TextEditingController();
  final _minDaysController = TextEditingController();
  final _maxDaysController = TextEditingController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setDefaultControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.loadSettings();
      if (!mounted) return;
      _hydrated = false;
      _hydrate(adminProvider.settings);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final item in _fees) {
      item.dispose();
    }
    for (final item in _windows) {
      item.dispose();
    }
    _interestController.dispose();
    _salaryPercentController.dispose();
    _initialCapitalController.dispose();
    _minDaysController.dispose();
    _maxDaysController.dispose();
    super.dispose();
  }

  void _hydrate(Map<String, dynamic>? settings) {
    if (settings == null || _hydrated) return;
    _interestController.text = '${settings['interest_rate_monthly'] ?? '2.50'}';
    _salaryPercentController.text =
        '${settings['max_salary_percentage'] ?? '50'}';
    _initialCapitalController.text =
        '${settings['initial_capital'] ?? '20000000'}'.replaceAll('.00', '');
    _minDaysController.text = '${settings['min_days'] ?? '1'}';
    _maxDaysController.text = '${settings['max_days'] ?? '30'}';

    _fees
      ..forEach((item) => item.dispose())
      ..clear();
    final feeRanges = settings['fee_ranges'] as List? ?? const [];
    if (feeRanges.isEmpty) {
      _addDefaultFees();
    } else {
      for (final item in feeRanges) {
        _fees.add(_FeeControllers.fromMap(item as Map));
      }
    }

    _windows
      ..forEach((item) => item.dispose())
      ..clear();
    final windows = settings['disbursement_windows'] as List? ?? const [];
    if (windows.isEmpty) {
      _addDefaultWindows();
    } else {
      for (final item in windows) {
        _windows.add(_WindowControllers.fromMap(item as Map));
      }
    }

    _hydrated = true;
    if (mounted) setState(() {});
  }

  void _setDefaultControllers() {
    _interestController.text = '2.5';
    _salaryPercentController.text = '50';
    _initialCapitalController.text = '20000000';
    _minDaysController.text = '1';
    _maxDaysController.text = '30';
    _fees
      ..forEach((item) => item.dispose())
      ..clear();
    _windows
      ..forEach((item) => item.dispose())
      ..clear();
    _addDefaultFees();
    _addDefaultWindows();
    _hydrated = true;
  }

  void _addDefaultFees() {
    _fees
      ..add(_FeeControllers(min: '50000', max: '150000', fee: '5000'))
      ..add(_FeeControllers(min: '150001', max: '400000', fee: '10000'))
      ..add(_FeeControllers(min: '400001', max: '1000000', fee: '15000'));
  }

  void _addDefaultWindows() {
    _windows
      ..add(
        _WindowControllers(
          name: 'Franja 1',
          start: '06:00',
          end: '12:00',
          process: '13:00',
        ),
      )
      ..add(
        _WindowControllers(
          name: 'Franja 2',
          start: '12:01',
          end: '17:00',
          process: '18:00',
        ),
      );
  }

  Future<void> _restoreDefaults() async {
    setState(_setDefaultControllers);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final payload = {
      'interest_rate_monthly': _interestController.text,
      'max_salary_percentage': _salaryPercentController.text,
      'initial_capital': _initialCapitalController.text,
      'min_days': int.tryParse(_minDaysController.text) ?? 1,
      'max_days': int.tryParse(_maxDaysController.text) ?? 30,
      'fee_ranges': _fees
          .asMap()
          .entries
          .map(
            (entry) => {
              'order': entry.key + 1,
              'min_amount': entry.value.min.text,
              'max_amount': entry.value.max.text,
              'fee': entry.value.fee.text,
            },
          )
          .toList(),
      'disbursement_windows': _windows
          .asMap()
          .entries
          .map(
            (entry) => {
              'order': entry.key + 1,
              'name': entry.value.name.text,
              'start_time': entry.value.start.text,
              'end_time': entry.value.end.text,
              'processing_time': entry.value.process.text,
            },
          )
          .toList(),
    };

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateSettings(payload);
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: success ? 'Configuracion guardada' : 'No se pudo guardar',
      message: success
          ? 'Los parametros globales ya quedaron actualizados.'
          : (adminProvider.error ?? 'Revisa los datos e intenta nuevamente.'),
      type: success ? AppPopupType.success : AppPopupType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminHeader(currentIndex: 4),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuracion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Administra los parametros del sistema',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        return TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _tabController.index == 0
                                  ? [
                                      const Color(0xFF2563EB),
                                      const Color(0xFF3B82F6),
                                    ]
                                  : [
                                      const Color(0xFF059669),
                                      const Color(0xFF10B981),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _tabController.index == 0
                                    ? const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.3)
                                    : const Color(
                                        0xFF059669,
                                      ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF64748B),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Fees e Intereses'),
                            Tab(text: 'Operacion'),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  _hydrate(adminProvider.settings);
                  if (adminProvider.isLoading && !_hydrated) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (adminProvider.error != null && !_hydrated) {
                    return Center(child: Text(adminProvider.error!));
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [_feesTab(), _operationTab()],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
    );
  }

  Widget _feesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      child: Column(
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  Icons.attach_money,
                  'Configuracion de Fees',
                  'Define comisiones por rango de monto',
                  _restoreDefaults,
                ),
                const SizedBox(height: 20),
                ..._fees.asMap().entries.map(
                  (entry) => _feeCard(entry.key, entry.value),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _fees.add(_FeeControllers())),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar rango'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  Icons.percent,
                  'Configuracion de Intereses',
                  'Tasa mensual usada por todos los adelantos',
                  _restoreDefaults,
                ),
                const SizedBox(height: 16),
                _textField(
                  'Tasa de interes mensual (%)',
                  _interestController,
                  decimal: true,
                ),
                const SizedBox(height: 20),
                _saveButton('Guardar Fees e Intereses'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      child: Column(
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  Icons.tune,
                  'Limites de Operacion',
                  'Aplica a empleados, empleadores y admin',
                  _restoreDefaults,
                ),
                const SizedBox(height: 16),
                _textField(
                  'Porcentaje maximo del salario (%)',
                  _salaryPercentController,
                  decimal: true,
                ),
                const SizedBox(height: 16),
                _textField(
                  'Capital inicial de la plataforma',
                  _initialCapitalController,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _textField('Dias minimos', _minDaysController),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField('Dias maximos', _maxDaysController),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _saveButton('Guardar Limites de Operacion'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  Icons.schedule,
                  'Franjas de Desembolso',
                  'Horarios globales de procesamiento',
                  _restoreDefaults,
                ),
                const SizedBox(height: 16),
                ..._windows.asMap().entries.map(
                  (entry) => _windowCard(entry.key, entry.value),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _windows.add(_WindowControllers())),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar franja'),
                  ),
                ),
                const SizedBox(height: 20),
                _saveButton('Guardar Franjas de Desembolso'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _warningCard(),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onRestore,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRestore,
          icon: const Icon(Icons.refresh),
          tooltip: 'Recargar',
        ),
      ],
    );
  }

  Widget _feeCard(int index, _FeeControllers item) {
    final colors = [
      const Color(0xFFF5F3FF),
      const Color(0xFFFFF1F2),
      const Color(0xFFECFEFF),
    ];
    final color = colors[index % colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rango ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _fees.length <= 1
                    ? null
                    : () => setState(() => _fees.removeAt(index).dispose()),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _textField('Monto minimo', item.min)),
              const SizedBox(width: 12),
              Expanded(child: _textField('Monto maximo', item.max)),
            ],
          ),
          const SizedBox(height: 12),
          _textField('Fee', item.fee),
        ],
      ),
    );
  }

  Widget _windowCard(int index, _WindowControllers item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _textField('Nombre', item.name, text: true)),
              IconButton(
                onPressed: _windows.length <= 1
                    ? null
                    : () => setState(() => _windows.removeAt(index).dispose()),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _textField('Inicio', item.start, text: true)),
              const SizedBox(width: 8),
              Expanded(child: _textField('Fin', item.end, text: true)),
            ],
          ),
          const SizedBox(height: 12),
          _textField('Procesamiento', item.process, text: true),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool decimal = false,
    bool text = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: text
              ? TextInputType.text
              : TextInputType.numberWithOptions(decimal: decimal),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _warningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'Los cambios se aplican inmediatamente a nuevos adelantos y recalculan el limite disponible de empleados existentes.',
        style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
      ),
    );
  }
}

class _FeeControllers {
  final TextEditingController min;
  final TextEditingController max;
  final TextEditingController fee;

  _FeeControllers({String min = '', String max = '', String fee = ''})
    : min = TextEditingController(text: _clean(min)),
      max = TextEditingController(text: _clean(max)),
      fee = TextEditingController(text: _clean(fee));

  factory _FeeControllers.fromMap(Map item) {
    return _FeeControllers(
      min: '${item['min_amount'] ?? ''}',
      max: '${item['max_amount'] ?? ''}',
      fee: '${item['fee'] ?? ''}',
    );
  }

  static String _clean(String value) => value.replaceAll('.00', '');

  void dispose() {
    min.dispose();
    max.dispose();
    fee.dispose();
  }
}

class _WindowControllers {
  final TextEditingController name;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController process;

  _WindowControllers({
    String name = 'Franja',
    String start = '06:00',
    String end = '12:00',
    String process = '13:00',
  }) : name = TextEditingController(text: name),
       start = TextEditingController(text: start),
       end = TextEditingController(text: end),
       process = TextEditingController(text: process);

  factory _WindowControllers.fromMap(Map item) {
    return _WindowControllers(
      name: '${item['name'] ?? 'Franja'}',
      start: '${item['start_time'] ?? '06:00'}',
      end: '${item['end_time'] ?? '12:00'}',
      process: '${item['processing_time'] ?? '13:00'}',
    );
  }

  void dispose() {
    name.dispose();
    start.dispose();
    end.dispose();
    process.dispose();
  }
}
