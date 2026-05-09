import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../companies/presentation/providers/company_provider.dart';

class EmployerCreateEmployeePage extends StatefulWidget {
  const EmployerCreateEmployeePage({super.key});

  @override
  State<EmployerCreateEmployeePage> createState() =>
      _EmployerCreateEmployeePageState();
}

class _EmployerCreateEmployeePageState
    extends State<EmployerCreateEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final List<String> _colombiaBanks = const [
    'Bancolombia',
    'Banco de Bogota',
    'Davivienda',
    'BBVA Colombia',
    'Banco de Occidente',
    'Banco Popular',
    'Banco AV Villas',
    'Banco Caja Social',
    'Banco Agrario',
    'Scotiabank Colpatria',
    'Itaú',
    'Citibank',
    'Nequi (Bancolombia)',
    'Daviplata',
    'Movii',
    'Otro',
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _passwordController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    _buildHero(),
                    const SizedBox(height: 16),
                    _buildFormSection(
                      title: 'Datos del colaborador',
                      icon: Icons.badge_outlined,
                      children: [
                        _formField(
                          controller: _nameController,
                          label: 'Nombre completo',
                          icon: Icons.person_outline,
                        ),
                        _formField(
                          controller: _documentController,
                          label: 'Cedula',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        _formField(
                          controller: _emailController,
                          label: 'Correo corporativo o personal',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            if (!value.contains('@')) {
                              return 'Correo invalido';
                            }
                            return null;
                          },
                        ),
                        _formField(
                          controller: _phoneController,
                          label: 'Telefono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          isRequired: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Nomina y acceso',
                      icon: Icons.payments_outlined,
                      children: [
                        _formField(
                          controller: _salaryController,
                          label: 'Salario mensual',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          helperText:
                              'Appdelanta usara este valor para calcular el cupo de adelanto.',
                          validator: (value) {
                            final salary = double.tryParse(
                              (value ?? '').replaceAll('.', ''),
                            );
                            if (salary == null || salary <= 0) {
                              return 'Ingresa un salario valido';
                            }
                            return null;
                          },
                        ),
                        _formField(
                          controller: _passwordController,
                          label: 'Contrasena temporal',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          helperText: 'El empleado podra cambiarla despues.',
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Minimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Datos bancarios',
                      icon: Icons.account_balance_outlined,
                      children: [
                        _formField(
                          controller: _bankAccountController,
                          label: 'Numero de cuenta',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          helperText:
                              'Aqui se enviaran los adelantos aprobados.',
                        ),
                        _bankDropdown(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildPolicyNote(),
                    const SizedBox(height: 18),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _bankNameController,
        readOnly: true,
        onTap: _isSubmitting ? null : _showBankSelector,
        decoration: _fieldDecoration(
          label: 'Banco',
          icon: Icons.account_balance_outlined,
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF047857),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Selecciona un banco';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: const Color(0xFF047857), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w600,
      ),
      helperStyle: const TextStyle(color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
      ),
    );
  }

  void _showBankSelector() {
    const banksPerPage = 6;
    var currentPage = 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final totalPages = (_colombiaBanks.length / banksPerPage).ceil();
            final start = currentPage * banksPerPage;
            final visibleBanks = _colombiaBanks
                .skip(start)
                .take(banksPerPage)
                .toList();
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF047857), Color(0xFF14B8A6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Seleccionar banco',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...visibleBanks.map((bank) {
                      final selected = _bankNameController.text == bank;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _bankNameController.text = bank);
                            Navigator.pop(sheetContext);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.account_balance_outlined,
                                  color: selected
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bank,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          onPressed: currentPage == 0
                              ? null
                              : () => setSheetState(() => currentPage--),
                          icon: const Icon(Icons.chevron_left_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFECFDF5),
                            disabledBackgroundColor: const Color(0xFFF1F5F9),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Pagina ${currentPage + 1} de $totalPages',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: currentPage >= totalPages - 1
                              ? null
                              : () => setSheetState(() => currentPage++),
                          icon: const Icon(Icons.chevron_right_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFECFDF5),
                            disabledBackgroundColor: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFE0F2FE)],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFBAE6FD), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF0F172A),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo empleado',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Registro de equipo',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Alta directa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Registra el empleado y su cupo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Con el salario definido, Appdelanta calcula el limite disponible y deja listo el acceso del colaborador.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroPill(
                  'Cupo inicial',
                  '50% salario',
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroPill(
                  'Acceso',
                  'Correo + clave',
                  Icons.mark_email_read_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA7F3D0), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF047857)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isRequired = true,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: TextInputAction.next,
        cursorColor: const Color(0xFF047857),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: const Color(0xFF047857), size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          helperStyle: const TextStyle(color: Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
          ),
        ),
        validator:
            validator ??
            (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Campo requerido';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildPolicyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF047857),
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'El empleado quedara activo y podra solicitar adelantos segun las reglas de la empresa.',
              style: TextStyle(
                color: Color(0xFF047857),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_rounded, size: 19),
            label: Text(_isSubmitting ? 'Creando' : 'Crear empleado'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final companyProvider = context.read<CompanyProvider>();
    final names = _nameController.text.trim().split(RegExp(r'\s+'));
    final firstName = names.first;
    final lastName = names.length > 1 ? names.skip(1).join(' ') : '';
    final salary = double.parse(_salaryController.text.replaceAll('.', ''));

    setState(() => _isSubmitting = true);
    final success = await companyProvider.addEmployee(
      username: _emailController.text.trim().split('@').first,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: firstName,
      lastName: lastName,
      salary: salary,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      documentNumber: _documentController.text.trim(),
      bankName: _bankNameController.text.trim(),
      bankAccount: _bankAccountController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    await AppPopup.show(
      context,
      title: 'No se pudo crear',
      message: companyProvider.errorMessage ?? 'No se pudo crear el empleado.',
      type: AppPopupType.error,
    );
  }
}
