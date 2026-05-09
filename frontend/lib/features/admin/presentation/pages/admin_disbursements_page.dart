import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_notifications_drawer.dart';

enum _DisbursementTabMode { pending, completed, recovered }

class AdminDisbursementsPage extends StatefulWidget {
  const AdminDisbursementsPage({super.key});

  @override
  State<AdminDisbursementsPage> createState() => _AdminDisbursementsPageState();
}

class _AdminDisbursementsPageState extends State<AdminDisbursementsPage>
    with SingleTickerProviderStateMixin {
  static const int _tabCount = 3;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await context.read<AdvanceProvider>().loadMyAdvances();
  }

  Future<void> _refreshCapital() async {
    try {
      await context.read<AdminProvider>().loadSettings();
    } catch (_) {
      // The disbursement flow should not fail if the dashboard provider is absent.
    }
  }

  void _ensureTabControllerLength() {
    if (_tabController.length == _tabCount) return;

    final previousIndex = _tabController.index.clamp(0, _tabCount - 1);
    _tabController.dispose();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: previousIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureTabControllerLength();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminHeader(currentIndex: 2),
            Expanded(
              child: Consumer<AdvanceProvider>(
                builder: (context, provider, _) {
                  final pending = provider.advances
                      .where((advance) => advance.isApproved)
                      .toList();
                  final completed = provider.advances
                      .where((advance) => advance.isDisbursed)
                      .toList();
                  final recovered = provider.advances
                      .where((advance) => advance.isRecovered)
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Desembolsos',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Procesa adelantos aprobados',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTabs(
                          pending.length,
                          completed.length,
                          recovered.length,
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: provider.isLoading && provider.advances.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildList(
                                      pending,
                                      'No hay desembolsos en esta categoria',
                                      mode: _DisbursementTabMode.pending,
                                    ),
                                    _buildList(
                                      completed,
                                      'No hay desembolsos completados',
                                      mode: _DisbursementTabMode.completed,
                                    ),
                                    _buildList(
                                      recovered,
                                      'No hay pagos recibidos',
                                      mode: _DisbursementTabMode.recovered,
                                    ),
                                  ],
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
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }

  Widget _buildTabs(int pending, int completed, int recovered) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
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
                colors: _tabColors(_tabController.index),
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _tabColors(
                    _tabController.index,
                  ).first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              _tabLabel('Pendientes $pending'),
              _tabLabel('Completados $completed'),
              _tabLabel('Pagos recibidos $recovered'),
            ],
          );
        },
      ),
    );
  }

  Tab _tabLabel(String label) {
    return Tab(
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }

  List<Color> _tabColors(int index) {
    return switch (index) {
      0 => const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      1 => const [Color(0xFF10B981), Color(0xFF34D399)],
      _ => const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    };
  }

  Widget _buildList(
    List<AdvanceModel> advances,
    String emptyMessage, {
    required _DisbursementTabMode mode,
  }) {
    if (advances.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            _buildEmptyState(emptyMessage),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 18),
        itemCount: advances.length,
        itemBuilder: (context, index) {
          return _buildDisbursementCard(advances[index], mode: mode);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisbursementCard(
    AdvanceModel advance, {
    required _DisbursementTabMode mode,
  }) {
    final hasBankInfo =
        _hasText(advance.employeeBankName) ||
        _hasText(advance.employeeBankAccount);
    final isPending = mode == _DisbursementTabMode.pending;
    final isCompleted = mode == _DisbursementTabMode.completed;
    final isRecovered = mode == _DisbursementTabMode.recovered;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: Color(0xFF7C3AED),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advance.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      advance.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(
                isRecovered
                    ? 'Reembolsado'
                    : isCompleted
                    ? 'Completado'
                    : 'Pendiente',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _moneyBox('A transferir', advance.amount)),
              const SizedBox(width: 8),
              Expanded(child: _moneyBox('Total adelanto', advance.totalAmount)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasBankInfo
                  ? const Color(0xFFFAF7FF)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasBankInfo
                    ? const Color(0xFFE9D5FF)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  Icons.account_balance_outlined,
                  'Banco',
                  _valueOrMissing(advance.employeeBankName),
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.credit_card_outlined,
                  'Cuenta',
                  _valueOrMissing(advance.employeeBankAccount),
                ),
                if (_hasText(advance.employeeDocument)) ...[
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.badge_outlined,
                    'Documento',
                    advance.employeeDocument!,
                  ),
                ],
                if (_hasText(advance.employeeEmail)) ...[
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.email_outlined,
                    'Email',
                    advance.employeeEmail!,
                  ),
                ],
                if (_hasText(advance.employeePhone)) ...[
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.phone_outlined,
                    'Telefono',
                    advance.employeePhone!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoPill('Aprobado', _date(advance.approvedAt)),
              _infoPill('Solicitado', _date(advance.requestDate)),
              if (!isPending)
                _infoPill('Desembolsado', _date(advance.disbursedAt)),
              if (isRecovered)
                _infoPill('Reembolsado', _date(advance.recoveryDate)),
              if (_hasText(advance.disbursementReference))
                _infoPill('Ref', advance.disbursementReference!),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildCardAction(advance, mode),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction(AdvanceModel advance, _DisbursementTabMode mode) {
    if (mode == _DisbursementTabMode.pending) {
      return ElevatedButton.icon(
        onPressed: () => _markCompleted(advance),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Marcar como completado'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    if (mode == _DisbursementTabMode.completed) {
      return ElevatedButton.icon(
        onPressed: () => _markRecovered(advance),
        icon: const Icon(Icons.payments_outlined, size: 18),
        label: const Text('Marcar como reembolsado'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _undoRecovered(advance),
      icon: const Icon(Icons.undo, size: 18),
      label: const Text('Deshacer reembolso'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0369A1),
        side: const BorderSide(color: Color(0xFFBAE6FD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _moneyBox(String label, num amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            _money(amount),
            maxLines: 1,
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    final color = switch (label) {
      'Completado' => const Color(0xFF0D9488),
      'Reembolsado' => const Color(0xFF0284C7),
      _ => const Color(0xFF7C3AED),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _markCompleted(AdvanceModel advance) async {
    final provider = context.read<AdvanceProvider>();
    final controller = TextEditingController(
      text: 'Transferencia adelanto #${advance.id}',
    );
    final reference = await _showCompleteDialog(advance, controller);
    controller.dispose();
    if (reference == null) return;

    final ok = await provider.disburseAdvance(
      advance.id,
      reference: reference.trim().isEmpty
          ? 'Transferencia adelanto #${advance.id}'
          : reference.trim(),
    );
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: ok ? 'Desembolso completado' : 'No se pudo completar',
      message: ok
          ? 'El adelanto paso a Completados.'
          : provider.errorMessage ?? 'Intenta nuevamente.',
      type: ok ? AppPopupType.success : AppPopupType.error,
    );
    if (ok) {
      _tabController.animateTo(1);
      await _refreshCapital();
      await _load();
    }
  }

  Future<void> _markRecovered(AdvanceModel advance) async {
    final provider = context.read<AdvanceProvider>();
    final confirm = await _showActionDialog(
      advance: advance,
      title: 'Marcar como reembolsado',
      message:
          'Entrara al capital el Total adelanto (${_money(advance.totalAmount)}) y el cupo del empleado se restaurara.',
      icon: Icons.payments_outlined,
      accentColor: const Color(0xFF0EA5E9),
      confirmLabel: 'Confirmar',
    );
    if (confirm != true) return;

    final ok = await provider.recoverAdvance(advance.id);
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: ok ? 'Pago recibido' : 'No se pudo marcar',
      message: ok
          ? 'El Total adelanto (${_money(advance.totalAmount)}) ingreso al capital.'
          : provider.errorMessage ?? 'Intenta nuevamente.',
      type: ok ? AppPopupType.recovered : AppPopupType.error,
    );
    if (ok) {
      _tabController.animateTo(2);
      await _refreshCapital();
      await _load();
    }
  }

  Future<String?> _showCompleteDialog(
    AdvanceModel advance,
    TextEditingController controller,
  ) {
    const accent = Color(0xFF7C3AED);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 410),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.24),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
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
                      colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completar desembolso',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Se descontara del capital disponible',
                              style: TextStyle(
                                color: Color(0xFFEDE9FE),
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
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Column(
                          children: [
                            _dialogInfoRow(
                              Icons.person_outline,
                              advance.employeeName,
                              _money(advance.amount),
                            ),
                            const SizedBox(height: 10),
                            _dialogInfoRow(
                              Icons.account_balance_outlined,
                              _valueOrMissing(advance.employeeBankName),
                              _valueOrMissing(advance.employeeBankAccount),
                            ),
                            const SizedBox(height: 10),
                            _dialogInfoRow(
                              Icons.receipt_long_outlined,
                              'Total adelanto',
                              _money(advance.totalAmount),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Referencia',
                          prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                            color: accent,
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
                              color: accent,
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
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, controller.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text('Completar'),
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
  }

  Future<void> _undoRecovered(AdvanceModel advance) async {
    final provider = context.read<AdvanceProvider>();
    final confirm = await _showActionDialog(
      advance: advance,
      title: 'Deshacer reembolso',
      message:
          'El adelanto volvera a Completados y se descontara del capital ${_money(advance.totalAmount)}.',
      icon: Icons.undo_rounded,
      accentColor: const Color(0xFFF97316),
      confirmLabel: 'Deshacer',
    );
    if (confirm != true) return;

    final ok = await provider.unrecoverAdvance(advance.id);
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: ok ? 'Reembolso deshecho' : 'No se pudo deshacer',
      message: ok
          ? 'Se desconto del capital ${_money(advance.totalAmount)}.'
          : provider.errorMessage ?? 'Intenta nuevamente.',
      type: ok ? AppPopupType.undo : AppPopupType.error,
    );
    if (ok) {
      _tabController.animateTo(1);
      await _refreshCapital();
      await _load();
    }
  }

  Future<bool?> _showActionDialog({
    required AdvanceModel advance,
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          Color.lerp(accentColor, Colors.black, 0.16)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _dialogInfoRow(
                      Icons.person_outline,
                      advance.employeeName,
                      _money(advance.amount),
                    ),
                    const SizedBox(height: 10),
                    _dialogInfoRow(
                      Icons.business_outlined,
                      advance.companyName,
                      'Total ${_money(advance.totalAmount)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 48),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _valueOrMissing(String? value) =>
      _hasText(value) ? value! : 'Sin registrar';

  String _date(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _money(num value) {
    final text = value.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$ $text';
  }
}
