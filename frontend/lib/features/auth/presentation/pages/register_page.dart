import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../employee/presentation/pages/employee_main_page.dart';
import '../../../employer/presentation/pages/employer_main_page.dart';
import '../../../admin/presentation/pages/admin_main_page.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

// Modelos para el registro de 3 pasos
class RegisterStep1Data {
  String role = 'employee';
  String fullName = '';
  String documentNumber = '';
  String email = '';
}

class RegisterStep2Data {
  String password = '';
  String confirmPassword = '';
  // Empleado
  String salary = '';
  // Empleador
  String businessName = '';
  String companyName = '';
  File? chamberOfCommerceFile;
  String chamberFileName = '';
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEBF5FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 32,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Header con pasos
                  _buildStepHeader(),
                  const SizedBox(height: 24),

                  // Contenido del paso actual
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ],
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
        final barMargin = isSmallScreen ? 4.0 : 8.0;
        
        return Column(
          children: [
            // Barra de progreso
            Row(
              children: [
                _buildStepIndicator(1, 'Paso 1'),
                Flexible(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: barMargin),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Container(
                              width: _currentStep >= 2
                                  ? constraints.maxWidth
                                  : (_currentStep == 1 ? null : 0),
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _buildStepIndicator(2, 'Paso 2'),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 4,
                        margin: EdgeInsets.symmetric(horizontal: barMargin),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: _currentStep >= 3 ? constraints.maxWidth : 0,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildStepIndicator(3, 'Paso 3'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: const Color(0xFF2563EB), width: 2)
            : null,
      ),
      child: Center(
        child: isActive && !isCurrent
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),

          // Tipo de usuario
          _buildDropdown(
            label: 'Tipo de Usuario',
            value: step1.role,
            icon: Icons.person,
            items: [
              DropdownMenuItem(value: 'employee', child: _buildRoleItem('Empleado', Icons.person)),
              DropdownMenuItem(value: 'employer', child: _buildRoleItem('Empleador', Icons.business)),
              DropdownMenuItem(value: 'admin', child: _buildRoleItem('Administrador', Icons.admin_panel_settings)),
            ],
            onChanged: (v) => setState(() => step1.role = v!),
          ),
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
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Siguiente →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  style: TextStyle(color: Color(0xFF6B7280)),
                  children: [
                    TextSpan(
                      text: 'Inicia sesión aquí',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
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
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
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
          ] else if (isEmployer) ...[
            _buildTextField(
              label: 'Razón Social',
              hint: 'Empresa ABC S.A.S',
              onChanged: (v) => step2.businessName = v,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Nombre de la Empresa',
              hint: 'ABC',
              onChanged: (v) => step2.companyName = v,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildFileUploadField(),
          ],
          const SizedBox(height: 24),

          // Botón siguiente
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _goToStep3,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Siguiente →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  style: TextStyle(color: Color(0xFF6B7280)),
                  children: [
                    TextSpan(
                      text: 'Inicia sesión aquí',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
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
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),

          // Banco
          _buildDropdown(
            label: 'Banco',
            value: step3.bankName.isEmpty ? null : step3.bankName,
            icon: Icons.account_balance,
            hint: 'Selecciona tu banco',
            items: [
              'Bancolombia',
              'Davivienda',
              'BBVA',
              'Banco de Bogotá',
              'Nequi (Bancolombia)',
              'Daviplata',
              'Scotiabank',
              'Itaú',
            ].map((bank) => DropdownMenuItem(
              value: bank,
              child: Text(bank),
            )).toList(),
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
                onChanged: (v) => setState(() => step3.termsAccepted = v ?? false),
                activeColor: const Color(0xFF2563EB),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => step3.termsAccepted = !step3.termsAccepted),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Términos y Condiciones\n',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Al registrarte aceptas nuestros términos de servicio y política de privacidad.',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF6B7280),
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
                backgroundColor: const Color(0xFF2563EB),
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
                        Text('Crear Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  style: TextStyle(color: Color(0xFF6B7280)),
                  children: [
                    TextSpan(
                      text: 'Inicia sesión aquí',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
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
      companyName: step2.companyName,
      chamberOfCommerceFile: step2.chamberOfCommerceFile,
      bankAccount: step3.accountNumber,
      bankName: step3.bankName,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Por favor inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar al login en lugar de mainpage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error al registrar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widgets auxiliares
  Widget _buildRoleItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
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
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              hint: hint != null ? Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF))) : null,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
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
            color: Color(0xFF374151),
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
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: true,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 20),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadField() {
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
                color: Color(0xFF374151),
              ),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickPDF,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: step2.chamberFileName.isEmpty
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF2563EB),
                style: BorderStyle.solid,
                width: step2.chamberFileName.isEmpty ? 1 : 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  step2.chamberFileName.isEmpty ? Icons.cloud_upload_outlined : Icons.description,
                  size: 32,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(height: 8),
                Text(
                  step2.chamberFileName.isEmpty
                      ? 'Subir PDF\nMáximo 5MB'
                      : 'Archivo: ${step2.chamberFileName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }
}
