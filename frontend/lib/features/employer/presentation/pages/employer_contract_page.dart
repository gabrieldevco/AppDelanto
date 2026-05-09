import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../companies/data/models/company_model.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import 'employer_contract_preview_page.dart';

class EmployerContractPage extends StatefulWidget {
  const EmployerContractPage({super.key});

  @override
  State<EmployerContractPage> createState() => _EmployerContractPageState();
}

class _EmployerContractPageState extends State<EmployerContractPage> {
  CompanyModel? _company;
  bool _isLoading = true;
  late TextEditingController _legalNameController;
  late TextEditingController _representativeNameController;
  late TextEditingController _representativeIdController;
  late TextEditingController _contractDurationController;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _representativeNameController.dispose();
    _representativeIdController.dispose();
    _contractDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyData() async {
    try {
      final companyProvider = context.read<CompanyProvider>();
      final authProvider = context.read<AuthProvider>();

      await companyProvider.loadMyCompany();
      final company = companyProvider.myCompany;
      final user = authProvider.user;

      if (!mounted || company == null || user == null) return;

      _company = company;
      _legalNameController = TextEditingController(
        text: company.legalName ?? company.name,
      );
      _representativeNameController = TextEditingController(
        text: user.fullName,
      );
      _representativeIdController = TextEditingController(
        text: user.documentNumber ?? '',
      );
      _contractDurationController = TextEditingController(text: '12 meses');
    } catch (_) {
      if (mounted) {
        await AppPopup.show(
          context,
          title: 'No se pudo cargar el contrato',
          message: 'Revisa los datos de la empresa e intenta nuevamente.',
          type: AppPopupType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : _company == null
            ? _buildErrorView()
            : _buildContractView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFECACA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No encontramos los datos del contrato',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Verifica que tu empresa tenga la informacion basica registrada antes de continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Volver',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractView() {
    final company = _company!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(
          children: [
            _topIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Contrato de vinculacion',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Revisa y descarga el documento',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El contrato ya viene preparado con la informacion principal de ${company.name}.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDBEAFE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos incluidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _infoTile('Empresa', company.legalName ?? company.name),
              _infoTile('NIT', company.taxId ?? 'Pendiente'),
              _infoTile('Ciudad', company.city ?? 'Pendiente'),
              _infoTile(
                'Representante',
                _representativeNameController.text.isEmpty
                    ? 'Pendiente'
                    : _representativeNameController.text,
              ),
              _infoTile(
                'Duracion',
                _contractDurationController.text.isEmpty
                    ? '12 meses'
                    : _contractDurationController.text,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EmployerContractPreviewPage(
                    company: company,
                    legalNameController: _legalNameController,
                    representativeNameController: _representativeNameController,
                    representativeIdController: _representativeIdController,
                    contractDurationController: _contractDurationController,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility_rounded, size: 22),
            label: const Text(
              'Abrir contrato completo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
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
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
