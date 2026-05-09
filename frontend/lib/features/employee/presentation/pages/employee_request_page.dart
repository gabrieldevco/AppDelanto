import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/employee_bottom_nav.dart';
import '../widgets/employee_header.dart';
import '../widgets/employee_notifications_drawer.dart';
import 'employee_advance_authorization_page.dart';
import 'employee_home_page.dart';

class EmployeeRequestPage extends StatefulWidget {
  const EmployeeRequestPage({super.key});

  @override
  State<EmployeeRequestPage> createState() => _EmployeeRequestPageState();
}

class _EmployeeRequestPageState extends State<EmployeeRequestPage> {
  static const double _amountStep = 10000;

  final _amountController = TextEditingController(text: '100000');

  double _amount = 100000;
  double _days = 25;
  double _minAmount = 50000;
  double _maxConfigAmount = 1000000;
  double _fee = 5000;
  double _interest = 0;
  double _monthlyRate = 0.025;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
      _calculateAdvance();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _total => _amount + _fee + _interest;
  double get _appliedInterestRate {
    if (_monthlyRate <= 0) return 0;
    return (_monthlyRate * (_days.toInt() / 30)).clamp(0, _monthlyRate);
  }

  String get _interestSummaryLabel {
    final applied = (_appliedInterestRate * 100).toStringAsFixed(2);
    final monthly = (_monthlyRate * 100).toStringAsFixed(2);
    return 'Interes ($applied% por ${_days.toInt()} dias, max $monthly% mensual)';
  }

  double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  String _formatCurrency(double value) {
    String result = value.toStringAsFixed(0);
    result = result.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return result;
  }

  double _snapAmount(double value, double maxAmount) {
    final clamped = value.clamp(_minAmount, maxAmount).toDouble();
    final steps = ((clamped - _minAmount) / _amountStep).round();
    final snapped = _minAmount + (steps * _amountStep);
    return snapped.clamp(_minAmount, maxAmount).toDouble();
  }

  int? _amountDivisions(double maxAmount) {
    final range = maxAmount - _minAmount;
    if (range <= 0) return null;
    return (range / _amountStep).round().clamp(1, 100000).toInt();
  }

  Future<void> _calculateAdvance() async {
    final provider = context.read<AdvanceProvider>();
    await provider.calculateAdvance(amount: _amount, days: _days.toInt());
    if (!mounted || provider.calculation == null) return;
    final calculation = provider.calculation!;
    setState(() {
      _fee = _toDouble(calculation['fee']);
      _interest = _toDouble(calculation['interest']);
      _monthlyRate = _toDouble(calculation['interest_rate_monthly']) / 100;
      _minAmount = _toDouble(calculation['min_amount']);
      _maxConfigAmount = _toDouble(calculation['max_amount']);
    });
  }

  void _setAmount(double value, double maxAmount, {bool updateText = false}) {
    final clamped = _snapAmount(value, maxAmount);
    setState(() {
      _amount = clamped;
      if (updateText) {
        _amountController.text = clamped.toStringAsFixed(0);
        _amountController.selection = TextSelection.collapsed(
          offset: _amountController.text.length,
        );
      }
    });
    _calculateAdvance();
  }

  void _commitTypedAmount(double maxAmount) {
    final typed = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', '.').trim(),
    );
    _setAmount(typed ?? _minAmount, maxAmount, updateText: true);
  }

  Future<void> _openAuthorizationPage(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.refreshProfile();
    if (!context.mounted) return;
    final employeeProfile = authProvider.user?.employeeProfile;

    if (employeeProfile?.isPendingApproval ?? false) {
      await AppPopup.show(
        context,
        title: 'Verificacion pendiente',
        message:
            'Debes esperar a que tu empleador verifique tu informacion para poder solicitar adelantos.',
        type: AppPopupType.warning,
      );
      return;
    }

    final authorizationData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeAdvanceAuthorizationPage(
          user: authProvider.user,
          amount: _amount,
          fee: _fee,
          interest: _interest,
          total: _total,
          days: _days.toInt(),
        ),
      ),
    );

    if (!context.mounted || authorizationData == null) return;
    await _submitAdvanceRequest(context, authorizationData);
  }

  Future<void> _submitAdvanceRequest(
    BuildContext context,
    Map<String, dynamic> authorizationData,
  ) async {
    if (_isSubmitting) return;
    final advanceProvider = context.read<AdvanceProvider>();

    setState(() => _isSubmitting = true);
    try {
      final success = await advanceProvider.createAdvance(
        amount: _amount,
        reason: 'Adelanto de nomina por ${_days.toInt()} dias',
        days: _days.toInt(),
        authorizationData: authorizationData,
      );

      if (!context.mounted) return;
      setState(() => _isSubmitting = false);

      if (!success) {
        final message =
            advanceProvider.errorMessage ??
            'No se pudo enviar la solicitud. Intenta nuevamente.';
        await AppPopup.show(
          context,
          title: message.toLowerCase().contains('verifique')
              ? 'Verificacion pendiente'
              : 'No se pudo solicitar',
          message: message,
          type: AppPopupType.warning,
        );
        return;
      }

      await AppPopup.show(
        context,
        title: 'Solicitud enviada',
        message: 'Tu solicitud fue enviada exitosamente.',
        type: AppPopupType.success,
      );
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeHomePage()),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      setState(() => _isSubmitting = false);
      await AppPopup.show(
        context,
        title: 'No se pudo solicitar',
        message: 'No se pudo enviar la solicitud. Intenta nuevamente.',
        type: AppPopupType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final availableLimit =
            user?.employeeProfile?.availableAdvanceLimit ?? 1000000;
        final configuredMax = availableLimit < _maxConfigAmount
            ? availableLimit
            : _maxConfigAmount;
        final maxAmount = configuredMax < _minAmount
            ? _minAmount
            : configuredMax;
        final salary = user?.employeeProfile?.salary ?? 0.0;

        if (_amount > maxAmount) {
          _amount = _snapAmount(
            maxAmount > _minAmount ? maxAmount : _minAmount,
            maxAmount,
          );
          _amountController.text = _amount.toStringAsFixed(0);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          endDrawer: const EmployeeNotificationsDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                const EmployeeHeader(currentIndex: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _availableCard(salary, maxAmount),
                      const SizedBox(height: 16),
                      _amountCard(maxAmount),
                      const SizedBox(height: 16),
                      _daysCard(),
                      const SizedBox(height: 16),
                      _summaryCard(),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _openAuthorizationPage(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00A86B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continuar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoCard(maxAmount),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const EmployeeBottomNav(currentIndex: 1),
        );
      },
    );
  }

  Widget _availableCard(double salary, double maxAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8FFF2), Color(0xFFBBF7D0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E)),
      ),
      child: Column(
        children: [
          Text(
            'Disponible para adelantar (50% de \$${_formatCurrency(salary)})',
            style: const TextStyle(fontSize: 14, color: Color(0xFF047857)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '\$ ${_formatCurrency(maxAmount)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00A86B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCard(double maxAmount) {
    return _sectionCard(
      title: 'Monto a solicitar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '\$ ',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              final typed = double.tryParse(
                value.replaceAll('.', '').replaceAll(',', '.').trim(),
              );
              if (typed == null) return;
              if (typed >= _minAmount && typed <= maxAmount) {
                setState(() => _amount = _snapAmount(typed, maxAmount));
                _calculateAdvance();
              }
            },
            onEditingComplete: () => _commitTypedAmount(maxAmount),
            onTapOutside: (_) => _commitTypedAmount(maxAmount),
          ),
          const SizedBox(height: 18),
          Slider(
            value: _amount,
            min: _minAmount,
            max: maxAmount,
            divisions: _amountDivisions(maxAmount),
            activeColor: const Color(0xFF00A86B),
            onChanged: (value) =>
                _setAmount(value, maxAmount, updateText: true),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$ ${_formatCurrency(_minAmount)}'),
              Text('\$ ${_formatCurrency(maxAmount)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _daysCard() {
    return _sectionCard(
      title: 'Plazo del adelanto',
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dias hasta proxima nomina',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${_days.toInt()} dias',
                style: const TextStyle(
                  color: Color(0xFF00A86B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: _days,
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: const Color(0xFF00A86B),
            onChanged: (value) {
              setState(() => _days = value);
              _calculateAdvance();
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return _sectionCard(
      title: 'Resumen del adelanto',
      child: Column(
        children: [
          _summaryRow('Monto adelantado', _amount, const Color(0xFF00A86B)),
          _summaryRow('Fee transaccion', _fee, const Color(0xFFF59E0B)),
          _summaryRow(
            _interestSummaryLabel,
            _interest,
            const Color(0xFFEA580C),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total a descontar en nomina',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  '\$ ${_formatCurrency(_total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          Text(
            '\$ ${_formatCurrency(value)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(double maxAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informacion importante',
            style: TextStyle(
              color: Color(0xFF047857),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _infoBullet('Monto minimo: \$ ${_formatCurrency(_minAmount)}'),
          _infoBullet('Limite maximo: \$ ${_formatCurrency(maxAmount)}'),
          _infoBullet('Descuento autorizado en la siguiente nomina'),
        ],
      ),
    );
  }

  Widget _infoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- ', style: TextStyle(color: Color(0xFF00A86B))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF047857)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
