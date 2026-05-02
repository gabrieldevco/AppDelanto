import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_notifications_drawer.dart';

class AdminDisbursementsPage extends StatefulWidget {
  const AdminDisbursementsPage({super.key});

  @override
  State<AdminDisbursementsPage> createState() => _AdminDisbursementsPageState();
}

class _AdminDisbursementsPageState extends State<AdminDisbursementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminHeader(),
            Expanded(
              child: Consumer<AdvanceProvider>(
                builder: (context, provider, _) {
                  final pending = provider.advances
                      .where((advance) => advance.isApproved)
                      .toList();
                  final completed = provider.advances
                      .where((advance) => advance.isDisbursed)
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
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTabs(pending.length, completed.length),
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
                                      completed: false,
                                    ),
                                    _buildList(
                                      completed,
                                      'No hay desembolsos completados',
                                      completed: true,
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

  Widget _buildTabs(int pending, int completed) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF111827),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Pendientes $pending'),
          Tab(text: 'Completados $completed'),
        ],
      ),
    );
  }

  Widget _buildList(
    List<AdvanceModel> advances,
    String emptyMessage, {
    required bool completed,
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
          return _buildDisbursementCard(advances[index], completed: completed);
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisbursementCard(
    AdvanceModel advance, {
    required bool completed,
  }) {
    final hasBankInfo =
        _hasText(advance.employeeBankName) ||
        _hasText(advance.employeeBankAccount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: Color(0xFF2563EB),
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
              _statusChip(completed ? 'Completado' : 'Pendiente'),
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
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasBankInfo
                    ? const Color(0xFFE2E8F0)
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
              if (completed)
                _infoPill('Desembolsado', _date(advance.disbursedAt)),
              if (_hasText(advance.disbursementReference))
                _infoPill('Ref', advance.disbursementReference!),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: completed
                ? OutlinedButton.icon(
                    onPressed: () => _markIncomplete(advance),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Marcar como incompleto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _markCompleted(advance),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Marcar como completado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _moneyBox(String label, num amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
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
        color: const Color(0xFFF8FAFC),
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
    final completed = label == 'Completado';
    final color = completed ? const Color(0xFF059669) : const Color(0xFF2563EB);
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
    final reference = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Completar desembolso'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Referencia',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reference == null) return;

    final ok = await provider.disburseAdvance(
      advance.id,
      reference: reference.trim().isEmpty
          ? 'Transferencia adelanto #${advance.id}'
          : reference.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Desembolso completado' : 'No se pudo completar'),
      ),
    );
    if (ok) {
      _tabController.animateTo(1);
      await _load();
    }
  }

  Future<void> _markIncomplete(AdvanceModel advance) async {
    final provider = context.read<AdvanceProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marcar como incompleto'),
        content: const Text('El adelanto volvera a pendientes de desembolso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await provider.undisburseAdvance(advance.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Desembolso marcado como incompleto' : 'No se pudo revertir',
        ),
      ),
    );
    if (ok) {
      _tabController.animateTo(0);
      await _load();
    }
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
