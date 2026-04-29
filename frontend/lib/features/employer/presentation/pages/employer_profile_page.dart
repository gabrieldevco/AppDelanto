import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_notifications_drawer.dart';

class EmployerProfilePage extends StatefulWidget {
  const EmployerProfilePage({super.key});

  @override
  State<EmployerProfilePage> createState() => _EmployerProfilePageState();
}

class _EmployerProfilePageState extends State<EmployerProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  bool _saving = false;

  final _razonSocialController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _emailController = TextEditingController();
  final _nitController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<CompanyProvider>();
    await provider.loadMyCompany();
    final company = provider.myCompany;
    if (company == null || !mounted) return;
    setState(() {
      _razonSocialController.text = company.legalName ?? '';
      _nombreComercialController.text = company.name;
      _emailController.text = company.email ?? '';
      _nitController.text = company.taxId ?? '';
      _phoneController.text = company.phone ?? '';
      _bankController.text = company.bankName ?? '';
      _accountController.text = company.bankAccount ?? '';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _razonSocialController.dispose();
    _nombreComercialController.dispose();
    _emailController.dispose();
    _nitController.dispose();
    _phoneController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const EmployerNotificationsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const EmployerHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi Perfil',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTabs(),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildCompanyTab(), _buildSecurityTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        label: const Text(
          'Volver',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildTabs() {
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Datos de Empresa'),
          Tab(text: 'Seguridad'),
        ],
      ),
    );
  }

  Widget _buildCompanyTab() {
    return Consumer<CompanyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.myCompany == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Información',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  if (_isEditing) {
                                    _saveCompany();
                                  } else {
                                    setState(() => _isEditing = true);
                                  }
                                },
                          child: Text(_isEditing ? 'Guardar' : 'Editar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field('Razón Social', _razonSocialController),
                    _field('Nombre Comercial', _nombreComercialController),
                    _field(
                      'Email',
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _field(
                      'Teléfono',
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _field('NIT', _nitController, enabled: false),
                    _field('Banco', _bankController),
                    _field('Cuenta bancaria', _accountController),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _infoBox(
                icon: Icons.info,
                title: 'Información importante:',
                text:
                    'Mantén los datos bancarios y de contacto actualizados para operar adelantos y recibir notificaciones.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar contraseña',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              _passwordField('Contraseña actual', _currentPasswordController),
              _passwordField('Nueva contraseña', _newPasswordController),
              _passwordField(
                'Confirmar contraseña',
                _confirmPasswordController,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _changePassword,
                  icon: const Icon(Icons.key, size: 18),
                  label: const Text('Actualizar contraseña'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _infoBox(
          icon: Icons.lock,
          title: 'Seguridad de tu cuenta:',
          text:
              'Usa una contraseña única y no la compartas. El cambio se aplica inmediatamente en el backend.',
          color: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFF92400E),
        ),
      ],
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    final active = enabled && _isEditing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            enabled: active,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: active
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: active
                    ? const BorderSide(color: Color(0xFFBFDBFE))
                    : BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: const Icon(Icons.visibility_off, size: 18),
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String text,
    Color color = const Color(0xFFDBEAFE),
    Color borderColor = const Color(0xFFBFDBFE),
    Color textColor = const Color(0xFF1E40AF),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompany() async {
    setState(() => _saving = true);
    final ok = await context.read<CompanyProvider>().updateCompany(
      name: _nombreComercialController.text.trim(),
      legalName: _razonSocialController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      bankName: _bankController.text.trim(),
      bankAccount: _accountController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Perfil actualizado' : 'No se pudo actualizar'),
      ),
    );
    if (ok) await context.read<AuthProvider>().refreshProfile();
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    if (newPassword.length < 6 ||
        newPassword != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifica la nueva contraseña')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().changePassword(
      oldPassword: _currentPasswordController.text,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Contraseña actualizada' : 'No se pudo actualizar'),
      ),
    );
  }
}
