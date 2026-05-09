import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/utils/responsive_utils.dart';
import 'package:frontend/core/widgets/app_popup.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

// Modelos para el registro de 3 pasos
class RegisterStep1Data {
  String role = 'employer';
  String fullName = '';
  String documentNumber = '';
  String email = '';
}

class RegisterStep2Data {
  String password = '';
  String confirmPassword = '';
  // Empleado
  String salary = '';
  int? companyId;
  String companyName = '';
  // Empleador
  String businessName = '';
  String employerCompanyName = '';
  String companyTaxId = '';
  String companyAddress = '';
  String companyCity = '';
  File? rutDocument;
  String rutFileName = '';
  File? chamberOfCommerceFile;
  String chamberFileName = '';
  File? legalRepresentativeIdDocument;
  String legalRepresentativeIdFileName = '';
  File? bankStatementsDocument;
  String bankStatementsDocumentName = '';
}

class RegisterStep3Data {
  String bankName = '';
  String accountNumber = '';
  bool termsAccepted = false;
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 1;
  bool _isLoading = false;

  // Datos de cada paso
  final step1 = RegisterStep1Data();
  final step2 = RegisterStep2Data();
  final step3 = RegisterStep3Data();

  // Form keys para cada paso
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Lista de empresas disponibles
  List<Map<String, dynamic>> _availableCompanies = [];
  bool _loadingCompanies = false;
  String? _companiesError;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAvailableCompanies() async {
    setState(() => _loadingCompanies = true);
    try {
      final response = await apiService.get('/api/companies/available/');
      setState(() {
        _availableCompanies = List<Map<String, dynamic>>.from(response);
        _companiesError = null;
      });
    } catch (e) {
      setState(() {
        _availableCompanies = [];
        _companiesError = 'No se pudieron cargar las empresas registradas';
      });
    } finally {
      setState(() => _loadingCompanies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveUtils.getScreenWidth(context);
    final isSmallScreen = screenWidth < 600;
    final isLandscapePhone = ResponsiveUtils.isLandscapePhone(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF1E6),
              Color(0xFFFFF7ED),
              Color(0xFFFFFBF7),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 32,
                vertical: isLandscapePhone ? 10 : 18,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscapePhone ? 760 : 500,
                ),
                child: Column(
                  children: [
                    _buildStepHeader(),
                    SizedBox(height: isLandscapePhone ? 14 : 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF101828,
                            ).withValues(alpha: 0.10),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isLandscapePhone ? 18 : 24),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final barMargin = isSmallScreen ? 6.0 : 10.0;
        const totalSteps = 2;

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildStepIndicator(1, totalSteps: totalSteps),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: barMargin),
                child: _buildProgressLine(isFilled: _currentStep >= 2),
              ),
            ),
            _buildStepIndicator(2, totalSteps: totalSteps),
          ],
        );
      },
    );
  }

  Widget _buildProgressLine({required bool isFilled}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFFFEDD5)),
            FractionallySizedBox(
              widthFactor: isFilled ? 1 : 0,
              alignment: Alignment.centerLeft,
              child: const ColoredBox(color: Color(0xFFF97316)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, {int totalSteps = 3}) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Semantics(
      label: 'Paso $step de $totalSteps',
      child: SizedBox.square(
        dimension: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF97316) : const Color(0xFFFFEDD5),
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: const Color(0xFFF97316), width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF9A3412),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  // PASO 1: Información Personal
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cuéntanos quién eres',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 20),

          _buildReadOnlyRole(),
          const SizedBox(height: 16),

          // Nombre completo
          _buildTextField(
            label: 'Nombre Completo',
            hint: 'Juan Pérez',
            initialValue: step1.fullName,
            onChanged: (v) => step1.fullName = v,
            validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),

          // Cédula
          _buildTextField(
            label: 'Cédula',
            hint: '1234567890',
            initialValue: step1.documentNumber,
            onChanged: (v) => step1.documentNumber = v,
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),

          // Correo
          _buildTextField(
            label: 'Correo Electrónico',
            hint: 'correo@ejemplo.com',
            initialValue: step1.email,
            onChanged: (v) => step1.email = v,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Campo requerido';
              if (!v!.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Botón siguiente
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Siguiente →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Link a login
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  text: '¿Ya tienes cuenta? ',
                  style: TextStyle(color: Color(0xFF667085)),
                  children: [
                    TextSpan(
                      text: 'Inicia sesión aquí',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToStep2() {
    if (_formKey1.currentState!.validate()) {
      setState(() => _currentStep = 2);
    }
  }

  // PASO 2: Seguridad y Datos
  Widget _buildStep2() {
    final isEmployee = step1.role == 'employee';
    final isEmployer = step1.role == 'employer';

    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 1),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Seguridad y Datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completa tu perfil',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 20),

          // Contraseña
          _buildPasswordField(
            label: 'Contraseña',
            hint: '••••••',
            onChanged: (v) => step2.password = v,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Campo requerido';
              if (v!.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirmar Contraseña
          _buildPasswordField(
            label: 'Confirmar Contraseña',
            hint: '••••••',
            onChanged: (v) => step2.confirmPassword = v,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Campo requerido';
              if (v != step2.password) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campos condicionales según rol
          if (isEmployee) ...[
            _buildTextField(
              label: 'Salario Mensual',
              hint: '2000000',
              initialValue: step2.salary,
              prefixText: '\$ ',
              onChanged: (v) => setState(() => step2.salary = v),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            // Dropdown de empresas
            _buildCompanyDropdown(),
          ] else if (isEmployer) ...[
            _buildTextField(
              label: 'Razón Social',
              hint: 'ABC',
              onChanged: (v) => step2.businessName = v,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Nombre de la Empresa',
              hint: 'Empresa ABC S.A.S',
              onChanged: (v) => step2.employerCompanyName = v,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'NIT',
              hint: '900123456-7',
              onChanged: (v) => step2.companyTaxId = v,
              keyboardType: TextInputType.text,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Direccion',
              hint: 'Calle 123 # 45-67',
              onChanged: (v) => step2.companyAddress = v,
              keyboardType: TextInputType.streetAddress,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Ciudad',
              hint: 'Barranquilla',
              onChanged: (v) => step2.companyCity = v,
              keyboardType: TextInputType.text,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildEmployerDocumentsSection(),
          ],
          const SizedBox(height: 24),

          // Botón siguiente o crear cuenta
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isEmployer ? _registerEmployer : _goToStep3,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEmployer ? 'Crear Cuenta' : 'Siguiente →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Link a login
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  text: '¿Ya tienes cuenta? ',
                  style: TextStyle(color: Color(0xFF667085)),
                  children: [
                    TextSpan(
                      text: 'Inicia sesión aquí',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToStep3() {
    if (_formKey2.currentState!.validate()) {
      setState(() => _currentStep = 3);
    }
  }

  // Registro para empleadores (sin paso 3)
  Future<void> _registerEmployer() async {
    if (!_formKey2.currentState!.validate()) return;
    if (!_hasAllEmployerDocuments()) {
      await _showRegisterDialog(
        title: 'Documentos incompletos',
        message:
            'Debes subir RUT, camara de comercio, cedula y extractos bancarios.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: step1.email.split('@').first,
      email: step1.email,
      password: step2.password,
      firstName: step1.fullName.split(' ').first,
      lastName: step1.fullName.split(' ').skip(1).join(' '),
      role: step1.role,
      phone: null,
      documentNumber: step1.documentNumber,
      salary: null,
      businessName: step2.businessName,
      companyName: step2.employerCompanyName,
      companyTaxId: step2.companyTaxId,
      companyAddress: step2.companyAddress,
      companyCity: step2.companyCity,
      companyId: null,
      rutDocument: step2.rutDocument,
      chamberOfCommerceFile: step2.chamberOfCommerceFile,
      legalRepresentativeIdDocument: step2.legalRepresentativeIdDocument,
      bankStatementsDocument: step2.bankStatementsDocument,
      bankAccount: null,
      bankName: null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      await _showRegisterDialog(
        title: 'Registro exitoso',
        message: 'Tu cuenta fue creada correctamente. Por favor inicia sesion.',
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else if (mounted) {
      await _showRegisterDialog(
        title: 'No se pudo registrar',
        message: authProvider.errorMessage ?? 'Error al registrar',
        isError: true,
      );
    }
  }

  // PASO 3: Información Bancaria
  Widget _buildStep3() {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 2),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Información Bancaria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Últimos detalles',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 20),

          // Banco
          _buildDropdown(
            label: 'Banco',
            value: step3.bankName.isEmpty ? null : step3.bankName,
            icon: Icons.account_balance,
            hint: 'Selecciona tu banco',
            items:
                [
                      'Bancolombia',
                      'Davivienda',
                      'BBVA',
                      'Banco de Bogotá',
                      'Nequi (Bancolombia)',
                      'Daviplata',
                      'Scotiabank',
                      'Itaú',
                    ]
                    .map(
                      (bank) =>
                          DropdownMenuItem(value: bank, child: Text(bank)),
                    )
                    .toList(),
            onChanged: (v) => setState(() => step3.bankName = v ?? ''),
          ),
          const SizedBox(height: 16),

          // Número de cuenta
          _buildTextField(
            label: 'Número de Cuenta',
            hint: '12345678901234',
            onChanged: (v) => step3.accountNumber = v,
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 20),

          // Términos y condiciones
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: step3.termsAccepted,
                onChanged: (v) =>
                    setState(() => step3.termsAccepted = v ?? false),
                activeColor: const Color(0xFFF97316),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => step3.termsAccepted = !step3.termsAccepted,
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Términos y Condiciones\n',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF97316),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Al registrarte aceptas nuestros términos de servicio y política de privacidad.',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF667085),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón crear cuenta
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Link a login
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  text: '¿Ya tienes cuenta? ',
                  style: TextStyle(color: Color(0xFF667085)),
                  children: [
                    TextSpan(
                      text: 'Inicia sesión aquí',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey3.currentState!.validate()) return;
    if (!step3.termsAccepted) {
      await _showRegisterDialog(
        title: 'Terminos pendientes',
        message: 'Debes aceptar los terminos y condiciones.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: step1.email.split('@').first,
      email: step1.email,
      password: step2.password,
      firstName: step1.fullName.split(' ').first,
      lastName: step1.fullName.split(' ').skip(1).join(' '),
      role: step1.role,
      phone: null,
      documentNumber: step1.documentNumber,
      salary: step2.salary.isNotEmpty ? double.tryParse(step2.salary) : null,
      businessName: step2.businessName,
      companyName: step2.employerCompanyName,
      companyTaxId: step2.companyTaxId,
      companyAddress: step2.companyAddress,
      companyCity: step2.companyCity,
      companyId: step2.companyId,
      rutDocument: step2.rutDocument,
      chamberOfCommerceFile: step2.chamberOfCommerceFile,
      legalRepresentativeIdDocument: step2.legalRepresentativeIdDocument,
      bankStatementsDocument: step2.bankStatementsDocument,
      bankAccount: step3.accountNumber,
      bankName: step3.bankName,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      await _showRegisterDialog(
        title: 'Registro exitoso',
        message: 'Tu cuenta fue creada correctamente. Por favor inicia sesion.',
      );
      if (!mounted) return;

      // Navegar al login en lugar de mainpage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else if (mounted) {
      await _showRegisterDialog(
        title: 'No se pudo registrar',
        message: authProvider.errorMessage ?? 'Error al registrar',
        isError: true,
      );
    }
  }

  Future<void> _showRegisterDialog({
    required String title,
    required String message,
    bool isError = false,
  }) async {
    if (!mounted) return;
    await AppPopup.show(
      context,
      title: title,
      message: message,
      type: isError ? AppPopupType.error : AppPopupType.success,
    );
  }

  // Dropdown de empresas para empleados
  Widget _buildCompanyDropdown() {
    if (_loadingCompanies) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_availableCompanies.isEmpty) {
      return _buildCompanyEmptySelector();
    }

    final items = _companyDropdownItems(
      _availableCompanies.map((company) {
        return DropdownMenuItem<int>(
          value: company['id'] as int,
          child: Text(company['name'] as String),
        );
      }).toList(),
    );

    return _buildDropdown(
      label: 'Empresa',
      hint: 'Selecciona tu empresa',
      icon: Icons.business,
      value: step2.companyId,
      items: items,
      onChanged: (value) => setState(() => step2.companyId = value as int?),
    );
  }

  List<DropdownMenuItem<dynamic>> _companyDropdownItems(
    List<DropdownMenuItem<int>> companies,
  ) {
    return [
      const DropdownMenuItem<int>(
        value: null,
        child: Text(
          'Selecciona una empresa...',
          style: TextStyle(color: Color(0xFFA8B3C2)),
        ),
      ),
      ...companies,
    ];
  }

  Widget _buildCompanyEmptySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Empresa',
          hint: _companiesError ?? 'No hay empresas registradas',
          icon: Icons.business,
          value: null,
          items: _companyDropdownItems(const []),
          onChanged: (_) {},
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _companiesError ?? 'No hay empresas disponibles para registro.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loadAvailableCompanies,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Recargar'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widgets auxiliares
  Widget _buildReadOnlyRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Usuario',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1E4D6)),
          ),
          child: _buildRoleItem('Empleador', Icons.business),
        ),
      ],
    );
  }

  Widget _buildRoleItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF97316)),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required IconData icon,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1E4D6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              hint: hint != null
                  ? Text(hint, style: const TextStyle(color: Color(0xFFA8B3C2)))
                  : null,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF667085)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    String? initialValue,
    required void Function(String) onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA8B3C2)),
            filled: true,
            fillColor: const Color(0xFFFFFBF7),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Color(0xFFF97316),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1E4D6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1E4D6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFF97316),
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required void Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: true,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA8B3C2), fontSize: 20),
            filled: true,
            fillColor: const Color(0xFFFFFBF7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1E4D6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1E4D6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFF97316),
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployerDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFileUploadTile(
          label: 'RUT',
          fileName: step2.rutFileName,
          onTap: () => _pickDocument(
            onSelected: (file, name) {
              step2.rutDocument = file;
              step2.rutFileName = name;
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUploadTile(
          label: 'Camara de Comercio',
          fileName: step2.chamberFileName,
          onTap: () => _pickDocument(
            onSelected: (file, name) {
              step2.chamberOfCommerceFile = file;
              step2.chamberFileName = name;
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUploadTile(
          label: 'Copia de cedula del representante legal',
          fileName: step2.legalRepresentativeIdFileName,
          onTap: () => _pickDocument(
            onSelected: (file, name) {
              step2.legalRepresentativeIdDocument = file;
              step2.legalRepresentativeIdFileName = name;
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUploadTile(
          label: 'Extractos bancarios de los ultimos 3 meses',
          fileName: step2.bankStatementsDocumentName,
          onTap: () => _pickDocument(
            onSelected: (file, name) {
              step2.bankStatementsDocument = file;
              step2.bankStatementsDocumentName = name;
            },
          ),
        ),
      ],
    );
  }

  bool _hasAllEmployerDocuments() {
    return step2.rutDocument != null &&
        step2.chamberOfCommerceFile != null &&
        step2.legalRepresentativeIdDocument != null &&
        step2.bankStatementsDocument != null;
  }

  Widget _buildFileUploadTile({
    required String label,
    required String fileName,
    required VoidCallback onTap,
  }) {
    final hasFile = fileName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile
                    ? const Color(0xFFF97316)
                    : const Color(0xFFF1E4D6),
                width: hasFile ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasFile ? Icons.description : Icons.cloud_upload_outlined,
                  size: 24,
                  color: const Color(0xFF667085),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasFile ? fileName : 'Subir PDF, PNG o JPEG',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDocument({
    required void Function(File file, String name) onSelected,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() => onSelected(File(file.path!), file.name));
        }
      }
    } catch (e) {
      if (!mounted) return;
      await _showRegisterDialog(
        title: 'No se pudo seleccionar',
        message: 'Error al seleccionar archivo: $e',
        isError: true,
      );
    }
  }

  Widget buildFileUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Cámara de Comercio (PDF)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: pickPDF,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: step2.chamberFileName.isEmpty
                    ? const Color(0xFFF1E4D6)
                    : const Color(0xFFF97316),
                style: BorderStyle.solid,
                width: step2.chamberFileName.isEmpty ? 1 : 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  step2.chamberFileName.isEmpty
                      ? Icons.cloud_upload_outlined
                      : Icons.description,
                  size: 32,
                  color: const Color(0xFF667085),
                ),
                const SizedBox(height: 8),
                Text(
                  step2.chamberFileName.isEmpty
                      ? 'Subir PDF\nMáximo 5MB'
                      : 'Archivo: ${step2.chamberFileName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> pickPDF() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            step2.chamberOfCommerceFile = File(file.path!);
            step2.chamberFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      await _showRegisterDialog(
        title: 'No se pudo seleccionar',
        message: 'Error al seleccionar archivo: $e',
        isError: true,
      );
    }
  }
}
