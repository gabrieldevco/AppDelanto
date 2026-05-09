import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../advances/data/models/advance_model.dart';
import '../../../advances/presentation/providers/advance_provider.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../../../companies/data/models/company_model.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../widgets/employer_bottom_nav.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_notifications_drawer.dart';
import 'employer_requests_page.dart';
import 'employer_contract_page.dart';

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
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const EmployerNotificationsDrawer(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const EmployerHeader(currentIndex: 0),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Consumer2<CompanyProvider, AdvanceProvider>(
                  builder: (context, companyProvider, advanceProvider, _) {
                    final company = companyProvider.myCompany;
                    if (company != null &&
                        company.isPreapproved &&
                        !company.isVerified) {
                      return _buildContractGate(companyProvider, company);
                    }

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
                      padding: ResponsiveUtils.getPagePadding(
                        context,
                      ).copyWith(bottom: 24),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: ResponsiveUtils.getMaxContentWidth(
                                context,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildHeroHeader(
                                  employeeCount: employees.length,
                                  pendingDiscount: pendingDiscount,
                                ),
                                const SizedBox(height: 18),
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
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<CompanyProvider>(
        builder: (context, provider, _) {
          final company = provider.myCompany;
          if (company != null && company.isPreapproved && !company.isVerified) {
            return const SizedBox.shrink();
          }
          return const EmployerBottomNav(currentIndex: 0);
        },
      ),
    );
  }

  Widget _buildContractGate(CompanyProvider provider, CompanyModel company) {
    final hasUploaded =
        company.platformContractFileUrl != null &&
        company.platformContractFileUrl!.isNotEmpty;
    final hasReceipt =
        company.subscriptionReceiptFileUrl != null &&
        company.subscriptionReceiptFileUrl!.isNotEmpty;
    return ListView(
      padding: ResponsiveUtils.getPagePadding(context).copyWith(bottom: 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getMaxContentWidth(context),
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF2563EB),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contrato de vinculacion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasUploaded
                        ? 'Contrato adjuntado. El administrador revisara el PDF firmado para activar tu empresa.'
                        : 'Descarga el contrato, diligencialo, firmalo manualmente y adjuntalo en PDF.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _contractInfo('Empresa', company.legalName ?? company.name),
                  _contractInfo('NIT', company.taxId ?? 'Pendiente'),
                  _contractInfo('Ciudad', company.city ?? 'Pendiente'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EmployerContractPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('Ver y Descargar Contrato'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _uploadSignedContract(provider),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        hasUploaded
                            ? 'Reemplazar contrato firmado'
                            : 'Adjuntar contrato firmado PDF',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _startSubscriptionReceiptFlow(provider),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: Text(
                        hasReceipt
                            ? 'Reemplazar volante de suscripcion (\$50.000)'
                            : 'Adjuntar volante de suscripcion (\$50.000)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF99F6E4)),
                        backgroundColor: const Color(0xFFF0FDFA),
                      ),
                    ),
                  ),
                  if (hasReceipt) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0F766E),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Volante adjuntado. El administrador podra revisarlo junto con tu contrato.',
                              style: TextStyle(
                                color: Color(0xFF115E59),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _contractInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadSignedContract(CompanyProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final ok = await provider.uploadPlatformContract(File(path));
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: ok ? 'Contrato adjuntado' : 'No se pudo adjuntar',
      message: ok
          ? 'El administrador recibira una notificacion para revisar el PDF firmado.'
          : provider.errorMessage ?? 'Intenta nuevamente.',
      type: ok ? AppPopupType.success : AppPopupType.error,
    );
  }

  Future<void> _startSubscriptionReceiptFlow(CompanyProvider provider) async {
    final confirmed = await AppPopup.confirm(
      context,
      title: 'Volante de suscripcion',
      message:
          'Consigna \$50.000 a la cuenta 54267607446 - Ahorros Bancolombia a nombre de Rafael Ricardo Vanegas Suarez. Luego adjunta una imagen de galeria o un PDF del volante.',
      type: AppPopupType.info,
      primaryLabel: 'Adjuntar',
      secondaryLabel: 'Cancelar',
    );
    if (!confirmed || !mounted) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Text(
                  'Selecciona el archivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Puedes enviar una imagen del volante o un PDF.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _pickerActionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Imagen de galeria',
                  subtitle: 'PNG, JPG o JPEG',
                  color: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.of(context).pop('image'),
                ),
                const SizedBox(height: 10),
                _pickerActionTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Archivo PDF',
                  subtitle: 'Sube el comprobante en PDF',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.of(context).pop('pdf'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    final result = await FilePicker.pickFiles(
      type: source == 'image' ? FileType.image : FileType.custom,
      allowedExtensions: source == 'image' ? null : ['pdf'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final ok = await provider.uploadSubscriptionReceipt(File(path));
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: ok ? 'Volante adjuntado' : 'No se pudo adjuntar',
      message: ok
          ? 'El administrador recibira una notificacion para revisar el volante de suscripcion.'
          : provider.errorMessage ?? 'Intenta nuevamente.',
      type: ok ? AppPopupType.success : AppPopupType.error,
    );
  }

  Widget _pickerActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required int employeeCount,
    required double pendingDiscount,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.24),
            blurRadius: 28,
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
                child: const Icon(Icons.business_center, color: Colors.white),
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
                  '$employeeCount empleados',
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
            'Panel de Control',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gestiona solicitudes, desembolsos y descuentos con claridad.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFFE0F2FE),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pendiente por descontar',
                    style: TextStyle(
                      color: Color(0xFFE0F2FE),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _money(pendingDiscount),
                  style: const TextStyle(
                    color: Colors.white,
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
                bgColor: const Color(0xFF1D4ED8),
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Adelantado',
                value: _money(totalAdvanced),
                icon: Icons.attach_money,
                bgColor: const Color(0xFF0891B2),
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
                bgColor: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total solicitudes',
                value: requestCount.toString(),
                icon: Icons.receipt_long,
                bgColor: const Color(0xFFECFEFF),
                iconColor: const Color(0xFF0891B2),
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
        gradient: textColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, Color.lerp(bgColor, Colors.black, 0.16)!],
              )
            : null,
        color: textColor == null ? bgColor : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: textColor != null ? 0.18 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    color: Color(0xFF64748B),
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
      'approved' => const Color(0xFF1D4ED8),
      'disbursed' || 'recovered' => const Color(0xFF0891B2),
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
