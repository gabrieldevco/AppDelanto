import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../widgets/employer_bottom_nav.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_notifications_drawer.dart';

class EmployerRequestsPage extends StatefulWidget {
  const EmployerRequestsPage({super.key});

  @override
  State<EmployerRequestsPage> createState() => _EmployerRequestsPageState();
}

class _EmployerRequestsPageState extends State<EmployerRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      endDrawer: const EmployerNotificationsDrawer(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const EmployerHeader(),
            Expanded(
              child: Consumer<AdvanceProvider>(
                builder: (context, provider, _) {
                  final pending = provider.advances
                      .where((a) => a.isPending)
                      .toList();
                  final approved = provider.advances
                      .where(
                        (a) => a.isApproved || a.isDisbursed || a.isRecovered,
                      )
                      .toList();
                  final rejected = provider.advances
                      .where((a) => a.isRejected || a.isCancelled)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solicitudes de Adelanto',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Aprueba o rechaza solicitudes',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildTabs(
                              pending.length,
                              approved.length,
                              rejected.length,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: provider.isLoading && provider.advances.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildList(pending, Icons.pending_actions),
                                  _buildList(
                                    approved,
                                    Icons.check_circle_outline,
                                  ),
                                  _buildList(rejected, Icons.cancel_outlined),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const EmployerBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTabs(int pending, int approved, int rejected) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF111827),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: [
          Tab(text: 'Pendientes $pending'),
          Tab(text: 'Aprobadas $approved'),
          Tab(text: 'Rechazadas $rejected'),
        ],
      ),
    );
  }

  Widget _buildList(List<AdvanceModel> advances, IconData emptyIcon) {
    if (advances.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Icon(emptyIcon, size: 64, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'No hay solicitudes en esta categoría',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: advances.length,
        itemBuilder: (context, index) => _buildRequestCard(advances[index]),
      ),
    );
  }

  Widget _buildRequestCard(AdvanceModel advance) {
    final color = _statusColor(advance.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  advance.employeeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _statusChip(advance.statusDisplay, color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Monto', _money(advance.amount))),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Fee', _money(advance.fee))),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Total', _money(advance.totalAmount))),
            ],
          ),
          if ((advance.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              advance.reason!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Solicitado el ${_date(advance.requestDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          if (advance.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(advance),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(advance),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
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
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _approve(AdvanceModel advance) async {
    final ok = await context.read<AdvanceProvider>().approveAdvance(advance.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Solicitud aprobada' : 'No se pudo aprobar')),
    );
    await _load();
  }

  Future<void> _reject(AdvanceModel advance) async {
    final provider = context.read<AdvanceProvider>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo',
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
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    final ok = await provider.rejectAdvance(
      advance.id,
      reason: reason.trim().isEmpty ? 'Sin especificar' : reason.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Solicitud rechazada' : 'No se pudo rechazar'),
      ),
    );
    await _load();
  }

  Color _statusColor(String status) {
    return switch (status) {
      'approved' => const Color(0xFF2563EB),
      'disbursed' || 'recovered' => const Color(0xFF059669),
      'rejected' || 'cancelled' => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _money(num value) {
    final text = value.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$ $text';
  }
}
